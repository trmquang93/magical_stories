---
applyTo: '**'
---
# System Patterns: Magical Stories

## Core Architecture
The application primarily follows the **MVVM (Model-View-ViewModel)** pattern within a SwiftUI context, although dedicated ViewModels are not explicitly defined for every view. State management relies heavily on SwiftUI's built-in mechanisms.

## Key Patterns & Concepts

1.  **SwiftUI Declarative UI:** The user interface is built using SwiftUI's declarative syntax. Views are functions of their state.

2.  **State Management:** (Leverages SwiftUI's native patterns)
    *   `@StateObject`: Used for owning and initializing reference-type objects (Services, Repositories) that persist for the lifetime of the view hierarchy.
    *   `@EnvironmentObject`: Used to inject shared objects down the view hierarchy.
    *   `@State`: Used for managing simple, transient view-local state.
    *   `@Binding`: Used to create a two-way connection between a view and its state managed elsewhere.
    *   `@Query`: Used to directly fetch and observe SwiftData models in views.

3.  **Service Layer Pattern:**
    *   Application logic related to external interactions (AI, persistence, StoreKit) and core functionalities is encapsulated in Service classes.
    *   Services are initialized as `@StateObject`s at the application root and injected into the view hierarchy using `.environmentObject()`.
    ```swift
    // Example from MagicalStoriesApp
    @StateObject private var storyRepository = StoryRepository()
    @StateObject private var settingsService = SettingsService()
    @StateObject private var purchaseService = PurchaseService()
    // ...
    MainTabView()
        .environmentObject(storyRepository)
        .environmentObject(settingsService)
        .environmentObject(purchaseService)
    ```

4.  **Dependency Injection:** Services and Repositories are injected primarily via `@EnvironmentObject`. Dependencies between services/repositories are typically handled via initializers.

5.  **Repository Pattern:**
    *   Abstracts data access logic from the rest of the application.
    *   Concrete repositories encapsulate CRUD operations for specific data models.
    *   Uses **SwiftData** as the primary persistence layer.

6.  **Navigation Patterns:**
    *   **Main Navigation:** `TabView` manages the top-level navigation.
    *   **Intra-Tab Navigation:** `NavigationStack` is used *within each tab*.
    *   **Modal Presentation:** `.sheet` is standard for modal forms.
    *   **View Transitions (Push):** `NavigationLink(value: ...)` is used with corresponding `.navigationDestination(for: ...)` modifiers.
    *   **Programmatic Navigation:** `NavigationPath` for complex navigation scenarios.
    *   **Navigation Best Practices:**
        *   Avoid nesting multiple `NavigationStack` components, as this disrupts navigation context and can cause back button behavior issues.
        *   Use consistent navigation patterns throughout the app - prefer `NavigationLink(value:)` with `.navigationDestination(for:)` over `NavigationLink(destination:)`.
        *   Remember that `MainTabView` already wraps each tab in a `NavigationStack`; adding another in tab content creates problematic nested stacks.
        *   Back button behavior is determined by the parent `NavigationStack` context - disrupting this context leads to navigation issues.
        *   Views that are navigation destinations should not wrap themselves in additional `NavigationStack`s.

7.  **View Structure Hierarchy:**
    ```
    MagicalStoriesApp
    └── RootView
        └── MainTabView
            ├── HomeView
            │   └── CollectionFormView (Sheet)
            ├── LibraryView
            │   └── StoryDetailView (Push via NavigationStack/Destination)
            ├── CollectionsListView (Tab Content, within NavigationStack)
            │   ├── CollectionCardView (List Item)
            │   └── CollectionDetailView (Push via NavigationStack/Destination)
            │       └── StoryDetailView (Push via NavigationStack/Destination)
            └── SettingsView
                └── ParentalControlsView (Implied)
    ```

8.  **Asynchronous Pattern:** 
    *   Uses `async/await` for network operations, data access, and background tasks.
    *   Views use `.task` modifiers for async operations.
    *   UI updates are dispatched on the main thread.
    *   Debug logging is used for async flows.

9.  **Error Handling Pattern:**
    *   Uses Swift's native `do-catch` with custom `Error` enums.
    *   Centralizes error management for specific domains (e.g., `AIErrorManager`).
    *   Views use `@State` for error tracking and `.alert` for presentation.

10. **Protocol-Based Testing Pattern:**
    *   Services and Repositories conform to protocols to enable mock implementations.
    *   Mocks are used for testing without live dependencies (network, disk I/O).
    *   **CollectionService Testing Approach:**
        *   **Unit Testing:** `CollectionServiceTests.swift` contains comprehensive tests for all core functionality:
            *   Uses mock implementations of dependencies (`MockCollectionRepository`, `MockStoryService`, `MockAchievementRepository`) injected through the initializer.
            *   Tests core methods in isolation including progress calculation, story completion, achievement creation, and CRUD operations.
            *   Tests error handling for all failure scenarios (non-existent IDs, etc.).
            *   Uses TDD approach with clear arrange-act-assert patterns.
            *   Directly verifies state changes in mocked repositories.
        *   **Integration Testing:** `CollectionServiceIntegrationTests.swift` verifies the end-to-end flow:
            *   Creates a dedicated test environment with in-memory SwiftData `ModelContainer`.
            *   Uses real service implementations with test configurations.
            *   Tests the complete collection lifecycle from creation to story completion.
            *   Verifies achievement creation and prevents duplicates.
            *   Follows a clear, tag-annotated test structure for selective test runs.
        *   Each test focuses on a single aspect of functionality and includes proper assertions for both expected behavior and error conditions.

11. **Illustration Generation Pattern:**
    *   Uses direct REST API calls with detailed prompts.
    *   Implements retry logic and error handling.
    *   Follows a consistent pattern for all image generation requests.

12. **Model-Repository-Service Pattern:**
    * **Models:** SwiftData `@Model` classes with appropriate relationships.
    * **Repositories:** Encapsulate SwiftData access logic and CRUD operations.
    * **Services:** Implement business logic, utilizing repositories for data access.
    * This pattern is consistently applied across different features (stories, collections, settings).

## Current Architecture Notes
- The system leverages standard SwiftUI patterns and MVVM concepts.
- Key additions include Growth Collections and StoreKit monetization.
- `TextToSpeechService` remains removed.
- Comprehensive testing strategy for services ensures reliability and maintainability.

*Note: For implementation status and feature details, please refer to progress.md.*
