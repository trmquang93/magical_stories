---
description: 
globs: 
alwaysApply: true
---
## Role
I am an expert software engineer with a unique characteristic: my memory resets completely between sessions. This isn't a limitation - it's what drives me to maintain perfect documentation. After each reset, I rely ENTIRELY on my Memory Bank to understand the project and continue work effectively.
## Memory Bank
- **The Memory Bank consists of core files and optional context files in Markdown format.** (High)

### Core Files (Required)
- `.roo/rules/projectbrief.md` — Foundation document defining core requirements and goals. (High)
- `.roo/rules/productContext.md` — Why this project exists and how it should work. (High)
- `.roo/rules/activeContext.md` — Current work focus and recent changes. Updated with T2 completion details. (High)
- `.roo/rules/systemPatterns.md` — System architecture and design patterns. (High)
- `.roo/rules/techContext.md` — Technologies used and development setup. (High)
- `.roo/rules/progress.md` — What works and what's left to build. Updated with T2 completion status. (High)

### Documentation Updates (Required)

- Update Memory Bank when discovering new project patterns. (High)
- Update after significant changes. (High)
- Update when user requests **update memory bank** (MUST review ALL files). (High)
- Update when context needs clarification. (High)
- **Always update project status after any code, logic, or documentation change, even minor or incremental.** (Critical)
- **Never** edit the mdc files. They are just a symbollink to original md files. Only update mentioned md files (Critical)

---

## General

- **REMEMBER:** After every memory reset, the Memory Bank is the only link to previous work. Maintain it with precision and clarity. (High)
- **Maintenance:** Update this file whenever a new rule or guideline is identified. (High)

### Permanent Memories

#### Technical Decisions
- **CollectionsListView Refactor (2025-04-16):**
  - CollectionsListView and CollectionCardView were reviewed and refactored for clarity, accessibility, and future integration.
  - .navigationDestination(for: StoryCollection.self) is now present in CollectionsListView's NavigationStack.
  - CollectionsListView is not yet integrated into the main UI; the collections list is still rendered directly in HomeView.
  - A new test file (CollectionsListView_Tests.swift) was created, providing basic test coverage for CollectionsListView (limited by SwiftUI testing constraints).
  - No duplication or conflicts found; code is ready for future tab integration (T6). 
  
- **UI & Snapshot Testing Standard (2025-04-16):**
  - Automated device-level UI tests (XCUITest) and pixel-perfect snapshot tests (SnapshotTesting) are implemented for LibraryView.
  - Snapshot tests are run for both light and dark mode, and on iPhone 11 size.
  - This is now a standard for all major UI features going forward.
  - Reference images are committed and reviewed on every UI change. 


- **Testing/Automation Pattern:** The project standardizes on using accessibility identifiers for UI elements that require automation. The `run_tests.sh` script supports both full and targeted test runs, and UI tests are used for end-to-end interaction verification when ViewInspector is not present.