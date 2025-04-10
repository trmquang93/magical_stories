# Swift Testing Framework Guide

## Overview
Swift Testing is Apple's modern testing framework introduced in Xcode 16 (June 2024). It offers expressive APIs, cross-platform support, and seamless integration with Swift's language features.

## Writing Tests

### Basic Test Structure
```swift
import Testing
@testable import MyApp

#Test("Test name describing what you're testing")
func testExample() {
    // Test code here
    #expect(actualValue == expectedValue)
}
```

### Assertions
- `#require`: Use for preconditions that must be true for the test to continue
  ```swift
  try #require(someValue != nil)
  ```

- `#expect`: Use for validating test outcomes
  ```swift
  #expect(someValue == expectedValue)
  ```

### Parameterized Tests
```swift
#Test("Parameterized test description", arguments: [
    "value1",
    "value2",
    "value3"
])
func testWithParameters(param: String) {
    // Test code using param
    #expect(someFunction(param).isValid)
}
```

### Asynchronous Tests
```swift
#Test("Asynchronous test description")
func testAsyncOperation() async throws {
    let result = try await someAsyncFunction()
    #expect(result.isSuccessful)
}
```

### Combined Example
```swift
#Test("Verify video content", arguments: [
    "Beach Day",
    "Mountain Hike",
    "City Tour"
])
func testVideoContent(videoName: String) async throws {
    let videoLibrary = try await VideoLibrary()
    let video = try #require(await videoLibrary.video(named: videoName))
    
    #expect(video.duration > 0)
    #expect(video.resolution.width >= 1280)
    #expect(video.tags.count >= 3)
}
```

## Running Tests

run script `run_tests.sh` to run all tests in the project

## Best Practices

- Write descriptive test names that explain what's being tested
- Keep tests focused on a single aspect of functionality
- Use parameterized tests for testing multiple scenarios
- Follow the AAA pattern: Arrange, Act, Assert
- Use `#require` for setup validation, `#expect` for test assertions
- Tests should be independent and not rely on each other

## Tips

- Swift Testing can run alongside existing XCTest frameworks
- Tests run in parallel by default for better performance
- Use `.enabled(if:)` modifier for conditional test execution
- Failed tests provide detailed diagnostics with actual vs expected values
