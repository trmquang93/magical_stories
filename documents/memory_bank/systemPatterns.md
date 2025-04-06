# System Patterns: Magical Stories

## Core Architecture
The application primarily follows the **MVVM (Model-View-ViewModel)** pattern within a SwiftUI context, although dedicated ViewModels are not explicitly defined for every view. State management relies heavily on SwiftUI's built-in mechanisms.

## Key Patterns & Concepts

1.  **SwiftUI Declarative UI:** The user interface is built using SwiftUI's declarative syntax. Views are functions of their state.
2.  **State Management:**
    -   `@StateObject`: Used for owning and initializing reference-type objects (Services) that persist for the lifetime of the view hierarchy where they are declared (typically at the App root).
    -   `@EnvironmentObject`: Used to inject shared objects (like services) down the view hierarchy without explicit passing.
    -   `@State`: Used for managing simple, transient view-local state (e.g., form inputs, presentation state).
    -   `@Binding`: Used to create a two-way connection between a view and its state managed elsewhere (often via `@State` in a parent view).
3.  **Service Layer:** Application logic related to external interactions (AI, persistence) and core functionalities (settings) is encapsulated in Service classes (`StoryService`, `SettingsService`, `PersistenceService`). These services are typically injected into the view hierarchy using `@EnvironmentObject`.
4.  **Dependency Injection:** Services are injected primarily via `@EnvironmentObject`. Service dependencies are handled during initialization in the `MagicalStoriesApp`.
5.  **Data Persistence:** SwiftData is used for local storage of generated `Story` objects. `PersistenceService` likely encapsulates SwiftData interactions (though not explicitly reviewed in detail yet).
6.  **Navigation:**
    -   `TabView`: Used for the main top-level navigation between Home, Library, and Settings.
    -   `NavigationStack`: Used within each tab for push/pop navigation (e.g., navigating from `LibraryView` to `StoryDetailView`).
    -   `.sheet` / `.fullScreenCover`: Used for presenting modal views (e.g., `StoryFormView`).
7.  **Asynchronous Operations:** `async/await` is used for handling asynchronous tasks like AI story generation (`StoryService`) and potentially data loading. Views use `.task` modifiers to initiate asynchronous work when they appear.
8.  **Protocol-Based Mocking (for Testing):** Service protocols (`StoryServiceProtocol`, `SettingsServiceProtocol`) exist, enabling the creation of mock objects for unit and integration testing (as seen with the removed `MockTextToSpeechService`).

## Current Architecture
- The system has been simplified by permanently removing `TextToSpeechService`, its protocol, and UI interactions.
- The core patterns (MVVM-like structure, SwiftUI state management, Service Layer, SwiftData persistence) remain unchanged.
- Future development will focus on enhancing visual and interactive aspects like illustration generation rather than audio features.
