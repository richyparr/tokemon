#!/bin/bash
# Build and sign Tokemon.app for release distribution
# Produces a signed .app bundle and .dmg installer
#
# Usage: ./scripts/build-release.sh <version>
# Example: ./scripts/build-release.sh 1.0.0
#
# Required environment variables:
#   APPLE_DEVELOPER_ID  - Developer ID Application certificate name
#                         (e.g., "Developer ID Application: Your Name (TEAMID)")
#
# Optional environment variables:
#   SKIP_SIGNING        - Set to "1" to skip code signing (for testing bundle structure)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# --- Arguments ---
VERSION="${1:?Usage: $0 <version> (e.g., 1.0.0)}"

# --- Configuration ---
APP_NAME="Tokemon"
BUNDLE_ID="ai.tokemon.app"
BUILD_DIR="${PROJECT_DIR}/.build/release"
APP_BUNDLE="${PROJECT_DIR}/${APP_NAME}.app"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
DMG_PATH="${PROJECT_DIR}/${DMG_NAME}"
ENTITLEMENTS="${PROJECT_DIR}/Tokemon/Tokemon.entitlements"

timestamp() {
    date "+%H:%M:%S"
}

echo "[$(timestamp)] Starting ${APP_NAME} release build v${VERSION}"
echo "=================================================="

# --- Step 1: Build release executable ---
echo "[$(timestamp)] Building release executable..."
cd "$PROJECT_DIR"
swift build -c release
echo "[$(timestamp)] Build complete."

# --- Step 2: Create app bundle structure ---
echo "[$(timestamp)] Creating app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# --- Step 3: Copy executable (SPM lowercases the target name) ---
cp "${BUILD_DIR}/tokemon" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
echo "[$(timestamp)] Copied executable."

# --- Step 4: Copy and update Info.plist with version ---
cp "${PROJECT_DIR}/Tokemon/Info.plist" "${APP_BUNDLE}/Contents/"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" "${APP_BUNDLE}/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${VERSION}" "${APP_BUNDLE}/Contents/Info.plist"
echo "[$(timestamp)] Updated Info.plist to version ${VERSION}."

# --- Step 5: Copy resources ---
if [ -d "${PROJECT_DIR}/Tokemon/Resources" ]; then
    cp "${PROJECT_DIR}/Tokemon/Resources/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/" 2>/dev/null || true
    cp "${PROJECT_DIR}/Tokemon/Resources/"*.png "${APP_BUNDLE}/Contents/Resources/" 2>/dev/null || true
    echo "[$(timestamp)] Copied resources."
fi

# --- Step 6: Copy SPM resource bundle (for Bundle.module) ---
RESOURCE_BUNDLE="${BUILD_DIR}/Tokemon_tokemon.bundle"
if [ -d "${RESOURCE_BUNDLE}" ]; then
    cp -r "${RESOURCE_BUNDLE}" "${APP_BUNDLE}/Contents/Resources/"
    echo "[$(timestamp)] Copied SPM resource bundle."
fi

# --- Step 7: Create PkgInfo ---
echo -n "APPL????" > "${APP_BUNDLE}/Contents/PkgInfo"

# --- Step 8: Code signing ---
if [ "${SKIP_SIGNING}" = "1" ]; then
    echo "[$(timestamp)] Skipping code signing (SKIP_SIGNING=1)."
    # Ad-hoc sign for local testing
    codesign --force --deep --sign - "${APP_BUNDLE}"
else
    if [ -z "${APPLE_DEVELOPER_ID}" ]; then
        echo "[$(timestamp)] ERROR: APPLE_DEVELOPER_ID environment variable is not set."
        echo "  Set it to your Developer ID Application certificate name."
        echo "  Example: export APPLE_DEVELOPER_ID=\"Developer ID Application: Your Name (TEAMID)\""
        echo ""
        echo "  To build without signing: SKIP_SIGNING=1 $0 ${VERSION}"
        exit 1
    fi

    echo "[$(timestamp)] Signing app bundle with Developer ID..."
    codesign --deep --force --verify --verbose \
        --sign "${APPLE_DEVELOPER_ID}" \
        --entitlements "${ENTITLEMENTS}" \
        --options runtime \
        "${APP_BUNDLE}"

    echo "[$(timestamp)] Verifying signature..."
    codesign --verify --verbose "${APP_BUNDLE}"
    echo "[$(timestamp)] Signature verified."
fi

# --- Step 9: Create DMG ---
echo "[$(timestamp)] Creating DMG installer..."
rm -f "${DMG_PATH}"
hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${APP_BUNDLE}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}"

# Sign DMG (if not skipping signing)
if [ "${SKIP_SIGNING}" != "1" ] && [ -n "${APPLE_DEVELOPER_ID}" ]; then
    echo "[$(timestamp)] Signing DMG..."
    codesign --sign "${APPLE_DEVELOPER_ID}" "${DMG_PATH}"
fi

echo "[$(timestamp)] Release build complete!"
echo "=================================================="
echo "  App:     ${APP_BUNDLE}"
echo "  DMG:     ${DMG_PATH}"
echo "  Version: ${VERSION}"
echo ""
echo "Next steps:"
if [ "${SKIP_SIGNING}" = "1" ]; then
    echo "  - Set APPLE_DEVELOPER_ID and rebuild to create a signed release"
else
    echo "  - Run: ./scripts/notarize.sh ${DMG_PATH}"
fi
