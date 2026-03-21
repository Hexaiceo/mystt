#!/bin/bash
# Build MySTT, sign with stable identity, install to /Applications, create DMG
set -e

SIGNING_IDENTITY="MySTT Developer"
INSTALL_PATH="/Applications/MySTT.app"
BUILD_DIR="build"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

cd "$PROJECT_DIR"

echo "=== Building MySTT ==="
swift build -c release 2>&1 | tail -5

BIN_PATH=$(swift build -c release --show-bin-path)

echo "=== Creating app bundle ==="
# Kill running instance
killall MySTT 2>/dev/null || true
sleep 1

rm -rf "$BUILD_DIR/MySTT.app" "$BUILD_DIR/MySTT.dmg"
mkdir -p "$BUILD_DIR/MySTT.app/Contents/"{MacOS,Resources}

# Binary
cp "$BIN_PATH/MySTT" "$BUILD_DIR/MySTT.app/Contents/MacOS/"

# Resource bundles
for bundle in "$BIN_PATH"/*.bundle; do
  [ -d "$bundle" ] && cp -R "$bundle" "$BUILD_DIR/MySTT.app/Contents/Resources/$(basename "$bundle")"
done

# Info.plist
cp MySTT/Info.plist "$BUILD_DIR/MySTT.app/Contents/"

# Icon
ICONSET_TMP="/tmp/AppIcon.iconset"
rm -rf "$ICONSET_TMP" && mkdir -p "$ICONSET_TMP"
for f in MySTT/Assets.xcassets/AppIcon.appiconset/icon_*.png; do
  cp "$f" "$ICONSET_TMP/$(basename "$f")"
done
iconutil -c icns "$ICONSET_TMP" -o "$BUILD_DIR/MySTT.app/Contents/Resources/AppIcon.icns"

# Clean and sign with STABLE identity
xattr -cr "$BUILD_DIR/MySTT.app"
codesign --force --sign "$SIGNING_IDENTITY" \
  --entitlements MySTT/MySTT.entitlements \
  --identifier "com.mystt.app" \
  "$BUILD_DIR/MySTT.app/Contents/MacOS/MySTT"

echo "=== Installing to $INSTALL_PATH ==="
rm -rf "$INSTALL_PATH"
cp -R "$BUILD_DIR/MySTT.app" "$INSTALL_PATH"

echo "=== Creating DMG ==="
hdiutil create -volname "MySTT" -srcfolder "$BUILD_DIR/MySTT.app" -ov -format UDZO "$BUILD_DIR/MySTT.dmg" 2>&1

echo ""
echo "=== Done ==="
echo "App:  $INSTALL_PATH"
echo "DMG:  $BUILD_DIR/MySTT.dmg ($(du -h "$BUILD_DIR/MySTT.dmg" | cut -f1))"
echo "Sign: $(codesign -dvv "$INSTALL_PATH/Contents/MacOS/MySTT" 2>&1 | grep Authority)"
echo ""
echo "Permissions (Accessibility, Automation, Microphone) persist across rebuilds"
echo "because the signing identity ($SIGNING_IDENTITY) and bundle ID (com.mystt.app) are stable."
