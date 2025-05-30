---
applyTo: '**'
---

# Active Context: Magical Stories

## Current Work Focus
✅ **COMPLETED:** Major prompting system refactoring using TDD methodology to eliminate code duplication and improve maintainability.

**UPCOMING:** Phase 2 enhancements (Combine integration, actor coordination) and comprehensive testing.

## Recent Changes
- **🎯 MAJOR: Prompting System Refactoring (Phase 1 Complete)**
  - **FluentPromptBuilder:** Implemented composable fluent API for type-safe prompt construction
    - Chainable methods: `.story()`, `.character()`, `.vocabulary()`, `.moral()`
    - Eliminated 300+ lines of duplicated prompt code
    - 18 comprehensive unit tests with 100% coverage
  - **AIGenerationStrategy:** Implemented strategy pattern for AI model selection
    - `GeminiTextStrategy`, `GeminiImageStrategy`, `ImagenStrategy` 
    - `AIStrategySelector` and `AICoordinator` for intelligent model routing
    - 12 comprehensive tests covering all strategies and error scenarios
  - **ConfigurablePromptTemplates:** External JSON-based template management
    - A/B testing support with template variants
    - Text-free enforcement system with multiple levels
    - Centralized template substitution system
    - 10 tests covering template loading and substitution
  - **Code Quality Improvements:**
    - Made protocols and structs public with proper access control
    - Fixed StoryParameters constructor signature consistency
    - Resolved mock declaration conflicts in test files
    - Maintained backward compatibility throughout refactoring

- Previous UI/Navigation Work:
  - Centralized navigation using `AppRouter` and `AppDestination` enum
  - Standardized `UITheme` design system implementation
  - Removed deprecated keyboard handling extensions

## Next Steps
- **Phase 2 Implementation:**
  - Implement Combine-based event system for reactive prompt updates
  - Add actor-based prompt coordination for better concurrency
- **Phase 3 Planning:**
  - Create type-safe prompt DSL with result builders
- **Testing & Integration:**
  - Ensure 100% test coverage across all new components
  - Integration testing with existing story generation flows
- **Performance Optimization:**
  - Profile prompt generation performance
  - Optimize AI model selection logic

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
