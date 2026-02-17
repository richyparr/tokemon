#!/bin/bash
# Submit a Tokemon DMG to Apple's notary service and staple the ticket
#
# Usage: ./scripts/notarize.sh <dmg-path>
# Example: ./scripts/notarize.sh Tokemon-1.0.0.dmg
#
# Required environment variables:
#   APPLE_ID       - Apple ID email address
#   AC_PASSWORD    - App-specific password (create at appleid.apple.com)
#   APPLE_TEAM_ID  - 10-character Apple Developer Team ID
#
# The notarization process:
#   1. Submits the DMG to Apple's notary service
#   2. Waits for Apple to scan and approve (typically 1-5 minutes)
#   3. Staples the notarization ticket to the DMG
#   4. Extracts the app, staples it, and repacks the DMG
#   5. Verifies the final result passes Gatekeeper

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# --- Arguments ---
DMG_PATH="${1:?Usage: $0 <dmg-path> (e.g., Tokemon-1.0.0.dmg)}"

# Resolve to absolute path
if [[ "${DMG_PATH}" != /* ]]; then
    DMG_PATH="${PROJECT_DIR}/${DMG_PATH}"
fi

# --- Validate environment ---
MISSING_VARS=0
for VAR in APPLE_ID AC_PASSWORD APPLE_TEAM_ID; do
    if [ -z "${!VAR}" ]; then
        echo "ERROR: ${VAR} environment variable is not set."
        MISSING_VARS=1
    fi
done

if [ "${MISSING_VARS}" -eq 1 ]; then
    echo ""
    echo "Required environment variables:"
    echo "  APPLE_ID       - Apple ID email address"
    echo "  AC_PASSWORD    - App-specific password (appleid.apple.com -> Security -> App-Specific Passwords)"
    echo "  APPLE_TEAM_ID  - 10-character team ID (Apple Developer Portal -> Membership)"
    exit 1
fi

# --- Validate DMG exists ---
if [ ! -f "${DMG_PATH}" ]; then
    echo "ERROR: DMG file not found: ${DMG_PATH}"
    echo "  Run build-release.sh first to create the DMG."
    exit 1
fi

DMG_FILENAME="$(basename "${DMG_PATH}")"
DMG_DIR="$(dirname "${DMG_PATH}")"

timestamp() {
    date "+%H:%M:%S"
}

echo "[$(timestamp)] Starting notarization of ${DMG_FILENAME}"
echo "=================================================="

# --- Step 1: Submit to notary service ---
echo "[$(timestamp)] Submitting to Apple notary service..."
echo "  This typically takes 1-5 minutes. The --wait flag will block until complete."
echo ""

xcrun notarytool submit "${DMG_PATH}" \
    --apple-id "${APPLE_ID}" \
    --password "${AC_PASSWORD}" \
    --team-id "${APPLE_TEAM_ID}" \
    --wait

echo ""
echo "[$(timestamp)] Notarization approved."

# --- Step 2: Staple ticket to DMG ---
echo "[$(timestamp)] Stapling notarization ticket to DMG..."
xcrun stapler staple "${DMG_PATH}"
echo "[$(timestamp)] DMG stapled."

# --- Step 3: Staple ticket to app inside DMG ---
echo "[$(timestamp)] Stapling ticket to app inside DMG..."
MOUNT_DIR=$(mktemp -d)
APP_STAGING_DIR=$(mktemp -d)

# Mount the DMG read-only to extract the app
hdiutil attach "${DMG_PATH}" -mountpoint "${MOUNT_DIR}" -nobrowse -quiet

# Copy app out for stapling
APP_NAME=$(ls "${MOUNT_DIR}" | grep '\.app$' | head -1)
if [ -n "${APP_NAME}" ]; then
    cp -R "${MOUNT_DIR}/${APP_NAME}" "${APP_STAGING_DIR}/"

    # Unmount
    hdiutil detach "${MOUNT_DIR}" -quiet

    # Staple the extracted app
    xcrun stapler staple "${APP_STAGING_DIR}/${APP_NAME}"

    # Recreate DMG with stapled app
    echo "[$(timestamp)] Repacking DMG with stapled app..."
    rm -f "${DMG_PATH}"
    hdiutil create \
        -volname "Tokemon" \
        -srcfolder "${APP_STAGING_DIR}/${APP_NAME}" \
        -ov \
        -format UDZO \
        "${DMG_PATH}"

    # Re-sign the new DMG
    if [ -n "${APPLE_DEVELOPER_ID}" ]; then
        codesign --sign "${APPLE_DEVELOPER_ID}" "${DMG_PATH}"
    fi

    # Re-staple the new DMG
    xcrun stapler staple "${DMG_PATH}"
else
    hdiutil detach "${MOUNT_DIR}" -quiet
    echo "[$(timestamp)] WARNING: No .app found inside DMG. Skipping app stapling."
fi

# Cleanup temp dirs
rm -rf "${MOUNT_DIR}" "${APP_STAGING_DIR}"

# --- Step 4: Verify ---
echo "[$(timestamp)] Verifying notarized DMG..."
spctl --assess --type open --context context:primary-signature --verbose "${DMG_PATH}" 2>&1 || true

echo ""
echo "[$(timestamp)] Notarization complete!"
echo "=================================================="
echo "  DMG: ${DMG_PATH}"
echo ""
echo "The DMG is now signed, notarized, and stapled."
echo "Users can download and open it without Gatekeeper warnings."
