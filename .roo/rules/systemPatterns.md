---
description:
globs:
alwaysApply: true
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
    *   `@Query`: Used in views like `CollectionsListView` to directly fetch and observe SwiftData models.

3.  **Service Layer & Setup:**
    *   Application logic related to external interactions (AI, persistence, StoreKit) and core functionalities is encapsulated in Service classes (`StoryService`, `SettingsService`, `IllustrationService`, `CollectionService`, `RecommendationEngine`, `PurchaseService`, `EntitlementManager`).
    *   Services and Repositories are often initialized as `@StateObject`s at the application root (`MagicalStoriesApp`) and injected into the view hierarchy using `.environmentObject()`.
    ```swift
    // Example from MagicalStoriesApp
    @StateObject private var storyRepository = StoryRepository() // Example
    @StateObject private var settingsService = SettingsService()
    @StateObject private var purchaseService = PurchaseService() // Example
    // ...
    MainTabView()
        .environmentObject(storyRepository)
        .environmentObject(settingsService)
        .environmentObject(purchaseService)
    ```

4.  **Dependency Injection:** Services and Repositories are injected primarily via `@EnvironmentObject`. Dependencies between services/repositories are typically handled via initializers.

5.  **Data Persistence & Repository Pattern:**
    *   The **Repository Pattern** is used to abstract data access logic. Concrete repositories (`StoryRepository`, `SettingsRepository`, `AchievementRepository`, `CollectionRepository`) encapsulate CRUD operations for specific data models.
    *   The application now uses **SwiftData** as the primary persistence layer for stories, settings, and user data.
    *   Legacy `UserDefaults` persistence and migration logic have been removed.

6.  **Navigation:**
    *   **Main Navigation:** `TabView` manages the top-level navigation.
    *   **Intra-Tab Navigation:** `NavigationStack` is used *within each tab*.
    *   **Modal Presentation:** `.sheet` is standard for modal forms (e.g., `CollectionFormView` presented from `HomeView`).
    *   **View Transitions (Push):** `NavigationLink(value: ...)` is used (e.g., in `CollectionsListView`, `CollectionDetailView`). Requires a corresponding `.navigationDestination(for: ...)` modifier placed higher in the view hierarchy within the `NavigationStack`.
    *   **Programmatic Navigation:** `NavigationPath` can be used.

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

8.  **Asynchronous Operations:** `async/await` is used extensively for AI interactions, data fetching/saving via Repositories, and other background tasks. Views use `.task` modifiers.
    *   Enforced async/await ordering in data persistence.
    *   UI updates dispatched on main thread.
    *   Debug logging added for async flows.

9.  **Error Handling:**
    *   Uses Swift's native `do-catch` and `Error` protocol.
    *   Custom error enums define specific failure cases.
    *   `AIErrorManager` centralizes handling for AI-related errors.
    *   Views use `@State` for error tracking and `.alert` for presentation.
    *   Error propagation improved in service layer.

10. **Protocol-Based Mocking (for Testing):**
    *   Service and Repository protocols (e.g., `StoryRepositoryProtocol`, `SettingsServiceProtocol`, `IllustrationServiceProtocol`, `CollectionServiceProtocol`) exist for most components, enabling the creation of mock objects for robust unit testing without live dependencies (like network calls or disk I/O).
    *   Improved mocking strategies are implemented across tests.

11. **Illustration Generation:** (No changes from previous state)
    *   Uses direct REST API calls.
    *   Detailed prompts, retry logic, error handling via `IllustrationError` and `AIErrorManager`.
    *   Saves images to persistent storage.
    *   Fully integrated.

12. **Growth Collections Implementation:**

    The Growth Collections feature is being implemented using these architectural patterns:

    - **Core Models:**
      - `StoryCollection` - SwiftData `@Model` class representing a collection of stories with a specific growth theme. Includes `completionProgress`.
      - `GrowthCategory` - Enum defining developmental categories.
      - Relationship between `StoryModel` and `StoryCollection` models via SwiftData's `@Relationship`.
      - `StoryModel` includes `readCount` and `lastReadAt` for progress tracking.

    - **Repository Pattern:**
      - `CollectionRepository` encapsulates SwiftData access logic for `StoryCollection` entities.
      - Provides CRUD operations and query methods.
      - Uses ModelContext for persistence operations.

    - **Service Layer:**
      - `CollectionService` implements business logic for creation, retrieval, and management of story collections.
      - Conforms to `CollectionServiceProtocol` for testability.
      - Includes logic for `createCollection`, `generateStoriesForCollection`, and `updateCollectionProgress` (based on `StoryModel.readCount`).
      - Will contain achievement logic (optional).

    - **UI Components (Current State):**
      - `CollectionsListView`: Main view for browsing collections. Uses `@Query` for data fetching and `NavigationLink(value:)` for navigation. Contains search functionality.
      - `CollectionCardView`: Displays summary info for a collection, including `completionProgress`. Used within `CollectionsListView`.
      - `CollectionDetailView`: Displays stories within a specific collection. Uses `NavigationLink(value:)` to navigate to `StoryDetailView`. *Note: Contains incorrect progress update logic (`toggleStoryCompletion`) slated for removal.*
      - `CollectionFormView`: Input form for creating a new collection. Captures parameters, calls `CollectionService` to create the collection shell and trigger story generation. Handles internal loading/error states.

    - **Integration Points:**
      - Growth Collections will be accessible via a dedicated tab in `MainTabView`, hosting `CollectionsListView` within a `NavigationStack`.
      - `HomeView` presents `CollectionFormView` modally.
      - Collections leverage existing story reading flows (navigating from `CollectionDetailView` to `StoryDetailView`).
      - Progress updates are triggered after a story is read (updating `StoryModel.readCount`), notifying `CollectionService` to recalculate `StoryCollection.completionProgress`.
      - Achievement system will track progress within collections.
      - Future StoreKit integration will gate premium collections.

## Current Architecture Notes
- The system leverages standard SwiftUI patterns and MVVM concepts.
- Key additions include Growth Collections and StoreKit monetization.
- `TextToSpeechService` remains removed.
