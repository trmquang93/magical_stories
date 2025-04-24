#!/bin/bash

# Color definitions for better readability
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
BOLD="\033[1m"
RESET="\033[0m"

# Print styled message
print_header() {
  echo -e "\n${BOLD}${BLUE}=== $1 ===${RESET}\n"
}

print_success() {
  echo -e "${GREEN}$1${RESET}"
}

print_info() {
  echo -e "$1"
}

print_warning() {
  echo -e "${YELLOW}$1${RESET}"
}

print_error() {
  echo -e "${RED}$1${RESET}"
}

# Check if xcodebuild exists
if ! command -v xcodebuild &> /dev/null; then
  print_error "Error: xcodebuild command not found. Make sure Xcode is installed correctly."
  exit 1
fi

# Get derived data path
DERIVED_DATA_PATH=$(xcodebuild -showBuildSettings -scheme magical-stories | grep OBJROOT | awk '{print $3}' | sed 's|/Build/Intermediates.noindex||')

if [ -z "$DERIVED_DATA_PATH" ]; then
  # Fallback to default location
  print_warning "Could not determine DerivedData path. Using default location."
  DERIVED_DATA_PATH="$HOME/Library/Developer/Xcode/DerivedData"
  MAGICAL_STORIES_DIR=$(find "$DERIVED_DATA_PATH" -name "magical-stories-*" -type d | head -n 1)
  if [ -n "$MAGICAL_STORIES_DIR" ]; then
    DERIVED_DATA_PATH="$MAGICAL_STORIES_DIR"
    print_info "Found project's DerivedData: $DERIVED_DATA_PATH"
  else
    print_warning "Could not find magical-stories specific directory. Will clean entire DerivedData."
  fi
fi

print_header "CLEANING XCODE CACHES"

# Close Xcode if it's running
print_info "Checking if Xcode is running..."
if pgrep -x "Xcode" > /dev/null; then
  print_warning "Xcode is currently running. Please close Xcode before continuing."
  read -p "Continue anyway? [y/N] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Aborting. Please close Xcode and run this script again."
    exit 1
  fi
  print_warning "Continuing despite Xcode running. This may cause issues."
else
  print_success "Xcode is not running. Proceeding."
fi

# Clean DerivedData
print_info "Cleaning DerivedData..."
if [ -d "$DERIVED_DATA_PATH" ]; then
  rm -rf "$DERIVED_DATA_PATH"
  print_success "Removed project's derived data at: $DERIVED_DATA_PATH"
else
  print_warning "DerivedData directory not found at: $DERIVED_DATA_PATH"
fi

# Clean module cache
print_info "Cleaning module cache..."
MODULE_CACHE="$HOME/Library/Developer/Xcode/DerivedData/ModuleCache.noindex"
if [ -d "$MODULE_CACHE" ]; then
  rm -rf "$MODULE_CACHE"
  print_success "Removed module cache at: $MODULE_CACHE"
else
  print_warning "Module cache not found at: $MODULE_CACHE"
fi

# Clean SDK stat cache
print_info "Cleaning SDK stat cache..."
SDK_CACHE="$HOME/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex"
if [ -d "$SDK_CACHE" ]; then
  rm -rf "$SDK_CACHE"
  print_success "Removed SDK stat cache at: $SDK_CACHE"
else
  print_warning "SDK stat cache not found at: $SDK_CACHE"
fi

# Recreate necessary directories with proper permissions
print_info "Recreating cache directories..."
mkdir -p "$MODULE_CACHE"
mkdir -p "$SDK_CACHE"
print_success "Cache directories recreated"

print_header "CLEANING PROJECT"

# Clean build folder
print_info "Cleaning build folder..."
rm -rf "./build"
print_success "Removed local build folder"

# Use xcodebuild clean
print_info "Running xcodebuild clean..."
xcodebuild clean -scheme magical-stories -quiet
print_success "xcodebuild clean completed"

print_header "REBUILDING PROJECT"

# Build the project without testing
print_info "Building the project (without running tests)..."
xcodebuild build -scheme magical-stories -destination 'platform=iOS Simulator,name=iPhone 16e,OS=18.4' -quiet
BUILD_RESULT=$?

if [ $BUILD_RESULT -eq 0 ]; then
  print_success "Build successful!"
  
  print_header "RUNNING TESTS"
  print_info "Now you can run the tests using ./run_tests.sh"
  
  # Optional: Ask if user wants to run tests now
  read -p "Do you want to run the tests now? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    ./run_tests.sh
  fi
else
  print_error "Build failed with exit code $BUILD_RESULT"
  print_info "You may need to open the project in Xcode to see detailed errors"
fi

print_header "CLEANUP COMPLETE"
print_success "Xcode cache cleaning and rebuild process completed" 