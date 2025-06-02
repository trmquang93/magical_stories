import SwiftData
import Testing
import Foundation

@testable import magical_stories

@MainActor
struct UserProfileSubscriptionTests {
    
    @Test("UserProfile initializes with correct subscription defaults")
    func testInitialSubscriptionState() async throws {
        let userProfile = UserProfile()
        
        // Verify default subscription state
        #expect(!userProfile.hasActiveSubscription)
        #expect(userProfile.subscriptionProductId == nil)
        #expect(userProfile.subscriptionExpiryDate == nil)
        #expect(userProfile.monthlyStoryCount == 0)
        #expect(userProfile.premiumFeaturesUsed.isEmpty)
        #expect(!userProfile.hasCompletedOnboarding)
        #expect(!userProfile.hasCompletedFirstStory)
        #expect(!userProfile.hasSeenPremiumFeatures)
        #expect(userProfile.trialStartDate == nil)
        #expect(userProfile.subscriptionCancelledDate == nil)
        
        // Verify computed properties
        #expect(!userProfile.isOnFreeTrial)
        #expect(!userProfile.isSubscriptionExpired)
        #expect(userProfile.trialDaysRemaining == 0)
        #expect(userProfile.remainingStoriesThisMonth == FreeTierLimits.storiesPerMonth)
        #expect(!userProfile.hasReachedMonthlyLimit)
        #expect(userProfile.subscriptionStatusText == "Free Plan")
    }
    
    @Test("UserProfile correctly handles subscription status updates")
    func testSubscriptionStatusUpdates() async throws {
        let userProfile = UserProfile()
        
        // Test activating subscription
        let expiryDate = Date().addingTimeInterval(86400 * 30) // 30 days
        userProfile.updateSubscriptionStatus(
            isActive: true,
            productId: "com.magicalstories.premium.monthly",
            expiryDate: expiryDate
        )
        
        #expect(userProfile.hasActiveSubscription)
        #expect(userProfile.subscriptionProductId == "com.magicalstories.premium.monthly")
        #expect(userProfile.subscriptionExpiryDate == expiryDate)
        #expect(userProfile.monthlyStoryCount == 0) // Should reset on activation
        #expect(userProfile.subscriptionStatusText.contains("Premium"))
        
        // Test deactivating subscription
        userProfile.updateSubscriptionStatus(
            isActive: false,
            productId: nil,
            expiryDate: nil
        )
        
        #expect(!userProfile.hasActiveSubscription)
        #expect(userProfile.subscriptionProductId == nil)
        #expect(userProfile.subscriptionExpiryDate == nil)
    }
    
    @Test("UserProfile correctly manages free trial state")
    func testFreeTrialManagement() async throws {
        let userProfile = UserProfile()
        
        let trialExpiry = Date().addingTimeInterval(86400 * 7) // 7 days
        userProfile.startFreeTrial(
            productId: "com.magicalstories.premium.monthly",
            expiryDate: trialExpiry
        )
        
        #expect(userProfile.hasActiveSubscription)
        #expect(userProfile.isOnFreeTrial)
        #expect(userProfile.trialStartDate != nil)
        #expect(userProfile.trialDaysRemaining > 0)
        #expect(userProfile.trialDaysRemaining <= 7)
        #expect(userProfile.monthlyStoryCount == 0) // Should reset for trial
        #expect(userProfile.subscriptionStatusText.contains("Free Trial"))
        
        // Test expired trial
        let expiredTrialExpiry = Date().addingTimeInterval(-86400) // Yesterday
        userProfile.updateSubscriptionStatus(
            isActive: false,
            productId: userProfile.subscriptionProductId,
            expiryDate: expiredTrialExpiry
        )
        
        #expect(!userProfile.isOnFreeTrial)
        #expect(userProfile.trialDaysRemaining == 0)
    }
    
    @Test("UserProfile tracks monthly story usage correctly")
    func testMonthlyUsageTracking() async throws {
        let userProfile = UserProfile()
        
        // Test initial state
        #expect(userProfile.monthlyStoryCount == 0)
        #expect(!userProfile.hasReachedMonthlyLimit)
        #expect(userProfile.remainingStoriesThisMonth == FreeTierLimits.storiesPerMonth)
        
        // Test incrementing usage
        for i in 1...FreeTierLimits.storiesPerMonth {
            userProfile.incrementMonthlyStoryCount()
            
            #expect(userProfile.monthlyStoryCount == i)
            #expect(userProfile.remainingStoriesThisMonth == FreeTierLimits.storiesPerMonth - i)
            
            if i < FreeTierLimits.storiesPerMonth {
                #expect(!userProfile.hasReachedMonthlyLimit)
            } else {
                #expect(userProfile.hasReachedMonthlyLimit)
            }
        }
        
        // Verify story generation count also incremented
        #expect(userProfile.storyGenerationCount == FreeTierLimits.storiesPerMonth)
        #expect(userProfile.lastGenerationDate != nil)
    }
    
    @Test("UserProfile resets monthly usage correctly")
    func testMonthlyUsageReset() async throws {
        let userProfile = UserProfile()
        
        // Generate some stories
        userProfile.incrementMonthlyStoryCount()
        userProfile.incrementMonthlyStoryCount()
        
        #expect(userProfile.monthlyStoryCount == 2)
        #expect(userProfile.hasReachedMonthlyLimit == false)
        
        let oldPeriodStart = userProfile.currentPeriodStart
        
        // Reset usage
        userProfile.resetMonthlyUsage()
        
        #expect(userProfile.monthlyStoryCount == 0)
        #expect(!userProfile.hasReachedMonthlyLimit)
        #expect(userProfile.remainingStoriesThisMonth == FreeTierLimits.storiesPerMonth)
        #expect(userProfile.currentPeriodStart != oldPeriodStart)
        #expect(userProfile.lastUsageReset != nil)
    }
    
