# Plan: Implement Story Categories

**Version:** 2.0
**Date:** 2025-04-24
**Author:** AI Assistant

---
**Changelog:**
- v2.0 (2025-04-24): Updated to assign story category via AI prompt, based on story content, with the AI returning both the story and the category in a JSON object. Removed all post-processing/keyword-based assignment logic from the plan.

## 1. Goal
Integrate a category system for stories, allowing users to browse stories by category in `LibraryView`. Categories are now assigned by the AI model based on the full story content, using the app's predefined set of categories, and returned as part of the story generation response.

## 2. Background
`LibraryView` displays hardcoded category cards (`LibraryCategoryCard`) with story counts calculated dynamically. Previously, categories were assigned by keyword matching on the theme. Now, the AI will analyze the generated story and select the most appropriate category from the allowed set, returning it alongside the story content.

## 3. Assumptions
- Categories remain hardcoded as defined in `LibraryView.swift`.
- The AI will be instructed to select a single category from the allowed set, based on the story content.
- The AI will return a JSON object with two fields: `story` (the full story text) and `category` (the selected category name).
- If the AI cannot determine a category, it will return `null` or an empty string for `category`.

## 4. Implementation Plan

### Task 1: Update Data Model (`StoryModels.swift`)
- **Objective:** Add a persistent `categoryName` property to the `Story` model.
- **Details:**
    - Add `var categoryName: String?` to the `Story` class definition within `StoryModels.swift`.
    - Update the `init` method to include the optional `categoryName`.
    - Update `CodingKeys`, `init(from:)`, and `encode(to:)` to handle the new property.
    - Add the new property to the convenience initializer if necessary.
    - Add the property to the `previewStory` static function for testing/previews.
- **Files:** `magical-stories/App/Models/StoryModels.swift`

### Task 2: Update PromptBuilder to Request Category from AI
- **Objective:** Modify the story generation prompt to instruct the AI to analyze the story and select a category from the allowed set.
- **Details:**
    - Extract the list of allowed categories (names) from `libraryCategories` in `LibraryView.swift` (or move to a shared constants file).
    - In `PromptBuilder.buildPrompt(parameters:)`, append instructions:
        - List the allowed categories by name.
        - Instruct the AI to analyze the full story and select the most appropriate category.
        - Instruct the AI to return a JSON object with two fields: `story` (the full story text, with page breaks as before) and `category` (the selected category name).
    - Example prompt addition:
        ```
        After writing the story, analyze its content and select the single most appropriate category from this list:
        [Fantasy, Animals, Bedtime, Adventure]
        Return your response as a JSON object with two fields:
        {
          "story": "<full story text with page breaks as before>",
          "category": "<selected category name from the list above>"
        }
        ```
- **Files:** `magical-stories/App/Services/PromptBuilder.swift`

### Task 3: Update Story Creation Flow (`StoryService.swift`)
- **Objective:** Parse the AI's JSON response and assign the returned category to the new story.
- **Details:**
    - In `StoryService.generateStory`, after receiving the AI response:
        - Parse the JSON to extract both the story content and the category.
        - Set the returned value to the `story.categoryName` property.
    - Ensure the `Story` object saved by `PersistenceService` includes the assigned `categoryName`.
    - Add error handling for invalid/missing category values.
- **Files:** `magical-stories/App/Services/StoryService.swift`

### Task 4: Update Library View (`LibraryView.swift`)
- **Objective:** Modify `LibraryView` to filter stories based on the selected category and enable interactive category cards.
- **Details:**
    - Add `@State private var selectedCategoryName: String? = nil` to `LibraryView`.
    - Modify `filteredStories`: If `selectedCategoryName` is not nil, filter `storyService.stories` to include only stories where `story.categoryName` matches `selectedCategoryName`. Apply search text filtering *after* category filtering.
    - Modify the `LazyVGrid` for `LibraryCategoryCard`:
        - Wrap each `LibraryCategoryCard` in a `Button` or add an `.onTapGesture`.
        - The action should set `selectedCategoryName = category.name`.
    - Add a "Clear Filter" or "All Stories" button/mechanism to set `selectedCategoryName = nil`. This could be near the category grid or integrated into the header.
    - Update the `categories` computed property: The `storyCount` calculation should now use the persistent `story.categoryName` instead of filtering by keywords dynamically.
        ```swift
        // Example update for storyCount
        let count = storyService.stories.filter { $0.categoryName == def.name }.count
        ```
    - Adjust UI styling to indicate the selected category (e.g., border, background change).
