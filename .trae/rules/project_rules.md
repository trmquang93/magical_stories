## Update Rules

- Update this file when discovering new project patterns. (High)
- Update this file after significant changes. (High)
- Update this file when user requests **update memory bank** (MUST review ALL files). (High)
- Update this file when context needs clarification. (High)

---

# Project Rules

(Add other project-specific rules below)

## Project Overview
- **Type:** iOS Application (SwiftUI)
- **Purpose:** AI-powered personalized story generation for children.
- **Core Technologies:** SwiftUI, SwiftData, Google AI (Gemini Pro SDK, Gemini 2.0 Flash/Pro for text/image), StoreKit 2, Swift Testing.

## Architecture & Design
- **Pattern:** MVVM-like with distinct Service and Repository layers.
- **UI:** SwiftUI, declarative views, state managed via `@State`, `@StateObject`, `@EnvironmentObject`.
- **Business Logic:** Encapsulated in Service classes (e.g., `StoryService`, `IllustrationService`, `CollectionService`).
- **Data Persistence:** Primarily **SwiftData**. Repositories (e.g., `StoryRepository`, `CollectionRepository`) abstract data access. `UserDefaults` potentially used for simple settings via `SettingsRepository` or `@AppStorage`.
- **Dependency Injection:** `@EnvironmentObject` for shared services/repositories in views; Initializer injection for service/repository dependencies.
- **Concurrency:** Extensive use of `async/await`. `@MainActor` for UI-related tasks.
- **Error Handling:** Custom error enums (e.g., `StoryServiceError`), `AIErrorManager` for logging.

## Coding Standards & Conventions
- **Language:** Swift
- **Style Guide:** Follow Swift API Design Guidelines. Enforced by SwiftLint.
- **Naming:** `UpperCamelCase` for types (structs, classes, enums, protocols), `lowerCamelCase` for functions, methods, properties, variables.
- **Documentation:** Use Swift documentation comments (`///`) for public APIs and complex logic.
- **File Structure:** Organize code by feature (`Features/`) and core components (`Core/Services`, `Core/Repositories`).
- **SwiftUI:** Break down complex views into smaller, reusable components. Use previews (`#Preview`) for UI development and testing.

## Testing
- **Frameworks:** **Swift Testing** for unit/integration tests, XCTest for UI tests.
- **Strategy:** TDD is encouraged (see `documents/dev/tdd-guidelines.md`). Aim for high coverage (targets specified in `README.md`).
- **Mocking:** Use protocol-based mocking for isolating dependencies in unit tests.
- **Execution:** Use `./run_tests.sh` script for running tests and generating reports.
- **Test Organization:**
  - Use hierarchical test grouping and tagging system
  - Separate unit tests from integration tests
  - Keep test files focused and manageable
- **Test Patterns:**
  - Write tests before implementation (Red-Green-Refactor)
  - Use descriptive test names following format: test[Feature][Scenario][ExpectedResult]
  - Support async testing with native Swift Concurrency
  - Utilize parameterized testing for multiple input cases
  - Apply test traits for conditional execution
- **Assertions:**
  - Use `#expect` for standard assertions
  - Make one logical assertion per test
  - Provide meaningful failure messages
- **Best Practices:**
  - Focus on critical path testing
  - Test edge cases and error conditions
  - Cover async operations thoroughly
  - Avoid dependencies between tests
  - Clean up test data when needed

## Key Services & Repositories
- `MagicalStoriesApp.swift`: App entry point, initializes and injects core services.
- `StoryService`: Handles AI text generation (Gemini).
- `IllustrationService`: Handles AI image generation (Gemini 2.0).
- `CollectionService`: Manages Growth Path story collections.
- `PersistenceService`: Central point for SwiftData operations (though repositories handle specifics).
- `StoryRepository`: CRUD operations for `StoryModel` (SwiftData).
- `CollectionRepository`: CRUD operations for `StoryCollection` (SwiftData).
- `SettingsService`/`SettingsRepository`: Manage user preferences.

## Configuration & Environment
- API keys and sensitive configurations are managed via `Config.xcconfig` (not committed).

## Version Control
- **Branching:** Use `feature/` and `bugfix/` prefixes.
- **Commits:** Follow Conventional Commits specification (see `CONTRIBUTING.md`).

## Documentation
- Key documents located in the `documents/` directory covering architecture, APIs, standards, etc.
- `README.md` provides a high-level overview and setup instructions.
- `CONTRIBUTING.md` outlines contribution guidelines.