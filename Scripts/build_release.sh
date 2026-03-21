#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/../MySTT"
BUILD_DIR="$SCRIPT_DIR/../build"

echo "=== MySTT Release Build ==="

if ! command -v xcodebuild &> /dev/null; then
    echo "ERROR: xcodebuild not found. Install Xcode."
    exit 1
fi

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

cd "$PROJECT_DIR"

# Resolve SPM dependencies
echo "Resolving dependencies..."
xcodebuild -project MySTT.xcodeproj \
    -scheme MySTT \
    -resolvePackageDependencies 2>&1 | tail -3

# Build release
echo "Building release..."
xcodebuild -project MySTT.xcodeproj \
    -scheme MySTT \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    -destination 'platform=macOS' \
    SWIFT_OPTIMIZATION_LEVEL='-O' \
    GCC_OPTIMIZATION_LEVEL='s' \
    STRIP_INSTALLED_PRODUCT=YES \
    COPY_PHASE_STRIP=YES \
    CODE_SIGN_IDENTITY="-" \
    build 2>&1 | tail -10

# Find the built app
APP_PATH=$(find "$BUILD_DIR/DerivedData" -name "MySTT.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo "ERROR: MySTT.app not found in build output"
    exit 1
fi

# Copy to build root
cp -R "$APP_PATH" "$BUILD_DIR/MySTT.app"

echo ""
echo "=== Build Complete ==="
echo "App: $BUILD_DIR/MySTT.app"
du -sh "$BUILD_DIR/MySTT.app"

# Verify code signature
codesign --verify "$BUILD_DIR/MySTT.app" 2>&1 && echo "Code signing: OK" || echo "Code signing: ad-hoc (unsigned)"
