# Technical Context: Magical Stories

## Core Technologies
-   **Language:** Swift (latest version preferred)
-   **UI Framework:** SwiftUI
-   **Platform:** iOS (targeting recent versions)
-   **Data Persistence:** SwiftData
-   **AI Service:** Google Generative AI (Gemini Pro) via its Swift SDK. API Key managed via `Configuration.swift` (not checked into Git).
-   **Testing:** Swift Testing framework (`@Test`, `#expect`, etc.)

## Development Environment
-   **IDE:** Xcode (latest version)
-   **Build System:** Xcode Build System
-   **Dependency Management:** Swift Package Manager (SPM) for external libraries (like GoogleGenerativeAI).
-   **Version Control:** Git (repository likely hosted on GitHub, based on `CHANGELOG.md` links).

## Key Libraries & Frameworks Used
-   **SwiftUI:** For UI, state management, and navigation.
-   **SwiftData:** For modeling and persisting `Story` data locally.
-   **Foundation:** For core data types, networking (potentially used by AI SDK), etc.
-   **GoogleGenerativeAI (Swift SDK):** For interacting with the Gemini Pro API to generate story content.
-   **Testing:** Swift's built-in testing framework.
-   **XCTest:** Underlying framework for UI tests (`magical-storiesUITests`).

## Build & Test Process
-   A script `run_tests.sh` exists to clean, build, and run unit and UI tests, likely using `xcodebuild`.
-   `xcbeautify` is used to format test output.
-   Code coverage reports are generated (though generation failed in the last test run due to build errors before they were fixed).

## Configuration
-   API keys (specifically `Configuration.geminiApiKey`) are stored locally, likely in a `Configuration.swift` file that is gitignored, to avoid committing secrets.