- **Files:** `magical-stories/App/Features/Library/LibraryView.swift`

### Task 5: Testing (TDD Approach)
- **Objective:** Ensure the category implementation works correctly and doesn't introduce regressions.
- **Details:**
    - **Model Tests:** Write tests in `StoryModels_Tests.swift` (or similar) to verify the `Story` model initializes correctly with `categoryName`.
    - **Service Tests:**
        - Write tests for the prompt construction to ensure the allowed categories are included and the instructions are clear.
        - Update tests in `StoryService_Tests.swift` to verify that `generateStory` correctly parses the AI's JSON response and assigns `categoryName` to the created `Story` object before saving. Use mocks for `PersistenceService` and AI responses.
    - **UI/Integration Tests:**
        - Update `LibraryView_Tests.swift` or UI tests (`magical-storiesUITests`) to:
            - Verify category counts are displayed correctly based on `categoryName`.
            - Verify tapping a category card filters the story list.
            - Verify clearing the filter shows all stories again.
            - Verify search works correctly in conjunction with category filters.
- **Files:** `magical-storiesTests/Models/*`, `magical-storiesTests/Services/*`, `magical-storiesTests/Views/*`, `magical-storiesUITests/*`

### Task 6: Data Migration (Optional - If needed)
- **Objective:** Assign categories to existing stories created before this change.
- **Details:**
    - Since `categoryName` is optional, existing stories will have `nil`.
    - Consider if a one-time migration is needed upon app launch to iterate through existing stories and assign `categoryName` by re-prompting the AI or using a fallback method. *Decision: Defer migration unless explicitly requested.*

### Task 7: Documentation Update
- **Objective:** Update project documentation to reflect the new category system.
- **Details:**
    - Update `documents/data/swift-data-schema.md` with the new `categoryName` field in the `Story` model.
    - Update `documents/Growth-Path-Stories.md` or relevant feature documents if categories impact other features.
    - Update `progress.md` with the status of this implementation.
    - Update `memory_bank/systemPatterns.md` if the category assignment introduces a notable pattern.
- **Files:** Relevant `.md` files in `documents/` and `.roo/rules/`.

## 5. Risks and Mitigation
- **Risk:** The AI may return an invalid or missing category, or a category not in the allowed set.
    - **Mitigation:** Add robust parsing and validation logic. If the category is invalid, set `categoryName` to `nil` and log the issue.
- **Risk:** Performance impact of filtering large numbers of stories in `LibraryView`.
    - **Mitigation:** Ensure SwiftData queries are efficient. If performance degrades, consider optimizing filtering logic or adding indices to `categoryName` in SwiftData (if supported/needed).
- **Risk:** UI complexity in `LibraryView` with filtering state.
    - **Mitigation:** Keep state management clear (`@State` for `selectedCategoryName`). Test UI interactions thoroughly.

## 6. Future Considerations
- Allow users to manually assign/change categories.
- Allow users to create custom categories.
- Support multiple categories per story.

## 7. Validation Criteria
- Stories created have a `categoryName` assigned by the AI based on their content.
- `LibraryView` displays correct story counts per category based on the persistent `categoryName`.
- Tapping a category card in `LibraryView` filters the displayed stories to that category.
- Searching works correctly alongside category filtering.
- All relevant tests pass.
- Documentation is updated.

---

**TODOs/Placeholders:**
- [ ] Move the allowed category names to a shared constants file if not already done, so they can be referenced in both the prompt and the UI.
- [ ] Update `PromptBuilder.buildPrompt(parameters:)` to include the new instructions and output format.
- [ ] Update `StoryService.generateStory` to parse the AI's JSON response and assign the category.
- [ ] Add error handling for invalid/missing category values in the AI response.
- [ ] Update all relevant tests and documentation as described above. 