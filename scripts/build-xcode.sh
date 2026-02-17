#!/bin/bash
# Build script for Tokemon using Xcode

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/.build-xcode"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  build       Build the app (default)"
    echo "  test        Run UI tests"
    echo "  clean       Clean build artifacts"
    echo "  archive     Create a release archive"
    echo "  regenerate  Regenerate Xcode project from project.yml"
    echo ""
}

check_xcode() {
    if ! xcodebuild -version &>/dev/null; then
        echo -e "${RED}Error: Xcode is not properly configured${NC}"
        echo "Run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
        echo "Then: sudo xcodebuild -license accept"
        exit 1
    fi
}

build() {
    check_xcode
    echo -e "${GREEN}Building Tokemon...${NC}"
    xcodebuild \
        -project "$PROJECT_DIR/Tokemon.xcodeproj" \
        -scheme Tokemon \
        -configuration Debug \
        -derivedDataPath "$BUILD_DIR" \
        build

    echo -e "${GREEN}Build complete!${NC}"
    echo "App location: $BUILD_DIR/Build/Products/Debug/Tokemon.app"
}

test_ui() {
    check_xcode
    echo -e "${GREEN}Running UI tests...${NC}"
    xcodebuild \
        -project "$PROJECT_DIR/Tokemon.xcodeproj" \
        -scheme Tokemon \
        -configuration Debug \
        -derivedDataPath "$BUILD_DIR" \
        test
}

clean() {
    echo -e "${YELLOW}Cleaning build artifacts...${NC}"
    rm -rf "$BUILD_DIR"
    xcodebuild \
        -project "$PROJECT_DIR/Tokemon.xcodeproj" \
        -scheme Tokemon \
        clean 2>/dev/null || true
    echo -e "${GREEN}Clean complete!${NC}"
}

archive() {
    check_xcode
    echo -e "${GREEN}Creating release archive...${NC}"
    xcodebuild \
        -project "$PROJECT_DIR/Tokemon.xcodeproj" \
        -scheme Tokemon \
        -configuration Release \
        -derivedDataPath "$BUILD_DIR" \
        -archivePath "$BUILD_DIR/Tokemon.xcarchive" \
        archive

    echo -e "${GREEN}Archive created at: $BUILD_DIR/Tokemon.xcarchive${NC}"
}

regenerate() {
    if ! command -v xcodegen &>/dev/null; then
        echo -e "${RED}Error: xcodegen not found${NC}"
        echo "Install with: brew install xcodegen"
        exit 1
    fi

    echo -e "${GREEN}Regenerating Xcode project...${NC}"
    cd "$PROJECT_DIR"
    xcodegen generate
    echo -e "${GREEN}Project regenerated!${NC}"
}

# Main
case "${1:-build}" in
    build)
        build
        ;;
    test)
        test_ui
        ;;
    clean)
        clean
        ;;
    archive)
        archive
        ;;
    regenerate)
        regenerate
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        usage
        exit 1
        ;;
esac
