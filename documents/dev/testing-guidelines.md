# Testing Guidelines

## Framework Choice

We use **Swift Testing framework** for all new tests. This provides:
- Modern, declarative syntax
- Built-in async/await support
- Parameterized testing
- Test organization with tags and traits

## Test Categories

### 1. Unit Tests
Location: `magical-storiesTests/`
*   Focus: Test individual functions, methods, or small components in isolation.
*   Dependencies: **Must** be mocked.
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
Location: `magical-storiesTests/` (often tagged `.integration`)
*   Focus: Test the interaction between multiple components or layers (e.g., Service -> Repository).
*   Dependencies: May use mocks for external systems (like network APIs) but test the integration between internal components. See also "Swift Integration Testing Guidelines" in `memory_bank/techContext.md` for tests involving live external services (run selectively).
```swift
@Test("Story persistence flow", .tags(.integration, .persistence))
func testStoryPersistence() async throws {
    // Arrange: Use mock storage or real in-memory implementation for testing
    let mockStorage = MockStoryStorage() // Assuming a mock exists
    let story = Story(title: "New Story")

    // Act
    try await mockStorage.save(story)
    let retrieved = try #require(await mockStorage.fetch(id: story.id))

    // Assert
    #expect(retrieved.title == story.title)
}
```

### 3. UI Tests
Location: `magical-storiesUITests/` (Uses XCTest currently)
*   Focus: Test user flows and interactions through the application's UI.
*   Dependencies: Interacts with the live app UI.
```swift
// Example using XCTest syntax
func testStoryCreationFlow() throws {
    let app = XCUIApplication()
    app.launch()

    app.buttons["Create Story"].tap()
    app.textFields["Title"].typeText("New Adventure")
    app.buttons["Save"].tap()

    XCTAssertTrue(app.staticTexts["New Adventure"].exists)
}
```

### 4. SwiftUI View Tests
Location: `magical-storiesTests/Views/`
*   Focus: Test the state logic, layout (using Mirror or View Inspection libraries), and behavior of individual SwiftUI views.
*   Dependencies: Inject mock services/repositories or use preview data.
```swift
@Test("StoryView displays title")
func testStoryViewDisplaysTitle() async throws {
    // Arrange
    let story = Story(title: "Test Story")
    // Inject mock environment objects if needed
    let view = await StoryView(story: story)
           // .environmentObject(MockSomeService())

    // Act & Assert (Using View Inspection or Mirror)
    // Example using hypothetical inspection library:
    // try await #expect(view.inspect().find(text: "Test Story").exists())

    // Example using Mirror (less robust for complex views):
    let mirror = Mirror(reflecting: view.body)
    // Simplified check - real checks would be more specific
    await #expect(mirror.children.count > 0)
}
```
For detailed SwiftUI testing patterns and best practices, see [SwiftUI Testing Patterns](./swiftui-testing-patterns.md).

## Test Organization

### Tagging System
Use tags extensively to categorize tests by feature, type, priority, etc.
```swift
// Feature tags
@Test("Story creation", .tags(.story, .creation))
@Test("User profile", .tags(.user, .profile))

// Test type tags
@Test("API integration", .tags(.integration, .api)) // For specific API integration points
@Test("Persistence logic", .tags(.unit, .persistence))

// Priority tags
@Test("Critical path", .tags(.critical))
@Test("Regression test", .tags(.regression))
```

### Conditional Testing
Enable/disable tests based on platform, feature flags, or environment variables.
```swift
// Platform-specific tests
@Test("iOS-specific feature",
      .enabled(if: Platform.current == .iOS))

// Feature flag tests
@Test("New feature test",
      .enabled(if: FeatureFlags.newFeatureEnabled))

// Skip integration tests locally if needed
@Test("Live API Call", .tags(.integration, .api),
      .disabled(if: Environment.isRunningLocally && !Environment.forceRunIntegrationTests, "Skipping live API test locally"))
```

## Testing Best Practices

