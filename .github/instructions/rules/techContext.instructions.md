# Technical Context

## Core Technologies
- **iOS**: SwiftUI + Combine + Swift 5.9+
- **Xcode**: 16+ with iOS 18.2 SDK
- **AI Services**: Google Gemini (2.5-flash-preview-04-17 + 1.5-pro)
- **Persistence**: SwiftData with ModelContainer
- **IAP**: StoreKit 2 with Transaction.updates monitoring
- **Testing**: XCTest + ViewInspector + SnapshotTesting

## Package Dependencies
```swift
.package("generative-ai-swift", "0.5.6")
.package("ViewInspector", "0.10.1") 
.package("swift-snapshot-testing", "1.18.3")
.package("KeyboardAvoider", "1.0.3")
```

## Configuration Management
- **AppConfig.swift**: API keys and environment settings
- **Config.plist**: Build-specific configuration
- **PromptTemplates.json**: AI prompt templates
- **subscription.storekit**: StoreKit testing configuration

## Build & Deployment
- **Schemes**: magical-stories (main target)
- **Destinations**: iOS Simulator + Physical devices
- **Testing**: Automated via xcodebuild + UI tests
- **Signing**: Development provisioning

## Development Environment
- **Platform**: macOS with Apple Silicon
- **Simulator**: iPhone 16 Pro (iOS 18.3.1)
- **Git**: Version control with feature branches
- **CLI Tools**: Xcode command line tools

## API Integration
- **Google AI**: REST API via generative-ai-swift SDK
- **StoreKit**: Native iOS subscription management
- **Analytics**: Custom usage tracking service

## Performance Considerations
- **Async/Await**: Non-blocking operations
- **@MainActor**: UI thread safety
- **Task management**: Proper cancellation handling
- **Memory**: WeakSelf patterns to prevent cycles