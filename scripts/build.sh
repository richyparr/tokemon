#!/bin/bash
# Tokemon Build Script
# Usage: ./scripts/build.sh [debug|release|archive]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Build with Swift Package Manager
build_spm() {
    local config="${1:-debug}"

    print_header "Building with Swift ($config)"

    if [ "$config" = "release" ]; then
        swift build -c release 2>&1 | tail -20
    else
        swift build 2>&1 | tail -20
    fi

    if [ $? -eq 0 ]; then
        print_success "Build successful"

        # Show binary location
        if [ "$config" = "release" ]; then
            echo "Binary: .build/release/tokemon"
        else
            echo "Binary: .build/debug/tokemon"
        fi
    else
        print_error "Build failed"
        exit 1
    fi
}

# Build with xcodebuild
build_xcode() {
    local config="${1:-Debug}"

    print_header "Building with Xcode ($config)"

    # Regenerate project
    if command -v xcodegen &> /dev/null; then
        echo "Regenerating Xcode project..."
        xcodegen generate --quiet
    fi

    xcodebuild build \
        -scheme Tokemon \
        -configuration "$config" \
        -destination 'platform=macOS' \
        2>&1 | xcpretty || true

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        print_success "Build successful"
    else
        print_error "Build failed"
        exit 1
    fi
}

# Create archive for distribution
build_archive() {
    print_header "Creating Archive"

    # Regenerate project
    if command -v xcodegen &> /dev/null; then
        echo "Regenerating Xcode project..."
        xcodegen generate --quiet
    fi

    local archive_path="build/Tokemon.xcarchive"

    xcodebuild archive \
        -scheme Tokemon \
        -configuration Release \
        -archivePath "$archive_path" \
        2>&1 | xcpretty || true

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        print_success "Archive created: $archive_path"
    else
        print_error "Archive failed"
        exit 1
    fi
}

# Parse arguments
case "${1:-debug}" in
    debug)
        build_spm "debug"
        ;;
    release)
        build_spm "release"
        ;;
    xcode)
        build_xcode "Debug"
        ;;
    xcode-release)
        build_xcode "Release"
        ;;
    archive)
        build_archive
        ;;
    *)
        echo "Usage: $0 [debug|release|xcode|xcode-release|archive]"
        echo ""
        echo "Commands:"
        echo "  debug         - Debug build with SPM (default)"
        echo "  release       - Release build with SPM"
        echo "  xcode         - Debug build with Xcode"
        echo "  xcode-release - Release build with Xcode"
        echo "  archive       - Create distribution archive"
        exit 1
        ;;
esac
