#!/bin/bash

# Color definitions for better readability
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
CYAN="\033[0;36m"
BOLD="\033[1m"
RESET="\033[0m"

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# Ensure pipeline commands return a failure status if any command fails
set -o pipefail

# Function to print section headers
print_header() {
  echo -e "\n${BOLD}${BLUE}=== $1 ===${RESET}\n"
}

# Function to print error messages
print_error() {
  echo -e "${RED}$1${RESET}"
}

# Function to print success messages
print_success() {
  echo -e "${GREEN}$1${RESET}"
}

# Function to print info messages
print_info() {
  echo -e "${CYAN}$1${RESET}"
}

# Function to print warnings
print_warning() {
  echo -e "${YELLOW}$1${RESET}"
}

# Check dependencies
check_dependency() {
  if ! command -v $1 &> /dev/null; then
    print_warning "$1 is not installed. Installing..."
    $2
    if ! command -v $1 &> /dev/null; then
      print_error "Failed to install $1. Some features may not work correctly."
      return 1
    fi
    print_success "$1 installed successfully."
  fi
  return 0
}

# Check for xcbeautify
check_dependency "xcbeautify" "gem install xcbeautify"

# Check for jq (used for JSON parsing)
JQ_AVAILABLE=false
if check_dependency "jq" "brew install jq"; then
  JQ_AVAILABLE=true
fi

# Remove previous results if they exist
print_header "CLEANING PREVIOUS TEST RESULTS"
rm -rf TestResults.xcresult
rm -rf TestResults.xml
rm -rf crash_logs
mkdir -p crash_logs

print_header "RUNNING TESTS"

