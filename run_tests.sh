#!/bin/bash
# Usage:
#   ./run_tests.sh                # Run all tests
#   ./run_tests.sh TestSuite      # Run a specific test suite
#   ./run_tests.sh --help         # Show this help message

# Extract test suite name if provided
TEST_SUITE_NAME=""
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Magical Stories Test Runner"
  echo ""
  echo "Usage:"
  echo "  ./run_tests.sh                # Run all tests"
  echo "  ./run_tests.sh TestSuite      # Run a specific test suite"
  echo "  ./run_tests.sh --help         # Show this help message"
  echo ""
  echo "Examples:"
  echo "  ./run_tests.sh StoryServiceTests     # Run only StoryServiceTests"
  echo "  ./run_tests.sh CollectionService     # Run tests containing 'CollectionService'"
  exit 0
elif [ -n "$1" ]; then
  TEST_SUITE_NAME="$1"
  
  # Search for the test suite in the project
  echo "Searching for test suite: $TEST_SUITE_NAME"
  
  # Find the test files matching the provided name
  TEST_FILES=$(find . -name "*.swift" -type f -exec grep -l "$TEST_SUITE_NAME" {} \;)
  
  if [ -z "$TEST_FILES" ]; then
    echo "Error: No test files found containing '$TEST_SUITE_NAME'"
    exit 1
  fi
  
  # Extract the test target from the first matching file
  TEST_FILE=$(echo "$TEST_FILES" | head -n 1)
  
  # Determine the test target from the file path
  if [[ "$TEST_FILE" == *"magical-storiesTests"* ]]; then
    TEST_TARGET="magical-storiesTests/$TEST_SUITE_NAME"
  else
    echo "Error: Could not determine test target from file: $TEST_FILE"
    exit 1
  fi
  
  echo "Found test suite in: $TEST_FILE"
  echo "Target determined as: $TEST_TARGET"
fi

# Create a temporary file to capture the raw output
OUTPUT_FILE=$(mktemp)
LOG_FILE=$(mktemp)

echo "Running tests..."

# Build and test configuration
destination='platform=iOS Simulator,name=iPhone 16 Pro,OS=18.3.1'
if [ -n "$TEST_TARGET" ]; then
  # Run tests and save raw output, only log errors
  xcodebuild clean test \
    -scheme magical-stories \
    -configuration Debug \
    -destination "$destination" \
    -enableCodeCoverage YES \
    -parallel-testing-enabled NO \
    -only-testing:"$TEST_TARGET" > "$OUTPUT_FILE" 2> "$LOG_FILE"
else
  # Run tests and save raw output, only log errors
  xcodebuild clean test \
    -scheme magical-stories \
    -configuration Debug \
    -destination "$destination" \
    -enableCodeCoverage YES \
    -parallel-testing-enabled NO > "$OUTPUT_FILE" 2> "$LOG_FILE"
fi

# Capture the exit status right after xcodebuild
BUILD_STATUS=$?

# Display the log file on screen to help with debugging
echo "------- Build log (first 1000 lines) --------"
head -n 1000 "$LOG_FILE"
echo "--------------------------------------------"

# Check if there were build errors
BUILD_FAILED=false
if grep -q "error:" "$LOG_FILE" || grep -q "error:" "$OUTPUT_FILE"; then
  echo -e "\n\033[1;31m=== BUILD ERRORS ===\033[0m"
  grep -A 2 "error:" "$LOG_FILE" "$OUTPUT_FILE" 2>/dev/null
  BUILD_FAILED=true
fi

# Check the xcodebuild exit status directly
if [ $BUILD_STATUS -ne 0 ]; then
  echo -e "\n\033[1;31mBuild or test execution failed with exit code $BUILD_STATUS\033[0m"
  BUILD_FAILED=true
fi

# Exit if build failed
if [ "$BUILD_FAILED" = true ]; then
  echo "Build failed. Check the logs above for details."
  rm "$OUTPUT_FILE" "$LOG_FILE"
  exit 1
fi

# Extract test results section with failures and issues
echo -e "\n--- Test Results ---"
if grep -q "recorded an issue at" "$OUTPUT_FILE"; then
  echo -e "\033[1;31mTest Failures:\033[0m"
  grep -A 2 "recorded an issue at" "$OUTPUT_FILE" | grep -v "^$" || true
  grep -E "Test Suite.*failed|Test Case.*failed|Test \".*\" failed|✖|⚠️" "$OUTPUT_FILE" | grep -v "^$" || true
  echo ""
elif grep -q "TEST FAILED" "$OUTPUT_FILE"; then
  grep -E "Test Suite.*failed|Test Case.*failed|Test \".*\" failed|✖|⚠️" "$OUTPUT_FILE" | grep -v "^$" || true
