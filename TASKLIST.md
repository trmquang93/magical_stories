# Project Task List: Magical Stories

## Project Overview
Magical Stories is an iOS app that generates personalized stories with illustrations for children. The current focus is on implementing planned major features after completing the MVP and core illustration generation.
Objectives: Implement Growth Story Collections, StoreKit Integration, and SwiftData Migration.
Constraints: iOS 16+, Swift/SwiftUI, Google AI, UserDefaults (current), SwiftData (target).

## Progress Summary
- Started: 2025-04-09
- Current Phase: Collection Feature Completion
- Completed Tasks: Tasks 1-2.5, 3.1-3.2, 4-8
- Current Focus: Starting StoreKit Integration (Task S1)

## Task Breakdown

### Feature: Growth Story Collections (Priority: High)
- [X] **Task 1: Data Models** (Completed on 2025-04-09)
    - [X] Task 1.1: Define `GrowthCollection` struct/class (Properties: id, title, description, theme, targetAgeGroup, stories: [Story], progress: Float, associatedBadges: [String]?) (Completed on 2025-04-09)
    - [X] Task 1.2: Define `CollectionParameters` struct (Properties: childAgeGroup, developmentalFocus, interests, etc.) (Completed on 2025-04-09)
    - [X] Task 1.3: Define `Badge` or `Achievement` struct/class (Properties: id, name, description, iconName, unlockCriteria) (Completed on 2025-04-09)
    - [X] Task 1.4: Update `Story` model if necessary to link to a collection (e.g., `collectionId: UUID?`) (Completed on 2025-04-09)
- [X] **Task 2: Persistence (UserDefaults - Temporary)** (Started 2025-04-09)
    - [X] Task 2.1: Create `CollectionRepositoryProtocol`.
    - [X] Task 2.2: Implement `UserDefaultsCollectionRepository`
        - Note: All subtasks implemented within the single file.
    - [X] Task 2.3: Create `AchievementRepositoryProtocol`. (Completed on 2025-04-09)
    - [X] Task 2.4: Implement `UserDefaultsAchievementRepository` (methods for fetching/saving achievements/badges). (Completed on 2025-04-09)
    - [X] Task 2.5: Integrate repositories with existing `PersistenceService` or create a dedicated service setup. (Completed on 2025-04-09)
        - Note: Implemented dual-repository support in PersistenceService for both UserDefaults and SwiftData, with migration flag control.
- [X] **Task 3: AI Service Layer (`CollectionService`)**
    - [X] Task 3.1: Define `CollectionServiceProtocol`. (Completed on 2025-04-09)
        - Note: Defined comprehensive protocol with collection management, progress tracking, and achievement integration.
    - [X] Task 3.2: Implement `CollectionService`:
        - [X] Subtask 3.2.1: Define `generateCollection(parameters: CollectionParameters) async throws -> GrowthCollection` method. (Completed on 2025-04-09)
        - [X] Subtask 3.2.2: Implement AI-based collection generation logic. (Completed on 2025-04-10)
            - Defined expected AI JSON response structure (`AICollectionOutlineResponse`).
            - Implemented prompt building (`buildCollectionOutlinePrompt`).
            - Added AI call, JSON parsing, error handling, and retry logic to `generateCollectionOutline`.
        - [X] Subtask 3.2.3: Implement logic to call `StoryService` iteratively to generate full stories for the collection outline. (Completed on 2025-04-09 - Part of initial implementation)
        - [X] Subtask 3.2.4: Assemble the `GrowthCollection` object with generated stories. (Completed on 2025-04-09 - Part of initial implementation)
        - [X] Subtask 3.2.5: Handle errors using `AIErrorManager`. (Completed on 2025-04-09/2025-04-10)
- [X] **Task 4: UI - Collection Input Form**
    - [X] Task 4.1: Create `CollectionFormView` (SwiftUI View). (Completed 2025-04-10)
    - [X] Task 4.2: Add input fields/pickers for `CollectionParameters` (Age Group, Focus, Interests). (Completed 2025-04-10)
    - [X] Task 4.3: Add button to trigger collection generation via `CollectionService`. (Completed 2025-04-10)
    - [X] Task 4.4: Integrate `CollectionFormView` (e.g., presented as a sheet from `HomeView` or a dedicated tab). (Completed 2025-04-10)
- [X] **Task 5: UI - Displaying Collections**
    - [X] Task 5.1: Create `CollectionsListView` (SwiftUI View) to display available `GrowthCollection`s. (Completed 2025-04-10)
    - [X] Task 5.2: Design `CollectionCardView` (SwiftUI View) to show collection title, description, progress. (Completed 2025-04-10)
    - [X] Task 5.3: Integrate `CollectionsListView` into the app (e.g., new TabView item or section in `LibraryView`). (Completed 2025-04-10)
