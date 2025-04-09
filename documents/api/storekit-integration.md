# StoreKit 2 Integration Architecture & Guide

## 1. Overview
This document outlines the architectural design and integration plan for StoreKit 2, enabling in-app purchases (IAPs) and subscriptions to unlock premium features in the Magical Stories app.

## 2. Monetization Strategy
The app will employ a freemium model:
-   **Core Functionality:** Basic story generation and library access will be free.
-   **Premium Access:** Unlocks features like access to all "Growth Collections", potentially advanced customization options, or offline access.
-   **Purchase Options:**
    -   Auto-Renewable Subscriptions (Monthly/Yearly) for ongoing premium access.
    -   Non-Consumable Purchase (Lifetime) for permanent premium access.

## 3. Product Definitions
Products are defined in App Store Connect and represented locally for easy reference and use with StoreKit APIs.

```swift
// Represents products defined in App Store Connect
enum StoreProduct: String, CaseIterable {
    // Subscriptions
    case premiumMonthly = "com.magicalstories.premium.monthly" // Example ID
    case premiumYearly = "com.magicalstories.premium.yearly"   // Example ID

    // Non-Consumable
    case lifetime = "com.magicalstories.lifetime"             // Example ID

    var productID: String { rawValue }

    static var allProductIDs: [String] {
        StoreProduct.allCases.map { $0.productID }
    }

    // Helper to identify subscription products
    var isSubscription: Bool {
        switch self {
        case .premiumMonthly, .premiumYearly: return true
        case .lifetime: return false
        }
    }
}
```

## 4. Architecture

The StoreKit integration relies on several key components working together:

*   **`PurchaseService` (Service Layer):**
    *   **Responsibilities:** Handles all direct interactions with the StoreKit framework. Loads product information (`Product.products(for:)`), initiates purchase flows (`product.purchase()`), listens for and processes transaction updates (`Transaction.updates`), handles transaction verification (`VerificationResult`), and manages restoring purchases (`AppStore.sync()`).
    *   **State:** Publishes the available `[Product]` list and potentially loading/error states related to StoreKit interactions. It does *not* directly manage entitlement state.
*   **`EntitlementManager` (Service Layer):**
    *   **Responsibilities:** Determines user access rights based on verified purchase history. It observes transaction updates (likely provided by `PurchaseService` or directly) and maintains the current entitlement status (e.g., `isPremiumUser: Bool`). Provides methods for other parts of the app to check if a feature is unlocked.
    *   **State:** Publishes the user's current entitlement status (e.g., `@Published var isPremium: Bool = false`). This is the source of truth for feature gating.
*   **UI Components (View Layer):**
    *   **`PaywallView` / `PremiumUpgradeView`:** Displays available products (fetched via `PurchaseService`) and initiates the purchase flow by calling `PurchaseService.purchase(product)`. Observes purchase state changes.
    *   **Feature Gating Views:** Wrap premium features, checking access rights via `EntitlementManager` before displaying content or showing an upgrade prompt. Uses `@EnvironmentObject` to access `EntitlementManager`.
*   **`StoreKitConfiguration` File:** Used for local testing of IAPs without App Store Connect interaction during development.

### Interaction Flow (Example: Purchasing Subscription)
1.  User navigates to `PaywallView`.
2.  `PaywallView` asks `PurchaseService` for available `Product`s.
3.  `PurchaseService` loads products using `Product.products(for:)` and publishes them.
4.  `PaywallView` displays the products.
5.  User taps "Subscribe".
6.  `PaywallView` calls `PurchaseService.purchase(selectedProduct)`.
7.  `PurchaseService` initiates `selectedProduct.purchase()`.
8.  StoreKit handles the purchase sheet and payment.
9.  `PurchaseService`'s transaction listener (`Transaction.updates`) receives a successful, verified transaction.
10. `PurchaseService` notifies `EntitlementManager` (or `EntitlementManager` observes the transaction updates directly).
11. `EntitlementManager` updates its internal state and publishes `isPremium = true`.
12. UI components observing `EntitlementManager` update accordingly (e.g., dismiss paywall, unlock features).

## 5. Key Implementation Details

### Product Loading (`PurchaseService`)
```swift
@MainActor
class PurchaseService: ObservableObject {
    @Published private(set) var products: [Product] = []
    // ... other properties like loading/error states

    func loadProducts() async {
        do {
            // Fetch products defined in StoreProduct enum
            self.products = try await Product.products(for: StoreProduct.allProductIDs)
        } catch {
            print("Failed to load products: \(error)")
            // Handle error state
        }
    }
}
```

### Purchase Flow (`PurchaseService`)
```swift
extension PurchaseService {
    // Initiates purchase, returns true on success, false on cancellation, throws on error
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            // Transaction verification happens here or in the listener
            print("Purchase successful: \(verification.payloadData.productID)")
            // Let the transaction listener handle the update and finishing
            return true // Indicate purchase initiated successfully
        case .userCancelled:
            print("Purchase cancelled by user.")
            return false
        case .pending:
            print("Purchase pending.")
            throw StoreError.pending // Or handle appropriately
        @unknown default:
            throw StoreError.unknown
        }
    }
}
```

