#!/bin/bash
# Usage:
#   ./run_tests.sh                # Run all tests
#   ./run_tests.sh TestSuite      # Run a specific test suite

# Extract test suite name if provided
TEST_SUITE_NAME=""
if [ -n "$1" ] && [ "$1" != "--help" ] && [ "$1" != "-h" ]; then
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
  xcodebuild test \
    -scheme magical-stories \
    -configuration Debug \
    -destination "$destination" \
    -enableCodeCoverage YES \
    -parallel-testing-enabled NO \
    -only-testing:"$TEST_TARGET" > "$OUTPUT_FILE" 2> "$LOG_FILE"
else
  # Run tests and save raw output, only log errors
  xcodebuild test \
    -scheme magical-stories \
    -configuration Debug \
    -destination "$destination" \
    -enableCodeCoverage YES \
    -parallel-testing-enabled NO > "$OUTPUT_FILE" 2> "$LOG_FILE"
fi

# Check if there were build errors
if grep -q "error:" "$LOG_FILE"; then
  echo -e "\n\033[1;31m=== BUILD ERRORS ===\033[0m"
  grep -A 2 "error:" "$LOG_FILE"
  rm "$OUTPUT_FILE" "$LOG_FILE"
  exit 1
fi

# Extract test results section with failures and issues
echo -e "\n--- Test Results ---"
if grep -q "recorded an issue at" "$OUTPUT_FILE"; then
  echo -e "\033[1;31mTest Failures:\033[0m"
  grep -A 2 "recorded an issue at" "$OUTPUT_FILE" | grep -v "^$" || true
  grep -E "Test Suite.*failed|Test Case.*failed|✖|⚠️" "$OUTPUT_FILE" | grep -v "^$" || true
  echo ""
elif grep -q "TEST FAILED" "$OUTPUT_FILE"; then
  grep -E "Test Suite.*failed|Test Case.*failed|✖|⚠️" "$OUTPUT_FILE" | grep -v "^$" || true
else
  echo "All tests passed."
fi

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