# Plan: Enhance CollectionFormView to Match StoryFormView

**Objective:** Refactor `CollectionFormView.swift` to align its visual appearance, structure, and user experience with `StoryFormView.swift`, leveraging shared components and consistent styling patterns defined in the `Theme`.

**Target File:** `magical-stories-app/App/Features/Collections/CollectionFormView.swift`
**Reference File:** `magical-stories-app/App/Features/Home/StoryFormView.swift`
**Component File:** `magical-stories-app/App/Features/Collections/CollectionFormViewComponents.swift` (To be created or updated)

## Phase 1: Analysis & Component Identification

1.  **Analyze `StoryFormView.swift`:**
    *   Identify key UI patterns: Animated background (`backgroundView`), header (`FormHeader`), reusable form field components (`ChildNameField`, `CharacterField`, etc. from `StoryFormViewComponents.swift`), loading overlay (`LoadingOverlayView`), error handling (`.alert`), toolbar style (custom back button), use of `Theme` constants, `ScrollView` structure.
    *   Note the separation of concerns: View logic in `StoryFormView`, reusable UI elements in `StoryFormViewComponents.swift`.
2.  **Analyze `CollectionFormView.swift`:**
    *   Identify current structure: `NavigationView` wrapping a `Form`, standard SwiftUI controls (`Picker`, `ValidatedTextField`), custom loading overlay, `.alert` for errors, standard toolbar items.
    *   Note differences: Lack of animated background, fields not extracted into components, different loading overlay style, standard form layout vs. custom layout in `StoryFormView`.
3.  **Identify Gaps & Required Components:**
    *   **Background:** Need an animated gradient background similar to `StoryFormView`.
    *   **Layout:** Replace `Form` with `ScrollView` and `VStack` for custom layout control matching `StoryFormView`.
    *   **Header:** Need a header component similar to `FormHeader`.
    *   **Form Fields (New/Refactored Components):**
        *   `CollectionChildNameField`: Reusable component for child's name (potentially share/adapt `ChildNameField` from `StoryFormViewComponents`).
        *   `AgeGroupField`: Component for the segmented `AgeGroup` picker, styled according to `Theme`.
        *   `DevelopmentalFocusField`: Component for the `DevelopmentalFocus` menu picker, styled according to `Theme`.
        *   `InterestsField`: Component for the multi-line `interests` text field, incorporating validation display.
        *   `CharactersField`: Component for the optional `characters` text field (potentially share/adapt `CharacterField` from `StoryFormViewComponents`).
    *   **Loading Overlay:** Replace the existing overlay with a reusable `CollectionLoadingOverlayView` matching the style of `StoryFormView`'s overlay.
    *   **Generate Button:** Refactor the button into a dedicated `GenerateCollectionButton` component.
    *   **Toolbar:** Update the "Cancel" button to match the circular style used in `StoryFormView`.
    *   **Styling:** Consistently apply `Theme.Spacing`, `Theme.Colors`, `Theme.Fonts`.

## Phase 2: Implementation

1.  **Create/Update Component File:**
    *   Create `magical-stories-app/App/Features/Collections/CollectionFormViewComponents.swift`.
    *   Implement the new components identified above (`CollectionFormBackgroundView`, `CollectionFormHeader`, `AgeGroupField`, `DevelopmentalFocusField`, `InterestsField`, `CharactersField`, `GenerateCollectionButton`, `CollectionLoadingOverlayView`).
    *   Reuse/adapt components from `StoryFormViewComponents.swift` where applicable (e.g., potentially for name/character fields if styling is identical). Ensure any shared components are placed appropriately (e.g., in a shared `DesignSystem` folder if used across multiple features).
2.  **Refactor `CollectionFormView.swift`:**
    *   Replace the `NavigationView`'s content with a `ZStack`.
    *   Add the `CollectionFormBackgroundView` to the `ZStack`.
    *   Replace the `Form` with a `ScrollView` containing a `VStack`.
    *   Integrate the `CollectionFormHeader`.
    *   Replace existing form fields with the newly created reusable components from `CollectionFormViewComponents.swift`. Pass necessary bindings (`@State` variables) to these components.
    *   Replace the existing loading overlay logic with the new `CollectionLoadingOverlayView`.
    *   Replace the existing generate button with the `GenerateCollectionButton` component.
    *   Update the `.toolbar` modifier to use the styled circular "Cancel" button.
    *   Ensure `.alert` for error handling remains functional and consistent.
    *   Apply `Theme` constants for padding, spacing, fonts, and colors throughout the view and its components.
    *   Verify dark/light mode compatibility.
    *   Ensure all state management (`@State`, `@EnvironmentObject`, `@Environment(\.dismiss)`) and the `generateCollection` async function remain correctly wired.
    *   Maintain haptic feedback calls (`hapticSuccess`, `hapticError`).

## Phase 3: Testing & Verification

1.  **Unit/Snapshot Tests:**
    *   Update `CollectionFormView_Tests.swift` to reflect the new structure.
    *   Add tests (unit or snapshot, where applicable) for the new components in `CollectionFormViewComponents.swift`.
    *   Verify that state changes (e.g., loading, error) correctly update the UI via the new components.
2.  **UI Testing:**
    *   Update existing UI tests (`CollectionFormUITests.swift` if it exists) or create new ones to verify:
        *   Correct rendering in light/dark modes.
        *   Interaction with new form components.
        *   Display of the loading overlay.
        *   Display of error alerts.
        *   Successful navigation/dismissal.
3.  **Manual Testing:**
    *   Perform manual tests on a device/simulator to confirm:
        *   Visual fidelity matches `StoryFormView`.
        *   Form input and validation work as expected.
        *   Collection generation process (including loading and success/error states) functions correctly.
        *   Responsiveness and layout on different screen sizes.

## Phase 4: Documentation & Cleanup

1.  **Update Memory Bank:** If significant patterns were changed or established, update relevant Memory Bank documents (e.g., `systemPatterns.md`).
2.  **Code Comments:** Add/update comments where necessary for clarity.
3.  **Remove Old Code:** Delete any unused code from the previous `CollectionFormView` implementation.