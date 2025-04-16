---
description:
globs:
alwaysApply: true
---
# Technical Context: Magical Stories

## Core Technologies
-   **Language:** Swift (latest version preferred)
-   **UI Framework:** SwiftUI
-   **Platform:** iOS 16.0+ (Target)
-   **Device Support:** iPhone and iPad (Basic Universal App support)
-   **Data Persistence:** Uses **SwiftData** as the primary persistence layer, abstracted via the Repository pattern. `UserDefaults` is only used for minor UI preferences and app settings.
-   **AI Service:**
    *   **Text Generation:** Google Generative AI (Gemini Pro) via its Swift SDK.
    *   **Image Generation:** Primarily uses **direct REST API calls** to Google's Generative AI platform (model: `imagen-3.0-generate-002`). The REST API endpoint is:

        ```
        https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict
        ```

        The `IllustrationService` constructs JSON request bodies containing the prompt and generation parameters, sends them asynchronously using Swift concurrency (`async/await`), and parses JSON responses with base64-encoded image data.

        Generated images are saved to the **Application Support/Illustrations/** directory, with file extensions determined by the MIME type of the image.

        The API key is sourced from `AppConfig`.

        Errors during image generation are comprehensively handled and logged via `AIErrorManager`.

        The project **does import the GoogleGenerativeAI SDK**, but this SDK is **not** used for image generation—only for text generation. The SDK import is retained for potential future use with image APIs, but the primary integration method for illustrations is via direct REST API calls.
-   **Testing:** **Swift Testing framework** (`@Test`, `#expect`, etc.) is used for unit and integration tests, complemented by **improved mocking strategies**.

## Development Environment
-   **IDE:** Xcode (latest version)
-   **Build System:** Xcode Build System
-   **Dependency Management:** Swift Package Manager (SPM) for external libraries (like GoogleGenerativeAI).
-   **Version Control:** Git (repository likely hosted on GitHub).

## Key Libraries & Frameworks Used
-   **SwiftUI:** For UI, state management, and navigation.
-   **Foundation:** For core data types, networking (`URLSession`), `UserDefaults` (minor preferences), `ProcessInfo`, etc.
-   **GoogleGenerativeAI (Swift SDK):** For interacting with the Gemini Pro API (text generation). `StoryService` uses `GenerativeModelProtocol`. The SDK is imported in the project but **not** used for image generation in `IllustrationService`, which relies on direct REST API calls instead.
-   **SwiftData:** Integrated as the primary data persistence layer. Used with `@Model`, `@Query`, `ModelContext`, etc.
-   **Testing:** Swift's built-in testing framework (`Testing`) is used for unit and integration tests.
-   **XCTest:** Underlying framework for UI tests (`magical-storiesUITests`).

## Core Technical Patterns & Guidelines
-   **Architecture:** Follows MVVM principles loosely, heavily relying on SwiftUI's state management and the Repository pattern for data access. See `memory_bank/systemPatterns.md`.
-   **State Management:** Primarily uses `@StateObject`, `@EnvironmentObject`, `@State`, `@Binding`, `@AppStorage`, and `@Query` (for direct SwiftData observation in views).
-   **Asynchronous Operations:** `async/await` is mandatory for all network operations and data access. Views use `.task`.
-   **Error Handling:** Utilize Swift's native `do-catch` with custom `Error` enums. `AIErrorManager` handles AI errors. Provide user feedback via `.alert`.
-   **Navigation:** Use `TabView`, `NavigationStack`, `.sheet`, and `NavigationLink` / `.navigationDestination`. See `memory_bank/systemPatterns.md`.
-   **UI Guidelines:** Follow Apple HIG, use SF Symbols, consider SF Pro Rounded.
-   **Accessibility:** Implement basic VoiceOver and Dynamic Type support.
-   **Personalization:** Support Dark Mode, use `@AppStorage` for preferences.
-   **Text-to-Speech:** Feature removed.

## Build & Test Process
-   A script `run_tests.sh` exists to clean, build, and run unit and UI tests using `xcodebuild`.
-   `xcbeautify` formats test output.
-   Code coverage reports are generated.

## Configuration
-   API keys (`AppConfig.geminiApiKey`) are stored locally in `Config.plist` (gitignored) and accessed via `AppConfig.swift`.
-   The same `AppConfig.geminiApiKey` is used for both text and image generation.

## Swift Integration Testing Guidelines

(This section remains unchanged as it reflects current practices)

*   **File Naming:** `ServiceNameIntegrationTests.swift`.
*   **Imports:** `Testing`, `@testable import magical_stories`, `Foundation`.
*   **Integration Tag:** `extension Tag { @Tag static var integration: Self }`.
*   **Test Suite:** `@Suite("Descriptive Suite Name")`.
*   **Test Method Signature:** `@Test func testMethodName() async throws`.
*   **API Key/Secrets Management:** Prioritize environment variables (`TEST_SERVICE_API_KEY`), fallback to `AppConfig`, log source, handle `ConfigurationError`.
*   **Robust Error Handling:** Use `do-catch`, catch specific errors, log details (`print`, `Issue.record`), re-throw critical errors.
*   **Assertions:** Use `#require` for essential unwrapping, `#expect` for conditions.
*   **Resource Cleanup:** Perform cleanup within `do-catch`, use `try?` for non-critical cleanup, log cleanup errors.
*   **Logging:** Use `print` for flow visibility, `Issue.record` for significant events/non-fatal errors.
