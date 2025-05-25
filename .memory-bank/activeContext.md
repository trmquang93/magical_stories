---
applyTo: '**'
---

# Active Context: Magical Stories

## Current Work Focus
Refactoring and enhancing the app's architecture and UI components for better maintainability and user experience.

## Recent Changes
- Refactored navigation structure to use `AppRouter` for managing tab and view navigation
  - Introduced `AppDestination` enum for type-safe navigation
  - Implemented an `AppRouter` class to manage navigation paths for each tab
  - Modified views to use the router instead of direct NavigationStack usage
  - Updated `StoryDetailView` to load story data based on storyID instead of passing the entire Story object
- Refactored UI theme system
  - Replaced old `Theme` with consistent `UITheme` usage across components
  - Standardized spacing, padding values, and gradient definitions
  - Enhanced color initialization with hex support
- Streamlined codebase
  - Removed keyboard handling extensions and related tests
  - Refactored scroll aware header transitions
  - Removed `AllStoriesView` and updated sorting logic

## Next Steps
- Complete testing of the new navigation system
- Address any edge cases in the UI theme refactoring
- Review error handling throughout the app
- Enhance performance in story and illustration generation workflows

## Active Decisions and Considerations
- Consolidating navigation logic into the `AppRouter` to simplify individual views and make navigation more predictable.
- Standardizing the design system through `UITheme` to ensure visual consistency and ease of maintenance.
- Streamlining the codebase by removing unused or redundant components, such as keyboard handling extensions.
- Transitioning from passing full model objects to using identifiers in navigation to reduce memory usage and improve state management.

## Important Patterns and Preferences
- Follow the Memory Bank structure and update protocols defined in `memory.instructions.md`.
- Adhere to Test-Driven Development (TDD) practices as defined in `tdd.instructions.md` for future coding tasks.
- Use the Router pattern for navigation through the `AppRouter` class.
- Consistently apply `UITheme` for all visual styling.
- Prefer ID-based navigation over passing full objects between views.
- Maintain documentation meticulously.

## Learnings and Project Insights
- The project is an iOS application called "Magical Stories."
- It uses SwiftUI, SwiftData, and Google AI for story and illustration generation.
- Key features include personalized story generation, a story library, growth collections, and parental controls.
- Monetization is planned via StoreKit 2.
- There's a strong emphasis on testing (unit, integration, UI, snapshot).
- The centralized navigation approach with `AppRouter` has significantly simplified navigation management.
- The consolidated design system with `UITheme` provides more consistent visual appearance and easier maintenance.
- ID-based navigation to StoryDetailView improves memory usage and state management.
- Built-in SwiftUI keyboard handling is preferred over custom keyboard management extensions.
