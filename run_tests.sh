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
  -enableAddressSanitizer YES \
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
  echo "🔍 Extracting crash diagnostics (if any)..."
  echo "----------------------------------------"

  if command -v jq &> /dev/null; then
    # Extract diagnostics array and iterate over potential crash logs
    xcrun xcresulttool get --legacy --format json --path TestResults.xcresult | jq -r '
      .actions._values[]?.actionResult.diagnostics._values[]? |
      select(.identifier._value | test("crash"; "i")) |
      "\(.identifier._value)::: \(.url._value)"' | while IFS=":::" read -r diag_id diag_url; do
        if [ -n "$diag_url" ]; then
          echo ""
          echo "🔹 Crash Diagnostic: $diag_id"
          # Attempt to export the crash diagnostic content
          if xcrun xcresulttool export --path TestResults.xcresult --output-path crash_log.txt --xcresult-path "$diag_url" 2>/dev/null; then
            echo "----- Crash Log Start ($diag_id) -----"
            cat crash_log.txt
            echo "----- Crash Log End ($diag_id) -----"
            rm -f crash_log.txt
          else
            echo "Could not export crash diagnostic at $diag_url"
          fi
        fi
      done
  else
    echo "jq not found. Install jq for better crash diagnostics extraction (brew install jq)."
    echo "Dumping raw diagnostics section:"
    xcrun xcresulttool get --legacy --format json --path TestResults.xcresult
  fi

  echo "----------------------------------------"
  echo "📋 Full Diagnostics Dump"
  echo "----------------------------------------"
  xcrun xcresulttool get --legacy --format json --path TestResults.xcresult | jq '.actions._values[].actionResult.diagnostics' || echo "Failed to extract diagnostics JSON"

  echo "----------------------------------------"
  echo "📋 Extracting Standard Output and Error Logs"
  echo "----------------------------------------"
  xcrun xcresulttool get --legacy --format json --path TestResults.xcresult | jq -r '
    .actions._values[].actionResult.diagnostics._values[]? |
    select(.identifier._value | test("Standard(Output|Error)"; "i")) |
    "\(.identifier._value)::: \(.url._value)"' | while IFS=":::" read -r log_id log_url; do
      if [ -n "$log_url" ]; then
        echo ""
        echo "🔹 Log: $log_id"
        if xcrun xcresulttool export --path TestResults.xcresult --output-path temp_log.txt --xcresult-path "$log_url" 2>/dev/null; then
          echo "----- Log Start ($log_id) -----"
          cat temp_log.txt
          echo "----- Log End ($log_id) -----"
          rm -f temp_log.txt
        else
          echo "Could not export log at $log_url"
        fi
      fi
  done


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
