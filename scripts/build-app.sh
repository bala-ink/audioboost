#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

CONFIGURATION="${CONFIGURATION:-release}"
APP_NAME="AudioBoost"
APP_DIR="$ROOT/dist/$APP_NAME.app"
BUILD_DIR="$ROOT/.build"
VERSION="${VERSION:-0.1.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"

swift build -c "$CONFIGURATION" --product "$APP_NAME"

BIN_PATH="$(swift build -c "$CONFIGURATION" --show-bin-path)"
EXECUTABLE="$BIN_PATH/$APP_NAME"

if [[ ! -x "$EXECUTABLE" ]]; then
  echo "error: built executable not found at $EXECUTABLE" >&2
  exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$EXECUTABLE" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ROOT/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ROOT/Resources/AudioBoost.icns" "$APP_DIR/Contents/Resources/$APP_NAME.icns"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$APP_DIR/Contents/Info.plist"

printf 'APPL????' > "$APP_DIR/Contents/PkgInfo"

codesign --force --deep --sign - "$APP_DIR" >/dev/null

echo "Built $APP_DIR"
