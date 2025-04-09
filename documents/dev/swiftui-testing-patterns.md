# SwiftUI Testing Patterns

This guide outlines best practices and patterns for testing SwiftUI views using the Swift Testing framework.

## View Testing Fundamentals

### 1. Basic Structure Testing
Test the presence and type of key UI elements within the view's body.
```swift
@Test("View hierarchy validation")
func testViewStructure() async throws {
    let view = await MyView()
    // Use Mirror or a View Inspection library
    await #expect(Mirror(reflecting: view.body).descendant("titleLabel") is Text)
}
```
*Key points:* Use `async` context, inspect hierarchy, verify key components.

### 2. State Management Testing
Test how the view responds to changes in its local `@State` or `@StateObject`.
```swift
@Test("View state updates")
func testStateChanges() async throws {
    // Arrange
    let view = await CounterView()
    await #expect(view.count == 0)

    // Act
    await view.increment() // Assume increment modifies internal @State

    // Assert
    await #expect(view.count == 1)
}
```
*Best practices:* Test initial state, verify transitions, test side effects.

### 3. User Interaction Testing
Simulate user actions (taps, gestures) and verify the resulting state changes or UI updates. (Note: Direct simulation like `.tap()` might require specific testing libraries or UI testing).
```swift
// Conceptual Example - Actual implementation depends on testing library/approach
@Test("Button action triggers state change")
func testButtonAction() async throws {
    let view = await MyViewWithButton()
    let initialState = await view.someState

    // Act: Simulate button tap (method depends on test setup)
    await view.performButtonAction() // Or simulate tap if possible

    // Assert
    await #expect(view.someState != initialState)
}
```
*Guidelines:* Test input handling, UI updates, gestures, accessibility actions.

## Testing Views with Dependencies

SwiftUI views often rely on external data or services (e.g., fetching stories, checking settings). Tests should isolate the view's logic from the dependency's logic using **mocking**.

### 1. Dependency Injection Patterns
Views receive dependencies primarily through:
*   **Initializer Injection:** Passing dependencies directly during view creation.
    ```swift
    struct StoryDetailView: View {
        let story: Story
        let analytics: AnalyticsServiceProtocol // Injected dependency

        init(story: Story, analytics: AnalyticsServiceProtocol = RealAnalyticsService()) {
            self.story = story
            self.analytics = analytics
        }
        // ... body ...
    }
    ```
*   **Environment Objects:** Injecting shared dependencies using `.environmentObject()`.
    ```swift
    struct SettingsView: View {
        @EnvironmentObject var settingsService: SettingsServiceProtocol
        // ... body ...
    }

    // In Test Setup or Preview:
    SettingsView()
        .environmentObject(MockSettingsService())
    ```

### 2. Injecting Mocks in Tests
During the "Arrange" phase of your test, provide mock implementations of the view's dependencies.

```swift
// Define Mock Service (conforming to the protocol)
struct MockSettingsService: SettingsServiceProtocol {
    var expectedValue: Bool = false
    func getSomeSetting() -> Bool { return expectedValue }
    // Implement other required methods...
}

@Test("SettingsView displays correct toggle state")
func testSettingsToggleState() async throws {
    // Arrange
    let mockService = MockSettingsService()
    mockService.expectedValue = true // Configure mock

    let view = SettingsView()
        .environmentObject(mockService) // Inject mock via environment

    // Act & Assert (using View Inspection or Mirror)
    // Example: Check if a Toggle reflects the mockService.expectedValue
    // await #expect(view.inspect().find(Toggle.self).isOn() == true)
}

@Test("StoryDetailView logs view event")
func testStoryDetailAnalytics() async throws {
    // Arrange
    let mockAnalytics = MockAnalyticsService() // Conforms to AnalyticsServiceProtocol
    let story = Story(title: "Test")
    let view = await StoryDetailView(story: story, analytics: mockAnalytics) // Inject mock via initializer

    // Act: Trigger the view's onAppear or relevant action
    await view.performAppearAction() // Hypothetical method triggering analytics

    // Assert: Verify the mock service was called
    #expect(mockAnalytics.logEventCalled == true)
    #expect(mockAnalytics.lastEventName == "storyViewed")
}
```
*Key points:* Use protocols, create mocks, inject mocks via initializer or environment, assert view behavior based on mock state/output, verify mock interactions.

## Common Testing Patterns

### 1. View Hierarchy Inspection (Mirror/Inspection Libs)
Verify the structure and types of views within the body.
```swift
@Test("Complex view hierarchy")
func testViewHierarchy() async throws {
    let view = await ComplexView()
    // Use Mirror or View Inspection library
    // await #expect(view.inspect().find(HeaderView.self).exists())
}
```

### 2. Conditional View Content
Test that views appear/disappear based on state.
```swift
@Test("Conditional view content")
func testConditionalContent() async throws {
    // Arrange
    let viewShowingDetail = await ContentView(showDetail: true)
    let viewHidingDetail = await ContentView(showDetail: false)

    // Assert
    // await #expect(viewShowingDetail.inspect().find(DetailView.self).exists())
    // await #expect(viewHidingDetail.inspect().find(DetailView.self).doesNotExist())
}
```

### 3. Dynamic List Content
Test lists render correctly based on input data.
```swift
@Test("List view content count")
func testListContent() async throws {
    // Arrange
    let items = ["Item 1", "Item 2"]
    let view = await ListView(items: items)

    // Assert
    // await #expect(view.inspect().findAll(Text.self).count == 2)
}
```

## Best Practices

1.  **View Creation:** Use `async` context, initialize with minimal dependencies (mocks preferred), use preview data where suitable.
2.  **View Inspection:** Use Mirror or dedicated libraries for structural validation. Check key components and modifiers.
3.  **State Verification:** Test initial state, transitions, and side effects, handling async updates.
4.  **Dependency Handling:** **Inject mock dependencies** to isolate the view. Test the view's reaction *to* the mock.
5.  **Test Organization:** Group related tests, test basic structure first, then interactions and edge cases.

## Common Pitfalls

1.  **Missing `async`/`await`:** View creation and state updates often require `await`.
2.  **Testing Implementation Details:** Avoid testing private properties directly. Focus on the view's observable behavior and structure. Use Mirror/Inspection carefully.
3.  **Not Mocking Dependencies:** Testing views with real services leads to slow, brittle tests dependent on external factors.

## Integration with TDD Workflow

1.  **Red:** Write a failing test for the desired view behavior (e.g., showing data from a mock service).
2.  **Green:** Implement the minimal view code and inject the mock to make the test pass.
3.  **Refactor:** Improve view structure, extract components, optimize state management, ensuring tests remain green.

## Resources

- [Swift Testing Documentation](https://developer.apple.com/xcode/swift-testing/)
- [Testing Guidelines](./testing-guidelines.md) (Includes mocking details)
- Project test examples in `magical-storiesTests/Views/`
