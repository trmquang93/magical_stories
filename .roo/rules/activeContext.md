---
description:
globs:
alwaysApply: true
---
# Active Context (as of 2025-04-16)

## Current Focus
The primary focus remains on **implementing the Growth Collections feature**. Core models and services are in place. Recent work involved reviewing existing UI components and refining the implementation plan.

### [Update 2025-04-16] Step T2 Complete: Refactor and Enhance CollectionDetailView
- CollectionDetailView was refactored to use `@Bindable` for more reactive state management.
- The deprecated `toggleStoryCompletion` function and button were removed as progress should be based on reading stories.
- UI now uses `Story.isCompleted` for the completion indicator instead of the non-existent `readCount` property.
- Added a `storyRow` helper function to resolve type-checking performance issues in complex SwiftUI views.
- Added `.navigationDestination(for: Story.self)` with a placeholder for StoryDetailView.
- Created `CollectionDetailView_Tests.swift` with tests that verify collection data, progress values, and state updates.
- Test suite follows best practices for testing SwiftUI views, focusing on model state validation.
- Next step (T3) will focus on enhancing `CollectionService` logic for better integration with the progress tracking flow.
  
### [Update 2025-04-16] Step T1 Complete: Finalize CollectionsListView Integration
- CollectionsListView and CollectionCardView were reviewed and refactored for clarity, accessibility, and future integration.
- .navigationDestination(for: StoryCollection.self) is now present in CollectionsListView's NavigationStack.
- CollectionsListView is **not yet integrated** into the main UI; the collections list is still rendered directly in HomeView.
- A new test file (CollectionsListView_Tests.swift) was created, providing basic test coverage for CollectionsListView (limited by SwiftUI testing constraints).
- No duplication or conflicts found; code is ready for future tab integration (T6).

1.  **Growth Collections:** Implementation ongoing.
    *   Core models (`StoryCollection`, `GrowthCategory`), repository (`CollectionRepository`), and service (`CollectionService`) created.
    *   Basic UI views (`CollectionsListView`, `CollectionCardView`, `CollectionDetailView`, `CollectionFormView`) exist.
    *   `HomeView` integrates the "Create Collection" button and `CollectionFormView`.
    *   `CollectionFormView` handles input and triggers collection creation and initial story generation via `CollectionService`.
    *   `CollectionsListView` uses `@Query` for data fetching.
    *   `CollectionCardView` displays `completionProgress`.
    *   `CollectionDetailView` displays stories but contains incorrect progress update logic that needs removal.
    *   Navigation uses `NavigationLink(value:)`.
    *   Progress tracking relies on `StoryModel.readCount` and `StoryCollection.completionProgress`.
    *   Refined plan created (see Next Steps).
2.  **StoreKit Integration:** Detailed design completed, awaiting implementation after Growth Collections.
3.  **UI/UX Refinement:** Upcoming focus.
4.  **Accessibility Improvements:** Upcoming focus.

## Recent Changes (Completion & Verification)

*   **Growth Collections Code Review & Plan Refinement:**
    *   Reviewed `CollectionsListView`, `CollectionCardView`, `CollectionDetailView`, `CollectionFormView`, and `StoryDataModels.swift`.
    *   Confirmed `CollectionsListView` uses `@Query`.
    *   Confirmed `CollectionCardView` displays `completionProgress`.
    *   Identified incorrect progress update logic (`toggleStoryCompletion` using non-existent `isCompleted` property) in `CollectionDetailView` for removal.
    *   Confirmed `CollectionFormView` correctly triggers `collectionService.createCollection` and `collectionService.generateStoriesForCollection`.
    *   Confirmed `StoryModel` uses `readCount` and `lastReadAt` for progress.
    *   Refined the implementation plan based on these findings.

*   **Growth Collections Initial Setup:**
    *   Implemented `StoryCollection` model with SwiftData integration.
    *   Created `GrowthCategory` enum.
    *   Developed `CollectionService` with basic CRUD operations.
    *   Defined relationship between `Story` and `StoryCollection` models.
    *   Added "Create Collection" button action in `HomeView.swift`.
    *   Integrated `CollectionFormView` with `CollectionService`.
    *   Updated `HomeView` preview provider.

*   **T1: Finalize CollectionsListView Integration (Complete):**
    *   Refactored `CollectionsListView` and `CollectionCardView` for clarity and accessibility.
    *   Ensured navigation destination is present in `CollectionsListView`.
    *   Created `CollectionsListView_Tests.swift` for basic test coverage.
    *   Documented that `CollectionsListView` is not yet integrated into the main UI.

*   **Google AI Integration Verified:** (No changes since last update)
    *   Confirmed API key usage.
    *   Verified image generation model.
    *   Validated response parsing.

*   **IllustrationService Implementation Completed:** (No changes since last update)
    *   Uses direct REST API calls.
    *   Detailed prompts, retry logic, error handling via `IllustrationError` and `AIErrorManager`.
    *   Saves images to persistent storage.
    *   Fully integrated.

*   **Testing Strategy Implemented:** (No changes since last update)
    *   Improved mocking, migrated tests to Swift Testing.
    *   Increased coverage.

*   **Story Saving & UI Refresh Fixes:** (No changes since last update)
    *   Fixed async timing bug.
    *   Stories appear immediately in LibraryView.

*   **Migration Cleanup:** (No changes since last update)
    *   Removed UserDefaults migration logic/tests.

## Next Steps (Refined Growth Collections Plan)

**T2: Refactor and Enhance `CollectionDetailView`**
*   ST-2.1: Review `CollectionDetailView` state management (`@State` vs. `@Bindable`/observation). (S)
*   ST-2.2: Verify Story List Display. (S)
*   ST-2.3: Ensure `.navigationDestination(for: StoryModel.self)` is correctly placed. (S)
*   ST-2.4: Verify Progress Display updates correctly. (S)
*   ST-2.6: Remove `toggleStoryCompletion` function and button. (S)
*   ST-2.5: Write/Update Tests for `CollectionDetailView`. (M)

**T3: Enhance `CollectionService` Logic**
*   ST-3.1: Implement `generateStoriesForCollection` logic. (L)
*   ST-3.2: Implement `updateCollectionProgress` based on `readCount`. (M)
*   ST-3.3: Implement Achievement/Badge Logic (Optional). (M)
*   ST-3.4: Write/Update Tests for `CollectionService`. (L)

**T4: Finalize `CollectionFormView` Integration**
*   ST-4.3: Verify Loading/Error State Handling in `CollectionFormView` & hosting view. (M)
*   ST-4.4: Write/Update Tests for `CollectionFormView` Integration. (M)

**T5: Implement Progress Tracking Flow**
*   ST-5.1: Update `StoryModel.readCount`/`lastReadAt` on story completion. (M)
*   ST-5.2: Notify `CollectionService.updateProgress` after `StoryModel` update. (S)
*   ST-5.3: Verify UI reflects progress updates. (S)
*   ST-5.4: Implement Achievement/Badge UI (Optional). (M)
*   ST-5.5: Write Tests for Progress Tracking Integration. (M)

**T6: Integrate Collections into Main Navigation (Complete)**
- CollectionsListView is now a dedicated tab in MainTabView.
- Users can access Growth Collections directly from the main navigation.
- All tests pass, and documentation is updated to reflect this change.
- This enables direct UI testing and supports incremental development of Growth Collections features.

**T7: Final Testing and Refinement**
*   ST-7.1: End-to-End Testing. (M)
*   ST-7.2: UI/UX Refinement. (M)
*   ST-7.3: Final Test Suite Run. (S)
