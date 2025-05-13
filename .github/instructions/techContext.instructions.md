---
applyTo: '**'
---

# Tech Context: Magical Stories

## Technologies Used
- **Programming Language:** Swift
- **UI Framework:** SwiftUI
- **Persistence:** SwiftData, UserDefaults (for simple settings)
- **AI:** Google AI (Gemini Pro for text, Imagen for illustrations via REST API)
- **In-App Purchases:** StoreKit 2
- **Testing:** Swift Testing (unit/integration), XCTest (UI tests), SnapshotTesting (for UI snapshot tests).
- **Dependency Management:** Swift Package Manager

## Development Setup
- **IDE:** Xcode
- **Version Control:** Git, hosted on GitHub.
- **CI/CD:** Configured (details in `documents/ops/deployment.md` and `buildServer.json`). The `run_tests.sh` script is used for executing tests.

## Technical Constraints
- iOS platform only.
- Relies on network connectivity for AI-powered generation and potentially for StoreKit operations.

## Dependencies
- **Google Generative AI Swift SDK:** For interacting with Gemini Pro.
- **ViewInspector:** For SwiftUI view testing.
- **Swift Snapshot Testing:** For pixel-perfect UI snapshot tests.
(See `project.pbxproj` for specific versions and other potential dependencies).

## Tool Usage Patterns
- **Accessibility Identifiers:** Used for UI elements to support UI automation.
- **`run_tests.sh`:** Script for running all or targeted tests. Supports running single test files with format: `./run_tests.sh TestTarget/TestClass` (e.g., `./run_tests.sh magical-storiesTests/IllustrationTaskRecoveryTests`).

## Design System
- **UITheme:** Central design system implementation with standardized colors, spacing, typography, and gradients.
- **Component Library:** Reusable UI components like `LoadingOverlayView`, `EnhancedFormComponents`, and styled form elements.
- **Consistent Styling:** Application-wide consistent use of spacing, padding, and visual elements.
