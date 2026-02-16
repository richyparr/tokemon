#!/bin/bash
# Build Tokemon.app bundle from SPM executable
set -e

# Configuration
APP_NAME="Tokemon"
BUNDLE_ID="ai.tokemon.app"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"

echo "Building ${APP_NAME}..."

# Step 1: Build release executable
swift build -c release

# Step 2: Create app bundle structure
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Step 3: Copy executable (note: SPM lowercases the target name)
cp "${BUILD_DIR}/tokemon" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# Step 4: Copy Info.plist
cp "Tokemon/Info.plist" "${APP_BUNDLE}/Contents/"

# Step 5: Copy resources (logos and app icon)
if [ -d "Tokemon/Resources" ]; then
    cp Tokemon/Resources/AppIcon.icns "${APP_BUNDLE}/Contents/Resources/" 2>/dev/null || true
    cp Tokemon/Resources/*.png "${APP_BUNDLE}/Contents/Resources/" 2>/dev/null || true
fi

# Step 6: Copy the resource bundle created by SPM (for Bundle.module)
RESOURCE_BUNDLE="${BUILD_DIR}/Tokemon_tokemon.bundle"
if [ -d "${RESOURCE_BUNDLE}" ]; then
    cp -r "${RESOURCE_BUNDLE}" "${APP_BUNDLE}/Contents/Resources/"
fi

# Step 7: Create PkgInfo
echo -n "APPL????" > "${APP_BUNDLE}/Contents/PkgInfo"

# Step 8: Ad-hoc code sign (required for notifications and other entitlements)
codesign --force --deep --sign - "${APP_BUNDLE}"

echo ""
echo "Built: ${APP_BUNDLE}"
echo "Bundle ID: ${BUNDLE_ID}"
echo ""
echo "Run with: open ${APP_BUNDLE}"
echo "Or: ./${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
