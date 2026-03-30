#!/bin/bash
set -e

PROJ_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJ_DIR/MySTT"
APP_DIR="$BUILD_DIR/build/MySTT.app"

echo "=== Building MySTT ==="
cd "$BUILD_DIR"
swift build 2>&1 | tail -3

echo "=== Creating MySTT.app bundle ==="
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RESOURCES"

# Copy binary + resource bundles
cp .build/arm64-apple-macosx/debug/MySTT "$MACOS/MySTT"
cp -R .build/arm64-apple-macosx/debug/*.bundle "$MACOS/" 2>/dev/null || true

# Create icns
ICON_SRC="MySTT/Assets.xcassets/AppIcon.appiconset"
ICONSET="/tmp/MySTT.iconset"
rm -rf "$ICONSET"; mkdir -p "$ICONSET"
for f in icon_16x16.png icon_16x16@2x.png icon_32x32.png icon_32x32@2x.png \
         icon_128x128.png icon_128x128@2x.png icon_256x256.png icon_256x256@2x.png \
         icon_512x512.png icon_512x512@2x.png; do
    cp "$ICON_SRC/$f" "$ICONSET/$f" 2>/dev/null || true
done
iconutil -c icns "$ICONSET" -o "$RESOURCES/AppIcon.icns" 2>/dev/null

# Info.plist
cat > "$CONTENTS/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>MySTT</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundleIdentifier</key><string>com.mystt.app</string>
    <key>CFBundleName</key><string>MySTT</string>
    <key>CFBundleDisplayName</key><string>MySTT</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>CFBundleShortVersionString</key><string>1.0.0</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>LSUIElement</key><true/>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSMicrophoneUsageDescription</key><string>MySTT needs microphone access to transcribe speech.</string>
    <key>NSAppleEventsUsageDescription</key><string>MySTT may use System Events as a fallback to paste text into other applications.</string>
</dict>
</plist>
PLIST

echo ""
echo "✅ MySTT.app ready at: $APP_DIR"
echo "   Run: open $APP_DIR"
