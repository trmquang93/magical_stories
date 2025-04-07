# System Patterns: Magical Stories

## Core Architecture
The application primarily follows the **MVVM (Model-View-ViewModel)** pattern within a SwiftUI context, although dedicated ViewModels are not explicitly defined for every view. State management relies heavily on SwiftUI's built-in mechanisms.

## Key Patterns & Concepts

1.  **SwiftUI Declarative UI:** The user interface is built using SwiftUI's declarative syntax. Views are functions of their state.

2.  **State Management:** (Leverages SwiftUI's native patterns)
    *   `@StateObject`: Used for owning and initializing reference-type objects (Services like `StoryService`, `SettingsService`) that persist for the lifetime of the view hierarchy where they are declared (typically at the App root).
    *   `@EnvironmentObject`: Used to inject shared objects (like services) down the view hierarchy without explicit passing.
    *   `@State`: Used for managing simple, transient view-local state (e.g., form inputs, UI state like `showingStoryForm`, `selectedTab`).
    *   `@Binding`: Used to create a two-way connection between a view and its state managed elsewhere (often via `@State` in a parent view).

3.  **Service Layer & Setup:**
    *   Application logic related to external interactions (AI, persistence) and core functionalities (settings) is encapsulated in Service classes (`StoryService`, `SettingsService`, `PersistenceService`, `IllustrationService`).
    *   Services are initialized as `@StateObject`s at the application root (`MagicalStoriesApp`) and injected into the view hierarchy using `.environmentObject()`.
    ```swift
    // Example from MagicalStoriesApp
    @StateObject private var storyService = StoryService()
    @StateObject private var settingsService = SettingsService()
    // ...
    MainTabView()
        .environmentObject(storyService)
        .environmentObject(settingsService)
    ```

4.  **Dependency Injection:** Services are injected primarily via `@EnvironmentObject`. Service dependencies are handled during initialization in the `MagicalStoriesApp`.

5.  **Data Persistence:** `PersistenceService` encapsulates data storage logic. Currently uses `UserDefaults` (MVP), with potential future migration to SwiftData.

6.  **Navigation:**
    *   **Main Navigation:** `TabView` manages the top-level navigation between Home, Library, and Settings tabs within `MainTabView`.
    *   **Intra-Tab Navigation:** `NavigationStack` is used *within each tab* for push/pop navigation (e.g., navigating from `StoriesView` to `StoryDetailView`).
    *   **Modal Presentation:** `.sheet` is the standard for presenting modal forms like `StoryFormView` and `GrowthStoryFormView`. `.fullScreenCover` can also be used.
    *   **View Transitions (Push):** `NavigationLink(value: ...)` combined with `.navigationDestination(for: ...)` is used for pushing detail views onto the `NavigationStack`.
    *   **Programmatic Navigation/Deep Linking:** `NavigationPath` can be used with `NavigationStack` for programmatic control over the navigation stack.
    *   **Navigation Guidelines:**
        *   ✅ **DO:** Use `NavigationStack` within tabs, use `.sheet`/`.fullScreenCover` for modals, use `NavigationPath` for deep links.
        *   ❌ **DON'T:** Mix `NavigationView` and `NavigationStack`, nest `NavigationStack`s, assume state persists across tab switches.

7.  **View Structure Hierarchy:**
    ```
    MainTabView
    ├── HomeView
    │   ├── StoryFormView (Sheet)
    │   └── GrowthStoryFormView (Sheet)
    ├── StoriesView (Renamed from LibraryView)
    │   └── StoryDetailView (Push)
    └── SettingsView
        └── ParentalControlsView (Implied, may be part of SettingsView)
    ```

8.  **Asynchronous Operations:** `async/await` is used for handling asynchronous tasks like AI story generation (`StoryService`), illustration generation (`IllustrationService`), and potentially data loading. Views use `.task` modifiers to initiate asynchronous work when they appear.

9.  **Error Handling:**
    *   Uses Swift's native `do-catch` blocks and `Error` protocol.
    *   Custom error enums (e.g., `StoryError`) define specific failure cases.
    *   Views typically use `@State` variables to track error presence and the specific error object.
    *   SwiftUI's `.alert` modifier is used to present user-friendly error messages based on the caught error.
    ```swift
    // Example Error Handling Pattern
    enum StoryError: Error { /* ... cases ... */ }

    struct SomeView: View {
        @State private var showError = false
        @State private var error: StoryError?

        func performAction() async {
            do {
                try await someService.action()
            } catch {
                self.error = error as? StoryError ?? .genericFailure
                self.showError = true
            }
        }

        var body: some View {
            // ... view content ...
            .alert("Error", isPresented: $showError, presenting: error) { /* ... */ }
        }
    }
    ```

10. **Protocol-Based Mocking (for Testing):** Service protocols (`StoryServiceProtocol`, `SettingsServiceProtocol`, `PersistenceServiceProtocol`) exist for most services, enabling the creation of mock objects for unit testing. Internally, `StoryService` also utilizes the `GenerativeModelProtocol` from the Google AI SDK to abstract the specific AI model interaction, further enhancing testability. Note: `IllustrationService` currently does not have a corresponding protocol and is tested via direct instantiation (primarily testing error paths with dummy keys).

11. **Illustration Generation:**
    *   A dedicated `IllustrationService` handles interaction with the Google Generative AI API (`gemini-2.0-flash-exp-image-generation` model) via **direct REST calls**.
    *   This service is injected via `@EnvironmentObject`.
    *   The `StoryProcessor` invokes the `IllustrationService` *after* story text generation and pagination.
    *   Generation occurs asynchronously, per page.
    *   The resulting image URL (or `nil` on failure) is stored in the page's data model (`illustrationURL: URL?`).
    *   UI views (`PageView`) use `AsyncImage` to load illustrations.

## Current Architecture Notes
- The system leverages standard SwiftUI patterns for structure, state, and navigation.
- `TextToSpeechService` has been removed.
- Focus is on core story generation, illustration, and persistence using `UserDefaults`.
- Adherence to the patterns outlined in `documents/App-structure.md` is crucial for consistency.
