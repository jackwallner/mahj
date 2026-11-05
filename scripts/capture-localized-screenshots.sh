#!/usr/bin/env bash
# Capture the raw App Store screens in every shipped language and region.
#
# Usage:
#   scripts/capture-localized-screenshots.sh phone <udid> [locale ...]
#   scripts/capture-localized-screenshots.sh ipad  [locale ...]   # own 13-inch sim
#
# Writes build/l10n-raw/<asc-locale>/{phone,ipad}/ for
# scripts/localize_appstore_screenshots.py --recapture. Phone runs on the pool
# iPhone 17 Pro the English set used; iPad goes through with-ipad-sim.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RAW="$ROOT/build/l10n-raw"

# ASC locale  catalog-language  AppleLocale
LOCALES=(
  "ar-SA ar ar_AE"
  "de-DE de de_DE"
  "es-ES es es_ES"
  "es-MX es es_MX"
  "fr-FR fr fr_FR"
  "fr-CA fr fr_CA"
  "id id id_ID"
  "vi vi vi_VN"
)

shoot() { # asc-locale language apple-locale kind udid
  local out="$RAW/$1/$4"
  rm -rf "$out"
  SCREENSHOT_LANGUAGE="$2" SCREENSHOT_LOCALE="$3" \
    "$ROOT/scripts/capture-screenshots.sh" "$5" "$out" "$([ "$4" = ipad ] && echo ipad_ || true)"
}

run() { # kind udid wanted...
  local kind="$1" udid="$2"; shift 2
  local line asc lang loc
  for line in "${LOCALES[@]}"; do
    read -r asc lang loc <<<"$line"
    if [ "$#" -gt 0 ] && [[ " $* " != *" $asc "* ]]; then continue; fi
    echo "== $kind $asc"
    shoot "$asc" "$lang" "$loc" "$kind" "$udid"
  done
}

case "${1:?phone|ipad}" in
  phone) shift; udid="${1:?udid}"; shift; run phone "$udid" "$@" ;;
  ipad)
    shift
    export -f run shoot
    export ROOT RAW
    export LOCALES_STR="${LOCALES[*]}"
    "$ROOT/scripts/with-ipad-sim.sh" bash -c "$(declare -p LOCALES RAW ROOT); $(declare -f shoot run); run ipad \"\$IPAD_UDID\" $*" ;;
  *) echo "usage: phone <udid> | ipad" >&2; exit 2 ;;
esac
