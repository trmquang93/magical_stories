import SwiftData
import Testing
import StoreKit

@testable import magical_stories

@MainActor
struct EntitlementManagerTests {
    
    @Test("EntitlementManager initializes with free subscription status")
    func testInitialState() async throws {
        let entitlementManager = EntitlementManager()
        
        #expect(!entitlementManager.isPremiumUser)
        #expect(entitlementManager.subscriptionStatus == .free)
        #expect(!entitlementManager.hasLifetimeAccess)
        #expect(entitlementManager.subscriptionStatusText == "Free Plan")
    }
    
    @Test("EntitlementManager grants access to all premium features for premium users")
    func testPremiumFeatureAccess() async throws {
        let entitlementManager = EntitlementManager()
        
        // Simulate premium subscription status
        await MainActor.run {
            entitlementManager.subscriptionStatus = .premiumMonthly(expiresAt: Date().addingTimeInterval(86400 * 30))
        }
        
        // Verify all premium features are accessible
        for feature in PremiumFeature.allCases {
            #expect(entitlementManager.hasAccess(to: feature), "Should have access to \(feature)")
        }
        
        #expect(entitlementManager.isPremiumUser)
    }
    
    @Test("EntitlementManager restricts premium features for free users")
    func testFreeUserFeatureRestriction() async throws {
        let entitlementManager = EntitlementManager()
        
        // Verify all premium features are restricted
        for feature in FreeTierLimits.restrictedFeatures {
            #expect(!entitlementManager.hasAccess(to: feature), "Should not have access to \(feature)")
        }
        
        #expect(!entitlementManager.isPremiumUser)
    }
    
    @Test("EntitlementManager correctly identifies expired subscriptions")
    func testExpiredSubscription() async throws {
        let entitlementManager = EntitlementManager()
        
        // Set expired subscription
        let pastDate = Date().addingTimeInterval(-86400) // Yesterday
        await MainActor.run {
            entitlementManager.subscriptionStatus = .premiumMonthly(expiresAt: pastDate)
        }
        
        #expect(!entitlementManager.isPremiumUser)
        
        // Should not have access to premium features when expired
        #expect(!entitlementManager.hasAccess(to: .unlimitedStoryGeneration))
        #expect(!entitlementManager.hasAccess(to: .growthPathCollections))
    }
    
    @Test("EntitlementManager handles lifetime access correctly")
    func testLifetimeAccess() async throws {
        let entitlementManager = EntitlementManager()
        
        await MainActor.run {
            entitlementManager.hasLifetimeAccess = true
        }
        
        #expect(entitlementManager.isPremiumUser)
        #expect(entitlementManager.subscriptionStatusText == "Lifetime Premium")
        
        // Should have access to all premium features
        for feature in PremiumFeature.allCases {
            #expect(entitlementManager.hasAccess(to: feature))
        }
    }
    
    @Test("EntitlementManager integrates with UsageTracker for story generation limits")
    func testUsageTrackerIntegration() async throws {
        let mockAnalyticsService = MockUsageAnalyticsService()
        let usageTracker = UsageTracker(usageAnalyticsService: mockAnalyticsService)
        let entitlementManager = EntitlementManager()
        
        entitlementManager.setUsageTracker(usageTracker)
        
        // For free users, should delegate to usage tracker
        let canGenerate = await entitlementManager.canGenerateStory()
        #expect(canGenerate) // Should be true initially
        
        // For premium users, should always allow
        await MainActor.run {
            entitlementManager.subscriptionStatus = .premiumMonthly(expiresAt: Date().addingTimeInterval(86400 * 30))
        }
        
        let canGeneratePremium = await entitlementManager.canGenerateStory()
        #expect(canGeneratePremium)
    }
    
    @Test("EntitlementManager provides correct usage statistics")
    func testUsageStatistics() async throws {
        let mockAnalyticsService = MockUsageAnalyticsService()
        let usageTracker = UsageTracker(usageAnalyticsService: mockAnalyticsService)
        let entitlementManager = EntitlementManager()
        
        entitlementManager.setUsageTracker(usageTracker)
        
        // Test free user statistics
        let freeStats = await entitlementManager.getUsageStatistics()
        #expect(freeStats.used == 0)
        #expect(freeStats.limit == FreeTierLimits.storiesPerMonth)
        #expect(!freeStats.isUnlimited)
        
        // Test premium user statistics
        await MainActor.run {
            entitlementManager.subscriptionStatus = .premiumMonthly(expiresAt: Date().addingTimeInterval(86400 * 30))
        }
        
        let premiumStats = await entitlementManager.getUsageStatistics()
        #expect(premiumStats.isUnlimited)
        #expect(premiumStats.limit == -1)
    }
    
    @Test("EntitlementManager returns correct paywall context")
    func testPaywallContext() async throws {
        let entitlementManager = EntitlementManager()
        
        let context = entitlementManager.getPaywallContext(for: .growthPathCollections)
        #expect(context == .featureRestricted)
    }
    
    @Test("EntitlementManager lists accessible and restricted features correctly")
    func testFeatureLists() async throws {
        let entitlementManager = EntitlementManager()
        
        // For free users
        let restrictedFeatures = entitlementManager.restrictedPremiumFeatures
        #expect(restrictedFeatures.count == FreeTierLimits.restrictedFeatures.count)
        
        let accessibleFeatures = entitlementManager.accessiblePremiumFeatures
        #expect(accessibleFeatures.isEmpty)
        
        // For premium users
        await MainActor.run {
            entitlementManager.subscriptionStatus = .premiumMonthly(expiresAt: Date().addingTimeInterval(86400 * 30))
        }
        
        let premiumAccessible = entitlementManager.accessiblePremiumFeatures
        let premiumRestricted = entitlementManager.restrictedPremiumFeatures
        
        #expect(premiumAccessible.count == PremiumFeature.allCases.count)
        #expect(premiumRestricted.isEmpty)
    }
}

// MARK: - Mock Analytics Service

class MockUsageAnalyticsService: UsageAnalyticsServiceProtocol {
    private var storyCount = 0
    private var lastGenerationDate: Date?
    
    func incrementStoryGenerationCount() async {
        storyCount += 1
    }
    
    func getStoryGenerationCount() async -> Int {
        return storyCount
    }
    
    func updateLastGenerationDate(date: Date) async {
        lastGenerationDate = date
    }
    
    func getLastGenerationDate() async -> Date? {
        return lastGenerationDate
    }
}