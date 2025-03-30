#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# Ensure pipeline commands return a failure status if any command fails
set -o pipefail

# Function to print colored output
print_colored() {
  local color=$1
  local text=$2
  case $color in
    "green") echo -e "\033[32m${text}\033[0m" ;;
    "red") echo -e "\033[31m${text}\033[0m" ;;
    "yellow") echo -e "\033[33m${text}\033[0m" ;;
    "blue") echo -e "\033[34m${text}\033[0m" ;;
  esac
}

# Function to print section header
print_header() {
  local title=$1
  echo
  print_colored "blue" "═══════════════════════════════════════════"
  print_colored "blue" "  ${title}"
  print_colored "blue" "═══════════════════════════════════════════"
}

# Check if xcpretty is installed
if ! command -v xcpretty &> /dev/null; then
    echo "xcpretty is not installed. Installing..."
    gem install xcpretty
fi

# Remove previous results if they exist
echo "Cleaning previous test results..."
rm -rf TestResults.xcresult

# Run tests with coverage
echo "Running tests..."
xcodebuild test \
  -project magical-stories.xcodeproj \
  -scheme magical-stories \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.2' \
  -enableCodeCoverage YES \
  -allowProvisioningUpdates \
  -resultBundlePath TestResults.xcresult | xcpretty --report junit
