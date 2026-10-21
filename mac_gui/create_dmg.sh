#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
APP_BUNDLE="$BUILD_DIR/BulkExtractor.app"

if [[ ! -d "$APP_BUNDLE" ]]; then
    echo "[*] App bundle not found at $APP_BUNDLE. Building first..."
    "$SCRIPT_DIR/build_app.sh"
fi

# Detect version
VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || echo "2.2.0")"
DMG_NAME="BulkExtractor-${VERSION}-macOS.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"

echo "=================================================="
echo " Creating Disk Image (DMG): $DMG_NAME"
echo "=================================================="

rm -f "$DMG_PATH"

# Check if create-dmg is available for customized drag-to-Applications window
if command -v create-dmg >/dev/null 2>&1; then
    echo "[*] Using create-dmg for styled installer layout..."
    create-dmg \
        --volname "Bulk Extractor $VERSION" \
        --volicon "$SCRIPT_DIR/Resources/AppIcon.icns" \
        --window-pos 200 120 \
        --window-size 580 320 \
        --icon-size 110 \
        --icon "BulkExtractor.app" 150 140 \
        --hide-extension "BulkExtractor.app" \
        --app-drop-link 430 140 \
        --no-internet-enable \
        "$DMG_PATH" \
        "$APP_BUNDLE" \
        || true
fi

# Fallback to standard hdiutil if create-dmg is missing or failed
if [[ ! -f "$DMG_PATH" ]]; then
    echo "[*] Building standard DMG with hdiutil..."
    STAGING_DIR="$(mktemp -d /tmp/dmg-staging.XXXXXX)"
    
    cp -R "$APP_BUNDLE" "$STAGING_DIR/"
    ln -s /Applications "$STAGING_DIR/Applications"
    
    hdiutil create \
        -volname "Bulk Extractor $VERSION" \
        -srcfolder "$STAGING_DIR" \
        -ov \
        -format UDZO \
        "$DMG_PATH"
        
    rm -rf "$STAGING_DIR"
fi

# Codesign DMG
SIGNING_IDENTITY="${CODESIGN_IDENTITY:--}"
echo "[*] Signing DMG with identity: $SIGNING_IDENTITY"
codesign -s "$SIGNING_IDENTITY" --force "$DMG_PATH" 2>/dev/null || true

# Notarization (if credentials are provided in environment)
if [[ -n "${APPLE_ID:-}" && -n "${APPLE_TEAM_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]]; then
    echo "[*] Submitting DMG for Apple Notarization..."
    xcrun notarytool submit "$DMG_PATH" \
        --apple-id "$APPLE_ID" \
        --team-id "$APPLE_TEAM_ID" \
        --password "$APPLE_APP_SPECIFIC_PASSWORD" \
        --wait
    
    echo "[*] Stapling notarization ticket to DMG..."
    xcrun stapler staple "$DMG_PATH"
fi

echo ""
echo "=================================================="
echo " [✓] Disk Image (DMG) Created Successfully!"
echo " DMG Location: $DMG_PATH"
echo " Size: $(du -h "$DMG_PATH" | cut -f1)"
echo "=================================================="
