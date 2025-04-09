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
    *   The **Repository Pattern** is used to abstract data access logic. Concrete repositories (`StoryRepository`, `SettingsRepository`, `AchievementRepository`, etc.) encapsulate CRUD operations for specific data models.
    *   The application **currently uses `UserDefaults`** for persistence. Migration to **SwiftData** is **planned as a future goal**. Repositories are designed to interact with SwiftData once integrated.
    *   `PersistenceService` (legacy, interacting with `UserDefaults`) remains in use until the planned migration to SwiftData occurs.

6.  **Navigation:**
    *   **Main Navigation:** `TabView` manages the top-level navigation.
    *   **Intra-Tab Navigation:** `NavigationStack` is used *within each tab*.
    *   **Modal Presentation:** `.sheet` is standard for modal forms.
    *   **View Transitions (Push):** `NavigationLink(value: ...)` with `.navigationDestination(for: ...)`.
    *   **Programmatic Navigation:** `NavigationPath` can be used.

7.  **View Structure Hierarchy:** (Remains largely the same, specific views for new features TBD)
    ```
    MainTabView
    ├── HomeView
    │   ├── StoryFormView (Sheet)
    │   └── GrowthStoryFormView (Sheet - Planned)
    ├── LibraryView (or StoriesView)
    │   └── StoryDetailView (Push)
    ├── CollectionsView (Planned)
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
    *   Service and Repository protocols (e.g., `StoryRepositoryProtocol`, `SettingsServiceProtocol`, `IllustrationServiceProtocol`) exist for most components, enabling the creation of mock objects for robust unit testing without live dependencies (like network calls or disk I/O).
    *   Improved mocking strategies are implemented across tests.

11. **Illustration Generation:**

    The `IllustrationService` is responsible for generating story illustrations using Google's Generative AI model (`imagen-3.0-generate-002`). Its implementation follows these architectural patterns:

    - **Direct REST API Integration:**
      - Communicates directly with the REST endpoint `https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict`.
      - Does **not** use any SDK abstractions, instead manually constructs HTTP requests and parses responses.
      - Defines internal `Codable` structs for request and response bodies, ensuring type-safe serialization.

    - **Prompt Engineering:**
      - Constructs a detailed prompt emphasizing **whimsical, child-friendly illustrations**.
      - Explicitly instructs **not to depict anthropomorphic animals** to maintain appropriate content.
      - The prompt is dynamically generated based on story context, but always includes these stylistic constraints.

    - **Retry Logic:**
      - Implements a retry mechanism with **up to 5 attempts**.
      - Waits **1 second** between retries upon failure.
      - Retries on network errors, API failures, or invalid responses to improve robustness.

    - **Comprehensive Error Handling:**
      - Uses a dedicated `IllustrationError` enum covering:
        - Network connectivity issues
        - API error responses
        - Invalid or unexpected API responses
        - Image decoding or processing failures
      - Errors are logged via the centralized `AIErrorManager`.
      - Errors propagate back to callers for appropriate UI handling.

    - **Response Parsing & Image Handling:**
      - Parses the API response to extract **base64-encoded image data**.
      - Decodes the base64 string into binary image data.
      - Dynamically determines the MIME type (e.g., PNG, JPEG) from response metadata or content.
      - Saves the decoded image to the app's persistent storage under `Application Support/Illustrations/`.
      - Uses helper methods to handle file naming, MIME type handling, and storage paths.

    - **Integration with App Flow:**
      - The `StoryProcessor` invokes `IllustrationService` asynchronously for each story page.
      - The resulting image file paths are stored in the `Page` model.
      - UI components like `PageView` load these images via `AsyncImage`, supporting smooth asynchronous loading.

    - **Additional Notes:**
      - The service conforms to `IllustrationServiceProtocol` for testability.
      - Internal helper methods encapsulate request construction, response parsing, error mapping, and file operations.
      - Designed to be extensible for future prompt variations or API changes.

## Current Architecture Notes
- The system leverages standard SwiftUI patterns and MVVM concepts.
- Key additions include Growth Collections, StoreKit monetization, and a migration to SwiftData using the Repository pattern.
- `TextToSpeechService` remains removed.
- The next major features—Growth Collections, StoreKit monetization, and SwiftData migration—are **planned and designed, but implementation has not yet begun**.
