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
rm -rf TestResults.xml

# Run tests with coverage
echo "Running tests..."
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
