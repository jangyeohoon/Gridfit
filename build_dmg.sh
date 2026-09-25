#!/bin/bash
set -e

# ==============================================================================
# Gridfit DMG Build & Packaging Script
# ==============================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build_output"
APP_NAME="Gridfit"
DMG_NAME="Gridfit.dmg"
SIGNING_IDENTITY="Developer ID Application: yeohoon jang (KQR52SK4D7)"

echo "🚀 [1/4] Building $APP_NAME (Release configuration)..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

xcodebuild build \
  -project "$PROJECT_DIR/Gridfit.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Release \
  -destination 'platform=macOS' \
  CONFIGURATION_BUILD_DIR="$BUILD_DIR/App" \
  > /dev/null

APP_PATH="$BUILD_DIR/App/$APP_NAME.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: Failed to find built application at $APP_PATH"
    exit 1
fi

echo "🔐 [2/4] Signing $APP_NAME with Developer ID..."
if security find-identity -v -p codesigning | grep -q "$SIGNING_IDENTITY"; then
    codesign --force --deep --options runtime --sign "$SIGNING_IDENTITY" "$APP_PATH"
    echo "   ✅ Signed with: $SIGNING_IDENTITY"
else
    echo "   ⚠️ Signing identity not found. Using ad-hoc signature..."
    codesign --force --deep --sign - "$APP_PATH"
fi

echo "📦 [3/4] Preparing DMG contents..."
DMG_STAGING="$BUILD_DIR/dmg_staging"
mkdir -p "$DMG_STAGING"
cp -R "$APP_PATH" "$DMG_STAGING/"

# Create symlink to /Applications for easy drag-and-drop installation
ln -s /Applications "$DMG_STAGING/Applications"

echo "💿 [4/4] Creating $DMG_NAME..."
FINAL_DMG="$PROJECT_DIR/$DMG_NAME"
rm -f "$FINAL_DMG"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGING" \
  -ov \
  -format UDZO \
  "$FINAL_DMG" > /dev/null

# Sign the DMG file itself if Developer ID is available
if security find-identity -v -p codesigning | grep -q "$SIGNING_IDENTITY"; then
    codesign --force --sign "$SIGNING_IDENTITY" "$FINAL_DMG"
    echo "   ✅ Signed DMG with Developer ID"
fi

# Cleanup staging directory
rm -rf "$BUILD_DIR"

echo ""
echo "🎉 [COMPLETE] Installation file created successfully!"
echo "📍 Location: $FINAL_DMG"
echo "📏 Size: $(du -sh "$FINAL_DMG" | cut -f1)"
echo "Ready to upload to GitHub Releases!"
