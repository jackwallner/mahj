#!/usr/bin/env bash
# CTA wording test captures (MetaAndCTARenderTests): both CTA arms on both
# purchase surfaces. Reinstalls the app first.
#
# Usage:
#   scripts/capture-meta-cta.sh <simulator-udid> <output-dir>
#
# Why a UI test and not simctl: the test drives the app to both surfaces and
# captures the trial copy exactly as it ships. Headless:
# never opens Simulator.app.
set -euo pipefail

UDID="${1:?usage: capture-meta-cta.sh <udid> <output-dir>}"
OUT="${2:?usage: capture-meta-cta.sh <udid> <output-dir>}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RESULT="$ROOT/build/meta-cta.xcresult"
rm -rf "$RESULT"
mkdir -p "$ROOT/build"

cd "$ROOT"

xcrun simctl uninstall "$UDID" com.jackwallner.mahj >/dev/null 2>&1 || true

test_status=0
xcodebuild test \
  -project MahjTrainer.xcodeproj \
  -scheme Screenshots \
  -destination "id=$UDID" \
  -resultBundlePath "$RESULT" \
  -only-testing:"MahjTrainerScreenshots/MetaAndCTARenderTests${ONLY_TEST:+/$ONLY_TEST}" \
  || test_status=$?

STAGE="$(mktemp -d)"
xcrun xcresulttool export attachments --path "$RESULT" --output-path "$STAGE"

mkdir -p "$OUT"
python3 - "$STAGE" "$OUT" <<'PY'
import json, pathlib, shutil, sys

stage, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
manifest = json.loads((stage / "manifest.json").read_text())

copied = 0
for entry in manifest:
    for att in entry.get("attachments", []):
        name = att.get("suggestedHumanReadableName") or att.get("exportedFileName", "")
        src = stage / att["exportedFileName"]
        if not src.exists() or not name:
            continue
        # Xcode appends _0_<uuid> to every attachment name; strip it so a re-run
        # overwrites the previous capture instead of piling up.
        stem = pathlib.Path(name).stem.split("_0_")[0]
        shutil.copyfile(src, out / f"{stem}{src.suffix}")
        copied += 1
print(f"wrote {copied} attachments to {out}")
PY

if (( test_status != 0 )); then
  echo "meta/cta render tests failed" >&2
  exit "$test_status"
fi

for expected in ${EXPECTED:-cta_seven_day_onboarding.png cta_my_onboarding.png cta_your_paywall.png att_prompt_home.png}; do
  if [[ ! -f "$OUT/$expected" ]]; then
    echo "missing required capture: $expected" >&2
    exit 1
  fi
done
