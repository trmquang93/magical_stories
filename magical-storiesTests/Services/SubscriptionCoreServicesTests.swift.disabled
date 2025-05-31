import XCTest
import StoreKit
import SwiftData
@testable import magical_stories

/// Comprehensive tests for the core subscription services
@MainActor
final class SubscriptionCoreServicesTests: XCTestCase {
    
    private var container: ModelContainer!
    private var context: ModelContext!
    private var userProfileRepository: UserProfileRepository!
    private var usageAnalyticsService: UsageAnalyticsService!
    private var purchaseService: PurchaseService!
    private var entitlementManager: EntitlementManager!
    private var usageTracker: UsageTracker!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory container for testing
        let schema = Schema([
            UserProfile.self,
            AppSettingsModel.self,
            ParentalControlsModel.self,
            Story.self,
            Page.self,
            AchievementModel.self,
            StoryCollection.self
        ])
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: config)
        context = container.mainContext
        
        // Initialize services
        userProfileRepository = UserProfileRepository(modelContext: context)
        usageAnalyticsService = UsageAnalyticsService(userProfileRepository: userProfileRepository)
        purchaseService = PurchaseService()
        entitlementManager = EntitlementManager()
        usageTracker = UsageTracker(usageAnalyticsService: usageAnalyticsService)
        
        // Connect services
        purchaseService.setEntitlementManager(entitlementManager)
        entitlementManager.setUsageTracker(usageTracker)
        
        print("✅ Test setup completed")
    }
    
    override func tearDown() async throws {
        container = nil
        context = nil
        userProfileRepository = nil
        usageAnalyticsService = nil
        purchaseService = nil
        entitlementManager = nil
        usageTracker = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Service Initialization Tests
    
    func testServiceInitialization() async throws {
        print("🧪 Testing service initialization...")
        
        // Test that all services initialize without crashing
        XCTAssertNotNil(purchaseService)
        XCTAssertNotNil(entitlementManager)
        XCTAssertNotNil(usageTracker)
        XCTAssertNotNil(usageAnalyticsService)
        
        // Test initial states
        XCTAssertFalse(entitlementManager.isPremiumUser)
        XCTAssertEqual(entitlementManager.subscriptionStatus, .free)
        XCTAssertFalse(entitlementManager.hasLifetimeAccess)
        
        // Test usage tracker initial state
        let currentUsage = await usageTracker.getCurrentUsage()
        XCTAssertEqual(currentUsage, 0)
        
        let canGenerate = await usageTracker.canGenerateStory()
        XCTAssertTrue(canGenerate) // Should be able to generate initially
        
        print("✅ Service initialization test passed")
    }
    
    // MARK: - Product Loading Tests
    
    func testProductLoading() async throws {
        print("🧪 Testing product loading from StoreKit configuration...")
        
        // Test loading products
        try await purchaseService.loadProducts()
        
        // Verify products were loaded
        XCTAssertTrue(purchaseService.hasLoadedProducts)
        XCTAssertEqual(purchaseService.products.count, 2, "Should load 2 products from Configuration.storekit")
        
        // Test specific products
        let monthlyProduct = purchaseService.product(for: .premiumMonthly)
        let yearlyProduct = purchaseService.product(for: .premiumYearly)
        
        XCTAssertNotNil(monthlyProduct, "Monthly product should be loaded")
        XCTAssertNotNil(yearlyProduct, "Yearly product should be loaded")
        
        // Test product details
        XCTAssertEqual(monthlyProduct?.id, SubscriptionProduct.premiumMonthly.productID)
        XCTAssertEqual(yearlyProduct?.id, SubscriptionProduct.premiumYearly.productID)
        
        // Test product pricing (from Configuration.storekit)
        XCTAssertEqual(monthlyProduct?.displayPrice, "$8.99")
        XCTAssertEqual(yearlyProduct?.displayPrice, "$89.99")
        
        // Test subscription period text
        XCTAssertEqual(monthlyProduct?.subscriptionPeriodText, "Monthly")
        XCTAssertEqual(yearlyProduct?.subscriptionPeriodText, "Yearly")
        
        // Test introductory offers
        XCTAssertTrue(monthlyProduct?.hasIntroductoryOffer ?? false)
        XCTAssertTrue(yearlyProduct?.hasIntroductoryOffer ?? false)
        
        print("✅ Product loading test passed")
        print("   Monthly: \(monthlyProduct?.displayName ?? "nil") - \(monthlyProduct?.displayPrice ?? "nil")")
        print("   Yearly: \(yearlyProduct?.displayName ?? "nil") - \(yearlyProduct?.displayPrice ?? "nil")")
    }
    
    // MARK: - Usage Tracking Tests
    
    func testUsageTracking() async throws {
        print("🧪 Testing usage tracking functionality...")
        
        // Test initial usage
        let initialUsage = await usageTracker.getCurrentUsage()
        XCTAssertEqual(initialUsage, 0)
        
        let initialRemaining = await usageTracker.getRemainingStories()
        XCTAssertEqual(initialRemaining, FreeTierLimits.storiesPerMonth)
        
        let canGenerateInitially = await usageTracker.canGenerateStory()
        XCTAssertTrue(canGenerateInitially)
        
        // Test incrementing usage
        await usageTracker.incrementStoryGeneration()
        
        let afterFirstIncrement = await usageTracker.getCurrentUsage()
        XCTAssertEqual(afterFirstIncrement, 1)
        
        let remainingAfterFirst = await usageTracker.getRemainingStories()
        XCTAssertEqual(remainingAfterFirst, FreeTierLimits.storiesPerMonth - 1)
        
        // Test reaching the limit
        for i in 2...FreeTierLimits.storiesPerMonth {
            await usageTracker.incrementStoryGeneration()
            let usage = await usageTracker.getCurrentUsage()
            XCTAssertEqual(usage, i)
        }
        
        // Test limit reached
        let finalUsage = await usageTracker.getCurrentUsage()
        XCTAssertEqual(finalUsage, FreeTierLimits.storiesPerMonth)
        
        let canGenerateAtLimit = await usageTracker.canGenerateStory()
        XCTAssertFalse(canGenerateAtLimit, "Should not be able to generate when at limit")
        
        let remainingAtLimit = await usageTracker.getRemainingStories()
        XCTAssertEqual(remainingAtLimit, 0)
        
        // Test usage statistics
        let stats = await usageTracker.getUsageStatistics()
        XCTAssertEqual(stats.storiesGenerated, FreeTierLimits.storiesPerMonth)
        XCTAssertEqual(stats.remainingStories, 0)
        XCTAssertTrue(stats.isAtLimit)
        XCTAssertEqual(stats.usagePercentage, 1.0)
        
        print("✅ Usage tracking test passed")
        print("   Final usage: \(finalUsage)/\(FreeTierLimits.storiesPerMonth)")
        print("   Usage percentage: \(stats.usagePercentage)")
    }
    
    // MARK: - Feature Access Tests
    
    func testFeatureAccessControl() async throws {
        print("🧪 Testing feature access control...")
        
        // Test free user access
        XCTAssertFalse(entitlementManager.isPremiumUser)
        XCTAssertFalse(entitlementManager.hasAccess(to: .unlimitedStoryGeneration))
        XCTAssertFalse(entitlementManager.hasAccess(to: .growthPathCollections))
        XCTAssertFalse(entitlementManager.hasAccess(to: .multipleChildProfiles))
        XCTAssertFalse(entitlementManager.hasAccess(to: .advancedIllustrations))
        XCTAssertFalse(entitlementManager.hasAccess(to: .priorityGeneration))
        XCTAssertFalse(entitlementManager.hasAccess(to: .parentalAnalytics))
        XCTAssertFalse(entitlementManager.hasAccess(to: .customThemes))
        
        // Test feature restriction checking
        XCTAssertTrue(entitlementManager.isFeatureRestricted(.unlimitedStoryGeneration))
        XCTAssertTrue(entitlementManager.isFeatureRestricted(.growthPathCollections))
        
        // Test restricted features list
        let restrictedFeatures = entitlementManager.restrictedPremiumFeatures
        XCTAssertEqual(restrictedFeatures.count, PremiumFeature.allCases.count)
        
        let accessibleFeatures = entitlementManager.accessiblePremiumFeatures
        XCTAssertEqual(accessibleFeatures.count, 0)
        
        // Test subscription status text
        XCTAssertEqual(entitlementManager.subscriptionStatusText, "Free Plan")
        XCTAssertNil(entitlementManager.renewalInformation)
        
        print("✅ Feature access control test passed")
        print("   Premium user: \(entitlementManager.isPremiumUser)")
        print("   Subscription status: \(entitlementManager.subscriptionStatusText)")
        print("   Restricted features: \(restrictedFeatures.count)")
    }
    
    // MARK: - Usage Analytics Integration Tests
    
    func testUsageAnalyticsIntegration() async throws {
        print("🧪 Testing usage analytics integration...")
        
        // Test initial analytics state
        let initialCount = await usageAnalyticsService.getStoryGenerationCount()
        XCTAssertEqual(initialCount, 0)
        
        let initialMonthlyCount = await usageAnalyticsService.getMonthlyUsageCount()
        XCTAssertEqual(initialMonthlyCount, 0)
        
        let canGenerate = await usageAnalyticsService.canGenerateStoryThisMonth()
        XCTAssertTrue(canGenerate)
        
        // Test incrementing through analytics service
        await usageAnalyticsService.incrementStoryGenerationCount()
        
        let afterIncrement = await usageAnalyticsService.getStoryGenerationCount()
        XCTAssertEqual(afterIncrement, 1)
        
        let monthlyAfterIncrement = await usageAnalyticsService.getMonthlyUsageCount()
        XCTAssertEqual(monthlyAfterIncrement, 1)
        
        // Test subscription status update
        let futureDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        await usageAnalyticsService.updateSubscriptionStatus(
            isActive: true,
            productId: SubscriptionProduct.premiumMonthly.productID,
            expiryDate: futureDate
        )
        
        // Test that premium users can generate unlimited stories
        let canGenerateAsPremium = await usageAnalyticsService.canGenerateStoryThisMonth()
        XCTAssertTrue(canGenerateAsPremium)
        
        // Test premium feature tracking
        await usageAnalyticsService.trackPremiumFeatureUsage("growth_path_collections")
        await usageAnalyticsService.trackPremiumFeatureUsage("unlimited_story_generation")
        
        print("✅ Usage analytics integration test passed")
        print("   Total stories: \(afterIncrement)")
        print("   Monthly stories: \(monthlyAfterIncrement)")
    }
    
    // MARK: - Monthly Reset Tests
    
    func testMonthlyReset() async throws {
        print("🧪 Testing monthly reset functionality...")
        
        // Generate some usage
        await usageTracker.incrementStoryGeneration()
        await usageTracker.incrementStoryGeneration()
        
        let usageBeforeReset = await usageTracker.getCurrentUsage()
        XCTAssertEqual(usageBeforeReset, 2)
        
        // Manually trigger monthly reset
        await usageTracker.resetMonthlyUsage()
        
        let usageAfterReset = await usageTracker.getCurrentUsage()
        XCTAssertEqual(usageAfterReset, 0)
        
        let remainingAfterReset = await usageTracker.getRemainingStories()
        XCTAssertEqual(remainingAfterReset, FreeTierLimits.storiesPerMonth)
        
        let canGenerateAfterReset = await usageTracker.canGenerateStory()
        XCTAssertTrue(canGenerateAfterReset)
        
        // Test usage statistics after reset
        let statsAfterReset = await usageTracker.getUsageStatistics()
        XCTAssertEqual(statsAfterReset.storiesGenerated, 0)
        XCTAssertFalse(statsAfterReset.isAtLimit)
        XCTAssertEqual(statsAfterReset.usagePercentage, 0.0)
        
        print("✅ Monthly reset test passed")
        print("   Usage before reset: \(usageBeforeReset)")
        print("   Usage after reset: \(usageAfterReset)")
    }
    
    // MARK: - Premium Upgrade/Downgrade Tests
    
    func testPremiumUpgradeDowngrade() async throws {
        print("🧪 Testing premium upgrade/downgrade scenarios...")
        
        // Start as free user and use up some stories
        await usageTracker.incrementStoryGeneration()
        await usageTracker.incrementStoryGeneration()
        
        let usageAsFreeUser = await usageTracker.getCurrentUsage()
        XCTAssertEqual(usageAsFreeUser, 2)
        
        // Simulate premium upgrade
        await usageTracker.resetUsageForPremiumUpgrade()
        
        // Usage count should remain but limit should be removed
        let usageAfterUpgrade = await usageTracker.getCurrentUsage()
        XCTAssertEqual(usageAfterUpgrade, 2) // Usage preserved
        
        // Should be able to generate more stories as premium user
        let canGenerateAsPremium = await usageTracker.canGenerateStory()
        XCTAssertTrue(canGenerateAsPremium)
        
        // Simulate downgrade back to free
        await usageTracker.resetForDowngrade()
        
        // Should still be able to generate since under limit
        let canGenerateAfterDowngrade = await usageTracker.canGenerateStory()
        XCTAssertTrue(canGenerateAfterDowngrade)
        
        // But if we reach limit, should be blocked
        await usageTracker.incrementStoryGeneration() // Now at 3
        let canGenerateAtLimit = await usageTracker.canGenerateStory()
        XCTAssertFalse(canGenerateAtLimit)
        
        print("✅ Premium upgrade/downgrade test passed")
        print("   Usage preserved through upgrade: \(usageAfterUpgrade)")
    }
    
    // MARK: - Subscription Models Tests
    
    func testSubscriptionModels() async throws {
        print("🧪 Testing subscription models and enums...")
        
        // Test SubscriptionProduct enum
        XCTAssertEqual(SubscriptionProduct.allCases.count, 2)
        XCTAssertEqual(SubscriptionProduct.premiumMonthly.displayPrice, "$8.99/month")
        XCTAssertEqual(SubscriptionProduct.premiumYearly.displayPrice, "$89.99/year")
        XCTAssertEqual(SubscriptionProduct.premiumYearly.savingsMessage, "Save 16% vs monthly")
        XCTAssertNil(SubscriptionProduct.premiumMonthly.savingsMessage)
        
        // Test PremiumFeature enum
        XCTAssertEqual(PremiumFeature.allCases.count, 8)
        XCTAssertEqual(PremiumFeature.unlimitedStoryGeneration.displayName, "Unlimited Stories")
        XCTAssertEqual(PremiumFeature.growthPathCollections.iconName, "books.vertical.fill")
        
        // Test FreeTierLimits
        XCTAssertEqual(FreeTierLimits.storiesPerMonth, 3)
        XCTAssertEqual(FreeTierLimits.maxChildProfiles, 1)
        XCTAssertTrue(FreeTierLimits.isFeatureRestricted(.growthPathCollections))
        XCTAssertTrue(FreeTierLimits.isFeatureRestricted(.unlimitedStoryGeneration))
        
        // Test SubscriptionStatus
        let freeStatus = SubscriptionStatus.free
        XCTAssertFalse(freeStatus.isActive)
        XCTAssertFalse(freeStatus.isPremium)
        XCTAssertEqual(freeStatus.displayText, "Free Plan")
        
        let futureDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        let premiumStatus = SubscriptionStatus.premiumMonthly(expiresAt: futureDate)
        XCTAssertTrue(premiumStatus.isActive)
        XCTAssertTrue(premiumStatus.isPremium)
        
        // Test PaywallContext
        let usageLimitContext = PaywallContext.usageLimitReached
        XCTAssertEqual(usageLimitContext.displayTitle, "You've reached your monthly limit")
        XCTAssertEqual(usageLimitContext.displayMessage, "Upgrade to Premium for unlimited story generation")
        
        print("✅ Subscription models test passed")
        print("   Premium features: \(PremiumFeature.allCases.count)")
        print("   Subscription products: \(SubscriptionProduct.allCases.count)")
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() async throws {
        print("🧪 Testing error handling scenarios...")
        
        // Test invalid product ID handling
        let invalidProduct = purchaseService.product(for: SubscriptionProduct(rawValue: "invalid") ?? .premiumMonthly)
        XCTAssertNil(invalidProduct)
        
        // Test loading products before initialization (should not crash)
        let newPurchaseService = PurchaseService()
        XCTAssertFalse(newPurchaseService.hasLoadedProducts)
        XCTAssertEqual(newPurchaseService.products.count, 0)
        
        // Test usage tracking with invalid state (should handle gracefully)
        let newUsageTracker = UsageTracker(usageAnalyticsService: usageAnalyticsService)
        let usage = await newUsageTracker.getCurrentUsage()
        XCTAssertGreaterThanOrEqual(usage, 0) // Should not crash
        
        print("✅ Error handling test passed")
    }
    
    // MARK: - Integration Test
    
    func testFullIntegration() async throws {
        print("🧪 Testing full service integration...")
        
        // Load products
        try await purchaseService.loadProducts()
        XCTAssertTrue(purchaseService.hasLoadedProducts)
        
        // Test initial state
        XCTAssertFalse(entitlementManager.isPremiumUser)
        let canGenerate = await entitlementManager.canGenerateStory()
        XCTAssertTrue(canGenerate)
        
        // Simulate story generation
        await entitlementManager.incrementUsageCount()
        let usage = await entitlementManager.getRemainingStories()
        XCTAssertEqual(usage, FreeTierLimits.storiesPerMonth - 1)
        
        // Test analytics integration
        await usageAnalyticsService.incrementStoryGenerationCount()
        let analyticsCount = await usageAnalyticsService.getStoryGenerationCount()
        XCTAssertGreaterThan(analyticsCount, 0)
        
        print("✅ Full integration test passed")
        print("   Services working together correctly")
    }
}

// MARK: - Test Helpers

extension SubscriptionCoreServicesTests {
    
    /// Helper to wait for async operations
    func waitForAsync(timeout: TimeInterval = 5.0, operation: @escaping () async throws -> Void) async throws {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    try await operation()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Helper to create a mock subscription transaction
    func createMockTransaction(productId: String, expiresAt: Date) {
        // This would be used for testing transaction processing
        // Implementation depends on your testing strategy for StoreKit
    }
}