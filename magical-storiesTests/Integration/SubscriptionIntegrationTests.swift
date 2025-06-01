import SwiftData
import Testing
import StoreKit

@testable import magical_stories

@MainActor
struct SubscriptionIntegrationTests {
    
    @Test("Complete subscription flow from free to premium matches requirements")
    func testCompleteSubscriptionFlow() async throws {
        let container = try ModelContainer(
            for: Story.self, StoryCollection.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        
        // Initialize all services as per requirements
        let userProfileRepository = UserProfileRepository(modelContext: context)
        
        // Pre-create a UserProfile to avoid SwiftData context issues during service initialization
        let initialProfile = UserProfile()
        try await userProfileRepository.save(initialProfile)
        
        let usageAnalyticsService = UsageAnalyticsService(userProfileRepository: userProfileRepository)
        let mockPersistenceService = MockPersistenceServiceFixed()
        let usageTracker = UsageTracker(usageAnalyticsService: usageAnalyticsService)
        let entitlementManager = TestableEntitlementManager()
        let purchaseService = PurchaseService()
        
        // Give services time to initialize (UsageAnalyticsService loads profile in background Task)
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        // Set up dependencies
        entitlementManager.setUsageTracker(usageTracker)
        entitlementManager.setUsageAnalyticsService(usageAnalyticsService)
        purchaseService.setEntitlementManager(entitlementManager)
        
        let mockModel = MockGenerativeModelFixed()
        mockModel.generateContentHandler = { _ in
            MockStoryGenerationResponseFixed(text: """
                <title>Test Story</title>
                <content>Test content</content>
                <category>Adventure</category>
                """)
        }
        
        let storyService = try StoryService(
            context: context,
            persistenceService: mockPersistenceService,
            model: mockModel,
            entitlementManager: entitlementManager
        )
        
        let storyParameters = StoryParameters(
            theme: "Adventure",
            childAge: 7,
            childName: "Alex",
            favoriteCharacter: "Dragon",
            storyLength: "short",
            developmentalFocus: nil,
            emotionalThemes: nil
        )
        
        // PHASE 1: Free user behavior per requirements
        
        // Verify initial free state
        #expect(!entitlementManager.isPremiumUser)
        #expect(entitlementManager.subscriptionStatus == .free)
        
        // Verify free user can generate up to FreeTierLimits.storiesPerMonth (3) stories
        for i in 1...FreeTierLimits.storiesPerMonth {
            let canGenerate = await storyService.canGenerateStory()
            #expect(canGenerate, "Should be able to generate story \(i)")
            
            let story = try await storyService.generateStory(parameters: storyParameters)
            #expect(story.title == "Test Story")
            
            let remainingStories = await storyService.getRemainingStories()
            #expect(remainingStories == FreeTierLimits.storiesPerMonth - i)
        }
        
        // Verify limit enforcement after reaching FreeTierLimits.storiesPerMonth
        let canGenerateAfterLimit = await storyService.canGenerateStory()
        #expect(!canGenerateAfterLimit)
        
        do {
            _ = try await storyService.generateStory(parameters: storyParameters)
            #expect(Bool(false), "Should have thrown usage limit error")
        } catch {
            #expect(error as? StoryServiceError == .usageLimitReached)
        }
        
        // PHASE 2: Premium feature restriction per requirements
        
        // Verify all premium features are restricted for free users
        for feature in FreeTierLimits.restrictedFeatures {
            #expect(!entitlementManager.hasAccess(to: feature), "Free user should not have access to \(feature)")
        }
        
        // Verify specific features from requirements
        #expect(!entitlementManager.hasAccess(to: .growthPathCollections))
        #expect(!entitlementManager.hasAccess(to: .unlimitedStoryGeneration))
        #expect(!entitlementManager.hasAccess(to: .multipleChildProfiles))
        #expect(!entitlementManager.hasAccess(to: .priorityGeneration))
        #expect(!entitlementManager.hasAccess(to: .advancedIllustrations))
        #expect(!entitlementManager.hasAccess(to: .parentalAnalytics))
        #expect(!entitlementManager.hasAccess(to: .customThemes))
        
        // PHASE 3: Premium upgrade per requirements
        
        // Simulate premium subscription activation via UsageAnalyticsService
        let expiryDate = Date().addingTimeInterval(86400 * 30) // 30 days
        
        // Update subscription status directly through the analytics service
        await usageAnalyticsService.updateSubscriptionStatus(
            isActive: true,
            productId: SubscriptionProduct.premiumMonthly.productID,
            expiryDate: expiryDate
        )
        
        // Also update the EntitlementManager for testing (normally this would happen via StoreKit)
        entitlementManager.simulatePremiumUpgrade(
            productId: SubscriptionProduct.premiumMonthly.productID,
            expiryDate: expiryDate
        )
        
        // Test workaround: Since EntitlementManager.refreshEntitlementStatus() triggers StoreKit dialogs,
        // we'll test the subscription logic through UsageAnalyticsService which updates UserProfile
        // and rely on the entitlementManager to pick up the status through its usage tracking
        
        // Give the system a moment to process the subscription status update
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // NOTE: EntitlementManager status won't update without real StoreKit transactions
        // Instead, we verify the UserProfile and analytics service integration
        let userProfile = try await userProfileRepository.fetchOrCreateUserProfile()
        #expect(userProfile.hasActiveSubscription)
        #expect(userProfile.subscriptionStatusText.contains("Premium"))
        
        // Verify unlimited story generation for premium users
        let canGeneratePremium = await storyService.canGenerateStory()
        #expect(canGeneratePremium)
        
        // NOTE: StoryService.getRemainingStories() depends on EntitlementManager.isPremiumUser
        // which requires real StoreKit transactions. We'll test the UserProfile state instead.
        
        // Verify that UserProfile shows premium features
        #expect(userProfile.hasActiveSubscription)
        #expect(!userProfile.hasReachedMonthlyLimit) // Premium should override limits
        
        // Verify premium user can generate stories beyond free limit
        for _ in 1...5 {
            let story = try await storyService.generateStory(parameters: storyParameters)
            #expect(story.title == "Test Story")
        }
        
        // PHASE 4: Monthly reset behavior per requirements
        
        // Reset to free user by simulating subscription expiration
        let pastDate = Date().addingTimeInterval(-86400) // Yesterday
        
        // Update subscription status to expired through analytics service
        await usageAnalyticsService.updateSubscriptionStatus(
            isActive: false,
            productId: nil,
            expiryDate: pastDate
        )
        
        // Also update the EntitlementManager for testing
        entitlementManager.simulateSubscriptionExpiration()
        
        // Test workaround: Since EntitlementManager.refreshEntitlementStatus() triggers StoreKit dialogs,
        // we'll test the subscription expiration through UsageAnalyticsService updates
        
        // Give the system a moment to process the subscription status update
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Verify usage tracking reset for new period
        await usageTracker.resetMonthlyUsage()
        
        let canGenerateAfterReset = await storyService.canGenerateStory()
        #expect(canGenerateAfterReset)
        
        let remainingAfterReset = await storyService.getRemainingStories()
        #expect(remainingAfterReset == FreeTierLimits.storiesPerMonth)
    }
    
    @Test("UserProfile subscription integration matches requirements")
    func testUserProfileSubscriptionIntegration() async throws {
        let userProfile = UserProfile()
        
        // Verify requirements: initial state
        #expect(userProfile.subscriptionStatusText == "Free Plan")
        #expect(userProfile.remainingStoriesThisMonth == FreeTierLimits.storiesPerMonth)
        #expect(!userProfile.hasReachedMonthlyLimit)
        
        // Test reaching monthly limit per requirements (3 stories per month)
        for _ in 0..<FreeTierLimits.storiesPerMonth {
            userProfile.incrementMonthlyStoryCount()
        }
        
        #expect(userProfile.hasReachedMonthlyLimit)
        #expect(userProfile.remainingStoriesThisMonth == 0)
        
        // Test subscription activation per requirements
        userProfile.updateSubscriptionStatus(
            isActive: true,
            productId: "com.magicalstories.premium.monthly",
            expiryDate: Date().addingTimeInterval(86400 * 30)
        )
        
        #expect(userProfile.subscriptionStatusText.contains("Premium Monthly"))
        #expect(!userProfile.hasReachedMonthlyLimit) // Premium overrides limit
        
        // Test free trial per requirements (7-day trial)
        let trialExpiry = Date().addingTimeInterval(86400 * 7)
        userProfile.startFreeTrial(
            productId: "com.magicalstories.premium.monthly",
            expiryDate: trialExpiry
        )
        
        #expect(userProfile.isOnFreeTrial)
        #expect(userProfile.trialDaysRemaining > 0)
        #expect(userProfile.trialDaysRemaining <= 7)
        #expect(userProfile.subscriptionStatusText.contains("Free Trial"))
    }
    
    @Test("Subscription products match exact requirements specification")
    func testSubscriptionProductsMatchRequirements() async throws {
        // Verify exact product IDs from requirements
        #expect(SubscriptionProduct.premiumMonthly.productID == "com.magicalstories.premium.monthly")
        #expect(SubscriptionProduct.premiumYearly.productID == "com.magicalstories.premium.yearly")
        
        // Verify exact pricing from requirements (using fallback prices when no Product available)
        #expect(SubscriptionProduct.premiumMonthly.displayPrice(from: nil) == "$8.99/month")
        #expect(SubscriptionProduct.premiumYearly.displayPrice(from: nil) == "$89.99/year")
        
        // Verify 16% savings message for yearly (using fallback when no Products available)
        #expect(SubscriptionProduct.premiumYearly.savingsMessage(yearlyProduct: nil, monthlyProduct: nil) == "Save 16% vs monthly")
        
        // Verify all required features are present
        let requiredFeatures = [
            "Unlimited story generation",
            "Growth Path Collections",
            "Advanced illustration features", 
            "Multiple child profiles",
            "Parental controls & analytics",
            "Priority generation speed",
            "7-day free trial"
        ]
        
        let productFeatures = SubscriptionProduct.premiumMonthly.features
        for requiredFeature in requiredFeatures {
            #expect(productFeatures.contains(requiredFeature), "Missing required feature: \(requiredFeature)")
        }
    }
    
    @Test("Free tier limits match exact requirements specification")
    func testFreeTierLimitsMatchRequirements() async throws {
        // Verify exact limits from requirements
        #expect(FreeTierLimits.storiesPerMonth == 3)
        #expect(FreeTierLimits.maxChildProfiles == 1)
        
        // Verify all required restricted features
        let requiredRestrictedFeatures: [PremiumFeature] = [
            .growthPathCollections,
            .unlimitedStoryGeneration,
            .multipleChildProfiles,
            .priorityGeneration,
            .advancedIllustrations,
            .parentalAnalytics,
            .customThemes
        ]
        
        for feature in requiredRestrictedFeatures {
            #expect(FreeTierLimits.restrictedFeatures.contains(feature), "Missing restricted feature: \(feature)")
            #expect(FreeTierLimits.isFeatureRestricted(feature))
        }
    }
    
    @Test("Analytics events match requirements specification")
    func testAnalyticsEventsMatchRequirements() async throws {
        // Verify all required analytics events from requirements are implemented
        let requiredEvents = [
            "paywall_shown",
            "product_viewed", 
            "purchase_started",
            "purchase_completed",
            "purchase_failed",
            "trial_started",
            "subscription_cancelled",
            "feature_restricted",
            "usage_limit_reached",
            "restore_purchases"
        ]
        
        // Test each event
        #expect(SubscriptionAnalyticsEvent.paywallShown(context: .usageLimitReached).eventName == "paywall_shown")
        #expect(SubscriptionAnalyticsEvent.productViewed(.premiumMonthly).eventName == "product_viewed")
        #expect(SubscriptionAnalyticsEvent.purchaseStarted(.premiumMonthly).eventName == "purchase_started")
        #expect(SubscriptionAnalyticsEvent.purchaseCompleted(.premiumMonthly).eventName == "purchase_completed")
        #expect(SubscriptionAnalyticsEvent.purchaseFailed(.premiumMonthly, error: .unknown).eventName == "purchase_failed")
        #expect(SubscriptionAnalyticsEvent.trialStarted(.premiumMonthly).eventName == "trial_started")
        #expect(SubscriptionAnalyticsEvent.subscriptionCancelled.eventName == "subscription_cancelled")
        #expect(SubscriptionAnalyticsEvent.featureRestricted(.growthPathCollections).eventName == "feature_restricted")
        #expect(SubscriptionAnalyticsEvent.usageLimitReached.eventName == "usage_limit_reached")
        #expect(SubscriptionAnalyticsEvent.restorePurchases.eventName == "restore_purchases")
    }
    
    @Test("Paywall contexts match requirements specification")
    func testPaywallContextsMatchRequirements() async throws {
        // Verify all required paywall contexts from requirements
        let contexts = PaywallContext.allCases
        
        #expect(contexts.contains(.usageLimitReached))
        #expect(contexts.contains(.featureRestricted))
        #expect(contexts.contains(.onboarding))
        #expect(contexts.contains(.settings))
        
        // Verify specific messaging requirements
        #expect(PaywallContext.usageLimitReached.displayTitle.contains("monthly limit"))
        #expect(PaywallContext.usageLimitReached.displayMessage.contains("unlimited"))
        
        #expect(PaywallContext.featureRestricted.displayTitle.contains("Premium Feature"))
        #expect(PaywallContext.featureRestricted.displayMessage.contains("Premium subscription"))
        
        #expect(PaywallContext.onboarding.displayMessage.contains("free trial"))
    }
    
    @Test("Error handling matches requirements specification")
    func testErrorHandlingMatchesRequirements() async throws {
        // Verify all required error types are implemented
        let usageLimitError = StoryServiceError.usageLimitReached
        #expect(usageLimitError.errorDescription?.contains("monthly story limit") == true)
        #expect(usageLimitError.errorDescription?.contains("Upgrade to Premium") == true)
        
        let subscriptionRequiredError = StoryServiceError.subscriptionRequired
        #expect(subscriptionRequiredError.errorDescription?.contains("Premium subscription required") == true)
        
        // Verify StoreError provides helpful messages
        let errors: [StoreError] = [.productNotFound, .pending, .cancelled, .notAllowed]
        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(error.recoverySuggestion != nil)
        }
    }
}

