#!/bin/bash
# Usage:
#   ./run_tests.sh                # Run all tests
#   ./run_tests.sh TestClass/testMethod  # Run a specific test or tests (see xcodebuild -only-testing syntax)
destination='platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'
# Check if xcbeautify is installed
if ! command -v xcbeautify &> /dev/null
then
    echo "xcbeautify could not be found. Please install it using 'brew install xcbeautify'."
    exit 1
fi
if [ -n "$1" ]; then
  echo "Running only test(s): $1"
  xcodebuild test \
    -scheme magical-stories \
    -configuration Debug \
    -destination "$destination" \
    -enableCodeCoverage YES \
    -parallel-testing-enabled NO \
    -only-testing:"$1" | xcbeautify
else
  echo "Running all tests"
  xcodebuild test \
    -scheme magical-stories \
    -configuration Debug \
    -destination "$destination" \
    -enableCodeCoverage YES \
    -parallel-testing-enabled NO | xcbeautify
fi