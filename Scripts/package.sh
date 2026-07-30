#!/usr/bin/env bash
set -euo pipefail

CONFIGURATION="${1:-release}"
DESTINATION="${2:-}"
ARCHITECTURE="${TOKENBAR_ARCH:-arm64}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

case "$CONFIGURATION" in
  debug|release) ;;
  *)
    echo "Configuration must be debug or release." >&2
    exit 2
    ;;
esac

if [[ -z "$DESTINATION" ]]; then
  DESTINATION="$ROOT/.build/TokenBar for Codex.app"
fi

swift build -c "$CONFIGURATION" --arch "$ARCHITECTURE" --product TokenBar
BIN_DIR="$(swift build -c "$CONFIGURATION" --arch "$ARCHITECTURE" --show-bin-path)"
STAGE="$ROOT/.build/tokenbar-package/TokenBar for Codex.app"

rm -rf -- "$ROOT/.build/tokenbar-package"
mkdir -p "$STAGE/Contents/MacOS" "$STAGE/Contents/Resources"
cp "$BIN_DIR/TokenBar" "$STAGE/Contents/MacOS/TokenBar"
cp "$ROOT/Packaging/Info.plist" "$STAGE/Contents/Info.plist"
if [[ -f "$ROOT/Resources/TokenBar.icns" ]]; then
  cp "$ROOT/Resources/TokenBar.icns" "$STAGE/Contents/Resources/TokenBar.icns"
fi
chmod +x "$STAGE/Contents/MacOS/TokenBar"

xattr -cr "$STAGE"
codesign --force --deep --sign - "$STAGE"
codesign --verify --deep --strict --verbose=2 "$STAGE"
file "$STAGE/Contents/MacOS/TokenBar" | grep -q "arm64"

mkdir -p "$(dirname "$DESTINATION")"
rm -rf -- "$DESTINATION"
/usr/bin/ditto "$STAGE" "$DESTINATION"
echo "$DESTINATION"
