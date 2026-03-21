#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/../build"
APP_PATH="$BUILD_DIR/MySTT.app"
DMG_PATH="$BUILD_DIR/MySTT.dmg"
DMG_TEMP="$BUILD_DIR/dmg_temp"

echo "=== Creating MySTT DMG ==="

if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: MySTT.app not found. Run build_release.sh first."
    exit 1
fi

# Clean previous DMG
rm -rf "$DMG_TEMP" "$DMG_PATH"
mkdir -p "$DMG_TEMP"

# Copy app to temp dir
cp -R "$APP_PATH" "$DMG_TEMP/MySTT.app"

# Create Applications symlink
ln -s /Applications "$DMG_TEMP/Applications"

# Create README
cat > "$DMG_TEMP/README.txt" << 'EOF'
MySTT - Speech to Text for macOS
=================================

Setup Instructions:
1. Drag MySTT.app to Applications
2. Launch MySTT from Applications
3. Grant Microphone permission when prompted
4. Grant Accessibility permission:
   System Settings > Privacy & Security > Accessibility > Add MySTT
5. Hold Right Option key to record, release to process

Model Setup (first time):
   Open Terminal and run:
   cd /path/to/MySTT/Scripts && bash setup_models.sh

For more info, see architecture.md
EOF

# Create DMG
echo "Creating DMG..."
hdiutil create -volname "MySTT" \
    -srcfolder "$DMG_TEMP" \
    -ov -format UDZO \
    "$DMG_PATH"

# Cleanup
rm -rf "$DMG_TEMP"

echo ""
echo "=== DMG Created ==="
echo "DMG: $DMG_PATH"
du -sh "$DMG_PATH"
