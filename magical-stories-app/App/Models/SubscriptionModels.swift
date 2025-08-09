import Foundation
import StoreKit

// MARK: - Subscription Product Definitions

/// Represents subscription products available in the app
enum SubscriptionProduct: String, CaseIterable, Identifiable, Sendable {
    case premiumMonthly = "com.qtm.magicalstories.premium.monthly"
    case premiumYearly = "com.qtm.magicalstories.premium.yearly"
    
    var id: String { rawValue }
    
    var productID: String { rawValue }
    
    var displayName: String {
        switch self {
        case .premiumMonthly:
            return R.string.localizable.subscriptionProductMonthly()
        case .premiumYearly:
            return R.string.localizable.subscriptionProductYearly()
        }
    }
    
    /// Gets the display price from a StoreKit Product, with fallback to hardcoded prices
    /// - Parameter product: The StoreKit product containing real pricing information
    /// - Returns: The display price string
    func displayPrice(from product: Product?) -> String {
        if let product = product {
            return product.displayPrice
        }
        
        // Fallback to hardcoded prices if product not available
        switch self {
        case .premiumMonthly:
            return "$8.99/month" // Note: Actual pricing should come from App Store
        case .premiumYearly:
            return "$89.99/year" // Note: Actual pricing should come from App Store
        }
    }
    
    /// Gets the savings message by comparing monthly and yearly product prices
    /// - Parameters:
    ///   - yearlyProduct: The yearly subscription product
    ///   - monthlyProduct: The monthly subscription product
    /// - Returns: Savings message if applicable
    func savingsMessage(yearlyProduct: Product?, monthlyProduct: Product?) -> String? {
        switch self {
        case .premiumMonthly:
            return nil
        case .premiumYearly:
            // Calculate real savings if both products are available
            if let yearly = yearlyProduct,
               let monthly = monthlyProduct {
                let yearlyPrice = NSDecimalNumber(decimal: yearly.price)
                let monthlyPrice = NSDecimalNumber(decimal: monthly.price)
                let twelve = NSDecimalNumber(value: 12)
                let annualMonthlyPrice = monthlyPrice.multiplying(by: twelve)
                
                if annualMonthlyPrice.compare(yearlyPrice) == .orderedDescending {
                    let savings = annualMonthlyPrice.subtracting(yearlyPrice)
                    let hundred = NSDecimalNumber(value: 100)
                    let savingsRatio = savings.dividing(by: annualMonthlyPrice)
                    let savingsPercentage = savingsRatio.multiplying(by: hundred)
                    let roundedSavings = Int(savingsPercentage.doubleValue.rounded())
                    return R.string.localizable.subscriptionSavingsPercentage(roundedSavings)
                }
            }
            
            // Return nil when products are not available (no fallback for test compliance)
            return nil
        }
    }
    
    var features: [String] {
        return [
            R.string.localizable.paywallFeatureUnlimitedStories(),
            R.string.localizable.paywallFeatureGrowthCollections(),
            R.string.localizable.paywallFeatureIllustrations(),
            R.string.localizable.paywallFeatureProfiles(),
            R.string.localizable.paywallFeatureAnalytics(),
            R.string.localizable.paywallFeaturePriority(),
            R.string.localizable.paywallFeatureTrial()
        ]
    }
    
    static var allProductIDs: [String] {
        SubscriptionProduct.allCases.map { $0.productID }
    }
}

// MARK: - Premium Feature Definitions

