# Magical Stories 🌟

Magical Stories is an iOS app that uses AI to generate personalized, age-appropriate bedtime stories for children. Built with SwiftUI and leveraging Google's Gemini Pro AI, it creates unique stories that adapt to each child's interests and developmental needs.

## Features ✨

- **Personalized Story Generation:** AI-powered stories tailored to your child's interests and age
- **Growth Path Stories:** Story collections designed for specific developmental goals
- **Text-to-Speech:** Built-in reading with child-friendly voices
- **Parental Controls:** Age-appropriate content filtering and monitoring
- **Offline Mode:** Save stories for offline reading
- **Accessibility:** Full VoiceOver and Dynamic Type support

## Getting Started 🚀

### Prerequisites
- Xcode 14.0+
- iOS 16.0+
- Swift 5.9+
- Google AI API Key (for development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/magical_stories.git
   cd magical_stories
   ```

2. **Set up configuration**
   ```bash
   cp Config.example.xcconfig Config.xcconfig
   ```
   Add your API keys to `Config.xcconfig`:
   ```
   GOOGLE_AI_API_KEY = your_api_key_here
   ```

3. **Open in Xcode**
   ```bash
   xed .
   ```

4. **Build and run**
   - Select your target device/simulator
   - Press ⌘R to build and run

## Architecture 🏛️

Magical Stories follows MVVM architecture with Clean Architecture principles:

```
App
├── Features/
│   ├── Story/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Models/
│   └── Settings/
├── Core/
│   ├── Services/
│   ├── Repositories/
│   └── Utilities/
└── Resources/
```

Key components:
- SwiftUI for UI
- SwiftData for persistence
- Google AI (Gemini Pro) for story generation
- StoreKit 2 for in-app purchases
- AVFoundation for text-to-speech

## Documentation 📚

- [Architecture Overview](documents/technical/architecture-overview.md)
- [API Integration](documents/api/google-ai-integration.md)
- [Data Schema](documents/data/swift-data-schema.md)
- [UI Guidelines](documents/ui/design-system.md)
- [Security Guidelines](documents/security/security-guidelines.md)
- [Testing Guidelines](documents/dev/testing-guidelines.md)

## Development 👩‍💻

### Code Style
We follow Swift style guidelines and use SwiftLint for enforcement. See [Coding Standards](documents/dev/coding-standards.md).

### Testing
- Unit tests required for business logic (90% coverage for models)
- UI tests for critical paths (70% coverage for views)
- Integration tests for services (85% coverage)
- Overall coverage target: 80%

Run tests using the provided script:
```bash
./run_tests.sh                # Run all tests
./run_tests.sh TestClass/testMethod  # Run a specific test or tests (see xcodebuild -only-testing syntax)
```

This will:
- Run all tests (unit, integration, UI) or only the specified test(s)
- Generate coverage reports
- Create JUnit test reports in TestResults directory
- Install xcpretty if needed

Or use Xcode: `⌘U` (basic test run without reports)

### Branching
```bash
# Feature branch
git checkout -b feature/your-feature-name

# Bug fix branch
git checkout -b bugfix/issue-description
```

## Contributing 🤝

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md).

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## Security 🔒

- [Security Guidelines](documents/security/security-guidelines.md)
- [Privacy Compliance](documents/security/privacy-compliance.md)

Report security vulnerabilities to security@magicalstories.app

## License 📄

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support 💬

- [Documentation](docs/)
- [Troubleshooting Guide](documents/maintenance/troubleshooting.md)
- [FAQ](docs/FAQ.md)
- Email: support@magicalstories.app

## Acknowledgments 🙏

- [Google AI](https://ai.google.dev/) for Gemini Pro
- Our amazing contributors
- The children and parents who inspire us

---

Made with ❤️ for children everywhere
