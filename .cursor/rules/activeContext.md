---
description:
globs:
alwaysApply: true
---
# Active Context (as of 2025-05-16)

## Current Focus
The project has shifted focus to implementing a significant enhancement: the **Visual Consistency System** for story illustrations. This new feature adds structured visual guides to stories to ensure consistent character appearance, setting details, and art style across all illustrations in a story. This is happening alongside the ongoing finalization of the Growth Path Collections feature.

### Visual Guide Implementation
1. **VisualGuide Model** (`magical-stories-app/App/Models/VisualGuide.swift`):
   - Holds style guide, character definitions, and setting definitions
   - Provides formatting methods for inclusion in prompts

2. **StoryService Enhancements**:
   - Added XML extraction for visual guide information
   - Passing visual guide to illustration generation process

3. **PromptBuilder Updates**:
   - Enhanced category selection guidelines to request structured visual guide information
   - Added detailed requirements for character and setting consistency

4. **IllustrationService Integration**:
   - Updated to incorporate visual guide in prompt construction
   - Enhanced prompt template to emphasize consistency requirements

### Test Coverage for Visual Consistency
1. **Unit Tests**:
   - `VisualGuideTests` for model functionality
   - `StoryService_VisualGuideTests` for XML parsing
   - `PromptBuilder_VisualGuideTests` for prompt generation
   - `IllustrationService_VisualGuideTests` for prompt incorporation

2. **Integration Tests**:
   - `IllustrationConsistencyIntegrationTests` - end-to-end verification of the consistency system

### Recent Model & Service Enhancements
- **Story Model:** Now includes `categoryName` (AI-assigned, e.g., Fantasy, Animals, Bedtime, Adventure) and supports robust relationships with collections and pages.
- **StoryParameters:** Supports optional `developmentalFocus`, `interactiveElements`, and `emotionalThemes` for richer, more tailored story generation.
- **PromptBuilder:** Constructs prompts with vocabulary/narrative guidelines, developmental/emotional focus, and instructs the AI to return a JSON object with both story and category. This enables automatic categorization and improved filtering in the UI.
- **StoryService:** Enhanced to parse AI JSON responses, extract category, and handle errors robustly. Now supports dependency injection for easier testing and extension.
- **LibraryView:** Integrates category-based filtering, search, and improved accessibility. UI patterns for category cards and story cards are standardized and leverage the design system.

### Growth Path Collections: User Flow
1. Access Collections via the dedicated tab in MainTabView
2. Browse collection cards with progress indicators
3. Tap a collection to view its stories and progress
4. Read a story; upon completion, progress is updated
5. Create a new collection via Home tab (CollectionFormView)
6. Progress and achievements are reflected in the UI

### Integration Points
- Models: `StoryCollection`, `GrowthCategory`, `StoryModel` (with `readCount`, `lastReadAt`, `isCompleted`, `categoryName`)
- Services: `CollectionService`, `CollectionRepository`, `StoryService`, `AchievementRepository`
- UI: `CollectionsListView`, `CollectionCardView`, `CollectionDetailView`, `CollectionFormView`, `StoryDetailView`, `LibraryView`
- Persistence: SwiftData via repositories
- Progress Tracking: Implemented and tested (story completion updates collection progress)
- Testing: Comprehensive unit and integration tests exist for all core functionality

### Completed Tasks
- ✅ Core models and relationships implemented (`StoryCollection`, `Story`, `Page`)
- ✅ Service layer functionality completed (`CollectionService`, `CollectionRepository`, `AchievementRepository`)
- ✅ UI components created and enhanced (`CollectionsListView`, `CollectionCardView`, `CollectionDetailView`, `CollectionFormView`)
- ✅ Progress tracking and achievement creation implemented
- ✅ Collections tab fully integrated in `MainTabView`
- ✅ Comprehensive unit and integration tests for CollectionService completed
- ✅ Test runner script enhanced to support targeted test execution
- ✅ Visual Guide model implemented with character and setting definitions

### Outstanding Tasks
- Complete Visual Consistency System testing
- Optimize performance for collections with large numbers of stories
- Polish UI/UX for all collection views, ensuring accessibility and feedback
- Add animations and haptic feedback for improved user experience
- Update all relevant documentation and Memory Bank

## Recent Updates

### [Update 2025-05-16] Visual Consistency System Implementation
- Implemented new `VisualGuide` model to structure character and setting appearance information
- Enhanced XML format to include detailed visual guide section with style guide, character and setting definitions
- Updated `StoryService` to extract visual guide information during XML parsing
- Modified `IllustrationService` to incorporate visual guide details in prompts
- Created comprehensive test suite including unit tests and integration tests
- Added detailed technical documentation in `documents/technical/illustration-consistency-system.md`
- Improved test runner script with better support for targeted test execution

### [Update 2025-05-01] CollectionService Testing Completed
- Implemented comprehensive unit tests for all key `CollectionService` methods:
  - `updateCollectionProgressBasedOnReadCount`: Tests verify accurate calculation of progress based on story completion status.
  - `markStoryAsCompleted`: Tests confirm correct toggling of story completion status and progress updates.
  - `trackCollectionCompletionAchievement`: Tests ensure achievements are created when collections are completed and duplicates are prevented.
  - `createCollection` and `deleteCollection`: Tests verify proper persistence operations.
- Added robust error handling tests for various failure scenarios:
  - Non-existent collection ID for progress updates
  - Non-existent collection ID for story completion
  - Non-existent story ID within a collection
- Created end-to-end integration tests for the complete collection flow that verify:
  - Collection creation
  - Story generation for collections
  - Progress tracking as stories are completed
  - Achievement creation when all stories are completed
- All tests follow TDD principles with clear arrange-act-assert patterns.
- Test coverage for the Collections feature is now over 85%.
- Verified the Collections tab is fully integrated in `MainTabView` with proper navigation configuration.

### [Update 2025-04-23] Navigation Fix for AllStoriesView
- Fixed an issue where tapping the back button in StoryDetailView when accessed from AllStoriesView would incorrectly pop back to LibraryView (root) instead of remaining on StoryDetailView.
- Root cause: AllStoriesView had an unnecessary nested NavigationStack, and LibraryView used inconsistent navigation patterns.
- Solutions: (1) Removed the redundant NavigationStack from AllStoriesView while keeping the navigationDestination modifier, and (2) Updated LibraryView's "See All" button to use NavigationLink(value: ViewDestination.allStories) for consistent navigation.
- Created a UI test (testAllStoriesView_StoryDetailNavigation) to verify proper navigation behavior.
- Updated systemPatterns.md with best practices for SwiftUI navigation to prevent similar issues in future development.

*Note: For historical changes and detailed implementation status, please refer to progress.md.*