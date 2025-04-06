# Technical Context: Magical Stories

## Core Technologies
-   **Language:** Swift (latest version preferred)
-   **UI Framework:** SwiftUI
-   **Platform:** iOS (targeting recent versions)
-   **Data Persistence:** `UserDefaults` via `PersistenceService` (MVP implementation). SwiftData is the likely long-term target.
-   **AI Service:**
    *   **Text Generation:** Google Generative AI (Gemini Pro) via its Swift SDK.
    *   **Image Generation (Planned):** Assumed Google AI Image Generation service/SDK.
-   **Testing:** Swift Testing framework (`@Test`, `#expect`, etc.)

## Development Environment
-   **IDE:** Xcode (latest version)
-   **Build System:** Xcode Build System
-   **Dependency Management:** Swift Package Manager (SPM) for external libraries (like GoogleGenerativeAI).
-   **Version Control:** Git (repository likely hosted on GitHub, based on `CHANGELOG.md` links).

## Key Libraries & Frameworks Used
-   **SwiftUI:** For UI, state management, and navigation.
-   **Foundation:** For core data types, networking, `UserDefaults`, etc.
-   **GoogleGenerativeAI (Swift SDK):** For interacting with the Gemini Pro API to generate story content.
-   **Google AI Image Generation SDK (Assumed/Planned):** For interacting with the image generation API.
-   **Testing:** Swift's built-in testing framework.
-   **XCTest:** Underlying framework for UI tests (`magical-storiesUITests`).

## Build & Test Process
-   A script `run_tests.sh` exists to clean, build, and run unit and UI tests, likely using `xcodebuild`.
-   `xcbeautify` is used to format test output.
-   Code coverage reports are generated.

## Configuration
-   API keys (specifically `Configuration.geminiApiKey` for text generation) are stored locally, likely in a `Configuration.swift` file that is gitignored, to avoid committing secrets.
-   A separate API key may be required for the planned Image Generation service, managed similarly.
