# Swift Coding Standards

## Overview
This document outlines coding standards and best practices for the Magical Stories app development team.

## Code Organization

### File Structure
```swift
// Standard file header
//
// FileName.swift
// Magical Stories
//
// Created by [Author Name] on [Date].
// Copyright © 2025 Magical Stories. All rights reserved.

import SwiftUI
import Combine
// Other imports...

// MARK: - Types
// MARK: - Constants
// MARK: - Properties
// MARK: - Lifecycle
// MARK: - Public Methods
// MARK: - Private Methods
```

### Directory Structure
```
MagicalStories/
├── App/
│   └── MagicalStoriesApp.swift
├── Features/
│   ├── Story/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Models/
│   └── Settings/
│       ├── Views/
│       ├── ViewModels/
│       └── Models/
├── Core/
│   ├── Services/
│   ├── Repositories/
│   └── Utilities/
└── Resources/
    ├── Assets.xcassets/
    └── Localizable.strings
```

## Naming Conventions

### General Guidelines
```swift
// Types: UpperCamelCase
struct StoryGenerator {}
class UserProfile {}
enum StoryTheme {}
protocol StoryGenerating {}

// Variables and functions: lowerCamelCase
var userName: String
func generateStory() {}

// Constants
let maximumStoryLength = 1000
static let defaultTheme = "adventure"

// Boolean variables should read as assertions
var isLoading: Bool
var hasContent: Bool
var shouldRefresh: Bool
```

### SwiftUI View Naming
```swift
// Main view
struct StoryView: View {
    var body: some View {
        // Content
    }
}

// Supporting views
struct StoryHeaderView: View {}
struct StoryContentView: View {}
struct StoryFooterView: View {}

// View modifiers
struct CardStyleModifier: ViewModifier {}
```

## Documentation

### Swift Documentation Style
```swift
/// Generates a personalized story based on given parameters.
/// 
/// This method uses AI to create a unique story tailored to the child's
/// preferences and age group.
///
/// ```swift
/// let story = try await generateStory(
///     theme: "adventure",
///     ageGroup: .preschool
/// )
/// ```
///
/// - Parameters:
///   - theme: The story theme (e.g., "adventure", "friendship")
///   - ageGroup: Target age group for the story
///   - childName: Optional name to personalize the story
///
/// - Returns: A generated story object
/// - Throws: `StoryError` if generation fails
func generateStory(
    theme: String,
    ageGroup: AgeGroup,
    childName: String? = nil
) async throws -> Story
```

### SwiftUI View Documentation
```swift
/// A view that displays a story card with preview content.
///
/// Story cards are used in the library view to show a brief preview
/// of each story. They support tapping to read the full story and
/// favorite/share actions.
struct StoryCard: View {
    /// The story to display
    let story: Story
    
    /// Whether the card is currently selected
    @State private var isSelected = false
    
    /// The action to perform when the card is tapped
    var onTap: () -> Void
}
```

## SwiftUI Best Practices

### View Organization
```swift
struct ContentView: View {
    // MARK: - Properties
    @StateObject private var viewModel: ContentViewModel
    @State private var isLoading = false
    
    // MARK: - View Components
    var body: some View {
        mainContent
    }
    
    private var mainContent: some View {
        VStack {
            header
            content
            footer
        }
    }
    
    private var header: some View {
        HeaderView()
    }
    
    // Additional view components...
}
```

### State Management
```swift
class StoryViewModel: ObservableObject {
    // Published properties
    @Published private(set) var stories: [Story] = []
    @Published private(set) var isLoading = false
    @Published var selectedTheme: String = ""
    
    // Dependencies
    private let storyService: StoryService
    
