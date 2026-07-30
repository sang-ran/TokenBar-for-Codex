#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="${1:-$ROOT/.build/TokenBar for Codex.app}"
ARCHIVE_PATH="${2:-$ROOT/.build/TokenBar-for-Codex.zip}"

if [[ ! -d "$APP_PATH/Contents/MacOS" ]]; then
  echo "Not a packaged macOS application: $APP_PATH" >&2
  exit 2
fi

case "$ARCHIVE_PATH" in
  *.zip) ;;
  *)
    echo "Archive path must end in .zip." >&2
    exit 2
    ;;
esac

mkdir -p "$(dirname "$ARCHIVE_PATH")"
rm -f -- "$ARCHIVE_PATH" "$ARCHIVE_PATH.sha256"
/usr/bin/ditto -c -k --norsrc --keepParent "$APP_PATH" "$ARCHIVE_PATH"

if /usr/bin/unzip -Z1 "$ARCHIVE_PATH" | /usr/bin/grep -q '^__MACOSX/'; then
  echo "Archive unexpectedly contains __MACOSX metadata." >&2
  exit 1
fi

archive_directory="$(cd "$(dirname "$ARCHIVE_PATH")" && pwd)"
archive_name="$(basename "$ARCHIVE_PATH")"
(
  cd "$archive_directory"
  /usr/bin/shasum -a 256 "$archive_name" > "$archive_name.sha256"
)
echo "$ARCHIVE_PATH"
echo "$ARCHIVE_PATH.sha256"