/// Represents premium features that require subscription access
enum PremiumFeature: String, CaseIterable, Identifiable, Codable, Sendable {
    case unlimitedStoryGeneration = "unlimited_story_generation"
    case growthPathCollections = "growth_path_collections"
    case multipleChildProfiles = "multiple_child_profiles"
    case advancedIllustrations = "advanced_illustrations"
    case priorityGeneration = "priority_generation"
    case offlineReading = "offline_reading"
    case parentalAnalytics = "parental_analytics"
    case customThemes = "custom_themes"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .unlimitedStoryGeneration:
            return R.string.localizable.premiumFeatureUnlimitedStoriesTitle()
        case .growthPathCollections:
            return R.string.localizable.premiumFeatureGrowthCollectionsTitle()
        case .multipleChildProfiles:
            return R.string.localizable.premiumFeatureProfilesTitle()
        case .advancedIllustrations:
            return R.string.localizable.premiumFeatureIllustrationsTitle()
        case .priorityGeneration:
            return R.string.localizable.premiumFeaturePriorityTitle()
        case .offlineReading:
            return R.string.localizable.premiumFeatureOfflineTitle()
        case .parentalAnalytics:
            return R.string.localizable.premiumFeatureAnalyticsTitle()
        case .customThemes:
            return R.string.localizable.premiumFeatureThemesTitle()
        }
    }
    
    var description: String {
        switch self {
        case .unlimitedStoryGeneration:
            return R.string.localizable.premiumFeatureUnlimitedStoriesDescription()
        case .growthPathCollections:
            return R.string.localizable.premiumFeatureGrowthCollectionsDescription()
        case .multipleChildProfiles:
            return R.string.localizable.premiumFeatureProfilesDescription()
        case .advancedIllustrations:
            return R.string.localizable.premiumFeatureIllustrationsDescription()
        case .priorityGeneration:
            return R.string.localizable.premiumFeaturePriorityDescription()
        case .offlineReading:
            return R.string.localizable.premiumFeatureOfflineDescription()
        case .parentalAnalytics:
            return R.string.localizable.premiumFeatureAnalyticsDescription()
        case .customThemes:
            return R.string.localizable.premiumFeatureThemesDescription()
        }
    }
    
    var unlockMessage: String {
        switch self {
        case .unlimitedStoryGeneration:
            return R.string.localizable.premiumFeatureUnlimitedStoriesUnlock()
        case .growthPathCollections:
            return R.string.localizable.premiumFeatureGrowthCollectionsUnlock()
        case .multipleChildProfiles:
            return R.string.localizable.premiumFeatureProfilesUnlock()
        case .advancedIllustrations:
            return R.string.localizable.premiumFeatureIllustrationsUnlock()
        case .priorityGeneration:
            return R.string.localizable.premiumFeaturePriorityUnlock()
        case .offlineReading:
            return R.string.localizable.premiumFeatureOfflineUnlock()
        case .parentalAnalytics:
            return R.string.localizable.premiumFeatureAnalyticsUnlock()
        case .customThemes:
            return R.string.localizable.premiumFeatureThemesUnlock()
        }
    }
    
    var iconName: String {
        switch self {
        case .unlimitedStoryGeneration:
            return "infinity"
        case .growthPathCollections:
            return "books.vertical.fill"
        case .multipleChildProfiles:
            return "person.2.fill"
        case .advancedIllustrations:
            return "photo.artframe"
        case .priorityGeneration:
            return "bolt.fill"
        case .offlineReading:
            return "wifi.slash"
        case .parentalAnalytics:
            return "chart.bar.fill"
        case .customThemes:
            return "paintbrush.fill"
        }
    }
}

// MARK: - Free Tier Definitions

/// Defines limitations for free tier users
struct FreeTierLimits: Sendable {
    static let storiesPerMonth = 3
    static let maxChildProfiles = 1
    static let restrictedFeatures: [PremiumFeature] = [
        .growthPathCollections,
        .unlimitedStoryGeneration,
        .multipleChildProfiles,
        .priorityGeneration,
        .advancedIllustrations,
        .parentalAnalytics,
        .customThemes
    ]
    
    static func isFeatureRestricted(_ feature: PremiumFeature) -> Bool {
        return restrictedFeatures.contains(feature)
    }
}

/// Represents free tier features available to all users
enum FreeTierFeature: String, CaseIterable, Identifiable, Sendable {
    case basicStoryGeneration = "basic_story_generation"
    case storyLibrary = "story_library"
    case basicReading = "basic_reading"
    case singleChildProfile = "single_child_profile"
    case basicSettings = "basic_settings"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .basicStoryGeneration:
            return R.string.localizable.freeTierFeatureBasicGenerationTitle()
        case .storyLibrary:
            return R.string.localizable.freeTierFeatureLibraryTitle()
        case .basicReading:
            return R.string.localizable.freeTierFeatureReadingTitle()
        case .singleChildProfile:
            return R.string.localizable.freeTierFeatureProfileTitle()
        case .basicSettings:
            return R.string.localizable.freeTierFeatureSettingsTitle()
        }
    }
    
    var description: String {
        switch self {
        case .basicStoryGeneration:
            return R.string.localizable.freeTierFeatureBasicGenerationDescription(FreeTierLimits.storiesPerMonth)
        case .storyLibrary:
            return R.string.localizable.freeTierFeatureLibraryDescription()
        case .basicReading:
            return R.string.localizable.freeTierFeatureReadingDescription()
        case .singleChildProfile:
            return R.string.localizable.freeTierFeatureProfileDescription()
        case .basicSettings:
            return R.string.localizable.freeTierFeatureSettingsDescription()
        }
    }
}

// MARK: - Subscription Status

/// Represents the current subscription status of the user
enum SubscriptionStatus: Equatable, Sendable {
    case free
    case premiumMonthly(expiresAt: Date)
    case premiumYearly(expiresAt: Date)
    case expired(lastActiveDate: Date)
    case pending
    
    var isActive: Bool {
        switch self {
        case .free, .expired, .pending:
            return false
        case .premiumMonthly(let expiresAt), .premiumYearly(let expiresAt):
            return expiresAt > Date()
        }
    }
    
    var isPremium: Bool {
        return isActive
    }
    
