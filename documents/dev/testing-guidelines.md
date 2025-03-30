# Testing Guidelines

## Framework Choice

We use Swift Testing framework for all new tests. This provides:
- Modern, declarative syntax
- Built-in async/await support
- Parameterized testing
- Test organization with tags and traits

## Test Categories

### 1. Unit Tests
Location: `magical-storiesTests/`
```swift
@Test("Story model validates title length")
func testStoryTitleValidation() {
    let story = Story(title: "")
    #expect(!story.isValid)
    
    let validStory = Story(title: "Valid Title")
    #expect(validStory.isValid)
}
```

### 2. Integration Tests
Location: `magical-storiesTests/Integration/`
```swift
@Test("Story persistence flow")
func testStoryPersistence() async throws {
    let storage = StoryStorage()
    let story = Story(title: "New Story")
    
    try await storage.save(story)
    let retrieved = try #require(await storage.fetch(id: story.id))
    #expect(retrieved.title == story.title)
}
```

### 3. UI Tests
Location: `magical-storiesUITests/`
```swift
@Test("Story creation flow")
func testStoryCreation() {
    let app = Application()
    app.launch()
    
    app.buttons["Create Story"].tap()
    app.textFields["Title"].typeText("New Adventure")
    app.buttons["Save"].tap()
    
    #expect(app.staticTexts["New Adventure"].exists)
}
```

### 4. SwiftUI View Tests
Location: `magical-storiesTests/Views/`
```swift
@Test("StoryView layout")
func testStoryViewLayout() async throws {
    let story = Story(title: "Test Story")
    let view = await StoryView(story: story)
    
    // Use Mirror reflection for view inspection
    let mirror = Mirror(reflecting: view.body)
    await #expect(mirror.descendant("title") != nil)
    await #expect(mirror.descendant("content") is VStack<TupleView>)
}
```

For detailed SwiftUI testing patterns and best practices, see [SwiftUI Testing Patterns](./swiftui-testing-patterns.md).

## Test Organization

### Tagging System
```swift
// Feature tags
@Test("Story creation", .tags(.story, .creation))
@Test("User profile", .tags(.user, .profile))

// Test type tags
@Test("API integration", .tags(.integration, .api))
@Test("Performance test", .tags(.performance))

// Priority tags
@Test("Critical path", .tags(.critical))
@Test("Regression test", .tags(.regression))
```

### Conditional Testing
```swift
// Platform-specific tests
@Test("iOS-specific feature",
      .enabled(if: Platform.current == .iOS))

// Feature flag tests
@Test("New feature test",
      .enabled(if: FeatureFlags.newFeatureEnabled))
```

## Testing Best Practices

### 1. Test Structure
- Follow Arrange-Act-Assert pattern
- Keep tests focused and concise
- Use meaningful test data
- Follow TDD workflow (Red-Green-Refactor)

### 2. Async Testing
```swift
@Test("Async data loading")
func testDataLoading() async throws {
    // Setup
    let loader = DataLoader()
    
    // Exercise
    let data = try await loader.fetchData()
    
    // Assert
    #expect(data != nil)
}
```

### 3. Error Testing
```swift
@Test("Handle network error")
func testNetworkError() async {
    do {
        let client = NetworkClient()
        _ = try await client.fetchInvalidURL()
        #expect(false, "Expected error not thrown")
    } catch {
        #expect(error is NetworkError)
    }
}
```

### 4. Parameterized Testing
```swift
@Test("Input validation",
      arguments: [
        (input: "", expected: false),
        (input: "   ", expected: false),
        (input: "valid", expected: true),
        (input: "too-long-input-string", expected: false)
      ])
func testInputValidation(input: String, expected: Bool) {
    let validator = InputValidator()
    #expect(validator.isValid(input) == expected)
}
```

## Test Execution

### Running Tests
1. Use the provided script:
```bash
./run_tests.sh
```

2. Through Xcode:
- ⌘U to run all tests
- ⌘⌥U to test current file
- Click play button in test navigator

### CI/CD Integration
- Tests run automatically on pull requests
- Code coverage reports generated
- Test results published to team dashboard

## Test Maintenance

### 1. Regular Review
- Review test coverage reports
- Update tests for new features
- Remove obsolete tests
- Improve test performance

### 2. Test Debugging
- Use breakpoints in tests
- Check test logs in TestResults.xcresult
- Review failure screenshots for UI tests

## Resources

- [Swift Testing Documentation](https://developer.apple.com/xcode/swift-testing/)
- [TDD Guidelines](./tdd-guidelines.md)
- [SwiftUI Testing Patterns](./swiftui-testing-patterns.md)
- Project test examples in source code
