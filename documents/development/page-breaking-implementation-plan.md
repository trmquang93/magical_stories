# Page Breaking Implementation Plan

## Feature Description
Implement a mechanism to allow AI-generated stories to include explicit page breaks, enabling the application to display stories in a paginated format based on these breaks. Include fallback logic for pagination when no predefined page break symbols are present.

## Architectural Overview
- The existing `StoryProcessor` will be modified to include logic for pagination based on a specific delimiter and fallback to a default pagination method if the delimiter is not found.
- The `StoryService` will be modified to call the appropriate method in `StoryProcessor` after receiving the raw story text from the AI.
- The `PromptBuilder` will be updated to include instructions for the AI to use `---` as the page break delimiter.
- The association of illustrations with specific pages will be handled within the `StoryService` after the text has been paginated by the `StoryProcessor`.
- The existing `StoryPage` model is suitable for holding the content of each page.

## Technical Specification

### Component: `StoryProcessor`

- **Location:** `magical-stories/App/Services/StoryProcessor.swift`
- **Modification:** Add or modify a method to handle pagination, incorporating delimiter-based splitting with a fallback.
- **Method:**
    ```swift
    func paginateStory(_ content: String, delimiter: String = "---") -> [StoryPage]
    ```
- **Logic:**
    1. Check if the `content` contains the specified `delimiter`.
    2. If the delimiter is present:
        a. Split `content` by the `delimiter`.
        b. Iterate through the resulting substrings.
        c. For each substring, trim leading and trailing whitespace and newline characters.
        d. If the trimmed substring is not empty, create a `StoryPage` object with the trimmed content.
        e. Collect the created `StoryPage` objects into an array.
    3. If the delimiter is NOT present:
        a. Fallback to the existing pagination logic (e.g., splitting by character count or paragraph count as currently implemented in `StoryProcessor`).
        b. Generate `StoryPage` objects using this fallback method.
    4. Return the array of `StoryPage` objects.
- **Dependencies:** None.

### Component: `StoryService`

- **Location:** `magical-stories/App/Services/StoryService.swift`
- **Modification:** Update the method responsible for processing AI-generated text (e.g., `generateStory`).
- **Logic:**
    1. After receiving the raw story text from the AI.
    2. Instantiate or inject `StoryProcessor`.
    3. Call `let pages = storyProcessor.paginateStory(rawText, delimiter: "---")`.
    4. Assign the `pages` array to the `story.pages` property.
    5. Proceed with saving the story and associating illustrations (logic for illustration association with specific pages will need to be added here, potentially based on page index).
- **Dependencies:** Depends on `StoryProcessor`.

### Component: `PromptBuilder`

- **Location:** `magical-stories/App/Services/PromptBuilder.swift`
- **Modification:** Update the method that builds the prompt for story generation.
- **Logic:** Include clear instructions for the AI to insert the string `---` at desired page break locations in the generated story text.

## Implementation Roadmap

1.  **Phase 1: Modify `StoryProcessor`:**
    *   Update the `StoryProcessor` class to modify the existing pagination logic or add a new method that incorporates the delimiter-based splitting with a fallback to the default pagination if the delimiter is not found.
    *   Write unit tests for the updated/new pagination logic covering both delimiter-based splitting and the fallback mechanism, including edge cases (no delimiter, multiple delimiters, leading/trailing delimiters, empty components, very long text without delimiters).
2.  **Phase 2: Update `PromptBuilder`:**
    *   Modify `PromptBuilder` to include instructions for the AI regarding the `---` delimiter.
3.  **Phase 3: Modify `StoryService`:**
    *   Update `StoryService` to use the appropriate `StoryProcessor` method for pagination and assign the paginated results to the `StoryModel`.
    *   Update existing `StoryService` tests or add new integration tests to verify the interaction with `StoryProcessor`.
    *   Implement logic to associate illustrations with specific pages within `StoryService`.
4.  **Phase 4: End-to-End Testing:**
    *   Test the full flow by generating a story and verifying that it is correctly paginated in `StoryDetailView` under both scenarios (with and without the delimiter).

## Technical Risks
- The AI might not consistently use the `---` delimiter as instructed. Mitigation: The fallback logic directly addresses this risk by ensuring pagination still occurs even if the delimiter is absent.
- Illustration association with pages might be complex. Mitigation: Start with a simple approach, e.g., associating illustrations sequentially with pages. Refine based on testing and AI capabilities.