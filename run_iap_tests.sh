#!/bin/bash

# IAP UI Tests Runner Script
# This script helps run the IAP UI tests with proper configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
SIMULATOR="iPhone 16 Pro"
SCHEME="magical-stories"
TEST_CLASS="IAPBasicUITests"

# Functions
print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}     Magical Stories IAP UI Tests Runner       ${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
}

print_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -s, --simulator NAME    iOS Simulator to use (default: iPhone 16 Pro)"
    echo "  -t, --test CLASS       Test class to run (default: IAPBasicUITests)"
    echo "  -m, --method METHOD    Specific test method to run"
    echo "  -c, --clean            Clean before building"
    echo "  -b, --build-only       Build only, don't run tests"
    echo "  -l, --list             List available simulators"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Run all basic IAP tests"
    echo "  $0 -m testAppLaunchesSuccessfully    # Run specific test"
    echo "  $0 -s \"iPhone 15\"                   # Use different simulator"
    echo "  $0 -c                                # Clean build first"
    echo "  $0 -l                                # List simulators"
}

list_simulators() {
    echo -e "${YELLOW}Available iOS Simulators:${NC}"
    xcrun simctl list devices | grep -E "iPhone|iPad" | grep "Booted\|Shutdown" | head -10
}

clean_build() {
    echo -e "${YELLOW}Cleaning build directory...${NC}"
    xcodebuild clean -scheme "$SCHEME"
    echo -e "${GREEN}Clean completed.${NC}"
}

build_project() {
    echo -e "${YELLOW}Building project...${NC}"
    if xcodebuild build -scheme "$SCHEME" -destination "platform=iOS Simulator,name=$SIMULATOR"; then
        echo -e "${GREEN}Build completed successfully.${NC}"
        return 0
    else
        echo -e "${RED}Build failed.${NC}"
        return 1
    fi
}

run_tests() {
    local test_target="magical-storiesUITests/$TEST_CLASS"
    
    if [ ! -z "$TEST_METHOD" ]; then
        test_target="$test_target/$TEST_METHOD"
    fi
    
    echo -e "${YELLOW}Running tests: $test_target${NC}"
    echo -e "${YELLOW}Simulator: $SIMULATOR${NC}"
    echo ""
    
    if xcodebuild test \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,name=$SIMULATOR" \
        -only-testing:"$test_target"; then
        echo ""
        echo -e "${GREEN}✅ Tests completed successfully!${NC}"
        return 0
    else
        echo ""
        echo -e "${RED}❌ Tests failed.${NC}"
        return 1
    fi
}

# Main execution
print_header

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--simulator)
            SIMULATOR="$2"
            shift 2
            ;;
        -t|--test)
            TEST_CLASS="$2"
            shift 2
            ;;
        -m|--method)
            TEST_METHOD="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        -b|--build-only)
            BUILD_ONLY=true
            shift
            ;;
        -l|--list)
            list_simulators
            exit 0
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            print_usage
            exit 1
            ;;
    esac
done

# Execute based on options
if [ "$CLEAN_BUILD" = true ]; then
    clean_build
fi

if ! build_project; then
    exit 1
fi

if [ "$BUILD_ONLY" = true ]; then
    echo -e "${GREEN}Build-only completed.${NC}"
    exit 0
fi

# Run the tests
if run_tests; then
    echo ""
    echo -e "${GREEN}🎉 IAP UI Tests completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}Test Results Summary:${NC}"
    echo -e "  Simulator: $SIMULATOR"
    echo -e "  Test Class: $TEST_CLASS"
    if [ ! -z "$TEST_METHOD" ]; then
        echo -e "  Test Method: $TEST_METHOD"
    fi
    echo ""
    echo -e "${YELLOW}💡 Next Steps:${NC}"
    echo -e "  1. Review test results in Xcode"
    echo -e "  2. Check app behavior on simulator"
    echo -e "  3. Run additional test cases as needed"
    echo -e "  4. View detailed logs at: ~/Documents/DerivedData/.../Logs/Test/"
else
    echo ""
    echo -e "${RED}💥 IAP UI Tests failed!${NC}"
    echo ""
    echo -e "${YELLOW}🔧 Troubleshooting:${NC}"
    echo -e "  1. Check simulator is available: $0 -l"
    echo -e "  2. Try cleaning first: $0 -c"
    echo -e "  3. Build only to check compilation: $0 -b"
    echo -e "  4. Try different simulator: $0 -s \"iPhone 15\""
    echo -e "  5. Run single test: $0 -m testAppLaunchesSuccessfully"
    exit 1
fi