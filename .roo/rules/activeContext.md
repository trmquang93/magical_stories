---
description: 
globs: 
alwaysApply: true
---
# Active Context (as of 2025-04-16)

## Current Focus
The primary focus is on **implementing Growth Collections feature** which has moved from planning to active development, with core models and services being implemented:
1.  **Growth Collections:** Implementation in progress - core models, repository and service layer have been created, with work continuing on UI components and integration.
2.  **StoreKit Integration:** Detailed design completed, awaiting implementation which will begin after Growth Collections feature is more mature.
3.  **UI/UX Refinement:** Upcoming focus on refining the story reading interface and overall user experience.
4.  **Accessibility Improvements:** Upcoming focus on enhancing accessibility features.

## Recent Changes (Completion & Verification)

*   **Growth Collections Implementation Started:**
    *   Implemented `StoryCollection` model with SwiftData integration.
    *   Created `GrowthCategory` enum with developmental categories.
    *   Developed `CollectionService` with basic CRUD operations.
    *   Defined relationship between `Story` and `StoryCollection` models.
    *   Started writing tests for collection-related functionality.
    *   Work continues on UI implementation and full integration.
    *   **Added "Create Collection" button action in `HomeView.swift` that toggles display of `CollectionFormView`.**
    *   **Integrated `CollectionFormView` with `CollectionService` via environment object injection.**
    *   **Updated `HomeView` preview provider to correctly initialize `CollectionService` with `CollectionRepository` using the SwiftData model context.**

*   **Google AI Integration Verified:**
    *   Confirmed correct API key (`GeminiAPIKey`) usage.
    *   Verified the image generation model (`gemini-2.0-flash-exp-image-generation`).
    *   Validated response parsing logic for the Gemini Flash API (handling `inlineData` base64 images).

*   **IllustrationService Implementation Completed:**
    *   Now primarily uses **direct REST API calls** to Google's Generative AI endpoint for image generation.
    *   Constructs **detailed prompts** emphasizing whimsical, child-friendly illustrations, explicitly instructing **not to depict anthropomorphic animals**.
    *   Implements **retry logic** with up to 5 attempts and 1-second delays between failures.
    *   Handles errors comprehensively via the `IllustrationError` enum.
    *   Successfully **saves generated images** to persistent storage at `Application Support/Illustrations/`.
    *   Logs errors through the `AIErrorManager`.
    *   Fully **integrated and operational** within the app's story generation flow.
    *   The SDK import remains, but the primary integration is now via REST API calls.

*   **Testing Strategy Implemented:**
    *   Successfully implemented improved mocking strategies (avoiding live API calls in unit tests).
    *   Migrated relevant tests to use Swift Testing framework.
    *   Increased overall test coverage, including integration tests.

*   **Story Saving & UI Refresh Fixes:**
    *   Fixed async timing and UI refresh bug in story saving flow.
    *   Implemented debug logging and error handling in `StoryService`.
    *   Stories now appear immediately after creation in LibraryView.

*   **Migration Cleanup:**
    *   Removed all UserDefaults to SwiftData migration logic.
    *   Deleted all related migration tests.
    *   Persistence now solely relies on SwiftData.

## Next Steps
1.  **Growth Collections:** Continue implementation with UI components and integration.
2.  **StoreKit Integration:** Begin implementation of `PurchaseService`, `EntitlementManager`, and related UI.
3.  **UI/UX Refinement:** Improve story reading interface and overall user experience.
4.  **Accessibility Improvements:** Enhance accessibility features.
