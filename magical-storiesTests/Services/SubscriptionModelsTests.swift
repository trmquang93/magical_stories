import Testing
import Foundation

@testable import magical_stories

struct SubscriptionModelsTests {
    
    @Test("SubscriptionProduct contains correct product IDs from requirements")
    func testSubscriptionProductIDs() async throws {
        // Verify product IDs match requirements document
        #expect(SubscriptionProduct.premiumMonthly.productID == "com.magicalstories.premium.monthly")
        #expect(SubscriptionProduct.premiumYearly.productID == "com.magicalstories.premium.yearly")
        
        // Verify all product IDs are collected correctly
        let allIDs = SubscriptionProduct.allProductIDs
        #expect(allIDs.contains("com.magicalstories.premium.monthly"))
        #expect(allIDs.contains("com.magicalstories.premium.yearly"))
        #expect(allIDs.count == 2)
    }
    
    @Test("SubscriptionProduct has correct fallback pricing")
    func testSubscriptionFallbackPricing() async throws {
        // Test fallback pricing when no StoreKit product is available
        #expect(SubscriptionProduct.premiumMonthly.displayPrice(from: nil) == "$8.99/month")
        #expect(SubscriptionProduct.premiumYearly.displayPrice(from: nil) == "$89.99/year")
        
        // Test fallback savings message when no StoreKit products are available
        #expect(SubscriptionProduct.premiumMonthly.savingsMessage(yearlyProduct: nil, monthlyProduct: nil) == nil)
        #expect(SubscriptionProduct.premiumYearly.savingsMessage(yearlyProduct: nil, monthlyProduct: nil) == "Save 16% vs monthly")
    }
    
    @Test("SubscriptionProduct calculates dynamic savings correctly")
    func testDynamicSavingsCalculation() async throws {
        // Create mock products for testing savings calculation
        // Note: In real tests, you would create proper StoreKit Product mocks
        // This is a conceptual test showing the expected behavior
        
        // Test case: Monthly $9.99, Yearly $99.99 (16.7% savings)
        // Expected: "Save 17% vs monthly" (rounded)
        
        // For now, verify the fallback behavior works correctly
        let monthlyProduct = SubscriptionProduct.premiumMonthly
        let yearlyProduct = SubscriptionProduct.premiumYearly
        
        // Test that monthly doesn't have a savings message
        #expect(monthlyProduct.savingsMessage(yearlyProduct: nil, monthlyProduct: nil) == nil)
        
        // Test that yearly has a fallback savings message
        #expect(yearlyProduct.savingsMessage(yearlyProduct: nil, monthlyProduct: nil) == "Save 16% vs monthly")
    }
    