### Transaction Handling & Verification (`PurchaseService` / Listener)
A detached `Task` listens for `Transaction.updates`. Verified transactions update the app state (via `EntitlementManager`) and are then finished.
```swift
// Inside PurchaseService or a dedicated listener class
func listenForTransactions() -> Task<Void, Error> {
    Task.detached {
        for await result in Transaction.updates {
            do {
                let transaction = try self.checkVerified(result)
                // Notify EntitlementManager or update shared state
                await EntitlementManager.shared.updateEntitlement(for: transaction) // Example
                await transaction.finish() // Finish transaction after processing
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }
    }
}

func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .unverified(_, let error): throw StoreError.verificationFailed(error)
    case .verified(let safe): return safe
    }
}
```

### Entitlement Checking (`EntitlementManager`)
Maintains and publishes the user's premium status based on verified, non-revoked, current transactions.
```swift
@MainActor
class EntitlementManager: ObservableObject {
    @Published private(set) var isPremium: Bool = false
    static let shared = EntitlementManager() // Singleton or injected

    init() {
        // Task to check initial status on launch
        Task { await checkInitialEntitlement() }
    }

    // Called by transaction listener or observes transactions
    func updateEntitlement(for transaction: Transaction) async {
        // Logic to check productID, revocationDate, expirationDate (for subs)
        // Update self.isPremium based on valid, current purchases/subscriptions
        await refreshEntitlementStatus() // Re-check overall status
    }

    func refreshEntitlementStatus() async {
        // Check latest transactions for active subscriptions or lifetime purchase
        var hasValidEntitlement = false
        if await hasValidLifetimePurchase() {
            hasValidEntitlement = true
        } else if await hasActiveSubscription() {
            hasValidEntitlement = true
        }
        self.isPremium = hasValidEntitlement
    }

    // Internal helpers (examples)
    private func hasValidLifetimePurchase() async -> Bool { /* Check Transaction.currentEntitlements */ }
    private func hasActiveSubscription() async -> Bool { /* Check Transaction.currentEntitlements for subs */ }

    // Public check used by UI/Features
    func hasAccess(to feature: PremiumFeature) -> Bool {
        switch feature {
        case .growthCollections, .advancedCustomization:
            return isPremium
        }
    }
}

enum PremiumFeature {
    case growthCollections
    case advancedCustomization
}
```

### Restore Purchases (`PurchaseService`)
```swift
extension PurchaseService {
    func restorePurchases() async throws {
        try await AppStore.sync()
        // EntitlementManager will be updated via transaction listener or manual refresh
        await EntitlementManager.shared.refreshEntitlementStatus()
    }
}
```

## 6. UI Integration
-   Use `@EnvironmentObject var entitlementManager: EntitlementManager` in views needing access checks.
-   Conditionally display UI:
    ```swift
    if entitlementManager.hasAccess(to: .growthCollections) {
        GrowthCollectionView()
    } else {
        Button("Unlock Growth Collections") { showPaywall = true }
            .sheet(isPresented: $showPaywall) { PaywallView() }
    }
    ```

## 7. Testing Strategy
-   **Local Testing:** Use a `StoreKitConfiguration.storekit` file defining test products and scenarios (subscriptions, purchases, failures). Run tests against this configuration in Xcode.
-   **Unit/Integration Tests:**
    -   Mock `PurchaseService` to test UI interactions (e.g., button taps calling `purchase`).
    -   Mock `EntitlementManager` to test feature gating UI logic based on different `isPremium` states.
    -   Test `PurchaseService` logic by mocking `Product` and `Transaction` APIs where possible, or test against the StoreKit configuration file.
    -   Test `EntitlementManager` logic by providing mock transaction data.

## 8. Phased Implementation Plan
1.  **Phase 1: Core Setup & Purchase Flow:**
    *   Define Products in App Store Connect & `StoreProduct` enum.
    *   Implement `PurchaseService` (product loading, basic purchase flow, transaction listener).
    *   Implement `EntitlementManager` (basic status tracking).
    *   Create basic `PaywallView`.
    *   Set up `StoreKitConfiguration` for local testing.
2.  **Phase 2: Entitlement & Feature Gating:**
    *   Refine `EntitlementManager` logic for subscription status checks and lifetime purchases.
    *   Implement `Restore Purchases`.
    *   Integrate `EntitlementManager` checks into UI for feature gating.
3.  **Phase 3: Advanced & Edge Cases:**
    *   Implement `Manage Subscriptions` link.
    *   Handle edge cases (pending transactions, interruptions, family sharing if applicable).
    *   Consider server-side receipt validation if required for business logic.
    *   UI Polish for paywall and upgrade prompts.

## 9. App Store Guidelines / Best Practices / Troubleshooting
(Refer to previous version's sections on Restore Purchases, Subscription Management, Receipt Validation, Error Handling, UI/UX, and Troubleshooting - adapt as needed for the new architecture). Ensure clear pricing, terms, and easy access to restore/manage functionality.

---
This documentation should be updated as the implementation progresses through phases, product offerings change, or StoreKit APIs evolve.
