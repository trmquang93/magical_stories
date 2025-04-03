#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# Ensure pipeline commands return a failure status if any command fails
set -o pipefail

# Check if xcpretty is installed
if ! command -v xcbeautify &> /dev/null; then
    echo "xcbeautify is not installed. Installing..."
    gem install xcbeautify
fi

# Remove previous results if they exist
echo "Cleaning previous test results..."
rm -rf TestResults.xcresult
rm -rf TestResults.xml # Reverted: Remove directory if it exists

# Run tests with coverage
echo "Running tests..."

# Run xcodebuild and capture the exit status, pipe output to xcbeautify
# Note: We capture the status of xcodebuild, not xcbeautify, thanks to pipefail
set +e # Temporarily disable exit on error to capture the status
xcodebuild test \
  -workspace magical-stories.xcodeproj/project.xcworkspace \
  -scheme magical-stories \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.2' \
  -enableCodeCoverage YES \
  -parallel-testing-enabled NO \
  -allowProvisioningUpdates \
  -resultBundlePath TestResults.xcresult | xcbeautify \
  --quiet \
  --report junit \
  --report-path TestResults.xml \
  --is-ci
TEST_EXIT_CODE=$?
set -e # Re-enable exit on error

# Check the test result
if [ $TEST_EXIT_CODE -ne 0 ]; then
  echo "----------------------------------------"
  echo "❌ Tests Failed! Extracting failure details..."
  echo "----------------------------------------"

  # Check if jq is installed for better formatting
  if command -v jq &> /dev/null; then
    echo "Formatting failure details using jq..."
    # Re-added --legacy flag as required by xcresulttool
    xcrun xcresulttool get --legacy --format json --path TestResults.xcresult | \
      jq -r '.actions._values[].actionResult.issues.testFailureSummaries._values[]? | select(. != null) | "\(.testCaseName._value // "Unknown Test Case"): \(.message._value // "No message")\n  File: \(.documentLocationInCreatingWorkspace.url._value // "N/A")\n  Line: \(.documentLocationInCreatingWorkspace.location.startingLineNumber // "N/A")\n"' \
      || { echo "jq processing failed. Printing raw JSON..."; xcrun xcresulttool get --legacy --format json --path TestResults.xcresult; }
  else
    echo "jq not found. Install jq for better formatted output (brew install jq)."
    echo "Printing raw failure details (JSON):"
    # Re-added --legacy flag
    xcrun xcresulttool get --legacy --format json --path TestResults.xcresult
  fi

  echo "----------------------------------------"
  # Still generate coverage report even on failure for analysis
  echo "📊 Generating Code Coverage Report (even on failure)..."
  echo "----------------------------------------"
  xcrun xccov view --report TestResults.xcresult --only-targets magical-stories || echo "Coverage report generation failed." # Use xcrun to find xccov
  echo "----------------------------------------"
  exit $TEST_EXIT_CODE
else
  echo "---------------------"
  echo "✅ Tests Passed!"
  echo "---------------------"
  echo ""
  echo "📊 Generating Code Coverage Report..."
  echo "----------------------------------------"
  # Generate and print coverage report for the main target
  xcrun xccov view --report TestResults.xcresult --only-targets magical-stories # Use xcrun to find xccov
  echo "----------------------------------------"
  exit 0
fi
