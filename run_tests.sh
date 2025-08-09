#!/bin/bash

# iOS Test Runner - Enhanced Output with Detailed Failure Information
# Usage: ./run-tests.sh [unit|ui|all]

set -e

PROJECT_NAME="magical-stories"
SCHEME="magical-stories"
DESTINATION="platform=iOS Simulator,name=iPhone 16 Pro,OS=latest"

echo "🧪 iOS Test Runner"
echo "=================="

# Function to extract detailed test failure information
extract_test_failure_details() {
    local test_name="$1"
    local full_output="$2"
    local xcresult_path="$3"
    local method_name=$(echo "$test_name" | sed 's/.*\.//' | sed 's/()$//')
    
    if [ "$VERBOSE" = "true" ]; then
        echo "[DEBUG] Extracting failure details for: $test_name" >&2
        echo "[DEBUG] Method name: $method_name" >&2
        echo "[DEBUG] xcresult path: $xcresult_path" >&2
    fi
    
    # Method 1: Try xcresulttool with various approaches
    if [ -n "$xcresult_path" ] && [ -d "$xcresult_path" ] && command -v xcrun >/dev/null 2>&1; then
        if [ "$VERBOSE" = "true" ]; then
            echo "[DEBUG] Attempting xcresulttool extraction..." >&2
        fi
        
        # First try: Get test issues and failure summaries
        local failure_details=$(xcrun xcresulttool get --format json --path "$xcresult_path" 2>/dev/null | 
            jq -r --arg test_name "$test_name" '
            .. | objects | 
            select(.testIdentifier? == $test_name or (.identifier? // .name? // .title?) | test($test_name)) | 
            (.failureSummary? // .message? // .issueDocument?.message? // empty)' 2>/dev/null | 
            grep -v "null" | head -5)
        
        if [ -n "$failure_details" ] && [ "$failure_details" != "null" ] && [ "$failure_details" != "" ]; then
            echo "$failure_details"
            return
        fi
        
        # Second try: Look for issues in test results
        local issue_details=$(xcrun xcresulttool get --format json --path "$xcresult_path" 2>/dev/null | 
            jq -r --arg test_name "$test_name" '
            .. | objects | select(.issues?) | .issues[] | 
            select(.testCaseName? == $test_name or .message | contains($test_name)) | 
            .message' 2>/dev/null | head -3)
            
        if [ -n "$issue_details" ] && [ "$issue_details" != "null" ] && [ "$issue_details" != "" ]; then
            echo "$issue_details"
            return
        fi
    fi
    
    # Method 2: Enhanced search for test-specific error patterns in the output
    if [ "$VERBOSE" = "true" ]; then
        echo "[DEBUG] Searching for error patterns in output..." >&2
    fi
    
    # Look for Swift Testing failure patterns (modern format)
    local swift_testing_errors=$(echo "$full_output" | grep -A 20 -B 5 "$method_name" | 
        grep -E "(failed|error|assertion|expectation|Issue recorded|XCTAssert)" | head -5)
    
    if [ -n "$swift_testing_errors" ]; then
        echo "$swift_testing_errors"
        return
    fi
    
    # Look for service-level error messages (from the actual logs)
    local service_errors=$(echo "$full_output" | 
        grep -E "\[$method_name\].*❌|\[$method_name\].*failed|❌.*$method_name|error.*$method_name" | head -3)
    
    if [ -n "$service_errors" ]; then
        echo "$service_errors"
        return
    fi
    
    # Method 3: Broader context search around test execution
    local test_context=$(echo "$full_output" | grep -A 15 -B 5 "$test_name")
    local failure_indicators=$(echo "$test_context" | grep -E "(failed|error|assertion|❌|✗|Issue recorded)" | head -3)
    
    if [ -n "$failure_indicators" ]; then
        echo "$failure_indicators"
        return
    fi
    
    # Method 4: Last resort - search for any nearby error messages
    local nearby_errors=$(echo "$full_output" | 
        grep -A 50 -B 10 "Test \"$method_name\"" | 
        grep -E "(❌|failed|error|assertion)" | head -3)
        
    if [ -n "$nearby_errors" ]; then
        echo "$nearby_errors"
        return
    fi
    
    # Method 5: If verbose, show more context
    if [ "$VERBOSE" = "true" ]; then
        echo "Test failed - detailed context:"
        echo "$test_context" | head -10
        return
    fi
    
    # Method 6: If all else fails, provide a helpful message
    echo "Test failed - run with --verbose for more details or individually: xcodebuild test -only-testing:\"$test_name\""
}

run_tests() {
    local target="$1"
    local name="$2"
    
    echo ""
    echo "🔍 Running $name..."
    
    # First, generate the project if needed
    if [ ! -f "$PROJECT_NAME.xcodeproj/project.pbxproj" ]; then
        echo "🔧 Generating Xcode project..."
        if command -v xcodegen >/dev/null 2>&1; then
            xcodegen generate 2>/dev/null || echo "⚠️ XcodeGen failed, proceeding with existing project"
        else
            echo "⚠️ XcodeGen not installed, using existing project"
        fi
    fi
    
    # Check if we have cached output for faster debugging
    cache_file="/tmp/xcodebuild_output_${target}.txt"
    if [ -f "$cache_file" ] && [ "$USE_CACHE" = "true" ]; then
        echo "📦 Using cached test output..."
        output=$(cat "$cache_file")
    else
        echo "🏃 Running tests..."
        # Run tests and capture output
        output=$(xcodebuild test \
            -project "$PROJECT_NAME.xcodeproj" \
            -scheme "$SCHEME" \
            -destination "$DESTINATION" \
            -only-testing:"$target" \
            2>&1)
        
        # Cache the output
        echo "$output" > "$cache_file"
        echo "💾 Test output cached to $cache_file"
    fi
    
    local exit_code=$?
    
    # Check for build failures (compilation errors)
    if echo "$output" | grep -q "BUILD FAILED\|fatal error:\|error:.*\.swift\|Build input file cannot be found\|Compilation failed"; then
        echo "💥 $name: Build failed"
        echo ""
        echo "🔥 Build Errors:"
        echo "$output" | grep -E "error:.*\.swift|fatal error:|Build input file cannot be found|.*\.swift:[0-9]+:[0-9]+: error:" | head -15 | sed 's/^/   /'
        echo ""
        echo "📋 Build Output (last 20 lines):"
        echo "$output" | tail -20 | sed 's/^/   /'
        return 1
    fi
    
    # Check for scheme/destination issues
    if echo "$output" | grep -q "Unable to find a destination\|does not contain a scheme"; then
        echo "💥 $name: Configuration error"
        echo ""
        echo "🔧 Configuration Issues:"
        echo "$output" | grep -E "Unable to find a destination|does not contain a scheme" | sed 's/^/   /'
        return 1
    fi
    
    # Check for Swift Testing framework output (new format)
    if echo "$output" | grep -q "✔ Test run with.*passed\|✘ Test run with.*failed\|◇ Test.*started\|✔ Test.*passed"; then
        # Swift Testing format
        # Count individual test results AND check overall summary
        passed=$(echo "$output" | grep -c "✔ Test.*passed" 2>/dev/null || echo "0")
        
        # Look for overall test run summary to get failure count
        swift_test_summary=$(echo "$output" | grep -E "✔ Test run with.*passed|✘ Test run with.*failed" | tail -1)
        if [ -n "$swift_test_summary" ]; then
            if echo "$swift_test_summary" | grep -q "✔ Test run with.*passed"; then
                # All tests passed
                failed="0"
            elif echo "$swift_test_summary" | grep -q "✘ Test run with.*failed.*with.*issues"; then
                # Some tests failed: "✘ Test run with X tests failed after Y seconds with Z issues."
                failed=$(echo "$swift_test_summary" | grep -o 'with [0-9]\+ issue' | grep -o '[0-9]\+')
                if [ -z "$failed" ] || ! [[ "$failed" =~ ^[0-9]+$ ]]; then
                    # Fallback: count failed test lines
                    failed=$(echo "$output" | grep -c "✗ Test.*failed\|✘ Test.*failed" 2>/dev/null || echo "1")
                fi
            else
                failed="0"
            fi
        else
            # No summary found, count individual results
            failed=$(echo "$output" | grep -c "✗ Test.*failed\|✘ Test.*failed" 2>/dev/null || echo "0")
        fi
        
        filtered_output=$(echo "$output" | grep -E "(✔ Test.*passed|✗ Test.*failed|✘ Test.*failed|◇ Test.*started)")
    else
        # XCTest format (legacy)
        filtered_output=$(echo "$output" | grep -E "(Test Case|Test Suite.*failed|Test Suite.*passed)")
        passed=$(echo "$filtered_output" | grep -c "Test Case.*passed" 2>/dev/null || echo "0")
        failed=$(echo "$filtered_output" | grep -c "Test Case.*failed" 2>/dev/null || echo "0")
    fi
    
    # Clean up counts (remove any whitespace)
    passed=$(echo "$passed" | tr -d ' \t\n\r')
    failed=$(echo "$failed" | tr -d ' \t\n\r')
    
    # Calculate total safely
    if [[ "$passed" =~ ^[0-9]+$ ]] && [[ "$failed" =~ ^[0-9]+$ ]]; then
        total=$((passed + failed))
    else
        echo "⚠️ $name: Failed to parse test results"
        echo ""
        echo "🔍 Debug Output (last 10 lines):"
        echo "$output" | tail -10 | sed 's/^/   /'
        return 1
    fi
    
    # Display summary
    if [ "$failed" -eq 0 ] && [ "$total" -gt 0 ]; then
        echo "✅ $name: $total tests - $passed passed, $failed failed"
        return 0
    elif [ "$total" -eq 0 ]; then
        echo "⚠️ $name: No tests found or build failed"
        if [ "$exit_code" -ne 0 ]; then
            echo ""
            echo "🔍 Debug Information:"
            echo "$output" | grep -E "Testing failed|BUILD FAILED|No tests|error:|fatal error:" | head -10 | sed 's/^/   /'
            echo ""
            echo "🔍 Full Build Output (last 30 lines):"
            echo "$output" | tail -30 | sed 's/^/   /'
        fi
        return 1
    else
        echo "❌ $name: $total tests - $passed passed, $failed failed"
        echo ""
        
        # Handle Swift Testing format failures
        if echo "$output" | grep -q "✗.*failed\|✘.*failed\|Failing tests:"; then
            echo "   Failed tests:"
            # Check if we have individual test failures in the filtered output
            if echo "$filtered_output" | grep -q "✗.*failed\|✘.*failed"; then
                echo "$filtered_output" | grep -E "✗.*failed|✘.*failed" | sed 's/^/   - /'
            fi
            # Also check for the "Failing tests:" section which lists failed test names
            if echo "$output" | grep -q "Failing tests:"; then
                echo "$output" | sed -n '/Failing tests:/,/^$/p' | grep -E "^\s*[A-Za-z].*\(\)" | sed 's/^/   - /'
            fi
            echo ""
            echo "   Detailed Failures:"
            
            # Extract failing test names from both output formats
            if echo "$output" | grep -q "Failing tests:"; then
                # Get test names from "Failing tests:" section - this is the most reliable
                failed_tests=$(echo "$output" | sed -n '/Failing tests:/,/^$/p' | grep -E "^\s*[A-Za-z].*\(\)" | sed 's/^\s*//' | sed 's/()$//')
            else
                # Extract from individual test failure lines
                failed_tests=$(echo "$filtered_output" | grep -E "✗.*failed|✘.*failed" | sed 's/.*Test "//' | sed 's/" failed.*//')
            fi
        else
            # Handle XCTest format failures (legacy)
            echo "   Failed tests:"
            echo "$filtered_output" | grep "Test Case.*failed" | sed 's/.*Test Case /   - /' | sed 's/ failed.*//' | sed "s/'//g"
            echo ""
            echo "   Detailed Failures:"
            
            # Extract detailed failure information with better pattern matching
            failed_tests=$(echo "$filtered_output" | grep "Test Case.*failed" | sed 's/.*Test Case //' | sed 's/ failed.*//' | sed "s/'//g")
        fi
        
        # Extract .xcresult path for detailed failure information
        xcresult_path=$(echo "$output" | grep -o '/.*\.xcresult' | tail -1)
        
        while IFS= read -r test_name; do
            if [ -n "$test_name" ]; then
                echo "   📍 $test_name:"
                
                # Use the enhanced failure extraction function
                failure_details=$(extract_test_failure_details "$test_name" "$output" "$xcresult_path")
                
                # Display failure details with better formatting
                if [ -n "$failure_details" ]; then
                    echo "$failure_details" | while IFS= read -r error_line; do
                        if [ -n "$error_line" ]; then
                            # Clean up the error message
                            clean_line=$(echo "$error_line" | sed 's/^[0-9-]* [0-9:]* *[+-][0-9]* //' | sed 's/\[.*\] //' | sed 's/❌ //')
                            
                            # Try to extract file information if present
                            file_info=$(echo "$error_line" | grep -o '[^/]*\.swift:[0-9]*')
                            
                            if [ -n "$file_info" ]; then
                                echo "      ❌ $clean_line ($file_info)"
                            else
                                echo "      ❌ $clean_line"
                            fi
                        fi
                    done
                else
                    echo "      ❌ Test failed - run with --verbose or check:"
                    echo "         xcodebuild test -only-testing:\"$test_name\" -enableCodeCoverage NO"
                fi
                echo ""
            fi
        done <<< "$failed_tests"
        
        return 1
    fi
}


# Parse arguments
test_type="${1:-all}"
USE_CACHE="${2:-false}"
VERBOSE="${3:-false}"
overall_failures=0

# Check for --verbose flag in any position
for arg in "$@"; do
    if [ "$arg" = "--verbose" ] || [ "$arg" = "-v" ]; then
        VERBOSE="true"
        break
    fi
done

# Show usage if requested
if [ "$test_type" = "--help" ] || [ "$test_type" = "-h" ]; then
    echo "Usage: $0 [test_type] [use_cache] [--verbose|-v]"
    echo "  test_type: unit, ui, or all (default: all)"
    echo "  use_cache: true to use cached output for debugging (default: false)"
    echo "  --verbose: show detailed failure output and debug information"
    echo ""
    echo "Examples:"
    echo "  $0 unit                    # Run unit tests"
    echo "  $0 unit true               # Use cached unit test output"
    echo "  $0 all false --verbose     # Run all tests with detailed failure info"
    echo "  $0 --verbose unit          # Run unit tests with verbose output"
    exit 0
fi

case "$test_type" in
    "unit")
        run_tests "magical-storiesTests" "Unit Tests" || overall_failures=1
        ;;
    "ui")
        echo "⚠️ No UI test target found in this project"
        echo "   Available test targets: magical-storiesTests"
        ;;
    "all"|*)
        run_tests "magical-storiesTests" "Unit Tests" || overall_failures=1
        echo ""
        echo "ℹ️ Note: No UI test target configured in this project"
        ;;
esac

echo ""
echo "=================="
if [ $overall_failures -eq 0 ]; then
    echo "🎉 All tests passed!"
else
    echo "💥 Some tests failed!"
fi
echo "=================="

exit $overall_failures