# Handle optional test name argument
ONLY_TEST_ARG=""
if [ $# -ge 1 ]; then
  TEST_NAME="$1"
  
  # Improved test name formatting
  # Check if test name includes a test target
  if [[ "$TEST_NAME" != *"magical-storiesTests"* && "$TEST_NAME" != *"magical-storiesUITests"* ]]; then
    # Check if this is a UI test based on filename pattern
    if [[ "$TEST_NAME" == *"_UITests"* ]]; then
      # This appears to be a UI test
      TEST_NAME="magical-storiesUITests/$TEST_NAME"
    elif [[ "$TEST_NAME" == *"/"* ]]; then
      # If it looks like Class/testMethod format, add the target
      TEST_NAME="magical-storiesTests/$TEST_NAME"
    elif [[ "$TEST_NAME" =~ ^test[A-Z] ]]; then
      # If it starts with 'test' followed by uppercase, assume it's just a method name
      # Try to extract test class name from the method name (common naming convention)
      CLASS_NAME=$(echo "$TEST_NAME" | sed -E 's/test([A-Za-z0-9_]+)_.*/\1/')
      if [ -n "$CLASS_NAME" ]; then
        TEST_NAME="magical-storiesTests/${CLASS_NAME}_Tests/$TEST_NAME"
      else
        print_warning "Could not determine test class from method name. Please specify full test path."
        print_info "Example: magical-storiesTests/MyTestClass/testMyMethod"
        exit 1
      fi
    else
      # Assume it's a test class name
      TEST_NAME="magical-storiesTests/$TEST_NAME"
    fi
  fi
  
  print_info "Running only test: ${BOLD}$TEST_NAME${RESET}"
  ONLY_TEST_ARG="-only-testing $TEST_NAME"
else
  print_info "Running all tests"
fi

# Run the tests with a timeout to prevent hanging
set +e # Temporarily disable exit on error to capture the status
timeout_cmd=""
if command -v timeout &> /dev/null; then
  timeout_cmd="timeout 30m" # 30 minute timeout
fi

# Determine which sanitizer to use (default to Address Sanitizer)
SANITIZER="address"
if [ $# -ge 2 ]; then
  if [ "$2" = "thread" ]; then
    SANITIZER="thread"
    print_info "Using Thread Sanitizer"
  elif [ "$2" = "undefined" ]; then
    SANITIZER="undefined"
    print_info "Using Undefined Behavior Sanitizer"
  elif [ "$2" = "none" ]; then
    SANITIZER="none"
    print_info "Running without sanitizers"
  else
    print_info "Using Address Sanitizer"
  fi
else
  print_info "Using Address Sanitizer (default)"
fi

# Configure sanitizer flags based on selection
SANITIZER_FLAGS=""
if [ "$SANITIZER" = "address" ]; then
  SANITIZER_FLAGS="-enableAddressSanitizer YES"
elif [ "$SANITIZER" = "thread" ]; then
  SANITIZER_FLAGS="-enableThreadSanitizer YES"
elif [ "$SANITIZER" = "undefined" ]; then
  SANITIZER_FLAGS="-enableUndefinedBehaviorSanitizer YES"
fi

$timeout_cmd xcodebuild test \
  -scheme magical-stories \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.2' \
  -enableCodeCoverage YES \
  $SANITIZER_FLAGS \
  -parallel-testing-enabled NO \
  -allowProvisioningUpdates \
  -resultBundlePath TestResults.xcresult \
  $ONLY_TEST_ARG | xcbeautify \
  --quiet \
  --report junit \
  --report-path TestResults.xml \
  --is-ci
TEST_EXIT_CODE=$?
set -e # Re-enable exit on error

# Function to extract and format test failures
extract_test_failures() {
  print_header "TEST FAILURES"
  
  if [ "$JQ_AVAILABLE" = true ]; then
    # Extract test failure summaries with detailed formatting
    xcrun xcresulttool get --legacy --format json --path TestResults.xcresult | \
      jq -r '.actions._values[].actionResult.issues.testFailureSummaries._values[]? | 
      select(. != null) | 
      "${RED}${BOLD}FAILED: ${RESET}${BOLD}\(.testCaseName._value // "Unknown Test Case")${RESET}\n${RED}Error: ${RESET}\(.message._value // "No message")\n  ${BOLD}File: ${RESET}\(.documentLocationInCreatingWorkspace.url._value // "N/A")\n  ${BOLD}Line: ${RESET}\(.documentLocationInCreatingWorkspace.location.startingLineNumber // "N/A")\n"' || {
        print_error "jq processing failed. Printing raw JSON..."
        xcrun xcresulttool get --legacy --format json --path TestResults.xcresult
      }
      
    # Extract additional context from test activities
    print_info "${BOLD}Extracting test activity details...${RESET}"
    xcrun xcresulttool get --legacy --format json --path TestResults.xcresult | \
      jq -r '.actions._values[].actionResult.testsRef.id._value' | \
      while read -r test_ref_id; do
        if [ -n "$test_ref_id" ]; then
          # Extract test failures with more context
          xcrun xcresulttool get --legacy --format json --path TestResults.xcresult --id "$test_ref_id" | \
            jq -r '.summaries._values[]?.testableSummaries._values[]?.tests._values[]? | 
            recurse(.subtests?._values[]?) | 
            select(.testStatus?._value == "Failure") | 
            "\n${PURPLE}${BOLD}=== Detailed Failure Information ===${RESET}\n${BOLD}Test: ${RESET}\(.identifier?._value // "Unknown")\n${BOLD}Duration: ${RESET}\(.duration?._value // "Unknown") seconds\n${BOLD}Activity Summaries: ${RESET}" + 
            (if .activitySummaries?._values then 
              ("\n" + (.activitySummaries?._values | map("  ${YELLOW}• \(.title?._value // "Unknown Activity")${RESET}" + 
              if .attachments?._values then 
                ("\n" + (.attachments?._values | map("    ${CYAN}- \(.name?._value // "Unknown Attachment")${RESET}") | join("\n"))) 
              else "" end) | join("\n"))) 
            else "None" end)' || true
          
          # Extract failure attachments (screenshots, logs, etc.)
          xcrun xcresulttool get --legacy --format json --path TestResults.xcresult --id "$test_ref_id" | \
            jq -r '.summaries._values[]?.testableSummaries._values[]?.tests._values[]? | 
            recurse(.subtests?._values[]?) | 
            select(.testStatus?._value == "Failure") | 
            .activitySummaries?._values[]? | 
            select(.attachments?._values != null) | 
            .attachments?._values[]? | 
            select(.payloadRef?.id?._value != null) | 
            "\(.name?._value // "Unknown Attachment")::: \(.payloadRef?.id?._value)"' | \
            while IFS=":::" read -r attachment_name attachment_id; do
              if [ -n "$attachment_id" ]; then
                attachment_file="crash_logs/attachment_$(echo "$attachment_name" | tr -dc '[:alnum:]')_$(date +%s).txt"
                if xcrun xcresulttool export --path TestResults.xcresult --output-path "$attachment_file" --id "$attachment_id" 2>/dev/null; then
                  print_info "${BOLD}📎 Test Attachment: ${CYAN}$attachment_name${RESET}"
                  echo -e "${CYAN}----- Attachment Content Start -----${RESET}"
                  cat "$attachment_file" | sed -E "s/(error|fail|exception|crash|fatal)/\${RED}\1\${RESET}/gi" | sed -E "s/(warning|deprecated)/\${YELLOW}\1\${RESET}/gi"
                  echo -e "${CYAN}----- Attachment Content End -----${RESET}"
                  print_info "Attachment saved to: $attachment_file"
                fi
              fi
            done
        fi
      done
      
    # Extract expected vs actual values for assertion failures
    print_info "${BOLD}Extracting expected vs actual values...${RESET}"
    xcrun xcresulttool get --legacy --format json --path TestResults.xcresult | \
      jq -r '.actions._values[].actionResult.issues.testFailureSummaries._values[]? | 
      select(. != null) | 
      select(.message._value | test("expected") or test("XCTAssert")) | 
      "\n${BOLD}Assertion Failure in ${RESET}\(.testCaseName._value // "Unknown Test Case"):\n" + 
      (if (.message._value | test("expected .* but got .*")) then 
        (.message._value | capture("expected (?<expected>.*) but got (?<actual>.*)") | 
        "${BOLD}Expected: ${GREEN}\(.expected)${RESET}\n${BOLD}Actual: ${RED}\(.actual)${RESET}") 
      elif (.message._value | test("XCTAssertEqual.*expected: \\(.*\\), actual: \\(.*\\)")) then 
        (.message._value | capture("expected: \\((?<expected>.*)\\), actual: \\((?<actual>.*)\\)") | 
        "${BOLD}Expected: ${GREEN}\(.expected)${RESET}\n${BOLD}Actual: ${RED}\(.actual)${RESET}") 
      else "${YELLOW}\(.message._value)${RESET}" end)' || true
  else
    print_warning "jq not installed. Install jq for better formatted output (brew install jq)."
    print_info "Printing raw failure details (JSON):"
    xcrun xcresulttool get --legacy --format json --path TestResults.xcresult
  fi
}

# Function to extract and process crash logs
extract_crash_logs() {
  print_header "CRASH DIAGNOSTICS"
  
  if [ "$JQ_AVAILABLE" = true ]; then
    # Create a directory for crash logs
    mkdir -p crash_logs
    
    # Extract all diagnostics that might be related to crashes
    xcrun xcresulttool get --legacy --format json --path TestResults.xcresult | jq -r '
      .actions._values[]?.actionResult.diagnostics._values[]? |
      select(.identifier._value | test("crash|exception|signal|abort|fatal|EXC_|SIGSEGV|SIGABRT"; "i")) |
      "\(.identifier._value)::: \(.url._value)"' | while IFS=":::" read -r diag_id diag_url; do
        if [ -n "$diag_url" ]; then
          print_info "${BOLD}🔹 Crash Diagnostic: ${PURPLE}$diag_id${RESET}"
          
          # Create a unique filename for this crash log
          crash_file="crash_logs/$(echo "$diag_id" | tr -dc '[:alnum:]')_$(date +%s).txt"
          
          # Attempt to export the crash diagnostic content
          if xcrun xcresulttool export --path TestResults.xcresult --output-path "$crash_file" --xcresult-path "$diag_url" 2>/dev/null; then
            echo -e "${YELLOW}----- Crash Log Start ($diag_id) -----${RESET}"
            
            # Try to symbolicate the crash log if it contains stack traces
            if grep -q "0x" "$crash_file"; then
              print_info "Attempting to symbolicate crash log..."
              if command -v atos &> /dev/null; then
                # Extract binary path and load addresses for symbolication
                binary_path=$(grep -o '/.*\.app/.*' "$crash_file" | head -1 || echo "")
                if [ -n "$binary_path" ] && [ -f "$binary_path" ]; then
                  # Create a symbolicated version
                  cat "$crash_file" | while IFS= read -r line; do
                    if [[ "$line" =~ 0x[0-9a-fA-F]+ ]]; then
                      addr=$(echo "$line" | grep -o '0x[0-9a-fA-F]\+' | head -1)
                      sym=$(xcrun atos -o "$binary_path" "$addr" 2>/dev/null || echo "")
                      if [ -n "$sym" ] && [ "$sym" != "$addr" ]; then
                        echo -e "${RED}$line${RESET}"
                        echo -e "${GREEN}Symbolicated: $sym${RESET}"
                      else
                        echo -e "$line"
                      fi
                    else
                      echo -e "$line"
                    fi
                  done
                else
                  cat "$crash_file"
                fi
              else
                cat "$crash_file"
              fi
            else
              cat "$crash_file"
            fi
            
            echo -e "${YELLOW}----- Crash Log End ($diag_id) -----${RESET}"
            print_info "Crash log saved to: $crash_file"
          else
            print_error "Could not export crash diagnostic at $diag_url"
          fi
        fi
      done
      
    # Look for Address Sanitizer reports
    print_info "${BOLD}Checking for Address Sanitizer reports...${RESET}"
    xcrun xcresulttool get --legacy --format json --path TestResults.xcresult | jq -r '
      .actions._values[]?.actionResult.diagnostics._values[]? |
      select(.identifier._value | test("Standard(Output|Error)"; "i")) |
      "\(.identifier._value)::: \(.url._value)"' | while IFS=":::" read -r log_id log_url; do
        if [ -n "$log_url" ]; then
          asan_file="crash_logs/asan_$(echo "$log_id" | tr -dc '[:alnum:]')_$(date +%s).txt"
          if xcrun xcresulttool export --path TestResults.xcresult --output-path "$asan_file" --xcresult-path "$log_url" 2>/dev/null; then
            if grep -q "ERROR: AddressSanitizer" "$asan_file" || grep -q "ThreadSanitizer" "$asan_file" || grep -q "UndefinedBehaviorSanitizer" "$asan_file"; then
              print_error "${BOLD}🔥 Sanitizer Error Detected in $log_id:${RESET}"
              echo -e "${RED}----- Sanitizer Report Start -----${RESET}"
              grep -A 50 -B 5 "Sanitizer" "$asan_file" || cat "$asan_file"
              echo -e "${RED}----- Sanitizer Report End -----${RESET}"
              print_info "Full sanitizer log saved to: $asan_file"
            fi
          fi
        fi
      done
  else
    print_warning "jq not installed. Install jq for better crash diagnostics extraction (brew install jq)."
    print_error "Dumping raw diagnostics section:"
    xcrun xcresulttool get --legacy --format json --path TestResults.xcresult
  fi
}

# Function to extract standard output and error logs
extract_std_logs() {
  print_header "STANDARD OUTPUT AND ERROR LOGS"
  
  if [ "$JQ_AVAILABLE" = true ]; then
    xcrun xcresulttool get --legacy --format json --path TestResults.xcresult | jq -r '
      .actions._values[].actionResult.diagnostics._values[]? |
      select(.identifier._value | test("Standard(Output|Error)"; "i")) |
      "\(.identifier._value)::: \(.url._value)"' | while IFS=":::" read -r log_id log_url; do
        if [ -n "$log_url" ]; then
          print_info "${BOLD}🔹 Log: ${CYAN}$log_id${RESET}"
          log_file="crash_logs/$(echo "$log_id" | tr -dc '[:alnum:]')_$(date +%s).txt"
          if xcrun xcresulttool export --path TestResults.xcresult --output-path "$log_file" --xcresult-path "$log_url" 2>/dev/null; then
            echo -e "${CYAN}----- Log Start ($log_id) -----${RESET}"
            # Highlight errors and warnings in the log
            cat "$log_file" | sed -E "s/(error|fail|exception|crash|fatal)/\${RED}\1\${RESET}/gi" | sed -E "s/(warning|deprecated)/\${YELLOW}\1\${RESET}/gi"
            echo -e "${CYAN}----- Log End ($log_id) -----${RESET}"
            print_info "Log saved to: $log_file"
          else
            print_error "Could not export log at $log_url"
          fi
        fi
      done
  else
    print_warning "jq not installed. Install jq for better log extraction (brew install jq)."
  fi
}

# Function to generate and display code coverage
generate_coverage_report() {
  print_header "CODE COVERAGE REPORT"
  
  # Generate and print coverage report for the main target
  xcrun xccov view --report TestResults.xcresult --only-targets magical-stories | while IFS= read -r line; do
    if [[ "$line" =~ [0-9]+.[0-9]+% ]]; then
      percentage=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+%')
      value=$(echo "$percentage" | grep -o '[0-9]\+\.[0-9]\+' | awk '{print int($1)}')
      
      if [ "$value" -ge 80 ]; then
        # Good coverage (>= 80%)
        echo -e "$line" | sed "s/$percentage/${GREEN}$percentage${RESET}/"
      elif [ "$value" -ge 60 ]; then
        # Medium coverage (60-79%)
        echo -e "$line" | sed "s/$percentage/${YELLOW}$percentage${RESET}/"
      else
        # Poor coverage (< 60%)
        echo -e "$line" | sed "s/$percentage/${RED}$percentage${RESET}/"
      fi
    else
      echo "$line"
    fi
  done || print_error "Coverage report generation failed."
}

# Function to analyze snapshot test failures
analyze_snapshot_failures() {
  print_header "SNAPSHOT TEST ANALYSIS"
  
  if [ "$JQ_AVAILABLE" = true ]; then
    # Check if there are any snapshot test failures
    snapshot_failures=$(xcrun xcresulttool get --legacy --format json --path TestResults.xcresult | \
      jq -r '.actions._values[].actionResult.issues.testFailureSummaries._values[]? | 
      select(. != null) | 
      select(.testCaseName._value | test("Snapshot")) | 
      .testCaseName._value' | wc -l | tr -d ' ')
    
    if [ "$snapshot_failures" -gt 0 ]; then
      print_info "${BOLD}Found ${snapshot_failures} snapshot test failures${RESET}"
      
      # Find reference images directory
      snapshot_ref_dir=""
      if [ -d "magical-storiesTests/SnapshotTests/__Snapshots__" ]; then
        snapshot_ref_dir="magical-storiesTests/SnapshotTests/__Snapshots__"
      elif [ -d "magical-storiesTests/__Snapshots__" ]; then
        snapshot_ref_dir="magical-storiesTests/__Snapshots__"
      fi
      
      if [ -n "$snapshot_ref_dir" ]; then
        print_info "${BOLD}Snapshot reference directory: ${RESET}${snapshot_ref_dir}"
        
        # Extract failed snapshot test names and look for their reference images
        xcrun xcresulttool get --legacy --format json --path TestResults.xcresult | \
          jq -r '.actions._values[].actionResult.issues.testFailureSummaries._values[]? | 
          select(. != null) | 
          select(.testCaseName._value | test("Snapshot")) | 
          .testCaseName._value' | while read -r test_name; do
            # Extract the class and method name
            class_name=$(echo "$test_name" | cut -d'/' -f1)
            method_name=$(echo "$test_name" | cut -d'/' -f2 | sed 's/()$//')
            
            print_info "${BOLD}Looking for reference images for: ${RESET}${class_name}/${method_name}"
            
            # Find reference images for this test
            find "$snapshot_ref_dir" -type f -name "*${method_name}*" | while read -r ref_image; do
              echo -e "${YELLOW}Reference image: ${RESET}${ref_image}"
              
              # Check if there's a failed image in the test results
              failed_image=$(find crash_logs -type f -name "*${method_name}*" | head -1)
              if [ -n "$failed_image" ]; then
                echo -e "${RED}Failed image: ${RESET}${failed_image}"
                
                # If we have ImageMagick installed, show the difference
                if command -v compare &> /dev/null; then
                  diff_image="crash_logs/diff_${method_name}_$(date +%s).png"
                  if compare -metric AE "$ref_image" "$failed_image" "$diff_image" 2>/dev/null; then
                    echo -e "${GREEN}Images are identical${RESET}"
                  else
                    echo -e "${RED}Images differ. Difference saved to: ${RESET}${diff_image}"
                    # If we have ImageMagick's montage, create a side-by-side comparison
                    if command -v montage &> /dev/null; then
                      montage_image="crash_logs/montage_${method_name}_$(date +%s).png"
                      montage "$ref_image" "$failed_image" "$diff_image" -geometry +5+5 "$montage_image"
                      echo -e "${CYAN}Side-by-side comparison: ${RESET}${montage_image}"
                    fi
                  fi
                else
                  echo -e "${YELLOW}Install ImageMagick for visual diff (brew install imagemagick)${RESET}"
                fi
              fi
            done
        done
      else
        print_warning "Could not find snapshot reference directory"
      fi
    else
      print_info "No snapshot test failures detected"
    fi
  else
    print_warning "jq not installed. Cannot analyze snapshot test failures."
  fi
}

# Function to summarize test results
summarize_results() {
  print_header "TEST SUMMARY"
  
  if [ "$JQ_AVAILABLE" = true ]; then
    # Extract test counts
    total_tests=$(xcrun xcresulttool get --legacy --format json --path TestResults.xcresult | jq -r '.actions._values[].actionResult.testsRef.id._value' | while read -r test_ref_id; do
      if [ -n "$test_ref_id" ]; then
        xcrun xcresulttool get --legacy --format json --path TestResults.xcresult --id "$test_ref_id" | jq -r '.summaries._values[]?.testableSummaries._values[]? | .tests._values[]? | recurse(.subtests?._values[]?) | select(.identifier?._value != null) | .identifier?._value' | wc -l | tr -d ' '
      fi
    done)
    
    failed_tests=$(xcrun xcresulttool get --legacy --format json --path TestResults.xcresult | jq -r '.actions._values[].actionResult.testsRef.id._value' | while read -r test_ref_id; do
      if [ -n "$test_ref_id" ]; then
        xcrun xcresulttool get --legacy --format json --path TestResults.xcresult --id "$test_ref_id" | jq -r '.summaries._values[]?.testableSummaries._values[]? | .tests._values[]? | recurse(.subtests?._values[]?) | select(.testStatus?._value == "Failure") | .identifier?._value' | wc -l | tr -d ' '
      fi
    done)
    
    # Calculate passed tests
    passed_tests=$((total_tests - failed_tests))
    
    # Print summary with colors
    echo -e "${BOLD}Tests Run: ${RESET}${total_tests}"
    echo -e "${BOLD}Tests Passed: ${RESET}${GREEN}${passed_tests}${RESET}"
    
    if [ "$failed_tests" -gt 0 ]; then
      echo -e "${BOLD}Tests Failed: ${RESET}${RED}${failed_tests}${RESET}"
      
      # Group failed tests by category for better readability
      print_info "${BOLD}Failed Tests by Category:${RESET}"
      
      # Get all failed tests
      failed_test_list=$(xcrun xcresulttool get --legacy --format json --path TestResults.xcresult | jq -r '.actions._values[].actionResult.testsRef.id._value' | while read -r test_ref_id; do
        if [ -n "$test_ref_id" ]; then
          xcrun xcresulttool get --legacy --format json --path TestResults.xcresult --id "$test_ref_id" | jq -r '.summaries._values[]?.testableSummaries._values[]? | .tests._values[]? | recurse(.subtests?._values[]?) | select(.testStatus?._value == "Failure") | .identifier?._value'
        fi
      done)
      
      # Group by test class
      # Create a temporary file to track printed classes
      class_printed_file=$(mktemp)
      
      echo "$failed_test_list" | sort | while read -r test; do
        class_name=$(echo "$test" | cut -d'/' -f1)
        method_name=$(echo "$test" | cut -d'/' -f2 | sed 's/()$//')
        
        # Check if class has been printed already
        if ! grep -q "^$class_name$" "$class_printed_file" 2>/dev/null; then
          echo -e "\n${PURPLE}${BOLD}$class_name:${RESET}"
          echo "$class_name" >> "$class_printed_file"
        fi
        echo -e "  ${RED}• $method_name${RESET}"
      done
      
      # Clean up temp file
      rm -f "$class_printed_file"
    else
      echo -e "${BOLD}Tests Failed: ${RESET}${GREEN}0${RESET}"
    fi
    
    # Check for crashes
    crash_count=$(find crash_logs -type f -name "crash_*" | wc -l | tr -d ' ')
    if [ "$crash_count" -gt 0 ]; then
      echo -e "${BOLD}Crashes Detected: ${RESET}${RED}${crash_count}${RESET}"
    else
      echo -e "${BOLD}Crashes Detected: ${RESET}${GREEN}0${RESET}"
    fi
  else
    print_warning "jq not installed. Cannot generate detailed test summary."
  fi
}

# Process test results
if [ $TEST_EXIT_CODE -ne 0 ]; then
  print_error "${BOLD}❌ TESTS FAILED!${RESET}"
  
  # Extract and display test failures
  extract_test_failures
  
  # Extract and display crash logs
  extract_crash_logs
  
  # Extract standard output and error logs
  extract_std_logs
  
  # Analyze snapshot test failures if any
  analyze_snapshot_failures
  
  # Generate coverage report even on failure
  generate_coverage_report
  
  # Summarize results
  summarize_results
  
  print_header "TROUBLESHOOTING TIPS"
  print_info "1. Check for memory issues (leaks, use-after-free, etc.)"
  print_info "2. Look for race conditions in async code"
  print_info "3. Verify test dependencies and mocks are properly set up"
  print_info "4. Ensure UI tests have proper delays for animations"
  print_info "5. Check for API changes that might affect tests"
  
  exit $TEST_EXIT_CODE
else
  print_success "${BOLD}✅ TESTS PASSED!${RESET}"
  
  # Generate coverage report
  generate_coverage_report
  
  # Analyze snapshot test failures if any
  analyze_snapshot_failures
  
  # Summarize results
  summarize_results
  
  exit 0
fi
