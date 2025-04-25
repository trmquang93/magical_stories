#!/bin/bash
# Usage:
#   ./run_tests.sh                # Run all tests
#   ./run_tests.sh TestClass/testMethod  # Run a specific test or tests (see xcodebuild -only-testing syntax)

if [ -n "$1" ]; then
  echo "Running only test(s): $1"
  xcodebuild test \
    -scheme magical-stories \
    -configuration Debug \
    -destination 'platform=iOS Simulator,name=iPhone 16e,OS=18.4' \
    -enableCodeCoverage YES \
    -parallel-testing-enabled NO \
    -only-testing "$1" | xcbeautify
else
  echo "Running all tests"
  xcodebuild test \
    -scheme magical-stories \
    -configuration Debug \
    -destination 'platform=iOS Simulator,name=iPhone 16e,OS=18.4' \
    -enableCodeCoverage YES \
    -parallel-testing-enabled NO | xcbeautify
fi