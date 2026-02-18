#!/bin/bash
# Tokemon Lint Script
# Usage: ./scripts/lint.sh [check|fix]

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

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if SwiftLint is available
check_swiftlint() {
    if ! command -v swiftlint &> /dev/null; then
        print_warning "SwiftLint not found. Install with: brew install swiftlint"
        return 1
    fi
    return 0
}

# Check if SwiftFormat is available
check_swiftformat() {
    if ! command -v swiftformat &> /dev/null; then
        print_warning "SwiftFormat not found. Install with: brew install swiftformat"
        return 1
    fi
    return 0
}

# Run SwiftLint
run_swiftlint() {
    local mode="${1:-check}"

    print_header "Running SwiftLint"

    if ! check_swiftlint; then
        return 1
    fi

    if [ "$mode" = "fix" ]; then
        swiftlint lint --fix --config .swiftlint.yml Tokemon/ TokemonTests/ TokemonUITests/ 2>/dev/null || \
        swiftlint lint --fix Tokemon/ TokemonTests/ TokemonUITests/
    else
        swiftlint lint --config .swiftlint.yml Tokemon/ TokemonTests/ TokemonUITests/ 2>/dev/null || \
        swiftlint lint Tokemon/ TokemonTests/ TokemonUITests/
    fi

    if [ $? -eq 0 ]; then
        print_success "SwiftLint passed"
    else
        print_warning "SwiftLint found issues"
    fi
}

# Run SwiftFormat
run_swiftformat() {
    local mode="${1:-check}"

    print_header "Running SwiftFormat"

    if ! check_swiftformat; then
        return 1
    fi

    if [ "$mode" = "fix" ]; then
        swiftformat Tokemon/ TokemonTests/ TokemonUITests/ --swiftversion 6.0
        print_success "SwiftFormat applied fixes"
    else
        swiftformat Tokemon/ TokemonTests/ TokemonUITests/ --lint --swiftversion 6.0
        if [ $? -eq 0 ]; then
            print_success "SwiftFormat check passed"
        else
            print_warning "SwiftFormat found issues. Run with 'fix' to auto-correct."
        fi
    fi
}

# Basic syntax check without external tools
run_syntax_check() {
    print_header "Running Syntax Check"

    echo "Checking Swift syntax..."

    local errors=0

    # Find Swift files and check for common issues
    while IFS= read -r file; do
        # Check for force unwraps (!)
        if grep -n '![^=]' "$file" | grep -v '//' | grep -v 'image:' | grep -v 'systemImage:' > /dev/null 2>&1; then
            echo "  Force unwrap found in: $file"
        fi

        # Check for very long lines (>200 chars)
        if awk 'length > 200' "$file" | head -1 | grep -q '.'; then
            echo "  Long lines in: $file"
        fi
    done < <(find Tokemon TokemonTests TokemonUITests -name "*.swift" 2>/dev/null)

    print_success "Syntax check complete"
}

# Parse arguments
case "${1:-check}" in
    check)
        run_syntax_check
        run_swiftlint "check" || true
        run_swiftformat "check" || true
        ;;
    fix)
        run_swiftlint "fix" || true
        run_swiftformat "fix" || true
        ;;
    swiftlint)
        run_swiftlint "${2:-check}"
        ;;
    swiftformat)
        run_swiftformat "${2:-check}"
        ;;
    *)
        echo "Usage: $0 [check|fix|swiftlint|swiftformat]"
        echo ""
        echo "Commands:"
        echo "  check      - Run all linters in check mode (default)"
        echo "  fix        - Run all linters and apply fixes"
        echo "  swiftlint  - Run SwiftLint only"
        echo "  swiftformat - Run SwiftFormat only"
        exit 1
        ;;
esac
