import Foundation

/// Configuration for Microsoft Clarity Analytics
struct ClarityConfiguration {
    
    // MARK: - Project Configuration
    
    /// Your Microsoft Clarity Project ID
    /// Get this from: https://clarity.microsoft.com/
    static let projectId: String = {
        return "s71f7omkuc"
    }()
    
    // MARK: - Environment Configuration
    
    /// Enable/disable analytics based on build configuration
    static let isEnabled: Bool = {
        #if DEBUG
        return true // Enable in debug for testing
        #else
        return true // Enable in production
        #endif
    }()
    
    /// Log level for Clarity SDK
    static let logLevel: String = {
        #if DEBUG
        return "verbose"
        #else
        return "info"
        #endif
    }()
    
    // MARK: - Privacy Configuration
    
    /// Enable/disable based on user privacy preferences
    static func shouldInitializeAnalytics() -> Bool {
        // Check user preferences for analytics opt-out
        let hasOptedOut = UserDefaults.standard.bool(forKey: "user_has_opted_out_of_analytics")
        return isEnabled && !hasOptedOut
    }
    
    /// Allow users to opt out of analytics
    @MainActor
    static func setAnalyticsOptOut(_ optOut: Bool) {
        UserDefaults.standard.set(optOut, forKey: "user_has_opted_out_of_analytics")
        
        if optOut {
            // If user opts out, pause current session
            ClarityAnalyticsService.shared.pauseSession()
        } else if isEnabled {
            // If user opts back in, resume or initialize
            ClarityAnalyticsService.shared.resumeSession()
        }
    }
}

// MARK: - Analytics Constants

extension ClarityConfiguration {
    
    /// Screen names for consistent tracking
    enum ScreenNames {
        static let home = "home"
        static let library = "library"
        static let storyDetail = "story_detail"
        static let collections = "collections"
        static let collectionDetail = "collection_detail"
        static let settings = "settings"
        static let paywall = "paywall"
        static let storyForm = "story_form"
        static let collectionForm = "collection_form"
    }
    
    /// Event categories for organized tracking
    enum EventCategories {
        static let storyGeneration = "story_generation"
        static let illustrationGeneration = "illustration_generation"
        static let subscription = "subscription"
        static let collection = "collection"
        static let userJourney = "user_journey"
        static let performance = "performance"
        static let error = "error"
    }
    
    /// User properties for segmentation
    enum UserProperties {
        static let subscriptionStatus = "subscription_status"
        static let ageGroup = "age_group"
        static let language = "language"
        static let deviceType = "device_type"
        static let appVersion = "app_version"
    }
}