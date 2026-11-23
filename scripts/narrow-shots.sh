#!/usr/bin/env bash
# Screenshots every screen in a narrow window on a booted simulator, so a
# release can be checked at the widths no pool device has: 320pt (a 6.1"
# iPhone with Display Zoom, iPad Slide Over) and 375pt (iPhone SE, mini,
# a zoomed Plus or Pro Max). Uses the DEBUG `-mahj.windowSize` and
# `-mahj.shot` launch arguments, so install a Debug build first.
#
# Usage: scripts/narrow-shots.sh <udid> <out-dir> [WxH ...]   (default 320x693 375x667)
#
# Look at every PNG: no tile, card or line of text may be cut at an edge or
# end in "...". (2026-11-21: a 1-star review, "text and tiles are constantly
# cut off", from an iPhone 15 Pro with Display Zoom.)
set -euo pipefail

UDID="${1:?usage: narrow-shots.sh <udid> <out-dir> [WxH ...]}"
OUT="${2:?out-dir}"
shift 2
SIZES=("$@")
[[ ${#SIZES[@]} -eq 0 ]] && SIZES=(320x693 375x667)

ROUTES=(home settings paywall reference stats challenge quick handplay
  room/tile-room room/card-room room/charleston-room room/table-room room/pro-tables
  drill/meet-tiles drill/tile-quiz drill/plus-tile-extras drill/category-cards drill/hand-match
  drill/plus-rack-extras drill/charleston-rules drill/charleston-pass drill/plus-charleston-extras
  drill/judgment-cards drill/table-quiz drill/plus-judgment-extras drill/pro-charleston
  drill/pro-defense drill/pro-rack-reading drill/pro-joker-rules)

for size in "${SIZES[@]}"; do
  mkdir -p "$OUT/$size"
  for route in "${ROUTES[@]}"; do
    xcrun simctl launch --terminate-running-process "$UDID" com.jackwallner.mahj \
      -progress.hasOnboarded YES -subscription.localProOverride YES -mahj.skillLevel some \
      -mahj.hasReadPrimer YES -mahj.suppressWhatsNew -reviewPrompt.launchCount 0 \
      -mahj.windowSize "$size" -mahj.shot "$route" >/dev/null
    # The route fires 2 seconds after launch; a pushed drill needs the rest.
    sleep 10
    xcrun simctl io "$UDID" screenshot "$OUT/$size/${route//\//_}.png" >/dev/null 2>&1
  done
  echo "$size: ${#ROUTES[@]} screens in $OUT/$size"
done
