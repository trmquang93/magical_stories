# Architecture Overview: Magical Stories

## 1. Application Architecture

The Magical Stories application follows a layered architecture, primarily leveraging SwiftUI and MVVM-like principles for structure, state management, and UI.

```mermaid
graph TD
    subgraph "UI Layer (SwiftUI)"
        direction TB
        A["Views (e.g., HomeView, LibraryView, StoryDetailView, PaywallView)"] --> B(State Management);
        B -- Uses --> C["@State, @StateObject, @EnvironmentObject, @Binding"];
    end

    subgraph "Service Layer"
        direction TB
        D[StoryService]
        E[IllustrationService]
        F[CollectionService]
        G[PurchaseService]
        H[EntitlementManager]
        I[SettingsService]
        J[...]
    end

    subgraph "Repository Layer"
        direction TB
        K[StoryRepository]
        L[SettingsRepository]
        M[AchievementRepository]
        N[...]
    end

    subgraph "Persistence Layer"
        direction TB
        O[SwiftData (Primary)]
        P[UserDefaults (Legacy/Settings)]
    end

    subgraph "External Services"
        direction TB
        Q[Google AI (Text & Image)]
        R[App Store (StoreKit)]
    end

    A --> D;
    A --> E;
    A --> F;
    A --> G;
    A --> H;
    A --> I;

    D --> Q;
    E --> Q;
    F --> K; % CollectionService might use StoryRepository
    G --> R;
    H -- Reads Purchase Status --> G; % Or observes transactions

    D --> K; % StoryService uses StoryRepository
    I --> L; % SettingsService uses SettingsRepository

    K --> O;
    L --> P; % Settings might still use UserDefaults or migrate
    M --> O;

    style O fill:#f9f,stroke:#333,stroke-width:2px
    style P fill:#lightgrey,stroke:#333,stroke-width:1px
```

### 1.1. Core Principles & Patterns
-   **SwiftUI:** The UI is built declaratively using SwiftUI. Views are functions of state.
-   **MVVM-like:** While not strictly enforcing dedicated ViewModels for every view, the architecture separates concerns:
    -   **Views (V):** SwiftUI Views responsible for layout and presentation.
    -   **View State (VM-like):** Managed via SwiftUI's state management tools (`@State`, `@StateObject`, `@EnvironmentObject`) often held within the View or in shared Service/Manager objects.
    -   **Model (M):** Data structures (`Story`, `Page`, `Collection`, `Setting`) and the logic encapsulated within Services and Repositories.
-   **Service Layer:** Encapsulates business logic, interactions with external APIs, and coordination. Key services include:
    -   `StoryService`: Handles text generation via Google AI.
    -   `IllustrationService`: Handles image generation via the Google AI REST API using the `imagen-3.0-generate-002` model.
    -   `CollectionService`: Manages creation and retrieval of themed "Growth Collections".
    -   `PurchaseService`: Interacts with StoreKit 2 for IAPs.
    -   `EntitlementManager`: Determines user access rights based on purchases.
    -   `SettingsService`: Manages user preferences and parental controls.
-   **Repository Pattern:** Abstracts data access logic. Repositories (`StoryRepository`, `SettingsRepository`, etc.) provide a clean API for CRUD operations, decoupling services from the specific persistence mechanism.
-   **Dependency Injection:** Primarily achieved using `@EnvironmentObject` for injecting shared services/repositories down the view hierarchy, and initializer injection for dependencies between services/repositories.

### 1.2. Key Subsystems
-   **Persistence (SwiftData):**
    -   The application is migrating to **SwiftData** as the primary persistence solution for core data like stories, collections, and user progress.
    -   Repositories interact directly with the SwiftData model context.
    -   `UserDefaults` may still be used for simple settings via `SettingsRepository` or `@AppStorage`.
    -   See `documents/data/persistence-guide.md` and `documents/data/swift-data-schema.md`.
