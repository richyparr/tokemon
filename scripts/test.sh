#!/bin/bash
# Tokemon Test Runner
# Usage: ./scripts/test.sh [unit|ui|all|quick]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if xcodebuild is available
check_xcode() {
    if ! command -v xcodebuild &> /dev/null; then
        print_warning "xcodebuild not found. Falling back to Swift Package Manager."
        return 1
    fi

    # Check if Xcode is properly configured
    if xcode-select -p 2>&1 | grep -q "CommandLineTools"; then
        print_warning "Xcode command line tools active, but full Xcode needed for UI tests."
        return 1
    fi

    return 0
}

# Run unit tests with Swift Package Manager
run_spm_tests() {
    print_header "Running Unit Tests (Swift Package Manager)"

    # Build first
    echo "Building..."
    if swift build 2>&1 | tail -5; then
        print_success "Build successful"
    else
        print_error "Build failed"
        exit 1
    fi

    echo ""
    echo "Note: SPM test target not configured. Use Xcode for full test suite."
    echo "Run: xcodebuild test -scheme Tokemon -destination 'platform=macOS'"
}

# Run unit tests with xcodebuild
run_unit_tests() {
    print_header "Running Unit Tests"

    # Regenerate project first
    if command -v xcodegen &> /dev/null; then
        echo "Regenerating Xcode project..."
        xcodegen generate --quiet
    fi

    xcodebuild test \
        -scheme Tokemon \
        -destination 'platform=macOS' \
        -only-testing:TokemonTests \
        -resultBundlePath "test-results/unit-tests.xcresult" \
        2>&1 | xcpretty || true

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        print_success "Unit tests passed"
    else
        print_error "Unit tests failed"
        return 1
    fi
}

# Run UI tests with xcodebuild
run_ui_tests() {
    print_header "Running UI Tests"

    # Regenerate project first
    if command -v xcodegen &> /dev/null; then
        echo "Regenerating Xcode project..."
        xcodegen generate --quiet
    fi

    xcodebuild test \
        -scheme Tokemon \
        -destination 'platform=macOS' \
        -only-testing:TokemonUITests \
        -resultBundlePath "test-results/ui-tests.xcresult" \
        2>&1 | xcpretty || true

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        print_success "UI tests passed"
    else
        print_error "UI tests failed"
        return 1
    fi
}

# Run all tests
run_all_tests() {
    print_header "Running All Tests"

    # Regenerate project first
    if command -v xcodegen &> /dev/null; then
        echo "Regenerating Xcode project..."
        xcodegen generate --quiet
    fi

    xcodebuild test \
        -scheme Tokemon \
        -destination 'platform=macOS' \
        -resultBundlePath "test-results/all-tests.xcresult" \
        2>&1 | xcpretty || true

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        print_success "All tests passed"
    else
        print_error "Some tests failed"
        return 1
    fi
}

# Quick build verification (no UI tests)
run_quick() {
    print_header "Quick Build Verification"

    echo "Building with Swift..."
    if swift build 2>&1 | tail -10; then
        print_success "Build successful"
    else
        print_error "Build failed"
        exit 1
    fi
}

# Create test results directory
mkdir -p test-results

# Parse arguments
case "${1:-all}" in
    unit)
        if check_xcode; then
            run_unit_tests
        else
            run_spm_tests
        fi
        ;;
    ui)
        if check_xcode; then
            run_ui_tests
        else
            print_error "UI tests require Xcode"
            exit 1
        fi
        ;;
    all)
        if check_xcode; then
            run_all_tests
        else
            run_spm_tests
        fi
        ;;
    quick)
        run_quick
        ;;
    *)
        echo "Usage: $0 [unit|ui|all|quick]"
        echo ""
        echo "Commands:"
        echo "  unit   - Run unit tests only"
        echo "  ui     - Run UI tests only"
        echo "  all    - Run all tests (default)"
        echo "  quick  - Quick build verification"
        exit 1
        ;;
esac

print_header "Test Run Complete"
