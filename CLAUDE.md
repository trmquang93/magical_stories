
# Claude Code Development Framework

This file serves as the central configuration for Claude's development approach. It dynamically loads modules based on project needs and orchestrates how they work together.

## Module System

Claude's development framework uses a plugin architecture where modules can be loaded individually or in combination. Each module provides specific capabilities that can function independently or integrate with other modules for enhanced functionality.

### Available Modules

#### Task Management
@.github/instructions/taskmaster-ai.instructions.md
- Breaks down complex tasks into manageable units
- Tracks progress and dependencies
- Maintains focused execution

#### Memory Bank
@.github/instructions/memory-bank.instructions.md
- Maintains project knowledge across sessions
- Organizes technical documentation
- Ensures consistent understanding
- Memory Bank Structure:
    - @.github/instructions/activeContext.instructions.md
    - @.github/instructions/rules/productContext.instructions.md
    - @.github/instructions/rules/progress.instructions.md
    - @.github/instructions/rules/projectbrief.instructions.md
    - @.github/instructions/rules/systemPatterns.instructions.md
    - @.github/instructions/rules/techContext.instructions.md
    - @.github/instructions/rules/test-run-schema.instructions.md

#### Developer Profile
@.github/instructions/ios-developer.instructions.md
- Defines required technical skills
- Guides implementation approaches
- Sets quality standards

#### TDD Methodology
@.github/instructions/tdd.instructions.md
- Implements test-driven development
- Ensures code quality and test coverage
- Structures development cycles

#### Product Requirements
@.github/instructions/PRD.instructions.md
- Defines core product functionality
- Sets user experience expectations
- Establishes success criteria

## Integration Patterns

When multiple modules are loaded, they automatically integrate through these connection points:

- **Task Management + Memory Bank**: Task info feeds into activeContext.md and progress.md
- **Task Management + TDD**: Testing tasks are integrated into workflow
- **Memory Bank + Developer Profile**: Technical knowledge informs documentation
- **Developer Profile + TDD**: Testing expertise guides implementation
- **All Modules + PRD**: Product requirements inform all aspects of development

## Usage Guide

1. **Independent Mode**: Load individual modules for focused capabilities
   ```
   @.github/instructions/taskmaster-ai.instructions.md  # Just task management
   ```

2. **Combination Mode**: Load multiple modules for enhanced functionality
   ```
   @.github/instructions/taskmaster-ai.instructions.md
   @.github/instructions/memory-bank.instructions.md
   ```

3. **Full Framework**: Load all modules for comprehensive development approach
   ```
   @.github/instructions/taskmaster-ai.instructions.md
   @.github/instructions/memory-bank.instructions.md
   @.github/instructions/developer-profile.instructions.md
   @.github/instructions/tdd.instructions.md
   @.github/instructions/PRD.instructions.md
   ```

The framework automatically detects which modules are loaded and adjusts its behavior accordingly, maintaining consistency regardless of which combination is used.