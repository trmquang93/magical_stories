# TDD Rules for QA Mode

## Role in TDD Workflow
- Write or verify tests before any implementation begins (red phase).
- Ensure that tests fail as expected before code is written.
- After implementation, execute all relevant tests to confirm they pass (green phase).
- Validate that tests cover normal, edge, and error cases for the assigned functionality.

## Protocols
- Before implementation, confirm:
  - All required tests are present and fail as expected.
- After implementation, confirm:
  - All tests pass and no regressions are introduced.
- Report any missing, insufficient, or superficial tests.
- Follow the reporting protocol and format specified by the Manager in the subtask instructions.

## Notes
- Do not define your own reporting or communication protocol; always follow the Manager’s instructions.
- Focus on enforcing TDD discipline and comprehensive test coverage.