# Test-Driven Development Guidelines with Swift Testing

## Overview

This document outlines our TDD practices using the Swift Testing framework. Follow these guidelines to ensure consistent test-driven development across the project.

## Swift Testing Key Features

1. Clear and Expressive API
   - Uses macros for declarative test syntax
   - Provides built-in assertion mechanisms
   - Supports parameterized testing
   - Native Swift Concurrency integration

2. Test Organization
   - Hierarchical test grouping
   - Tagging system for test categorization
   - Conditional test execution with traits
   - Parallel test execution by default

## TDD Workflow

### 1. Write Test First (Red Phase)
```swift
@Test("User registration validates email format")
func testEmailValidation() {
    let validator = UserValidator()
    #expect(!validator.isValidEmail("invalid-email"))
    #expect(validator.isValidEmail("user@example.com"))
}
```

Key Points:
- Write the test before implementation
- Use descriptive test names
- Make assertions using `#expect`
- Verify test fails initially

### 2. Implement Code (Green Phase)
- Write minimal code to make tests pass
- Focus on functionality, not optimization
- Run tests to verify implementation

### 3. Refactor
- Improve code structure while maintaining test passes
- Extract common setup into helper methods
- Add test tags for organization
- Consider performance optimizations

## Test Patterns

### Basic Test Structure
```swift
@Test("Feature description")
func testFeature() {
    // Setup
    let sut = SystemUnderTest()
    
    // Exercise & Assert
    #expect(sut.someMethod() == expectedResult)
}
```

### Async Testing
```swift
@Test("Async operation completes successfully")
func testAsyncOperation() async throws {
    // Setup
    let sut = SystemUnderTest()
    
    // Exercise
    let result = try await sut.asyncOperation()
    
    // Assert
    #expect(result == expectedResult)
}
```

### Parameterized Testing
```swift
@Test("Input validation",
      arguments: [
        (input: "valid@email.com", expected: true),
        (input: "invalid-email", expected: false)
      ])
func testInputValidation(input: String, expected: Bool) {
    let validator = InputValidator()
    #expect(validator.isValid(input) == expected)
}
```

### Using Test Traits
```swift
// Conditional execution
@Test("Feature only available on iOS 16+",
      .enabled(if: #available(iOS 16.0, *)))
func testNewFeature() { ... }

// Tagged tests
@Test("UI component layout",
      .tags(.ui, .regression))
func testLayout() { ... }
```

## Best Practices

1. Test Naming
   - Use descriptive names that explain the test's purpose
   - Follow format: test[Feature][Scenario][ExpectedResult]
   - Include relevant context in the test name

2. Assertions
   - Use `#expect` for standard assertions
   - Use `#require` for unwrapping optionals
   - Make one logical assertion per test
   - Provide meaningful failure messages

3. Test Organization
   - Group related tests together
   - Use tags to categorize tests
   - Keep test files focused and manageable
   - Separate unit tests from integration tests

4. Test Data
   - Use meaningful test data
   - Create helper methods for common test data setup
   - Avoid dependencies between tests
   - Clean up test data in tearDown if needed

## Running Tests

Use the provided test script:
```bash
./run_tests.sh
```

This script:
- Cleans previous test results
- Runs tests with code coverage enabled
- Formats output using xcpretty
- Generates test reports

## Code Coverage Requirements

- Aim for comprehensive test coverage
- Focus on critical path testing
- Test edge cases and error conditions
- Cover async operations thoroughly

## Migration from XCTest

When migrating existing tests:
1. Convert test classes to test functions
2. Replace XCTest assertions with `#expect`
3. Update async test methods
4. Add appropriate tags and traits
5. Verify all tests pass after migration

## Additional Resources

- [Swift Testing Documentation](https://developer.apple.com/xcode/swift-testing/)
- Project test examples in `magical-storiesTests/`
- CI/CD test configuration in project settings
