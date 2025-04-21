# App Structure: Magical Stories

## Main Navigation
- **TabView** with the following tabs:
  - Home
  - Library
  - Collections (Growth Path Collections)
  - Settings

## Growth Path Collections Integration
- **Collections Tab:**
  - Hosts `CollectionsListView` within a `NavigationStack`.
  - Each collection is displayed as a `CollectionCardView`.
  - Tapping a card navigates to `CollectionDetailView` (shows stories and progress).
  - Tapping a story navigates to `StoryDetailView` (paginated reading).
  - Progress is tracked and updated as stories are completed.
  - "Create Collection" is initiated from HomeView, presenting `CollectionFormView` as a sheet.
  - **Delete Collection:** Users can delete a collection by swiping left on a collection in the Collections tab (swipe-to-delete UI).

## User Flow (Growth Path Collections)
1. User taps "Collections" tab to view all collections.
2. User browses collection cards with progress indicators.
3. User taps a collection to view its stories and progress.
4. User reads a story; upon completion, progress is updated.
5. User can create a new collection via the Home tab.
6. User can delete a collection by swiping left on a collection card in the Collections tab.
6. Progress and achievements (planned) are reflected in the UI.

## Outstanding Tasks for Growth Path Collections
- Ensure Collections tab is present and fully integrated in `MainTabView`.
- Finalize navigation and destination logic for all collection-related views.
- Complete end-to-end and edge case testing for the full user flow.
- Implement (optional) achievement/badge logic and UI.
- Update all relevant documentation and Memory Bank after each change.

## Final UI/UX Polish & Accessibility (Pre-Release Phase)
- Polish UI/UX for all collection views, ensure accessibility and feedback
- Add animations or haptic feedback for progress/achievements (if feasible)
- Perform final accessibility audit and visual refinement

## Related Files
- `App/Features/Collections/CollectionsListView.swift`
- `App/Features/Collections/CollectionCardView.swift`
- `App/Features/Collections/CollectionDetailView.swift`
- `App/Features/Collections/CollectionFormView.swift`
- `App/Features/Library/StoryDetailView.swift`
- `App/Services/CollectionService.swift`
- `App/Services/CollectionRepository.swift`
- `magical-storiesTests/Views/CollectionDetailView_Tests.swift`
- `magical-storiesTests/Views/CollectionsListView_Tests.swift`
- `magical-storiesTests/Views/StoryReadingIntegrationTests.swift`

## View Hierarchy (Simplified)

MagicalStoriesApp
└── RootView
    └── MainTabView
        ├── HomeView
        ├── LibraryView
        ├── CollectionsListView ← **NEW TAB**
        └── SettingsView

## Notes
- CollectionsListView is no longer only accessible from HomeView; it is now a dedicated tab.
- This change enables direct UI testing and incremental development of Growth Collections features.

### IllustrationService (2025-04-20 Update)
- Now uses Gemini 2.0 multimodal API for illustration generation.
- Sends previous page's image as inline_data for context when available.
- Falls back to text-only prompt for first page or missing image.
- Legacy Imagen API is retained for single-image mode or as a fallback.
- Improved error handling and response parsing for multimodal output. 