- [X] **Task 6: UI - Collection Detail View**
    - [X] Task 6.1: Create `CollectionDetailView` (SwiftUI View). (Completed 2025-04-10)
    - [X] Task 6.2: Display collection details (title, description, theme). (Completed 2025-04-10)
    - [X] Task 6.3: List stories within the collection. Allow navigation to `StoryDetailView`. (Completed 2025-04-10)
    - [X] Task 6.4: Display progress visually (e.g., progress bar). (Completed 2025-04-10)
    - [X] Task 6.5: Display associated badges (placeholder implementation). (Completed 2025-04-10)
- [X] **Task 7: Progress Tracking & Achievements**
    - [X] Task 7.1: Implement logic to update collection progress when a story within it is completed. (Completed 2025-04-10)
        - Added `collectionId` to `Story` struct.
        - Updated `CollectionService` to assign `collectionId`.
        - Added `handleStoryCompletion` in `StoryDetailView` to calculate and update progress via `CollectionService`.
    - [X] Task 7.2: Implement logic to check and award badges/achievements based on completion criteria. (Completed 2025-04-10)
        - Called `collectionService.checkAchievements` in `handleStoryCompletion`.
        - Added alert to display newly earned achievements.
    - [X] Task 7.3: Update relevant UI components to reflect progress and earned achievements. (Completed 2025-04-10)
        - Progress updates automatically via `@EnvironmentObject` observation.
        - Achievement display handled by alert (further UI refinement possible later).
- [X] **Task 8: Integration & Testing**
    - [X] Task 8.1: Inject `CollectionService` and repositories using `@EnvironmentObject`. (Completed 2025-04-10)
    - [X] Task 8.2: Write Unit Tests for new Models, Repositories, and Services using Swift Testing and mocking protocols. (Completed 2025-04-10)
        - Tested `CollectionService` (generation, progress, achievements).
        - Tested `StoryDetailView.handleStoryCompletion` logic.
        - Mocks created for dependencies.
    - [X] Task 8.3: Write Integration Tests for the collection generation flow. (Completed 2025-04-10)
        - Implemented `CollectionServiceIntegrationTests` with the following scenarios:
        - Scenario: Full generation success path with complete end-to-end flow.
        - Scenario: Generation with AI error handling and retry mechanism.
    - [X] Task 8.4: Write UI Tests for the new views and user flows. (Completed 2025-04-10)
        - Implemented `GrowthCollectionsUITests` with the following scenarios:
        - Scenario: Create Collection flow.
        - Scenario: View Collection Details flow.
        - Scenario: Complete Story within Collection flow.

### Feature: StoreKit Integration (Priority: Medium)
- [ ] Task S1: Setup StoreKit Configuration file.
- [ ] Task S2: Define Product Identifiers (e.g., premium subscription, collection unlock).
- [ ] Task S3: Implement `PurchaseService` (fetch products, purchase, restore purchases).
- [ ] Task S4: Implement `EntitlementManager` (check user entitlements).
- [ ] Task S5: Integrate with UI (e.g., "Go Premium" button, unlock collection button).
- [ ] Task S6: Update relevant services/views to check entitlements before granting access to premium features/collections.
- [ ] Task S7: Testing (Sandbox environment).

### Feature: Persistence Migration to SwiftData (Priority: Low/Medium)
- [ ] Task D1: Define SwiftData models (`@Model`) mirroring existing structs (Story, Page, GrowthCollection, etc.).
- [ ] Task D2: Implement `SwiftDataStoryRepository`.
- [ ] Task D3: Implement `SwiftDataCollectionRepository`.
- [ ] Task D4: Implement `SwiftDataAchievementRepository`.
- [ ] Task D5: Update `MagicalStoriesApp` setup to initialize SwiftData container and inject ModelContext.
- [ ] Task D6: Refactor Services and ViewModels to use `ModelContext` or the new SwiftData repositories.
- [ ] Task D7: Implement data migration logic from `UserDefaults` to SwiftData (if needed for existing users).
- [ ] Task D8: Update tests to work with SwiftData (potentially using in-memory context for testing).

## Next Steps
1. Complete Growth Collections feature review (Finalized 2025-04-10)
2. Begin StoreKit Integration (Task S1 - S2)
3. Progress to implementing `PurchaseService` and `EntitlementManager` (Tasks S3 - S4)

## Issues and Considerations
- Need to ensure proper error handling in AI generation - ADDRESSED in Tasks 3.2.5 and 8.3
- Consider caching strategies for generated content - Will review as part of performance optimization
- Plan for offline functionality - Will handle in separate task
- Consider performance optimization for large collections - Will address if needed after user testing
- The exact AI prompting strategy for generating a *collection* of stories needs careful design within `CollectionService` (Task 3.2.2) - IMPLEMENTED and TESTED
- Data migration from UserDefaults to SwiftData will require careful planning (Task D7) - Pending
- StoreKit testing requires setup with App Store Connect and Sandbox testers (Task S7) - Next focus area
- AI Prompt for collection generation needs monitoring and potential refinement - Initial implementation successful, will monitor in production 