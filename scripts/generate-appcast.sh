#!/bin/bash
set -e

# Generate appcast.xml for Sparkle updates
# Run after creating a new release DMG
#
# Usage: ./scripts/generate-appcast.sh <version> <dmg-path>
#
# Environment:
#   SPARKLE_ED_PRIVATE_KEY - Path to EdDSA private key (optional, skips signing if not set)

VERSION=$1
DMG_PATH=$2

if [ -z "$VERSION" ] || [ -z "$DMG_PATH" ]; then
    echo "Usage: ./scripts/generate-appcast.sh <version> <dmg-path>"
    exit 1
fi

if [ ! -f "$DMG_PATH" ]; then
    echo "Error: DMG not found at $DMG_PATH"
    exit 1
fi

# Get file info
FILE_SIZE=$(stat -f%z "$DMG_PATH")
PUB_DATE=$(date -R)

# For EdDSA signature, use Sparkle's sign_update tool
# This requires the private key from Sparkle setup
SIGNATURE=""
if [ -n "$SPARKLE_ED_PRIVATE_KEY" ] && [ -f "$SPARKLE_ED_PRIVATE_KEY" ]; then
    if command -v sign_update &> /dev/null; then
        SIGNATURE=$(sign_update "$DMG_PATH")
        echo "Signed with EdDSA key"
    else
        echo "Warning: sign_update not found, skipping signature"
    fi
else
    echo "Warning: SPARKLE_ED_PRIVATE_KEY not set, skipping signature"
fi

# Build signature attribute if present
SIGNATURE_ATTR=""
if [ -n "$SIGNATURE" ]; then
    SIGNATURE_ATTR="sparkle:edSignature=\"$SIGNATURE\""
fi

cat > appcast.xml << EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Tokemon Updates</title>
    <link>https://tokemon.app/appcast.xml</link>
    <description>Most recent changes with links to updates.</description>
    <language>en</language>
    <item>
      <title>Version ${VERSION}</title>
      <pubDate>${PUB_DATE}</pubDate>
      <sparkle:version>${VERSION}</sparkle:version>
      <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <enclosure
        url="https://github.com/nicktretyakov/tokemon/releases/download/v${VERSION}/Tokemon-${VERSION}.dmg"
        length="${FILE_SIZE}"
        type="application/octet-stream"
        ${SIGNATURE_ATTR}
      />
    </item>
  </channel>
</rss>
EOF

echo "Generated appcast.xml for version ${VERSION}"
echo "  File size: ${FILE_SIZE} bytes"
echo "  Publish date: ${PUB_DATE}"
