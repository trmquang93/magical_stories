# System Patterns & Architecture

## Core Architecture
- **Pattern**: MVVM with SwiftUI
- **State Management**: Combine framework with @Published properties
- **Dependency Injection**: Constructor-based with StateObject in MagicalStoriesApp
- **Navigation**: AppRouter with ViewFactory for centralized routing

## Service Layer Architecture
```
MagicalStoriesApp
├── StoryService (AI story generation)
├── IllustrationService (AI image generation)  
├── CollectionService (story collections)
├── PurchaseService (StoreKit 2 IAP)
├── EntitlementManager (subscription state)
├── TransactionObserver (StoreKit monitoring)
└── PersistenceService (SwiftData)
```

## Data Flow Patterns
- **SwiftData**: Primary persistence with ModelContainer
- **Repository Pattern**: Data access abstraction
- **@EnvironmentObject**: Service injection across view hierarchy
- **@Published**: Reactive state updates
- **Async/Await**: Concurrency throughout

## IAP Transaction Flow (Fixed)
```
Purchase → PurchaseService.purchase()
├── Transaction.verification
├── calculateExpirationDate()
├── EntitlementManager.updateEntitlement() 
├── UI reactive updates (@Published)
└── Transaction.finish()
```

## Feature Gating System
- **FeatureGate**: SwiftUI component for premium restrictions
- **EntitlementManager**: Central access control
- **PremiumFeature**: Enum-based feature definitions
- **PaywallView**: Upgrade prompts

## Error Handling Patterns
- **StoreError**: Structured error types
- **Logger**: OSLog for debugging
- **Try/Catch**: Async error propagation
- **@MainActor**: Thread safety for UI updates

## Testing Patterns
- **XCTest**: Unit and integration tests
- **ViewInspector**: SwiftUI view testing
- **SnapshotTesting**: Visual regression tests
- **Mock services**: Dependency injection for testing