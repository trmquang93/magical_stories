---
applyTo: '**'
---

# AI Assistant Self-Updating Rules for Software Projects

## Core Principles

1. **Primary Goal**: Assist effectively with software development while continuously improving through learned experiences.

2. **Code Quality**: Prioritize clean, maintainable, and well-documented code that follows project standards.

3. **Technical Accuracy**: Ensure all technical suggestions are accurate, efficient, and follow best practices.

4. **Adaptability**: Update this ruleset based on project-specific requirements, tech stack changes, and user feedback.

5. **Transparency**: Clearly communicate when and why rules are being updated.

## Project Context Learning

1. When learning about project architecture, document in the "Project Architecture" section.

2. When encountering codebase-specific patterns or conventions, add to "Code Conventions" section.

3. When identifying tech stack specifics and dependencies, update the "Tech Stack" section.

4. All project context updates must be timestamped and referenced to specific files or discussions.

## Development Workflow Learning

1. Document CI/CD practices and preferences in the "Development Pipeline" section.

2. Track testing methodologies and requirements in the "Testing Standards" section.

3. Record deployment processes and environments in the "Deployment" section.

4. Note code review standards and common feedback in the "Code Review" section.

## Update Mechanism

1. The assistant shall review this document after significant code changes or feedback sessions.

2. Updates should be proposed with reference to specific code, commits, or discussions.

3. User approval is required before permanently modifying core rules.

4. Technical clarifications and project-specific details may be updated autonomously.

## Project Architecture

- *This section will populate as the assistant learns about the project structure*

## Code Conventions

- *This section will populate as the assistant learns coding standards*

## Tech Stack

- *This section will populate with details about languages, frameworks, and tools*

## Development Pipeline

- *This section will document CI/CD practices*

## Testing Standards

- The `ModelContext` for testing is set up using an in-memory configuration. This involves:
  1. Defining a schema that includes the required models (e.g., `Story` and `Page`).
  2. Creating a `ModelContainer` with the schema and a configuration specifying in-memory storage (`isStoredInMemoryOnly: true`).
  3. Initializing the `ModelContext` with the `ModelContainer`.

- Example setup:
  ```swift
  let schema = Schema([Story.self, Page.self])
  let container = try! ModelContainer(
      for: schema, configurations: [.init(isStoredInMemoryOnly: true)]
  )
  let context = ModelContext(container)
  ```

## Deployment

- *This section will track deployment processes*

## Code Review

- *This section will document code review practices and common feedback*

## User Preferences

- *This section will track user-specific coding preferences*

## Performance Adjustments

- *This section will populate as performance feedback is received*

## Version History

- **V1.0** - Initial software project-focused ruleset created [Current Date]

---

*Note to future versions: This document serves as both a technical reference and learning journal. Maintain its integrity while allowing it to evolve with project experience.*