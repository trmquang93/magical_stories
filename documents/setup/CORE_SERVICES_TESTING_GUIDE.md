# Core Subscription Services Testing Guide

## 🎉 Phase 1 Complete: Core Infrastructure

We've successfully implemented all the core subscription infrastructure services. Here's what's ready for testing:

### ✅ Completed Core Services

1. **PurchaseService** - Handles all StoreKit operations
2. **EntitlementManager** - Manages subscription status and feature access
3. **UsageTracker** - Tracks monthly usage limits for free users
4. **Enhanced UsageAnalyticsService** - Extended with subscription tracking
5. **Updated UserProfile Model** - Added subscription and usage fields
6. **SubscriptionModels** - Complete data models and enums
7. **StoreKit Configuration** - Ready for local testing

## 🧪 Testing the Core Services

### Prerequisites

1. **Add StoreKit Configuration to Xcode:**
   ```
   1. Open your Xcode project
   2. Add Configuration.storekit to your project target
   3. Edit Scheme → Run → Options → StoreKit Configuration → Select "Configuration.storekit"
   ```

2. **Build the Project:**
   - The new services should compile without errors
   - New files are automatically added to the project

### Test Scenarios

#### 1. Service Initialization Test

Create a simple test to verify services initialize correctly:

```swift
// Add this to your test target or create a playground
@MainActor
func testServiceInitialization() async {
    // Test PurchaseService
    let purchaseService = PurchaseService()
    
    // Test EntitlementManager
    let entitlementManager = EntitlementManager()
    
    // Test UsageTracker (you'll need UsageAnalyticsService)
    let userProfileRepo = UserProfileRepository(modelContext: yourContext)
    let usageAnalytics = UsageAnalyticsService(userProfileRepository: userProfileRepo)
    let usageTracker = UsageTracker(usageAnalyticsService: usageAnalytics)
    
    // Verify initial state
    assert(!entitlementManager.isPremiumUser)
    assert(entitlementManager.subscriptionStatus == .free)
    
    print("✅ All services initialized successfully")
}
```

#### 2. Product Loading Test

Test StoreKit product loading:

```swift
@MainActor
func testProductLoading() async throws {
    let purchaseService = PurchaseService()
    
    do {
        try await purchaseService.loadProducts()
        
        // Should load 2 products from Configuration.storekit
        assert(purchaseService.products.count == 2)
        assert(purchaseService.hasLoadedProducts)
        
        // Check product details
        let monthlyProduct = purchaseService.product(for: .premiumMonthly)
        let yearlyProduct = purchaseService.product(for: .premiumYearly)
        
        assert(monthlyProduct != nil)
        assert(yearlyProduct != nil)
        assert(monthlyProduct?.displayPrice == "$8.99")
        assert(yearlyProduct?.displayPrice == "$89.99")
        
        print("✅ Products loaded successfully")
        print("Monthly: \(monthlyProduct?.displayName ?? "nil")")
        print("Yearly: \(yearlyProduct?.displayName ?? "nil")")
        
    } catch {
        print("❌ Product loading failed: \(error)")
        throw error
    }
}
```

#### 3. Usage Tracking Test

Test the monthly usage limits:

```swift
@MainActor
func testUsageTracking() async {
    let usageTracker = UsageTracker(usageAnalyticsService: yourAnalyticsService)
    
    // Test initial state
    let initialUsage = await usageTracker.getCurrentUsage()
    assert(initialUsage == 0)
    
    let canGenerate = await usageTracker.canGenerateStory()
    assert(canGenerate == true) // Should be able to generate stories initially
    
    // Test incrementing usage
    await usageTracker.incrementStoryGeneration()
    let afterIncrement = await usageTracker.getCurrentUsage()
    assert(afterIncrement == 1)
    
    // Test remaining stories
    let remaining = await usageTracker.getRemainingStories()
    assert(remaining == FreeTierLimits.storiesPerMonth - 1)
    
    print("✅ Usage tracking working correctly")
    print("Current usage: \(afterIncrement)")
    print("Remaining: \(remaining)")
}
```

#### 4. Feature Access Test

