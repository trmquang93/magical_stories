import Foundation
import StoreKit

// MARK: - Subscription Product Definitions

/// Represents subscription products available in the app
enum SubscriptionProduct: String, CaseIterable, Identifiable {
    case premiumMonthly = "com.magicalstories.premium.monthly"
    case premiumYearly = "com.magicalstories.premium.yearly"
    
    var id: String { rawValue }
    
    var productID: String { rawValue }
    
    var displayName: String {
        switch self {
        case .premiumMonthly:
            return "Premium Monthly"
        case .premiumYearly:
            return "Premium Yearly"
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
            return "$8.99/month"
        case .premiumYearly:
            return "$89.99/year"
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
                    return "Save \(roundedSavings)% vs monthly"
                }
            }
            
            // Fallback to hardcoded savings message
            return "Save 16% vs monthly"
        }
    }
    
    var features: [String] {
        return [
            "Unlimited story generation",
            "Growth Path Collections",
            "Advanced illustration features",
            "Multiple child profiles",
            "Parental controls & analytics",
            "Priority generation speed",
            "7-day free trial"
        ]
    }
    
    static var allProductIDs: [String] {
        SubscriptionProduct.allCases.map { $0.productID }
    }
}

// MARK: - Premium Feature Definitions

/// Represents premium features that require subscription access
enum PremiumFeature: String, CaseIterable, Identifiable {
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
            return "Unlimited Stories"
        case .growthPathCollections:
            return "Growth Path Collections"
        case .multipleChildProfiles:
            return "Multiple Child Profiles"
        case .advancedIllustrations:
            return "Advanced Illustrations"
        case .priorityGeneration:
            return "Priority Generation"
        case .offlineReading:
            return "Offline Reading"
        case .parentalAnalytics:
            return "Parental Analytics"
        case .customThemes:
            return "Custom Themes"
        }
    }
    
    var description: String {
        switch self {
        case .unlimitedStoryGeneration:
            return "Create as many magical stories as your imagination allows"
        case .growthPathCollections:
            return "Access developmental story collections designed by child development experts"
        case .multipleChildProfiles:
            return "Create personalized profiles for all your children"
        case .advancedIllustrations:
            return "Get premium visual consistency and enhanced illustration quality"
        case .priorityGeneration:
            return "Skip the wait with faster story generation"
        case .offlineReading:
            return "Read your favorite stories without an internet connection"
        case .parentalAnalytics:
            return "Track your child's reading progress and developmental milestones"
        case .customThemes:
            return "Create custom story themes tailored to your child's interests"
        }
    }
    
    var unlockMessage: String {
        switch self {
        case .unlimitedStoryGeneration:
            return "Create unlimited magical stories"
        case .growthPathCollections:
            return "Access developmental story collections"
        case .multipleChildProfiles:
            return "Add profiles for all your children"
        case .advancedIllustrations:
            return "Get premium visual consistency"
        case .priorityGeneration:
            return "Skip the wait with priority generation"
        case .offlineReading:
            return "Read stories without internet"
        case .parentalAnalytics:
            return "Track your child's reading progress"
        case .customThemes:
            return "Create custom story themes"
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
struct FreeTierLimits {
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
enum FreeTierFeature: String, CaseIterable, Identifiable {
    case basicStoryGeneration = "basic_story_generation"
    case storyLibrary = "story_library"
    case basicReading = "basic_reading"
    case singleChildProfile = "single_child_profile"
    case basicSettings = "basic_settings"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .basicStoryGeneration:
            return "Basic Story Generation"
        case .storyLibrary:
            return "Story Library"
        case .basicReading:
            return "Basic Reading"
        case .singleChildProfile:
            return "Single Child Profile"
        case .basicSettings:
            return "Basic Settings"
        }
    }
    
    var description: String {
        switch self {
        case .basicStoryGeneration:
            return "Generate \(FreeTierLimits.storiesPerMonth) stories per month"
        case .storyLibrary:
            return "Access your personal story library"
        case .basicReading:
            return "Read stories with standard features"
        case .singleChildProfile:
            return "One child profile with basic customization"
        case .basicSettings:
            return "Essential parental controls and app settings"
        }
    }
}

// MARK: - Subscription Status

/// Represents the current subscription status of the user
enum SubscriptionStatus: Equatable {
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
            return "Free Plan"
        case .premiumMonthly(let expiresAt):
            return "Premium Monthly (expires \(DateFormatter.shortDate.string(from: expiresAt)))"
        case .premiumYearly(let expiresAt):
            return "Premium Yearly (expires \(DateFormatter.shortDate.string(from: expiresAt)))"
        case .expired(let lastActiveDate):
            return "Expired (was active until \(DateFormatter.shortDate.string(from: lastActiveDate)))"
        case .pending:
            return "Purchase Pending"
        }
    }
    
    var renewalText: String? {
        switch self {
        case .premiumMonthly(let expiresAt), .premiumYearly(let expiresAt):
            return "Renews on \(DateFormatter.shortDate.string(from: expiresAt))"
        default:
            return nil
        }
    }
}

// MARK: - Store Errors

/// Represents errors that can occur during Store operations
enum StoreError: LocalizedError {
    case productNotFound
    case purchaseFailed(String)
    case verificationFailed(Error)
    case pending
    case unknown
    case cancelled
    case notAllowed
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found in the App Store"
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        case .verificationFailed(let error):
            return "Transaction verification failed: \(error.localizedDescription)"
        case .pending:
            return "Purchase is pending approval"
        case .unknown:
            return "An unknown error occurred"
        case .cancelled:
            return "Purchase was cancelled"
        case .notAllowed:
            return "Purchase not allowed"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .productNotFound:
            return "Please check your internet connection and try again"
        case .purchaseFailed:
            return "Please verify your payment method and try again"
        case .verificationFailed:
            return "Please contact support if this issue persists"
        case .pending:
            return "Your purchase is being processed. Please wait a moment"
        case .unknown:
            return "Please try again or contact support"
        case .cancelled:
            return "You can complete your purchase at any time"
        case .notAllowed:
            return "Please check your device restrictions or payment settings"
        }
    }
}

// MARK: - Analytics Events

/// Represents analytics events for subscription tracking
enum SubscriptionAnalyticsEvent {
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
enum PaywallContext: String, CaseIterable {
    case usageLimitReached = "usage_limit_reached"
    case featureRestricted = "feature_restricted"
    case onboarding = "onboarding"
    case settings = "settings"
    case homePromotion = "home_promotion"
    case libraryPromotion = "library_promotion"
    
    var displayTitle: String {
        switch self {
        case .usageLimitReached:
            return "You've reached your monthly limit"
        case .featureRestricted:
            return "Premium Feature"
        case .onboarding:
            return "Welcome to Magical Stories Premium"
        case .settings:
            return "Upgrade to Premium"
        case .homePromotion:
            return "Unlock More Magic"
        case .libraryPromotion:
            return "Expand Your Library"
        }
    }
    
    var displayMessage: String {
        switch self {
        case .usageLimitReached:
            return "Upgrade to Premium for unlimited story generation"
        case .featureRestricted:
            return "This feature is available with Premium subscription"
        case .onboarding:
            return "Start your free trial and unlock all premium features"
        case .settings:
            return "Get unlimited stories and exclusive features"
        case .homePromotion:
            return "Create unlimited stories with Premium"
        case .libraryPromotion:
            return "Build a bigger library with unlimited story generation"
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