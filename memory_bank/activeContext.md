# Active Context (as of 2025-04-03)

## Current Focus
The primary focus of the recent work was the **removal of the native Text-to-Speech (TTS) functionality**.

## Changes Made
- **Removed `TextToSpeechService`:** The core service file (`TextToSpeechService.swift`) and its protocol (`TextToSpeechServiceProtocol`) were deleted.
- **Removed TTS Tests:** Associated unit tests (`TextToSpeechServiceTests.swift`) and relevant UI tests in `StoryDetailView_Tests.swift` were removed.
- **Updated UI:**
    - The audio controls overlay (play/pause, etc.) was completely removed from `StoryDetailView.swift`.
    - Text highlighting functionality during speech was removed.
- **Updated App Initialization:** `MagicalStoriesApp.swift`, `RootView.swift`, and `MainTabView.swift` were updated to remove the initialization and injection of the TTS service.
- **Documentation Updated:** `CHANGELOG.md` and `documents/App-structure.md` were updated to reflect the removal.

## Reason for Change
The TTS functionality was permanently removed to streamline the application architecture and focus development efforts on core story generation and visualization features. This architectural change allows for a more focused user experience centered on visual storytelling.

## Next Steps (Potential)
- Implement story illustration generation to enhance the visual experience.
- Further refine the UI/UX of the story reading interface.
- Develop themed story collections based on developmental goals.