elif grep -q "Test \".*\" failed" "$OUTPUT_FILE"; then
  echo -e "\033[1;31mTest Failures in Swift Testing:\033[0m"
  grep -A 2 "Test \".*\" failed" "$OUTPUT_FILE" | grep -v "^$" || true
else
  echo "All tests passed."
fi

# Extract test counts - support both XCTest and Swift Testing syntax
XCTEST_TOTAL=$(grep -o "Test Case.*started" "$OUTPUT_FILE" | wc -l | tr -d ' ')
XCTEST_FAILED=$(grep -o "Test Case.*failed" "$OUTPUT_FILE" | wc -l | tr -d ' ')

SWIFT_TESTING_TOTAL=$(grep -o "Test \".*\" started" "$OUTPUT_FILE" | wc -l | tr -d ' ')
# If no total count was found, try counting the passed tests directly
if [ "$SWIFT_TESTING_TOTAL" -eq 0 ]; then
  SWIFT_TESTING_TOTAL=$(grep -o "Test \".*\" passed" "$OUTPUT_FILE" | wc -l | tr -d ' ')
fi

SWIFT_TESTING_FAILED=$(grep -o "Test \".*\" failed" "$OUTPUT_FILE" | wc -l | tr -d ' ')

# Combine counts from both test frameworks
TOTAL_TESTS=$((XCTEST_TOTAL + SWIFT_TESTING_TOTAL))
FAILED_TESTS=$((XCTEST_FAILED + SWIFT_TESTING_FAILED))
PASSED_TESTS=$((TOTAL_TESTS - FAILED_TESTS))

# Print test statistics
echo -e "\n\033[1;34m=== TEST STATISTICS ===\033[0m"
echo -e "Total Tests Run: \033[1;37m$TOTAL_TESTS\033[0m"
echo -e "Tests Passed:    \033[1;32m$PASSED_TESTS\033[0m"
echo -e "Tests Failed:    \033[1;31m$FAILED_TESTS\033[0m"
echo ""

# Check if tests recorded issues or failed
if grep -q "recorded an issue at" "$OUTPUT_FILE" || grep -q "TEST FAILED" "$OUTPUT_FILE"; then
  echo -e "\n\033[1;31m=== FAILURE DETAILS ===\033[0m"
  
  # Get issue locations
  ISSUE_LOCATIONS=$(grep -o "[a-zA-Z0-9_]\+\.swift:[0-9]\+" "$OUTPUT_FILE" | sort -u)
  if [ -n "$ISSUE_LOCATIONS" ]; then
    echo -e "\033[1;36mFailure Locations:\033[0m"
    echo "$ISSUE_LOCATIONS"
    echo ""
  fi
  
  # Extract record = true setting for snapshot tests
  if [[ "$TEST_FILE" == *"SnapshotTests"* ]] && grep -q "record = true" "$TEST_FILE"; then
    RECORD_SETTING=$(grep -n "record = true" "$TEST_FILE")
    echo -e "\033[1;33mSnapshot Test Issue Detected:\033[0m"
    echo "The 'record' variable is set to true in $TEST_FILE (line $(echo $RECORD_SETTING | cut -d: -f1))"
    echo ""
    echo -e "\033[1;36mExplanation:\033[0m"
    echo "• When record = true, tests will UPDATE reference images rather than VERIFY against them"
    echo "• This causes tests to appear to fail when they're actually updating references"
    echo ""
    echo -e "\033[1;36mTo fix snapshot test failures:\033[0m"
    echo "1. If updating snapshots was intentional: commit the updated images"
    echo "2. If verifying against existing snapshots: change 'record = true' to 'record = false'"
    echo ""
    
    # Check if we can find the specific snapshot failure messages
    if grep -q "Snapshot did not match" "$OUTPUT_FILE"; then
      echo -e "\033[1;36mSnapshot Mismatch Details:\033[0m"
      grep -A 3 "Snapshot did not match" "$OUTPUT_FILE" | grep -v "^--$" || true
    fi
  else
    # For non-snapshot test failures
    echo -e "\033[1;33mTest Failure Details:\033[0m"
    
    # Try to get specific assertion failures
    if grep -q "assertion failed" "$OUTPUT_FILE"; then
      grep -B 1 -A 3 "assertion failed" "$OUTPUT_FILE" | grep -v "^--$" || true
    elif grep -q "XCTAssert" "$OUTPUT_FILE"; then
      grep -B 1 -A 3 "XCTAssert" "$OUTPUT_FILE" | grep -v "^--$" || true
    else
      grep -B 1 -A 3 "failed" "$OUTPUT_FILE" | grep -v "^--$" || true
    fi
  fi
fi

# Clean up
rm "$OUTPUT_FILE" "$LOG_FILE"