    // Intent methods
    func loadStories() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            stories = try await storyService.fetchStories()
        } catch {
            // Handle error
        }
    }
}
```

## Error Handling

### Error Types
```swift
enum StoryError: LocalizedError {
    case generationFailed
    case invalidParameters(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .generationFailed:
            return "Failed to generate story"
        case .invalidParameters(let param):
            return "Invalid parameter: \(param)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
```

### Error Handling Pattern
```swift
func handleError(_ error: Error) {
    switch error {
    case let storyError as StoryError:
        handleStoryError(storyError)
    case let networkError as URLError:
        handleNetworkError(networkError)
    default:
        handleUnexpectedError(error)
    }
}

private func handleStoryError(_ error: StoryError) {
    // Log error
    Logger.error("Story generation error: \(error)")
    
    // Show user-friendly message
    alertMessage = error.errorDescription ?? "Unknown error"
}
```

## Testing Standards

### Unit Test Structure
```swift
class StoryViewModelTests: XCTestCase {
    // MARK: - Properties
    private var sut: StoryViewModel!
    private var mockService: MockStoryService!
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        mockService = MockStoryService()
        sut = StoryViewModel(service: mockService)
    }
    
    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func test_loadStories_whenSuccessful_updatesStories() async {
        // Given
        let expectedStories = [Story.mock()]
        mockService.stories = expectedStories
        
        // When
        await sut.loadStories()
        
        // Then
        XCTAssertEqual(sut.stories, expectedStories)
        XCTAssertFalse(sut.isLoading)
    }
}
```

### Mock Objects
```swift
class MockStoryService: StoryServicing {
    var stories: [Story] = []
    var error: Error?
    
    func fetchStories() async throws -> [Story] {
        if let error = error {
            throw error
        }
        return stories
    }
}
```

## Performance Guidelines

### Memory Management
```swift
// Prefer structs over classes when possible
struct StoryParameters {
    let theme: String
    let ageGroup: AgeGroup
    let childName: String?
}

// Use weak references in closures
class StoryViewController {
    private func setupBindings() {
        button.tap
            .sink { [weak self] in
                self?.handleTap()
            }
            .store(in: &cancellables)
    }
}
```

### Async/Await Best Practices
```swift
// Prefer async/await over completion handlers
func generateStory() async throws -> Story {
    // Async implementation
}

// Use Task groups for concurrent operations
func generateMultipleStories(themes: [String]) async throws -> [Story] {
    try await withThrowingTaskGroup(of: Story.self) { group in
        for theme in themes {
            group.addTask {
                try await generateStory(theme: theme)
            }
        }
        
        var stories: [Story] = []
        for try await story in group {
            stories.append(story)
        }
        return stories
    }
}
```

## Git Guidelines

### Commit Messages
```
feat: Add story generation feature
^--^  ^------------------------^
|     |
|     +-> Summary in present tense
|
+-------> Type: feat, fix, docs, style, refactor, test, chore
```

### Branch Naming
```
feature/story-generation
bugfix/memory-leak
refactor/view-model
docs/readme-update
```

## SwiftLint Rules
```yaml
# .swiftlint.yml
disabled_rules:
  - line_length
  - trailing_whitespace
  
opt_in_rules:
  - empty_count
  - missing_docs
  
included:
  - MagicalStories
  
excluded:
  - Pods
  - MagicalStoriesTests

line_length:
  warning: 120
  error: 200
```

## Best Practices

1. **Code Organization**
   - Follow consistent file structure
   - Group related functionality
   - Use clear naming conventions
   - Document public interfaces

2. **SwiftUI**
   - Keep views focused and small
   - Extract reusable components
   - Use proper state management
   - Follow view hierarchy guidelines

3. **Testing**
   - Write unit tests
   - Use clear test names
   - Follow Given-When-Then
   - Mock dependencies

4. **Performance**
   - Monitor memory usage
   - Use value types
   - Implement proper caching
   - Profile regularly

5. **Git**
   - Write clear commits
   - Use feature branches
   - Review before merging
   - Keep branches updated

## Review Checklist

- [ ] Follows naming conventions
- [ ] Properly documented
- [ ] Tests included
- [ ] Error handling implemented
- [ ] Memory management considered
- [ ] SwiftLint passing
- [ ] Documentation updated
- [ ] Performance impact considered
- [ ] Security reviewed
- [ ] Accessibility implemented

---

This document should be updated when:
- New coding patterns emerge
- Best practices change
- Team agreements update
- Tools or processes change
