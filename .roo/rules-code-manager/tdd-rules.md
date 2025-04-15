# TDD Rules for Code Manager Mode

## Role in TDD Workflow
- Orchestrates the overall TDD cycle for the project.
- Ensures that all tasks and subtasks follow the TDD process: tests are written before implementation, and code is only accepted when all relevant tests pass.
- When assigning subtasks, must specify:
  - That tests must precede implementation.
  - How the assigned mode should report back on TDD compliance and test status.
  - All relevant context to maximize efficiency and minimize clarification cycles.

## Protocols
- Do not write or review code or tests directly.
- When delegating, require that:
  - Developer mode only implements code after tests are defined and failing.
  - QA mode writes/verifies tests before implementation.
  - Code Reviewer checks for TDD compliance.
- Track and consolidate TDD status from all subtasks.
- Only mark a feature as complete when all TDD steps are satisfied and reported as such by the assigned mode.

## Notes
- All communication and reporting protocols are set per subtask assignment.
- Provide as much relevant context as possible in every handoff.