# Technical Context: Magical Stories

## Core Technologies
-   **Language:** Swift (latest version preferred)
-   **UI Framework:** SwiftUI
-   **Platform:** iOS 16.0+ (Target)
-   **Device Support:** iPhone and iPad (Basic Universal App support)
-   **Data Persistence:** `UserDefaults` via `PersistenceService` (MVP implementation). SwiftData is the likely long-term target.
-   **AI Service:**
    *   **Text Generation:** Google Generative AI (Gemini Pro) via its Swift SDK.
    *   **Image Generation:** Google Generative AI (`gemini-2.0-flash-exp-image-generation` model) via direct REST API calls (not the Swift SDK).
-   **Testing:** Swift Testing framework (`@Test`, `#expect`, etc.)

## Development Environment
-   **IDE:** Xcode (latest version)
-   **Build System:** Xcode Build System
-   **Dependency Management:** Swift Package Manager (SPM) for external libraries (like GoogleGenerativeAI).
-   **Version Control:** Git (repository likely hosted on GitHub, based on `CHANGELOG.md` links).

## Key Libraries & Frameworks Used
-   **SwiftUI:** For UI, state management, and navigation. Core components include `TabView`, `NavigationStack`, `List`, `Form`, `TextField`, `Picker`, `.sheet`, `NavigationLink`, `.navigationDestination`, `AsyncImage`.
-   **Foundation:** For core data types, networking (`URLSession` for image gen), `UserDefaults`, `ProcessInfo`, etc.
-   **GoogleGenerativeAI (Swift SDK):** For interacting with the Gemini Pro API to generate story content. `StoryService` uses the `GenerativeModelProtocol` provided by the SDK for abstraction and testability.
-   **(No SDK for Image Gen):** Direct `URLSession` calls are used for image generation API interaction.
-   **Testing:** Swift's built-in testing framework (`Testing`).
-   **XCTest:** Underlying framework for UI tests (`magical-storiesUITests`).

## Core Technical Patterns & Guidelines
-   **Architecture:** Follows MVVM principles loosely, heavily relying on SwiftUI's state management. See `memory_bank/systemPatterns.md` for details.
-   **State Management:** Primarily uses `@StateObject` (for services), `@EnvironmentObject` (for service injection), `@State` (for local view state), `@Binding` (for two-way connections), and `@AppStorage` (for user preferences).
-   **Asynchronous Operations:** `async/await` is mandatory for all network operations (AI calls, potential future data loading). Views use `.task` for initiating async work.
-   **Error Handling:** Utilize Swift's native `do-catch` mechanism with custom `Error` enums (e.g., `StoryError`). Provide user-friendly feedback via SwiftUI `.alert`. Handle API errors gracefully.
-   **Navigation:** Use `TabView` for main sections, `NavigationStack` within tabs, `.sheet` for modals, and `NavigationLink` / `.navigationDestination` for push navigation. See `memory_bank/systemPatterns.md`.
-   **UI Guidelines:**
    *   Follow Apple Human Interface Guidelines (HIG).
    *   Use SF Symbols for consistent iconography.
    *   Use SF Pro Rounded font where appropriate for a child-friendly feel.
-   **Accessibility:** Implement basic VoiceOver support and ensure Dynamic Type compatibility for adjustable font sizes.
-   **Personalization:** Support Dark Mode via `.preferredColorScheme`, use `@AppStorage` for preferences.
-   **Text-to-Speech:** *Initially considered (AVSpeechSynthesizer), but feature was removed.*

## Build & Test Process
-   A script `run_tests.sh` exists to clean, build, and run unit and UI tests, likely using `xcodebuild`.
-   `xcbeautify` is used to format test output.
-   Code coverage reports are generated.

## Configuration
-   API keys (specifically `AppConfig.geminiApiKey`) are stored locally in `Config.plist` (which should be gitignored) and accessed via `AppConfig.swift`.
-   The same `AppConfig.geminiApiKey` is used for both text (via SDK) and image generation (via direct REST calls).

## Swift Integration Testing Guidelines

These guidelines are based on the patterns established in `magical-storiesTests/Services/IllustrationServiceIntegrationTests.swift` for tests interacting with external services or requiring significant setup.

*   **File Naming:** Integration test files should follow the convention `ServiceNameIntegrationTests.swift`.
*   **Imports:** Essential imports include `Testing` for the testing framework and `@testable import magical_stories` to access internal types from the main app target. `Foundation` may be needed for specific functionalities like `ProcessInfo`.
*   **Integration Tag:** Define a specific tag for integration tests using `extension Tag { @Tag static var integration: Self }`. This allows selective running of tests. Apply the tag to relevant suites or individual tests.
*   **Test Suite:** Group related integration tests using the `@Suite("Descriptive Suite Name")` attribute on a struct.
*   **Test Method Signature:** Use the standard Swift Testing signature for asynchronous tests that can throw errors: `@Test func testMethodName() async throws`.
*   **API Key/Secrets Management:**
    *   Prioritize test-specific environment variables (e.g., `TEST_SERVICE_API_KEY`) for sensitive data like API keys. Access using `ProcessInfo.processInfo.environment["YOUR_KEY"]`.
    *   Provide a fallback mechanism to use the standard application configuration (e.g., `AppConfig`) if the environment variable is not set.
    *   Log the source of the API key being used (`Environment Variable` or `AppConfig`) for clarity during test runs using `print` or `Issue.record`.
    *   Handle potential `ConfigurationError` during service initialization if keys are missing or invalid.
*   **Robust Error Handling:**
    *   Wrap potentially failing operations (like service initialization and API calls) in `do-catch` blocks.
    *   Catch specific error types relevant to the operation (e.g., `ConfigurationError`, `IllustrationError`).
    *   Log detailed error information using `print` for immediate visibility and `Issue.record` for persistent tracking of non-fatal issues.
    *   Re-throw critical errors (like configuration or core API call failures) using `throw error` to ensure the test fails clearly and execution stops at the point of failure.
*   **Assertions:**
    *   Use `#require` to safely unwrap essential optional values returned from successful operations (e.g., a result URL). If the value is `nil`, the test fails with a clear message.
    *   Use `#expect` to assert conditions that must be true for the test to pass (e.g., checking file existence, verifying properties).
*   **Resource Cleanup:**
    *   Perform cleanup (e.g., deleting temporary files) within the main `do-catch` block or a nested one, typically after assertions.
    *   Use `try?` for cleanup operations (like `FileManager.removeItem`) where failure shouldn't necessarily fail the entire test.
    *   Log cleanup errors using `print` or `Issue.record` for visibility, but avoid re-throwing unless the cleanup failure invalidates the test's core purpose.
*   **Logging:**
    *   Use `print` statements strategically to provide visibility into the test's flow (e.g., "Initializing service...", "Calling API...", "Cleanup complete..."). Prefix logs with a clear indicator like "--- Integration Test: ---".
    *   Use `Issue.record` to log significant events, non-fatal errors (like cleanup issues), or configuration details (like API key source) that should be persisted in test results without failing the test.
