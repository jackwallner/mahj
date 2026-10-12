#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$DIR/.."

SCHEME="MahjTrainer"
ARCHIVE_PATH="$PROJECT_DIR/build/MahjTrainer.xcarchive"

cd "$PROJECT_DIR"

# Auto-increment build number so TestFlight never rejects a duplicate
echo "==> Bumping build number..."
CURRENT_BUILD=$(grep 'CURRENT_PROJECT_VERSION:' project.yml | sed 's/.*: *"\(.*\)".*/\1/')
NEXT_BUILD=$((CURRENT_BUILD + 1))
sed -i '' "s/CURRENT_PROJECT_VERSION: \"$CURRENT_BUILD\"/CURRENT_PROJECT_VERSION: \"$NEXT_BUILD\"/" project.yml
echo "    $CURRENT_BUILD -> $NEXT_BUILD"

echo "==> Regenerating Xcode project..."
if command -v xcodegen &> /dev/null; then
  xcodegen generate
else
  echo "warning: xcodegen not found. Using existing MahjTrainer.xcodeproj."
fi

echo "==> Cleaning..."
xcodebuild -project MahjTrainer.xcodeproj -scheme "$SCHEME" clean

# Archive signing uses the same ASC API key as the upload step when one is
# available (env or ~/.baseball_credentials), so a stale Xcode Apple ID session
# cannot fail the run halfway through.
CREDENTIALS="${ASC_CREDENTIALS_FILE:-$HOME/.baseball_credentials}"
if [[ -z "${ASC_API_KEY_ID:-}" || -z "${ASC_ISSUER_ID:-}" || -z "${ASC_KEY_PATH:-}" ]] && [[ -f "$CREDENTIALS" ]]; then
  # shellcheck disable=SC1090
  source "$CREDENTIALS"
fi
AUTH_ARGS=()
if [[ -n "${ASC_API_KEY_ID:-}" && -n "${ASC_ISSUER_ID:-}" && -f "${ASC_KEY_PATH:-/nonexistent}" ]]; then
  AUTH_ARGS=(-authenticationKeyPath "$ASC_KEY_PATH" -authenticationKeyID "$ASC_API_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")
  echo "==> Signing with App Store Connect API key $ASC_API_KEY_ID"
else
  echo "==> No ASC API key found; signing with Xcode's local Apple ID session"
fi

echo "==> Archiving..."
xcodebuild -project MahjTrainer.xcodeproj -scheme "$SCHEME" -configuration Release archive -archivePath "$ARCHIVE_PATH" -destination "generic/platform=iOS" -allowProvisioningUpdates ${AUTH_ARGS[@]+"${AUTH_ARGS[@]}"}

echo "==> Exporting & Uploading..."
exec "$DIR/upload-testflight.sh" "$ARCHIVE_PATH"
