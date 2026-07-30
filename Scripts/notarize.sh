#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="${1:-$ROOT/.build/TokenBar for Codex.app}"
ARCHIVE_PATH="${2:-$ROOT/.build/TokenBar-for-Codex-notarized.zip}"
NOTARY_PROFILE="${TOKENBAR_NOTARY_PROFILE:-TokenBarNotary}"

if [[ ! -d "$APP_PATH/Contents/MacOS" ]]; then
  echo "Not a packaged macOS application: $APP_PATH" >&2
  exit 2
fi

signature_details="$(codesign -dvv "$APP_PATH" 2>&1 || true)"
if [[ "$signature_details" != *"Authority=Developer ID Application:"* ]]; then
  echo "The app must be signed with a Developer ID Application certificate." >&2
  echo "Set TOKENBAR_SIGN_IDENTITY when running Scripts/package.sh." >&2
  exit 2
fi

codesign --verify --deep --strict --verbose=2 "$APP_PATH"
"$ROOT/Scripts/create_archive.sh" "$APP_PATH" "$ARCHIVE_PATH"

xcrun notarytool submit \
  "$ARCHIVE_PATH" \
  --keychain-profile "$NOTARY_PROFILE" \
  --wait
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"
spctl --assess --type execute --verbose=4 "$APP_PATH"

# Rebuild the distributed archive so it contains the stapled ticket.
"$ROOT/Scripts/create_archive.sh" "$APP_PATH" "$ARCHIVE_PATH"
