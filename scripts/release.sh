#!/bin/bash
# Build, sign, notarize, staple, and zip Tokemon.app for distribution.
#
# Usage: ./scripts/release.sh [version]
#   If version is omitted, uses MARKETING_VERSION from the Xcode project.
#
# Prerequisites:
#   - "Developer ID Application: Richard Parr (58C29SJJC5)" cert in keychain
#   - notarytool keychain profile named "tokemon-notary"
#     (created via: xcrun notarytool store-credentials tokemon-notary ...)
#
# Output:
#   - dist/Tokemon.zip (notarized, stapled, ready for gh release create)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

SCHEME="Tokemon"
CONFIG="Release"
TEAM_ID="58C29SJJC5"
SIGN_IDENTITY="Developer ID Application: Richard Parr (${TEAM_ID})"
NOTARY_PROFILE="tokemon-notary"

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    VERSION=$(grep -m1 "MARKETING_VERSION" Tokemon.xcodeproj/project.pbxproj | sed 's/.*= \(.*\);/\1/')
fi
echo "==> Releasing Tokemon v${VERSION}"

DIST_DIR="${PROJECT_DIR}/dist"
ARCHIVE_PATH="${DIST_DIR}/Tokemon.xcarchive"
EXPORT_DIR="${DIST_DIR}/export"
ZIP_PATH="${DIST_DIR}/Tokemon.zip"

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# 1. Archive
echo "==> Archiving (this takes a few minutes)..."
xcodebuild \
    -scheme "$SCHEME" \
    -configuration "$CONFIG" \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=macOS" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    CODE_SIGN_IDENTITY="$SIGN_IDENTITY" \
    CODE_SIGN_STYLE=Manual \
    archive | xcbeautify 2>/dev/null || \
xcodebuild \
    -scheme "$SCHEME" \
    -configuration "$CONFIG" \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=macOS" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    CODE_SIGN_IDENTITY="$SIGN_IDENTITY" \
    CODE_SIGN_STYLE=Manual \
    archive

# 2. Export with Developer ID
echo "==> Exporting signed app..."
xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "${SCRIPT_DIR}/ExportOptions.plist"

APP_PATH="${EXPORT_DIR}/Tokemon.app"
if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: ${APP_PATH} not found after export."
    exit 1
fi

# 3. Verify signing
echo "==> Verifying signature..."
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
codesign --display --verbose=2 "$APP_PATH" 2>&1 | grep -E "^(Authority|TeamIdentifier)="

# 4. Zip for notarization (notarytool accepts zip directly)
echo "==> Creating zip for notarization..."
NOTARIZE_ZIP="${DIST_DIR}/Tokemon-notarize.zip"
ditto -c -k --keepParent "$APP_PATH" "$NOTARIZE_ZIP"

# 5. Submit to notary service
echo "==> Submitting to Apple notary service (1-5 min)..."
xcrun notarytool submit "$NOTARIZE_ZIP" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait

# 6. Staple ticket to the .app
echo "==> Stapling notarization ticket..."
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"

# 7. Repackage final zip with stapled app
echo "==> Creating final Tokemon.zip..."
rm -f "$ZIP_PATH" "$NOTARIZE_ZIP"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

# 8. Gatekeeper assessment
echo "==> Gatekeeper check..."
spctl --assess --type execute --verbose "$APP_PATH" 2>&1 || true

SHA256=$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')
SIZE=$(du -h "$ZIP_PATH" | awk '{print $1}')

echo ""
echo "=================================================="
echo "  Release ready: $ZIP_PATH"
echo "  Version:      $VERSION"
echo "  Size:         $SIZE"
echo "  SHA256:       $SHA256"
echo "=================================================="
echo ""
echo "Next:"
echo "  gh release create v${VERSION} \"$ZIP_PATH\" --title \"v${VERSION}\" --generate-notes"
echo "  Update homebrew-tokemon/Casks/tokemon.rb sha256 to: $SHA256"