    var displayText: String {
        switch self {
        case .free:
            return R.string.localizable.subscriptionStatusFree()
        case .premiumMonthly(let expiresAt):
            return R.string.localizable.subscriptionStatusMonthlyExpires(DateFormatter.shortDate.string(from: expiresAt))
        case .premiumYearly(let expiresAt):
            return R.string.localizable.subscriptionStatusYearlyExpires(DateFormatter.shortDate.string(from: expiresAt))
        case .expired(let lastActiveDate):
            return R.string.localizable.subscriptionStatusExpired(DateFormatter.shortDate.string(from: lastActiveDate))
        case .pending:
            return R.string.localizable.subscriptionStatusPending()
        }
    }
    
    var renewalText: String? {
        switch self {
        case .premiumMonthly(let expiresAt), .premiumYearly(let expiresAt):
            return R.string.localizable.subscriptionRenewal(DateFormatter.shortDate.string(from: expiresAt))
        default:
            return nil
        }
    }
}

// MARK: - Store Errors

/// Represents errors that can occur during Store operations
enum StoreError: LocalizedError, Sendable {
    case productNotFound
    case purchaseFailed(String)
    case verificationFailed(any Error)
    case pending
    case unknown
    case cancelled
    case notAllowed
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return R.string.localizable.errorProductNotFound()
        case .purchaseFailed(let message):
            return R.string.localizable.errorPurchaseFailed(message)
        case .verificationFailed(let error):
            return R.string.localizable.errorVerificationFailed(error.localizedDescription)
        case .pending:
            return R.string.localizable.errorPending()
        case .unknown:
            return R.string.localizable.errorUnknown()
        case .cancelled:
            return R.string.localizable.errorCancelled()
        case .notAllowed:
            return R.string.localizable.errorNotAllowed()
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .productNotFound:
            return R.string.localizable.errorRecoveryProductNotFound()
        case .purchaseFailed:
            return R.string.localizable.errorRecoveryPurchaseFailed()
        case .verificationFailed:
            return R.string.localizable.errorRecoveryVerificationFailed()
        case .pending:
            return R.string.localizable.errorRecoveryPending()
        case .unknown:
            return R.string.localizable.errorRecoveryUnknown()
        case .cancelled:
            return R.string.localizable.errorRecoveryCancelled()
        case .notAllowed:
            return R.string.localizable.errorRecoveryNotAllowed()
        }
    }
}

// MARK: - Analytics Events

/// Represents analytics events for subscription tracking
enum SubscriptionAnalyticsEvent: Sendable {
    case paywallShown(context: PaywallContext)
    case productViewed(SubscriptionProduct)
    case purchaseStarted(SubscriptionProduct)
    case purchaseCompleted(SubscriptionProduct)
    case purchaseFailed(SubscriptionProduct, error: StoreError)
    case trialStarted(SubscriptionProduct)
    case subscriptionCancelled
    case featureRestricted(PremiumFeature)
    case usageLimitReached
    case restorePurchases
    
    var eventName: String {
        switch self {
        case .paywallShown:
            return "paywall_shown"
        case .productViewed:
            return "product_viewed"
        case .purchaseStarted:
            return "purchase_started"
        case .purchaseCompleted:
            return "purchase_completed"
        case .purchaseFailed:
            return "purchase_failed"
        case .trialStarted:
            return "trial_started"
        case .subscriptionCancelled:
            return "subscription_cancelled"
        case .featureRestricted:
            return "feature_restricted"
        case .usageLimitReached:
            return "usage_limit_reached"
        case .restorePurchases:
            return "restore_purchases"
        }
    }
}

/// Context for when paywall is presented
enum PaywallContext: String, CaseIterable, Sendable {
    case usageLimitReached = "usage_limit_reached"
    case featureRestricted = "feature_restricted"
    case onboarding = "onboarding"
    case settings = "settings"
    case homePromotion = "home_promotion"
    case libraryPromotion = "library_promotion"
    
    var displayTitle: String {
        switch self {
        case .usageLimitReached:
            return R.string.localizable.paywallUsageLimitTitle()
        case .featureRestricted:
            return R.string.localizable.paywallFeatureTitle()
        case .onboarding:
            return R.string.localizable.paywallOnboardingTitle()
        case .settings:
            return R.string.localizable.paywallUpgradeTitle()
        case .homePromotion:
            return R.string.localizable.paywallHomePromotionTitle()
        case .libraryPromotion:
            return R.string.localizable.paywallLibraryPromotionTitle()
        }
    }
    
    var displayMessage: String {
        switch self {
        case .usageLimitReached:
            return R.string.localizable.paywallUsageLimitMessage()
        case .featureRestricted:
            return R.string.localizable.paywallFeatureMessage()
        case .onboarding:
            return R.string.localizable.paywallOnboardingMessage()
        case .settings:
            return R.string.localizable.paywallUpgradeMessage()
        case .homePromotion:
            return R.string.localizable.paywallHomePromotionMessage()
        case .libraryPromotion:
            return R.string.localizable.paywallLibraryPromotionMessage()
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}