    @Test("UserProfile tracks premium feature usage")
    func testPremiumFeatureTracking() async throws {
        let userProfile = UserProfile()
        
        #expect(userProfile.premiumFeaturesUsed.isEmpty)
        
        // Mark features as used
        userProfile.markPremiumFeatureUsed(.growthPathCollections)
        userProfile.markPremiumFeatureUsed(.unlimitedStoryGeneration)
        
        #expect(userProfile.premiumFeaturesUsed.count == 2)
        #expect(userProfile.premiumFeaturesUsed.contains(PremiumFeature.growthPathCollections.rawValue))
        #expect(userProfile.premiumFeaturesUsed.contains(PremiumFeature.unlimitedStoryGeneration.rawValue))
        
        // Test idempotency - marking same feature again shouldn't duplicate
        userProfile.markPremiumFeatureUsed(.growthPathCollections)
        #expect(userProfile.premiumFeaturesUsed.count == 2)
    }
    
    @Test("UserProfile manages onboarding state correctly")
    func testOnboardingStateManagement() async throws {
        let userProfile = UserProfile()
        
        // Test initial onboarding state
        #expect(!userProfile.hasCompletedOnboarding)
        #expect(!userProfile.hasCompletedFirstStory)
        #expect(!userProfile.hasSeenPremiumFeatures)
        #expect(userProfile.shouldShowOnboarding())
        
        // Complete onboarding steps
        userProfile.completeOnboarding()
        #expect(userProfile.hasCompletedOnboarding)
        #expect(!userProfile.shouldShowOnboarding())
        
        userProfile.completeFirstStory()
        #expect(userProfile.hasCompletedFirstStory)
        
        userProfile.markPremiumFeaturesSeen()
        #expect(userProfile.hasSeenPremiumFeatures)
    }
    
    @Test("UserProfile handles subscription cancellation correctly")
    func testSubscriptionCancellation() async throws {
        let userProfile = UserProfile()
        
        // Set up active subscription first
        let expiryDate = Date().addingTimeInterval(86400 * 30)
        userProfile.updateSubscriptionStatus(
            isActive: true,
            productId: "com.magicalstories.premium.monthly",
            expiryDate: expiryDate
        )
        
        #expect(userProfile.subscriptionCancelledDate == nil)
        
        // Cancel subscription
        userProfile.cancelSubscription()
        
        #expect(userProfile.subscriptionCancelledDate != nil)
        #expect(userProfile.hasActiveSubscription) // Should remain active until expiry
    }
    
    @Test("UserProfile provides correct subscription status text for different states")
    func testSubscriptionStatusText() async throws {
        let userProfile = UserProfile()
        
        // Free plan
        #expect(userProfile.subscriptionStatusText == "Free Plan")
        
        // Active monthly subscription
        userProfile.updateSubscriptionStatus(
            isActive: true,
            productId: "com.magicalstories.premium.monthly",
            expiryDate: Date().addingTimeInterval(86400 * 30)
        )
        #expect(userProfile.subscriptionStatusText.contains("Premium Monthly"))
        
        // Active yearly subscription
        userProfile.updateSubscriptionStatus(
            isActive: true,
            productId: "com.magicalstories.premium.yearly",
            expiryDate: Date().addingTimeInterval(86400 * 365)
        )
        #expect(userProfile.subscriptionStatusText.contains("Premium Yearly"))
        
        // Free trial
        userProfile.startFreeTrial(
            productId: "com.magicalstories.premium.monthly",
            expiryDate: Date().addingTimeInterval(86400 * 7)
        )
        #expect(userProfile.subscriptionStatusText.contains("Free Trial"))
        #expect(userProfile.subscriptionStatusText.contains("days left"))
        
        // Expired subscription
        userProfile.updateSubscriptionStatus(
            isActive: false,
            productId: "com.magicalstories.premium.monthly",
            expiryDate: Date().addingTimeInterval(-86400)
        )
        #expect(userProfile.subscriptionStatusText == "Subscription Expired")
    }
    
    @Test("UserProfile calculates child age correctly")
    func testChildAgeCalculation() async throws {
        let calendar = Calendar.current
        let fiveYearsAgo = calendar.date(byAdding: .year, value: -5, to: Date())!
        let sevenYearsAgo = calendar.date(byAdding: .year, value: -7, to: Date())!
        
        let userProfile = UserProfile(childName: "Test Child", dateOfBirth: fiveYearsAgo)
        #expect(userProfile.childAgeInYears == 5)
        
        userProfile.dateOfBirth = sevenYearsAgo
        #expect(userProfile.childAgeInYears == 7)
    }
    
    @Test("UserProfile subscription state affects monthly limits correctly")
    func testSubscriptionEffectOnLimits() async throws {
        let userProfile = UserProfile()
        
        // As free user, generate up to limit
        for _ in 0..<FreeTierLimits.storiesPerMonth {
            userProfile.incrementMonthlyStoryCount()
        }
        #expect(userProfile.hasReachedMonthlyLimit)
        
        // Upgrade to premium
        userProfile.updateSubscriptionStatus(
            isActive: true,
            productId: "com.magicalstories.premium.monthly",
            expiryDate: Date().addingTimeInterval(86400 * 30)
        )
        
        // With active subscription, should not be limited
        #expect(!userProfile.hasReachedMonthlyLimit)
        
        // Downgrade back to free
        userProfile.updateSubscriptionStatus(
            isActive: false,
            productId: nil,
            expiryDate: nil
        )
        
        // Should be limited again
        #expect(userProfile.hasReachedMonthlyLimit)
    }
}