-   **AI Integration (Google AI):**
    -   Leverages Google AI for text (Gemini Pro via SDK) and image generation (`imagen-3.0-generate-002` via REST API).
    -   Managed by `StoryService` and `IllustrationService`.
    -   See `documents/api/google-ai-integration.md`.
-   **Growth Collections:**
    -   A core feature providing themed story sets.
    -   Managed by `CollectionService`, likely interacting with `StoryRepository` and potentially AI services.
    -   Models define collection structure and content.
    -   **CollectionsListView supports swipe-to-delete for deleting collections, calling `CollectionService.deleteCollection`.**
-   **StoreKit Integration (Monetization):**
    -   Enables premium features via subscriptions or lifetime purchase.
    -   `PurchaseService` handles StoreKit API interactions (loading products, purchases, transactions).
    -   `EntitlementManager` tracks purchase status and gates access to premium features (like specific Collections).
    -   See `documents/api/storekit-integration.md`.

### 1.3. State Management
-   Relies heavily on SwiftUI's built-in tools:
    -   `@StateObject`: For owning service/repository instances at appropriate scopes.
    -   `@EnvironmentObject`: For accessing shared instances in subviews.
    -   `@State`: For transient, view-local UI state.
    -   `@Published`: Within `ObservableObject` classes (Services, Managers) to notify views of changes (e.g., `EntitlementManager.isPremium`).

## 2. Testing Architecture

A comprehensive testing strategy ensures code quality and stability.

### 2.1. Framework & Categories
-   **Swift Testing:** The primary framework for unit and integration tests.
-   **XCTest:** Used for UI tests (`magical-storiesUITests`).
-   **Categories:** Unit, Integration, UI, and SwiftUI View tests are employed.
-   **Delete collection feature:** Tested at the service and repository layers; UI-level swipe-to-delete is documented and follows SwiftUI best practices.

### 2.2. Key Principles
-   **Mocking:** Protocol-based mocking is crucial for isolating components in unit tests. Services and Repositories have corresponding protocols (e.g., `IllustrationServiceProtocol`, `StoryRepositoryProtocol`) and mock implementations are used extensively.
-   **Dependency Injection:** Mocks are injected during test setup.
-   **Test Data:** Managed via mock configurations, local JSON, or `StoreKitConfiguration` files.
-   **CI/CD:** Automated test execution, coverage reporting, and quality gates are integrated into the development workflow.

### 2.3. Further Details
For detailed guidelines, patterns, and examples, refer to:
-   `documents/dev/testing-guidelines.md`
-   `documents/dev/swiftui-testing-patterns.md`
-   `memory_bank/techContext.md` (Swift Integration Testing Guidelines section)

## 3. Future Considerations
-   Refining error handling across layers.
-   Optimizing SwiftData performance and queries.
-   Expanding analytics and monitoring.
-   Potential introduction of dedicated ViewModels if view complexity increases significantly.

## [2025-04-20] Gemini 2.0 Multimodal Illustration Generation

- **Service:** IllustrationService now uses Gemini 2.0 (`gemini-2.0-flash-exp-image-generation:generateContent`) for illustration generation.
- **Multimodal Input:** When generating a new page's illustration, the previous page's image (if available) is loaded from persistent storage and sent as `inline_data` alongside the text prompt.
- **API Request:**
  - Request body includes both a text part (scene description) and an image part (base64-encoded previous illustration).
  - `generationConfig` specifies `[\"TEXT\", \"IMAGE\"]` as response modalities.
- **Response Parsing:**
  - The service parses `candidates[].content.parts[]` for an `inline_data` part with an image MIME type.
  - The image is extracted, decoded, and saved to persistent storage.
- **Fallback:**
  - If no previous image is available (first page or error), only the text prompt is sent.
  - Legacy Imagen API is retained for single-image mode or as a fallback.
- **Error Handling:**
  - Improved error handling and retry logic for API/network failures.
  - Logs all API responses and errors for debugging.

See `IllustrationService.swift` for implementation details and request/response code examples.
