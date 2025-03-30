# StoreKit 2 Integration Guide

## Overview
This document outlines the integration of StoreKit 2 for in-app purchases and subscriptions in the Magical Stories app.

## Products Configuration

### Product Types
1. **Auto-Renewable Subscriptions**
   - Premium Monthly (`com.magicalstories.premium.monthly`)
   - Premium Yearly (`com.magicalstories.premium.yearly`)

2. **Non-Consumable**
   - Lifetime Access (`com.magicalstories.lifetime`)

### Product Configuration
```swift
enum StoreProduct: String, CaseIterable {
    case premiumMonthly = "com.magicalstories.premium.monthly"
    case premiumYearly = "com.magicalstories.premium.yearly"
    case lifetime = "com.magicalstories.lifetime"
    
    var productID: String { rawValue }
    
    static var subscriptionIDs: [String] {
        [premiumMonthly.productID, premiumYearly.productID]
    }
}
```

## Store Implementation

### Store Manager
```swift
@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedIDs = Set<String>()
    
    var hasActiveSubscription: Bool {
        !purchasedIDs.isDisjoint(with: Set(StoreProduct.subscriptionIDs))
    }
    
    init() {
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    func loadProducts() async {
        do {
            products = try await Product.products(for: StoreProduct.allCases.map(\.productID))
        } catch {
            print("Failed to load products: \(error)")
        }
    }
}
```

### Purchase Flow
```swift
extension StoreManager {
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return transaction
            
        case .userCancelled:
            return nil
            
        case .pending:
            throw StoreError.pending
        
        @unknown default:
            throw StoreError.unknown
        }
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}
```

### Subscription Management
```swift
extension StoreManager {
    func checkSubscriptionStatus() async -> SubscriptionStatus {
        guard let subscription = await getCurrentSubscription() else {
            return .none
        }
        
        guard let expirationDate = subscription.expirationDate,
              let renewalDate = subscription.renewalDate else {
            return .none
        }
        
        if expirationDate < .now {
            return .expired(renewalDate)
        }
        
        return .active(expirationDate)
    }
    
    private func getCurrentSubscription() async -> Transaction? {
        guard let result = await Transaction.latest(for: StoreProduct.subscriptionIDs) else {
            return nil
        }
        
        do {
            return try checkVerified(result)
        } catch {
            print("Failed to verify subscription: \(error)")
            return nil
        }
    }
}
```

### Transaction Handling
```swift
extension StoreManager {
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.handleTransaction(transaction)
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }
    
    private func handleTransaction(_ transaction: Transaction) async {
        if transaction.revocationDate == nil {
            // Valid purchase
            await self.updatePurchasedProducts()
        } else {
            // Revoked purchase
            await self.removePurchase(transaction.productID)
        }
    }
}
```

### Receipt Validation
```swift
extension StoreManager {
    func validateReceipt() async throws {
        guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: appStoreReceiptURL) else {
            throw StoreError.noReceipt
        }
        
        let receiptString = receiptData.base64EncodedString()
        // Implement server-side validation
    }
}
```

### Error Handling
```swift
enum StoreError: LocalizedError {
    case pending
    case verificationFailed
    case noReceipt
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .pending:
            return "Purchase is pending approval"
        case .verificationFailed:
            return "Purchase verification failed"
        case .noReceipt:
            return "App Store receipt not found"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
```

## Premium Features Management

### Feature Gates
```swift
class PremiumFeatures {
    static let shared = PremiumFeatures()
    
    func isFeatureEnabled(_ feature: Feature) -> Bool {
        switch feature {
        case .growthPath:
            return StoreManager.shared.hasActiveSubscription
        case .multipleChildren:
            return StoreManager.shared.hasActiveSubscription
        case .exportStories:
            return StoreManager.shared.hasActiveSubscription
        }
    }
}

enum Feature {
    case growthPath
    case multipleChildren
    case exportStories
}
```

### Premium UI
```swift
struct PremiumBadge: View {
    var body: some View {
        Image(systemName: "star.fill")
            .foregroundColor(.yellow)
            .overlay(
                Text("PRO")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
            )
    }
}

struct PremiumFeatureView<Content: View>: View {
    let feature: Feature
    let content: () -> Content
    
    var body: some View {
        if PremiumFeatures.shared.isFeatureEnabled(feature) {
            content()
        } else {
            PremiumUpgradeView(feature: feature)
        }
    }
}
```

## Testing

### StoreKit Configuration
1. Create `StoreKitConfig.storekit`:
```
{
  "identifier": "com.magicalstories.premium.monthly",
  "type": "subscription",
  "duration": "P1M",
  "price": 4.99
}
```

### Test Cases
```swift
class StoreTests: XCTestCase {
    var storeManager: StoreManager!
    
    override func setUp() {
        super.setUp()
        storeManager = StoreManager()
    }
    
    func testPurchaseSubscription() async throws {
        let product = // Get test product
        let transaction = try await storeManager.purchase(product)
        XCTAssertNotNil(transaction)
    }
}
```

## App Store Guidelines Compliance

### Required Implementations
1. **Restore Purchases**
```swift
extension StoreManager {
    func restorePurchases() async throws {
        try await AppStore.sync()
        await updatePurchasedProducts()
    }
}
```

2. **Subscription Management**
```swift
extension StoreManager {
    func showManageSubscriptions() async throws {
        try await AppStore.showManageSubscriptions()
    }
}
```

### Privacy Considerations
1. Include required privacy labels
2. Implement Ask to Track if needed
3. Handle subscription status changes

## Best Practices

1. **Receipt Validation**
   - Implement server-side validation
   - Cache validation results
   - Handle network errors

2. **Error Handling**
   - Provide clear error messages
   - Implement retry logic
   - Log purchase failures

3. **Testing**
   - Test with StoreKit configuration file
   - Test receipt validation
   - Test restore purchases

4. **UI/UX**
   - Clear pricing information
   - Obvious subscription terms
   - Easy access to restore purchases
   - Simple upgrade flow

## Troubleshooting

### Common Issues

1. **Purchase Failed**
   - Check internet connection
   - Verify product identifier
   - Check payment method

2. **Receipt Validation Failed**
   - Check server connectivity
   - Verify receipt format
   - Check environment (sandbox vs production)

3. **Subscription Not Recognized**
   - Force refresh receipt
   - Check transaction status
   - Verify entitlements

---

This documentation should be updated when:
- Product configurations change
- New features are added
- App Store guidelines change
- StoreKit APIs are updated
