#!/usr/bin/env bash
# Capture the App Store screenshot set from the real app.
#
# Usage:
#   scripts/capture-screenshots.sh <simulator-udid> <output-dir> [prefix]
#
# The iPad set needs a 13-inch device (2064x2752); the pool has no iPad Pro, so
# scripts/with-ipad-sim.sh creates a throwaway one and hands the UDID over.
# Runs headless: it never opens Simulator.app.
#
# SCREENSHOT_LANGUAGE (catalog code, e.g. de) and SCREENSHOT_LOCALE (e.g. de_DE)
# run the app in that language and region; unset, the app runs in English.
# scripts/capture-localized-screenshots.sh sets both per locale.
set -euo pipefail

UDID="${1:?usage: capture-screenshots.sh <udid> <output-dir> [prefix]}"
OUT="${2:?usage: capture-screenshots.sh <udid> <output-dir> [prefix]}"
PREFIX="${3:-}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# The run needs this Mac's leased simulator and local files; never overflow to GitHub.
export GH_SIM_OVERFLOW=0
RESULT="$ROOT/build/screenshots.xcresult"
rm -rf "$RESULT"
mkdir -p "$ROOT/build"

cd "$ROOT"
# Export whatever the run captured even when the test reports a failure: a
# missing element on screen 4 should not throw away screens 1 to 3.
VERSION="$(awk '/MARKETING_VERSION/ {gsub(/[":]/, "", $2); print $2; exit}' project.yml)"

# The status bar override only sticks on a booted device.
xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || true
# A fresh install every run: saved progress (a half-done drill's Resume card,
# streaks, hands played) would otherwise leak from the previous language's run.
xcrun simctl uninstall "$UDID" com.jackwallner.mahj >/dev/null 2>&1 || true
# A clean status bar (9:41, full bars) on every capture, as the store set has.
xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged \
  --batteryLevel 100 --wifiBars 3 --cellularBars 4 >/dev/null 2>&1 || true

# Exported as well as passed as settings: on Xcode 27 the settings alone did not
# reach the test process, the environment form did.
export TEST_RUNNER_SCREENSHOT_APP_VERSION="$VERSION"
if [ -n "${SCREENSHOT_LANGUAGE:-}" ]; then
  STRINGS="$(mktemp -t mahj-strings).json"
  python3 "$ROOT/scripts/dump_screenshot_strings.py" "$SCREENSHOT_LANGUAGE" "$STRINGS"
  export TEST_RUNNER_SCREENSHOT_LANGUAGE="$SCREENSHOT_LANGUAGE"
  export TEST_RUNNER_SCREENSHOT_LOCALE="${SCREENSHOT_LOCALE:-}"
  export TEST_RUNNER_SCREENSHOT_STRINGS="$STRINGS"
fi

# TEST_RUNNER_-prefixed settings arrive in the UI test process as plain env
# vars, which is how the runner learns the marketing version it must mark as
# already seen to keep the What's New sheet off every screenshot.
xcodebuild test \
  -project MahjTrainer.xcodeproj \
  -scheme Screenshots \
  -destination "id=$UDID" \
  -resultBundlePath "$RESULT" \
  -only-testing:MahjTrainerScreenshots/ScreenshotTests \
  TEST_RUNNER_SCREENSHOT_APP_VERSION="$VERSION" \
  || echo "xcodebuild reported failures; exporting what was captured" >&2

STAGE="$(mktemp -d)"
xcrun xcresulttool export attachments --path "$RESULT" --output-path "$STAGE"

mkdir -p "$OUT"
# The manifest maps Xcode's generated filenames back to the names the test gave
# each attachment; without it every shot lands as a UUID.
python3 - "$STAGE" "$OUT" "$PREFIX" <<'PY'
import json, pathlib, re, shutil, sys

stage, out, prefix = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]), sys.argv[3]
manifest = json.loads((stage / "manifest.json").read_text())

copied = 0
for entry in manifest:
    for att in entry.get("attachments", []):
        name = att.get("suggestedHumanReadableName") or att.get("exportedFileName", "")
        src = stage / att["exportedFileName"]
        if not src.exists() or not name:
            continue
        # Xcode appends _<n>_<UUID> to attachment names; keep the test's own name.
        stem = re.sub(r"_\d+_[0-9A-F]{8}-[0-9A-F-]{27}$", "", pathlib.Path(name).stem)
        shutil.copyfile(src, out / f"{prefix}{stem}{src.suffix}")
        copied += 1
print(f"wrote {copied} screenshots to {out}")
PY