### 1. Test Structure
- Follow **Arrange-Act-Assert** pattern clearly.
- Keep tests focused on a single behavior or scenario.
- Use descriptive test names.
- Use meaningful and realistic test data.
- Consider TDD workflow (Red-Green-Refactor).

### 2. Mocking & Dependency Injection
- **Protocol-Based Design:** Define protocols for services, repositories, and other dependencies (e.g., `StoryRepositoryProtocol`, `IllustrationServiceProtocol`).
- **Mock Implementations:** Create mock classes/structs conforming to these protocols. Mocks should allow setting expected return values/errors and verifying method calls.
- **Injection:** Inject mocks into the System Under Test (SUT) during the "Arrange" phase. Use initializer injection preferably, or environment objects for SwiftUI views.
- **Goal:** Isolate the SUT from its dependencies, ensuring unit tests are fast, reliable, and don't rely on external systems (network, filesystem, database).
```swift
// Example Mock
struct MockIllustrationService: IllustrationServiceProtocol {
    var mockResult: Result<URL, Error>?

    func generateIllustration(prompt: String) async throws -> URL {
        switch mockResult {
        case .success(let url): return url
        case .failure(let error): throw error
        case .none: throw TestError.mockNotConfigured
        }
    }
}

@Test("StoryProcessor uses IllustrationService")
func testStoryProcessingWithIllustration() async throws {
    // Arrange
    let mockIllustrator = MockIllustrationService()
    mockIllustrator.mockResult = .success(URL(string: "http://example.com/image.png")!)
    let processor = StoryProcessor(illustrationService: mockIllustrator) // Inject mock
    let storyParams = // ... setup params ...

    // Act
    let story = try await processor.createStory(parameters: storyParams)

    // Assert
    #expect(story.pages.first?.illustrationURL != nil)
    // Further assertions on mock interactions if needed
}
```

### 3. Async Testing
Use `async throws` for test functions involving asynchronous operations. Use `await` for calling async functions.
```swift
@Test("Async data loading")
func testDataLoading() async throws {
    // Arrange
    let loader = DataLoader() // Assume DataLoader is testable or uses mock dependencies

    // Act
    let data = try await loader.fetchData()

    // Assert
    #expect(data != nil)
}
```

### 4. Error Testing
Test that expected errors are thrown under specific conditions. Use `AssertThrowsError` or `do-catch` with `#expect` inside the `catch` block.
```swift
@Test("Handle network error")
func testNetworkError() async {
    // Arrange
    let client = MockNetworkClient() // Mock client configured to throw
    client.shouldThrow = NetworkError.invalidResponse

    // Act & Assert
    await #expect(throws: NetworkError.invalidResponse) {
        _ = try await client.fetchData()
    }

    // Alternative using do-catch
    // do {
    //     _ = try await client.fetchData()
    //     #expect(Bool(false), "Expected error not thrown") // Fail if no error
    // } catch let error as NetworkError {
    //     #expect(error == .invalidResponse) // Verify specific error
    // } catch {
    //     #expect(Bool(false), "Unexpected error type thrown: \(error)")
    // }
}
```

### 5. Parameterized Testing
Use `arguments:` within `@Test` to run the same test logic with different inputs and expected outputs.
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
2. Through Xcode: ⌘U (all), ⌘⌥U (current file), Test Navigator play button.

### CI/CD Integration
- Tests run automatically on pull requests via GitHub Actions (or similar).
- Code coverage reports are generated and potentially checked against thresholds.
- Test results are published for visibility.

## Test Maintenance

### 1. Regular Review
- Monitor test coverage reports.
- Update tests alongside feature changes or refactoring.
- Remove obsolete tests.
- Refactor tests for clarity and performance.

### 2. Test Debugging
- Use breakpoints within test code.
- Inspect test logs (`print`, `Issue.record`) in Xcode's Test Report.
- Review failure screenshots/videos for UI tests.

## Resources

- [Swift Testing Documentation](https://developer.apple.com/xcode/swift-testing/)
- [TDD Guidelines](./tdd-guidelines.md)
- [SwiftUI Testing Patterns](./swiftui-testing-patterns.md)
- Project test examples in source code (`magical-storiesTests/`)