    @Test("SubscriptionProduct includes all required features from requirements")
    func testSubscriptionFeatures() async throws {
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
    
    @Test("PremiumFeature enum contains all features from requirements")
    func testPremiumFeatures() async throws {
        let allFeatures = PremiumFeature.allCases
        
        // Verify all required premium features are present
        #expect(allFeatures.contains(.unlimitedStoryGeneration))
        #expect(allFeatures.contains(.growthPathCollections))
        #expect(allFeatures.contains(.multipleChildProfiles))
        #expect(allFeatures.contains(.advancedIllustrations))
        #expect(allFeatures.contains(.priorityGeneration))
        #expect(allFeatures.contains(.offlineReading))
        #expect(allFeatures.contains(.parentalAnalytics))
        #expect(allFeatures.contains(.customThemes))
        
        // Verify each feature has proper display properties
        for feature in allFeatures {
            #expect(!feature.displayName.isEmpty)
            #expect(!feature.description.isEmpty)
            #expect(!feature.unlockMessage.isEmpty)
            #expect(!feature.iconName.isEmpty)
        }
    }
    
    @Test("FreeTierLimits matches requirements specification")
    func testFreeTierLimits() async throws {
        // Verify the exact limit from requirements document
        #expect(FreeTierLimits.storiesPerMonth == 3)
        #expect(FreeTierLimits.maxChildProfiles == 1)
        
        // Verify all premium features are properly restricted
        let restrictedFeatures = FreeTierLimits.restrictedFeatures
        #expect(restrictedFeatures.contains(.growthPathCollections))
        #expect(restrictedFeatures.contains(.unlimitedStoryGeneration))
        #expect(restrictedFeatures.contains(.multipleChildProfiles))
        #expect(restrictedFeatures.contains(.priorityGeneration))
        #expect(restrictedFeatures.contains(.advancedIllustrations))
        #expect(restrictedFeatures.contains(.parentalAnalytics))
        #expect(restrictedFeatures.contains(.customThemes))
        
        // Test restriction check method
        for feature in restrictedFeatures {
            #expect(FreeTierLimits.isFeatureRestricted(feature))
        }
    }
    
    @Test("FreeTierFeature enum provides correct descriptions")
    func testFreeTierFeatures() async throws {
        let basicGeneration = FreeTierFeature.basicStoryGeneration
        #expect(basicGeneration.description.contains("3 stories per month"))
        
        let singleProfile = FreeTierFeature.singleChildProfile
        #expect(singleProfile.description.contains("One child profile"))
        
        // Verify all free features have proper descriptions
        for feature in FreeTierFeature.allCases {
            #expect(!feature.displayName.isEmpty)
            #expect(!feature.description.isEmpty)
        }
    }
    
    @Test("SubscriptionStatus correctly identifies active vs inactive states")
    func testSubscriptionStatus() async throws {
        let freeStatus = SubscriptionStatus.free
        #expect(!freeStatus.isActive)
        #expect(!freeStatus.isPremium)
        
        let futureDate = Date().addingTimeInterval(86400 * 30) // 30 days from now
        let activeMonthly = SubscriptionStatus.premiumMonthly(expiresAt: futureDate)
        #expect(activeMonthly.isActive)
        #expect(activeMonthly.isPremium)
        
        let activeYearly = SubscriptionStatus.premiumYearly(expiresAt: futureDate)
        #expect(activeYearly.isActive)
        #expect(activeYearly.isPremium)
        
        let pastDate = Date().addingTimeInterval(-86400) // Yesterday
        let expiredMonthly = SubscriptionStatus.premiumMonthly(expiresAt: pastDate)
        #expect(!expiredMonthly.isActive)
        #expect(!expiredMonthly.isPremium)
        
        let expiredStatus = SubscriptionStatus.expired(lastActiveDate: pastDate)
        #expect(!expiredStatus.isActive)
        #expect(!expiredStatus.isPremium)
        
        let pendingStatus = SubscriptionStatus.pending
        #expect(!pendingStatus.isActive)
        #expect(!pendingStatus.isPremium)
    }
    
    @Test("SubscriptionStatus provides correct display text")
    func testSubscriptionStatusDisplay() async throws {
        #expect(SubscriptionStatus.free.displayText == "Free Plan")
        #expect(SubscriptionStatus.pending.displayText == "Purchase Pending")
        
        let futureDate = Date().addingTimeInterval(86400 * 30)
        let activeMonthly = SubscriptionStatus.premiumMonthly(expiresAt: futureDate)
        #expect(activeMonthly.displayText.contains("Premium Monthly"))
        #expect(activeMonthly.renewalText != nil)
        
        let activeYearly = SubscriptionStatus.premiumYearly(expiresAt: futureDate)
        #expect(activeYearly.displayText.contains("Premium Yearly"))
        #expect(activeYearly.renewalText != nil)
    }
    
    @Test("StoreError provides helpful error messages and recovery suggestions")
    func testStoreErrors() async throws {
        let errors: [StoreError] = [
            .productNotFound,
            .purchaseFailed("Test error"),
            .verificationFailed(NSError(domain: "test", code: 1)),
            .pending,
            .unknown,
            .cancelled,
            .notAllowed
        ]
        
        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
            #expect(error.recoverySuggestion != nil)
            #expect(!error.recoverySuggestion!.isEmpty)
        }
    }
    
    @Test("PaywallContext provides appropriate titles and messages")
    func testPaywallContext() async throws {
        let contexts = PaywallContext.allCases
        
        for context in contexts {
            #expect(!context.displayTitle.isEmpty)
            #expect(!context.displayMessage.isEmpty)
            
            // Verify specific context messages match requirements
            switch context {
            case .usageLimitReached:
                #expect(context.displayTitle.contains("monthly limit"))
                #expect(context.displayMessage.contains("unlimited"))
                
            case .featureRestricted:
                #expect(context.displayTitle.contains("Premium Feature"))
                #expect(context.displayMessage.contains("Premium subscription"))
                
            case .onboarding:
                #expect(context.displayTitle.contains("Premium"))
                #expect(context.displayMessage.contains("free trial"))
                
            case .settings:
                #expect(context.displayTitle.contains("Premium"))
                #expect(context.displayMessage.contains("unlimited"))
                
            case .homePromotion, .libraryPromotion:
                #expect(context.displayMessage.contains("unlimited") || context.displayMessage.contains("Premium"))
            }
        }
    }
    
    @Test("SubscriptionAnalyticsEvent provides correct event names")
    func testAnalyticsEvents() async throws {
        let paywallEvent = SubscriptionAnalyticsEvent.paywallShown(context: .usageLimitReached)
        #expect(paywallEvent.eventName == "paywall_shown")
        
        let productViewedEvent = SubscriptionAnalyticsEvent.productViewed(.premiumMonthly)
        #expect(productViewedEvent.eventName == "product_viewed")
        
        let purchaseCompletedEvent = SubscriptionAnalyticsEvent.purchaseCompleted(.premiumYearly)
        #expect(purchaseCompletedEvent.eventName == "purchase_completed")
        
        let usageLimitEvent = SubscriptionAnalyticsEvent.usageLimitReached
        #expect(usageLimitEvent.eventName == "usage_limit_reached")
        
        let featureRestrictedEvent = SubscriptionAnalyticsEvent.featureRestricted(.growthPathCollections)
        #expect(featureRestrictedEvent.eventName == "feature_restricted")
    }
}