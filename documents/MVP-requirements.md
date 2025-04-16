# MVP Requirements: Magical Stories

## Core MVP Features (Updated)
- Personalized single story generation (StoryFormView, StoryService, Google AI integration)
- Story Library (LibraryView, persistent storage via SwiftData)
- Story Reading (StoryDetailView, paginated, progress bar)
- Parental Controls (SettingsView, content filtering, screen time)
- Illustration Generation (AI-powered, per page)
- **Growth Path Collections (NEW):**
  - Themed, developmentally-focused sets of stories
  - Progress tracking per collection and story
  - Dedicated Collections tab in main navigation
  - Collection creation flow (form, AI story generation)
  - UI for browsing, detail, and reading
  - (Planned) Achievements/badges for progress

## Growth Path Collections: User Flow
1. User taps "Collections" tab to view all collections
2. User browses collection cards with progress indicators
3. User taps a collection to view its stories and progress
4. User reads a story; upon completion, progress is updated
5. User can create a new collection via the Home tab
6. Progress and achievements (planned) are reflected in the UI

## Outstanding Tasks for Growth Path Collections
- Ensure Collections tab is present and fully integrated in `MainTabView`
- Finalize navigation and destination logic for all collection-related views
- Complete end-to-end and edge case testing for the full user flow
- Polish UI/UX for all collection views, ensuring accessibility and feedback
- Implement (optional) achievement/badge logic and UI
- Update all relevant documentation and Memory Bank after each change

## Testing & Validation
- End-to-end tests for collection creation, story reading, and progress tracking
- UI/UX validation for accessibility and feedback
- Test coverage for all new logic and UI

## Documentation
- All changes and new patterns must be reflected in project documentation and Memory Bank

- [x] CollectionsListView is integrated as a dedicated tab in MainTabView, enabling direct access to Growth Collections and supporting UI testing and incremental development. 