Test premium feature access control:

```swift
@MainActor
func testFeatureAccess() async {
    let entitlementManager = EntitlementManager()
    
    // Test free user access
    assert(!entitlementManager.hasAccess(to: .unlimitedStoryGeneration))
    assert(!entitlementManager.hasAccess(to: .growthPathCollections))
    assert(!entitlementManager.hasAccess(to: .multipleChildProfiles))
    
    // Test usage limits for free users
    let canGenerate = await entitlementManager.canGenerateStory()
    // Should be true initially (assuming usage tracker allows it)
    
    let remaining = await entitlementManager.getRemainingStories()
    assert(remaining == FreeTierLimits.storiesPerMonth) // Should be 3 initially
    
    print("✅ Feature access control working correctly")
    print("Premium user: \(entitlementManager.isPremiumUser)")
    print("Subscription status: \(entitlementManager.subscriptionStatusText)")
}
```

### Test Purchase Flow (Simulator Only)

**Important:** Only test purchases in the simulator with StoreKit configuration!

```swift
@MainActor
func testPurchaseFlow() async throws {
    let purchaseService = PurchaseService()
    let entitlementManager = EntitlementManager()
    
    // Connect services
    purchaseService.setEntitlementManager(entitlementManager)
    
    // Load products
    try await purchaseService.loadProducts()
    
    guard let monthlyProduct = purchaseService.product(for: .premiumMonthly) else {
        throw TestError.productNotFound
    }
    
    // Attempt purchase (will show StoreKit test UI in simulator)
    let success = try await purchaseService.purchase(monthlyProduct)
    
    if success {
        // Check if entitlements updated
        await entitlementManager.refreshEntitlementStatus()
        
        print("✅ Purchase completed successfully")
        print("Premium status: \(entitlementManager.isPremiumUser)")
        print("Subscription: \(entitlementManager.subscriptionStatusText)")
    }
}
```

## 🚀 What's Ready for Integration

### Services Ready to Use:

1. **PurchaseService** - Ready for paywall integration
2. **EntitlementManager** - Ready for feature gating
3. **UsageTracker** - Ready for usage limit UI
4. **Enhanced Analytics** - Ready for tracking

### Next Steps:

1. **Create PaywallView** - UI for subscription purchase
2. **Create FeatureGate** - Component for premium feature protection
3. **Update StoryService** - Integrate usage limits
4. **Update HomeView** - Add feature gating

## 🐛 Common Issues & Solutions

### Issue: Products Not Loading
```
Solution: Verify StoreKit configuration is selected in scheme
Check: Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration
```

### Issue: Services Not Compiling
```
Solution: Ensure all new files are added to your app target
Check: Select each new .swift file → File Inspector → Target Membership
```

### Issue: UserProfile Model Changes
```
Solution: You may need to reset the SwiftData model
For testing: Delete app from simulator to reset database
For production: Implement proper Core Data migration
```

### Issue: Memory Leaks or Retain Cycles
```
Solution: Services use weak references where appropriate
The EntitlementManager and PurchaseService are designed to avoid retain cycles
```

## 📱 Simulator Testing

1. **Install on Simulator**
2. **Open Debug Menu**: Debug → StoreKit → Manage Transactions
3. **Test Purchase Flow**: Try purchasing subscriptions
4. **Test Restore**: Clear purchases and restore
5. **Test Expiration**: Use time controls to test subscription expiry

## 🎯 Success Criteria

- [ ] All services initialize without crashes
- [ ] Products load from StoreKit configuration
- [ ] Usage tracking increments correctly
- [ ] Feature access control works for free users
- [ ] Purchase flow completes in simulator
- [ ] Entitlements update after purchase
- [ ] Monthly usage resets work correctly

## 📋 Ready for Phase 2

With all core services complete, you're ready to move to Phase 2:

- **UI Components** (PaywallView, FeatureGate)
- **Service Integration** (StoryService, CollectionService updates)
- **Feature Gating** (HomeView, SettingsView updates)

The foundation is solid and ready for the user-facing components!

---

**Next Task:** Create PaywallView for subscription purchase UI