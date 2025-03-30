# SwiftUI Testing Patterns

This guide outlines best practices and patterns for testing SwiftUI views using the Swift Testing framework.

## View Testing Fundamentals

### 1. Basic Structure Testing

```swift
@Test("View hierarchy validation")
func testViewStructure() async throws {
    let view = await MyView()
    await #expect(Mirror(reflecting: view.body).descendant("content") is VStack<TupleView>)
}
```

Key points:
- Always use async context for view creation
- Use Mirror reflection to inspect view hierarchy
- Verify presence and type of key view components
- Test the basic structure before complex interactions

### 2. State Management Testing

```swift
@Test("View state updates")
func testStateChanges() async throws {
    // Initial state
    let view = await MyView()
    await #expect(view.initialState == expectedValue)
    
    // State transition
    await view.updateState()
    await #expect(view.currentState == newExpectedValue)
}
```

Best practices:
- Test initial state values
- Verify state transitions
- Test side effects of state changes
- Consider async state updates

### 3. User Interaction Testing

```swift
@Test("Button action triggers state change")
func testButtonAction() async throws {
    let view = await MyView()
    let initialState = await view.someState
    
    await view.button.tap()
    
    // Verify state changed after interaction
    await #expect(view.someState != initialState)
}
```

Guidelines:
- Test user input handling
- Verify UI updates in response to actions
- Test gesture recognizers when used
- Validate accessibility actions

## Common Testing Patterns

### 1. View Hierarchy Inspection

```swift
@Test("Complex view hierarchy")
func testViewHierarchy() async throws {
    let view = await ComplexView()
    let mirror = Mirror(reflecting: view.body)
    
    // Navigate view hierarchy
    await #expect(mirror.descendant("content", "header") is HeaderView)
    await #expect(mirror.descendant("content", "list") is ListView)
}
```

### 2. Conditional View Content

```swift
@Test("Conditional view content")
func testConditionalContent() async throws {
    let view = await ContentView(showDetail: true)
    await #expect(Mirror(reflecting: view.body).descendant("detail") != nil)
    
    let hideView = await ContentView(showDetail: false)
    await #expect(Mirror(reflecting: hideView.body).descendant("detail") == nil)
}
```

### 3. Dynamic List Content

```swift
@Test("List view content")
func testListContent() async throws {
    let items = ["Item 1", "Item 2"]
    let view = await ListView(items: items)
    
    let mirror = Mirror(reflecting: view.body)
    await #expect(mirror.descendant("content") is List<String, Text>)
}
```

## Best Practices

1. View Creation
   - Always create views in async context
   - Initialize with minimal required dependencies
   - Use preview data when appropriate
   - Clean up resources in tearDown if needed

2. View Inspection
   - Use Mirror for structural validation
   - Check for presence of key components
   - Verify view hierarchy relationships
   - Test view modifiers when critical

3. State Verification
   - Test initial state
   - Verify state transitions
   - Validate side effects
   - Handle async state updates properly

4. Test Organization
   - Group related tests together
   - Test basic functionality first
   - Progress to complex interactions
   - Include error cases and edge conditions

## Common Pitfalls

1. Async Context
   ```swift
   // Incorrect ❌
   let view = MyView()
   
   // Correct ✅
   let view = await MyView()
   ```

2. Mirror Reflection
   ```swift
   // Incorrect ❌
   #expect(view.somePrivateProperty == value)
   
   // Correct ✅
   #expect(Mirror(reflecting: view.body).descendant("content") != nil)
   ```

3. State Updates
   ```swift
   // Incorrect ❌
   view.updateState()
   #expect(view.state == newValue)
   
   // Correct ✅
   await view.updateState()
   await #expect(view.state == newValue)
   ```

## Integration with TDD Workflow

1. Red Phase
   ```swift
   @Test("New feature requirement")
   func testNewFeature() async throws {
       let view = await FeatureView()
       await #expect(view.hasNewFeature) // Initially fails
   }
   ```

2. Green Phase
   - Implement minimal view code
   - Add required properties and methods
   - Make test pass with basic implementation

3. Refactor Phase
   - Improve view structure
   - Extract reusable components
   - Optimize state management
   - Maintain passing tests

## Resources

- [Swift Testing Documentation](https://developer.apple.com/xcode/swift-testing/)
- [TDD Guidelines](./tdd-guidelines.md)
- Project test examples in `magical-storiesTests/Views/`
