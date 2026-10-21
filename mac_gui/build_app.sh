#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
APP_NAME="BulkExtractor.app"
APP_BUNDLE="$BUILD_DIR/$APP_NAME"

echo "=================================================="
echo " Building Standalone Bulk Extractor macOS App"
echo "=================================================="

# 1. Verify / Build C++ CLI binary
CLI_BIN="$REPO_ROOT/src/bulk_extractor"
if [[ ! -f "$CLI_BIN" ]]; then
    echo "[*] bulk_extractor binary not found at $CLI_BIN. Building..."
    (cd "$REPO_ROOT" && make -j"$(sysctl -n hw.ncpu || echo 4)")
fi

if [[ ! -x "$CLI_BIN" ]]; then
    echo "[-] Error: bulk_extractor binary is not executable at $CLI_BIN"
    exit 1
fi
echo "[+] Found bulk_extractor binary: $CLI_BIN"

# Extract engine version automatically
ENGINE_VERSION="$("$CLI_BIN" -V 2>/dev/null | awk '{print $2}' || echo "2.2.0")"
if [[ -z "$ENGINE_VERSION" ]]; then
    ENGINE_VERSION="2.2.0"
fi
echo "[+] Detected bulk_extractor engine version: $ENGINE_VERSION"

# Update EngineVersion.swift bundled fallback
sed -i '' "s/public static var bundled: String = .*/public static var bundled: String = \"$ENGINE_VERSION\"/" "$SCRIPT_DIR/Sources/BulkExtractorApp/Models/EngineVersion.swift" 2>/dev/null || true

# 2. Build Swift App (Release mode)
echo "[*] Building SwiftUI Application..."
(cd "$SCRIPT_DIR" && swift build -c release)

SWIFT_BIN="$SCRIPT_DIR/.build/release/BulkExtractorApp"
if [[ ! -f "$SWIFT_BIN" ]]; then
    echo "[-] Error: Swift binary not found at $SWIFT_BIN"
    exit 1
fi
echo "[+] Built Swift executable: $SWIFT_BIN"

# 3. Create .app Bundle Layout
echo "[*] Assembling $APP_NAME structure..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
mkdir -p "$APP_BUNDLE/Contents/Helpers"
mkdir -p "$APP_BUNDLE/Contents/Frameworks"

# Copy App binary
cp "$SWIFT_BIN" "$APP_BUNDLE/Contents/MacOS/BulkExtractorApp"
chmod +x "$APP_BUNDLE/Contents/MacOS/BulkExtractorApp"

# Copy and update Info.plist with engine version
cp "$SCRIPT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $ENGINE_VERSION" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :BulkExtractorEngineVersion string $ENGINE_VERSION" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || true
echo "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Copy AppIcon if available
if [[ -f "$SCRIPT_DIR/Resources/AppIcon.icns" ]]; then
    cp "$SCRIPT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

# 4. Bundle C++ CLI and all dynamic library dependencies
python3 "$SCRIPT_DIR/bundle_dependencies.py" "$APP_BUNDLE" "$CLI_BIN"

echo ""
echo "=================================================="
echo " [✓] Build and Bundling Completed Successfully!"
echo " App Bundle Location:"
echo "   $APP_BUNDLE"
echo ""
echo " To launch the app:"
echo "   open \"$APP_BUNDLE\""
echo " To install:"
echo "   cp -R \"$APP_BUNDLE\" /Applications/"
echo "=================================================="
