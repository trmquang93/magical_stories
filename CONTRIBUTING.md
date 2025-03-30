# Contributing to Magical Stories

## Welcome! 👋

Thank you for considering contributing to Magical Stories! This document outlines the process and guidelines for contributing to the project.

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct. We expect all contributors to uphold these guidelines to ensure a positive and inclusive environment.

## Getting Started

1. **Fork the Repository**
   ```bash
   git clone https://github.com/YOUR-USERNAME/magical_stories.git
   cd magical_stories
   ```

2. **Set Up Development Environment**
   - Install Xcode 14.0 or later
   - Install required dependencies:
     ```bash
     xed .  # Open in Xcode
     ```
   - Copy `Config.example.xcconfig` to `Config.xcconfig`
   - Add your API keys to `Config.xcconfig`

3. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Process

### 1. Code Style
- Follow the [Swift Style Guide](documents/dev/coding-standards.md)
- Use SwiftLint for code style validation
- Maintain existing code formatting

### 2. Testing
- Write unit tests for new features
- Ensure all tests pass
- Follow [Testing Guidelines](documents/dev/testing-guidelines.md)

### 3. Documentation
- Update relevant documentation
- Add inline comments for complex logic
- Include SwiftUI Previews for UI components

## Pull Request Process

1. **Update Documentation**
   - Add/update relevant documentation
   - Include SwiftUI Preview if adding UI components
   - Update CHANGELOG.md with your changes

2. **Create Pull Request**
   - Give a clear PR title and description
   - Link related issues
   - Fill out the PR template

3. **Code Review**
   - Address review comments
   - Keep the discussion focused
   - Be patient and respectful

4. **Merging**
   - Maintain a clean commit history
   - Squash commits if necessary
   - Use meaningful commit messages

## Commit Messages

Follow the conventional commits specification:
```
type(scope): description

[optional body]

[optional footer]
```

Types:
- feat: New feature
- fix: Bug fix
- docs: Documentation changes
- style: Code style changes
- refactor: Code refactoring
- test: Test updates
- chore: Maintenance tasks

Example:
```
feat(story-gen): add support for custom themes

Added the ability to create custom story themes with:
- Theme editor UI
- Theme validation
- Theme persistence

Closes #123
```

## Issue Reports

When reporting issues:

1. **Use Issue Template**
   - Fill out all required sections
   - Be specific and clear

2. **Include**
   - Steps to reproduce
   - Expected behavior
   - Actual behavior
   - Screenshots if applicable
   - Device/OS version

3. **Labels**
   - Use appropriate labels
   - Add priority if known

## Feature Requests

When requesting features:

1. **Use Feature Template**
   - Describe the feature clearly
   - Explain the use case
   - Suggest implementation if possible

2. **Discussion**
   - Be open to feedback
   - Participate in discussion
   - Help refine the proposal

## Development Setup

### Environment Setup
```bash
# Install dependencies
brew install swiftlint
pod install # if using CocoaPods

# Set up pre-commit hooks
./scripts/setup-hooks.sh
```

### Configuration
1. Copy configuration template:
   ```bash
   cp Config.example.xcconfig Config.xcconfig
   ```

2. Add your API keys:
   ```
   GOOGLE_AI_API_KEY = your_key_here
   ```

3. Set up development environment:
   ```bash
   ./scripts/setup-dev.sh
   ```

## Release Process

1. **Version Bump**
   - Update version in project settings
   - Update CHANGELOG.md
   - Create version tag

2. **Testing**
   - Run full test suite
   - Perform manual testing
   - Check documentation

3. **Submit**
   - Create release PR
   - Get approvals
   - Merge to main

## Getting Help

- Join our [Slack channel](#)
- Check [FAQ](docs/FAQ.md)
- Ask in [Discussions](#)

## Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Credited in app About section

## Questions?

Feel free to:
- Open an issue
- Start a discussion
- Contact maintainers

Thank you for contributing to Magical Stories! 🌟

---

Remember: Focus on creating magic for children while maintaining code quality and security.