// MARK: - Mock Services for Integration Testing

/// Using the existing mock persistence service that works correctly
typealias MockPersistenceServiceFixed = MockPersistenceService

class MockGenerativeModelFixed: GenerativeModelProtocol {
    var generateContentHandler: ((String) -> StoryGenerationResponse)?
    
    func generateContent(_ prompt: String) async throws -> StoryGenerationResponse {
        return generateContentHandler?(prompt) ?? MockStoryGenerationResponseFixed(text: "Default response")
    }
}

struct MockStoryGenerationResponseFixed: StoryGenerationResponse {
    let text: String?
}

/// Testable EntitlementManager that inherits from EntitlementManager but disables StoreKit calls
@MainActor  
class TestableEntitlementManager: EntitlementManager {
    
    /// Override init to prevent automatic entitlement checking
    override init() {
        // Call parent init but then immediately set a recent check timestamp to prevent StoreKit calls
        super.init()
        
        // Set a recent timestamp to prevent checkInitialEntitlements from calling refreshEntitlementStatus
        let userDefaults = UserDefaults.standard
        userDefaults.set(Date(), forKey: "last_entitlement_check")
    }
    
    /// Override to prevent StoreKit system dialog calls during testing
    override func refreshEntitlementStatus() async {
        // Test-safe implementation - no StoreKit calls, just update the timestamp
        let userDefaults = UserDefaults.standard
        userDefaults.set(Date(), forKey: "last_entitlement_check")
        
        // Don't call the parent implementation as it contains Transaction.currentEntitlements
        // which triggers StoreKit system dialogs requiring user interaction
    }
    
    /// Private storage for test subscription status to override the parent's status
    private var testSubscriptionStatus: SubscriptionStatus?
    
    /// Override isPremiumUser to use test status when available
    override var isPremiumUser: Bool {
        if let testStatus = testSubscriptionStatus {
            return testStatus.isPremium || hasLifetimeAccess
        }
        return super.isPremiumUser
    }
    
    /// Override subscriptionStatus to use test status when available
    override var subscriptionStatusText: String {
        if let testStatus = testSubscriptionStatus {
            if hasLifetimeAccess {
                return "Lifetime Premium"
            }
            return testStatus.displayText
        }
        return super.subscriptionStatusText
    }
    
    /// Test helper method to simulate premium subscription activation
    func simulatePremiumUpgrade(productId: String, expiryDate: Date) {
        if productId.contains("monthly") {
            testSubscriptionStatus = .premiumMonthly(expiresAt: expiryDate)
        } else if productId.contains("yearly") {
            testSubscriptionStatus = .premiumYearly(expiresAt: expiryDate)
        }
    }
    
    /// Test helper method to simulate subscription expiration
    func simulateSubscriptionExpiration() {
        testSubscriptionStatus = .free
    }
}

