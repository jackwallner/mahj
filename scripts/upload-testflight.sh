#!/usr/bin/env bash
# Upload an archive to TestFlight via xcodebuild -exportArchive with
# AppStoreUploadOptions.plist (destination=upload, method=app-store-connect).
#
# Authentication, in order of preference:
#   1. App Store Connect API key. Read from the environment, or sourced from
#      ~/.baseball_credentials (the fleet's shared ASC key) when the three
#      variables are not already set. This is the reliable path: it does not
#      depend on Xcode being signed in or on a cached Apple ID session that
#      can expire between runs.
#   2. Xcode's local Apple ID session (Xcode -> Settings -> Accounts, team
#      YXG4MP6W39), used only when no API key is available.
#
# Required for the API key path:
#   ASC_API_KEY_ID   key id            (AuthKey_<ID>.p8)
#   ASC_ISSUER_ID    issuer id
#   ASC_KEY_PATH     absolute path to the .p8 file
#
# Usage:
#   ./scripts/upload-testflight.sh [path/to/MahjTrainer.xcarchive]
#
# Default archive: ./build/MahjTrainer.xcarchive

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCHIVE="${1:-$ROOT/build/MahjTrainer.xcarchive}"
STAGING="$ROOT/build/upload-staging"
PLIST="$ROOT/AppStoreUploadOptions.plist"
CREDENTIALS="${ASC_CREDENTIALS_FILE:-$HOME/.baseball_credentials}"

if [[ ! -d "$ARCHIVE" ]]; then
  echo "error: archive not found: $ARCHIVE" >&2
  echo "Create one first: bash scripts/testflight.sh" >&2
  exit 1
fi

if [[ ! -f "$PLIST" ]]; then
  echo "error: missing $PLIST" >&2
  exit 1
fi

# Pick up the fleet ASC key when the caller has not supplied one.
if [[ -z "${ASC_API_KEY_ID:-}" || -z "${ASC_ISSUER_ID:-}" || -z "${ASC_KEY_PATH:-}" ]]; then
  if [[ -f "$CREDENTIALS" ]]; then
    # shellcheck disable=SC1090
    source "$CREDENTIALS"
  fi
fi

AUTH_ARGS=()
if [[ -n "${ASC_API_KEY_ID:-}" && -n "${ASC_ISSUER_ID:-}" && -n "${ASC_KEY_PATH:-}" ]]; then
  if [[ ! -f "$ASC_KEY_PATH" ]]; then
    echo "error: ASC_KEY_PATH does not exist: $ASC_KEY_PATH" >&2
    exit 1
  fi
  AUTH_ARGS=(
    -authenticationKeyPath "$ASC_KEY_PATH"
    -authenticationKeyID "$ASC_API_KEY_ID"
    -authenticationKeyIssuerID "$ASC_ISSUER_ID"
  )
  AUTH_LABEL="App Store Connect API key $ASC_API_KEY_ID"
else
  AUTH_LABEL="local Xcode Apple ID session (no ASC API key found; set ASC_API_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH or populate $CREDENTIALS)"
fi

mkdir -p "$STAGING"
echo "Uploading archive to App Store Connect..."
echo "  archive: $ARCHIVE"
echo "  plist:   $PLIST"
echo "  auth:    $AUTH_LABEL"

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$STAGING" \
  -exportOptionsPlist "$PLIST" \
  -allowProvisioningUpdates \
  ${AUTH_ARGS[@]+"${AUTH_ARGS[@]}"}

echo "Upload accepted. Check App Store Connect -> TestFlight for \"Processing\"."
