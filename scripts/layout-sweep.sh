#!/usr/bin/env bash
# Layout and accessibility capture sweep (LayoutSweepTests) on one throwaway
# simulator: creates it, boots it headless, runs every requested text size /
# orientation / scope, exports the screenshots, then shuts it down and deletes
# it. Never opens Simulator.app, never uses a named destination.
#
# Usage:
#   scripts/layout-sweep.sh <device-type-id> <label> <out-root> <run>...
#
#   run = SIZE:ORIENT:SCOPE[:BUILD]
#     SIZE   L | XXXL | AX3 | AX5
#     ORIENT portrait | landscape
#     SCOPE  full | compare | new | rest | ipad_landscape
#     BUILD  key into XCTESTRUN_<BUILD> / OUT_<BUILD> env vars (default: main)
#
# Env:
#   XCTESTRUN_main  .xctestrun from `xcodebuild build-for-testing -scheme Screenshots`
#   XCTESTRUN_<b>   another build's .xctestrun (e.g. an older release)
#   OUT_<b>         output root for that build (default: <out-root>)
#
# Screenshots land in <out-root>/<label>/<SIZE>[-landscape]/<screen>.png, with
# the test's notes (unreachable controls, edge overflow, PASS/FAIL checks) in
# notes.txt beside them.
#
# Example:
#   XCTESTRUN_main=$(ls ~/Library/Developer/Xcode/DerivedData/MahjTrainer-*/Build/Products/Screenshots_*.xctestrun) \
#   scripts/layout-sweep.sh com.apple.CoreSimulator.SimDeviceType.iPhone-17 iphone17 out \
#     L:portrait:full XXXL:portrait:full AX3:portrait:full AX5:portrait:full
set -euo pipefail

TYPE="${1:?usage: layout-sweep.sh <device-type-id> <label> <out-root> <run>...}"
LABEL="${2:?label}"
OUT_ROOT="${3:?out-root}"
shift 3

BUNDLE_ID="com.jackwallner.mahj"
RUNTIME="$(xcrun simctl list runtimes -j | python3 -c "
import json,sys
rts=[r for r in json.load(sys.stdin)['runtimes'] if r['isAvailable'] and r['platform']=='iOS']
print(sorted(rts, key=lambda r: [int(x) for x in r['version'].split('.')])[-1]['identifier'])
")"

# SWEEP_UDID reuses an existing (already booted) simulator and leaves it alone.
if [[ -n "${SWEEP_UDID:-}" ]]; then
  UDID="$SWEEP_UDID"
else
  UDID="$(xcrun simctl create "mahj-sweep-$LABEL-$$" "$TYPE" "$RUNTIME")"
fi
WORK="$(mktemp -d)"
cleanup() {
  if [[ -z "${SWEEP_UDID:-}" ]]; then
    xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true
    xcrun simctl delete "$UDID" >/dev/null 2>&1 || true
  fi
  rm -rf "$WORK"
}
trap cleanup EXIT

echo "[$LABEL] created $UDID ($TYPE, $RUNTIME); waiting for a boot slot"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 \
  --cellularBars 4 --wifiBars 3 >/dev/null 2>&1 || true
echo "[$LABEL] booted"

for run in "$@"; do
  IFS=: read -r SIZE ORIENT SCOPE BUILD <<<"$run"
  BUILD="${BUILD:-main}"
  xctestrun_var="XCTESTRUN_$BUILD"
  out_var="OUT_$BUILD"
  XCTESTRUN="${!xctestrun_var:?set $xctestrun_var}"
  ROOT="${!out_var:-$OUT_ROOT}"
  DIR_NAME="$SIZE"
  [[ "$ORIENT" == "landscape" ]] && DIR_NAME="$SIZE-landscape"
  OUT="$ROOT/$LABEL/$DIR_NAME"
  mkdir -p "$OUT"

  # A fresh install per run: progress, the monthly challenge result and the
  # tracking answer all persist otherwise.
  # Terminate first: an app still running from the last run can survive the
  # uninstall with its data container intact.
  for _ in 1 2 3; do
    xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
    xcrun simctl uninstall "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
    xcrun simctl get_app_container "$UDID" "$BUNDLE_ID" data >/dev/null 2>&1 || break
    sleep 2
  done
  xcrun simctl privacy "$UDID" reset all "$BUNDLE_ID" >/dev/null 2>&1 || true

  RESULT="$WORK/$BUILD-$DIR_NAME.xcresult"
  echo "[$LABEL] $BUILD $SIZE $ORIENT $SCOPE: running"
  start=$(date +%s)
  status=0
  TEST_RUNNER_SWEEP_SIZE="$SIZE" TEST_RUNNER_SWEEP_ORIENT="$ORIENT" TEST_RUNNER_SWEEP_SCOPE="$SCOPE" \
    xcodebuild test-without-building -quiet \
      -xctestrun "$XCTESTRUN" \
      -destination "id=$UDID" \
      -resultBundlePath "$RESULT" \
      -only-testing:MahjTrainerScreenshots/LayoutSweepTests/testSweep \
      -collect-test-diagnostics never \
      >"$WORK/log.txt" 2>&1 || status=$?

  xcrun xcresulttool get test-results summary --path "$RESULT" --compact >"$OUT/summary.json" 2>/dev/null || true
  STAGE="$WORK/stage-$BUILD-$DIR_NAME"
  mkdir -p "$STAGE"
  xcrun xcresulttool export attachments --path "$RESULT" --output-path "$STAGE" >/dev/null 2>&1 || true
  python3 - "$STAGE" "$OUT" <<'PY'
import json, pathlib, re, shutil, sys

stage, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
manifest_path = stage / "manifest.json"
if not manifest_path.exists():
    print("  no attachments exported")
    sys.exit(0)
copied = 0
for entry in json.loads(manifest_path.read_text()):
    for att in entry.get("attachments", []):
        name = att.get("suggestedHumanReadableName") or ""
        src = stage / att.get("exportedFileName", "")
        if not src.exists() or not name:
            continue
        stem = pathlib.Path(name).stem
        # Xcode appends _<index>_<UUID> to every attachment name.
        stem = re.sub(r"_\d+_[0-9A-Fa-f-]{36}$", "", stem)
        if stem.startswith("shot_"):
            dest = out / f"{stem[5:]}{src.suffix}"
        elif stem == "notes":
            dest = out / "notes.txt"
        else:
            dest = out / f"{stem}.txt"
        if src.suffix in (".mov", ".mp4") or "Spindump" in stem or "Screen Recording" in stem:
            continue
        shutil.copyfile(src, dest)
        copied += 1
print(f"  exported {copied} attachments")
PY
  echo "[$LABEL] $BUILD $SIZE $ORIENT $SCOPE: done in $(( $(date +%s) - start ))s (xcodebuild status $status) -> $OUT"
  if (( status != 0 )); then
    tail -20 "$WORK/log.txt" | sed "s/^/  /"
  fi
  rm -rf "$RESULT" "$STAGE"
done
if [[ -n "${SWEEP_UDID:-}" ]]; then echo "[$LABEL] finished; kept $UDID"; else echo "[$LABEL] finished; deleting $UDID"; fi
