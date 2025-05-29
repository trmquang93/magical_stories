---
applyTo: '**'
---

# System Patterns: Magical Stories

## Architecture
- **MVVM (Model-View-ViewModel):** The primary architectural pattern, separating UI (View), presentation logic and state (ViewModel), and data and business logic (Model).
- **SwiftUI:** Used for declarative UI development.
- **Service Layer:** Encapsulates business logic, AI interactions, and other core functionalities (e.g., `StoryService`, `IllustrationService`, `CollectionService`, `PurchaseService`).
- **Repository Pattern:** Abstracts data access, decoupling services from the persistence mechanism (e.g., `StoryRepository`, `SettingsRepository`).
- **Dependency Injection:** Utilized for managing dependencies, primarily through `@EnvironmentObject` and initializer injection.
- **Centralized Navigation:** Using `AppRouter` to manage navigation paths across different tabs, with `AppDestination` enum providing type-safe navigation destinations.

## Key Technical Decisions
- **SwiftData:** Primary persistence solution for core application data.
- **Google AI (Gemini Pro & Imagen):** Used for text and illustration generation.
- **StoreKit 2:** For handling in-app purchases and subscriptions.
- **Swift Testing & XCTest:** For unit, integration, and UI testing.

## Design Patterns
- **Strategy Pattern:** `AIGenerationStrategy` with implementations for different AI models (`GeminiTextStrategy`, `GeminiImageStrategy`, `ImagenStrategy`).
- **Builder Pattern:** `FluentPromptBuilder` provides composable, chainable API for prompt construction.
- **Template Method:** `ConfigurablePromptTemplates` with external JSON configuration and A/B testing support.
- **Singleton:** For global services like `IllustrationTaskManager`, `AppRouter`, and `ConfigurablePromptTemplates.shared`.
- **Observer:** `@Published` properties in `ObservableObject` classes to notify views of state changes.
- **Coordinator:** `IllustrationCoordinator` manages illustration task restoration and processing; `AICoordinator` manages AI strategy selection.
- **Router Pattern:** `AppRouter` centralizes navigation logic and state across the application.
- **Factory Pattern:** `ViewFactory` creates views for navigation destinations.

## Component Relationships
- **Views** observe **ViewModels** (or service objects acting as such) for state changes.
- **ViewModels/Services** interact with **Repositories** for data access.
- **Repositories** interact with **SwiftData** or other persistence mechanisms.
- **Services** interact with external APIs (e.g., Google AI, StoreKit).

## Critical Implementation Paths
- **Story Generation Flow (Refactored):** 
  - User input -> `FluentPromptBuilder` -> `AICoordinator` strategy selection -> `GeminiTextStrategy` execution -> Story processing -> Display
- **Illustration Generation Flow (Refactored):**
  - Story content -> `AICoordinator` -> `ImagenStrategy` or `GeminiImageStrategy` based on complexity -> Image processing -> Display
- **Prompt Template Management:**
  - `ConfigurablePromptTemplates.shared` -> JSON template loading -> A/B testing selection -> Template substitution -> Final prompt
- **Growth Collection Management:** Creation, progress tracking, display, and deletion of collections.
- **In-App Purchase Flow:** Product display -> Purchase initiation -> Transaction handling -> Entitlement management.
