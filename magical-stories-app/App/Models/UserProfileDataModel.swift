import Foundation
import SwiftData

/// Represents the user's profile, including preferences and usage statistics.
/// Assumed to be a single instance for the application.
@Model
final class UserProfile: @unchecked Sendable {
    // --- Fields from Schema Document ---
    @Attribute(.unique) var id: UUID // Make ID unique to enforce singleton nature
    var createdAt: Date

    // Child Information
    var childName: String
    var dateOfBirth: Date
    var interests: [String]

    // Preferences
    var preferredThemes: [String]
    var favoriteCharacters: [String]

    // Settings (Consider moving to AppSettingsModel if purely device settings)
    var useTextToSpeech: Bool
    var preferredVoiceIdentifier: String?
    var darkModePreferenceRaw: String // Store raw value for enum

    // Statistics (General Reading)
    var totalStoriesRead: Int
    var totalReadingTime: TimeInterval // Store as Double
    var lastReadDate: Date?

    // Relationships (Achievements might be better linked elsewhere if not user-specific)
    // @Relationship(deleteRule: .cascade)
    // var achievements: [Achievement] // Commented out as per schema, but consider if needed

    // --- Fields for Usage Analytics (Phase 3 Migration) ---
    var storyGenerationCount: Int
    var lastGenerationDate: Date?
    var lastGeneratedStoryId: UUID? // Store UUID directly
    
    // --- Subscription and Usage Tracking Fields ---
    var monthlyStoryCount: Int
    var currentPeriodStart: Date?
    var subscriptionExpiryDate: Date?
    var hasActiveSubscription: Bool
    var subscriptionProductId: String?
    var lastUsageReset: Date?
    var premiumFeaturesUsed: [String] // Track which premium features have been used
    var hasCompletedOnboarding: Bool
    var hasCompletedFirstStory: Bool
    var hasSeenPremiumFeatures: Bool
    var trialStartDate: Date?
    var subscriptionCancelledDate: Date?

    // --- Computed Properties ---
    var darkModePreference: DarkModePreference {
        get { DarkModePreference(rawValue: darkModePreferenceRaw) ?? .system }
        set { darkModePreferenceRaw = newValue.rawValue }
    }
    
    /// Returns true if the user is currently on a free trial
    var isOnFreeTrial: Bool {
        guard let trialStart = trialStartDate else { return false }
        guard let expiryDate = subscriptionExpiryDate else { return false }
        let now = Date()
        return now >= trialStart && now < expiryDate && hasActiveSubscription
    }
    
    /// Returns true if the subscription has expired
    var isSubscriptionExpired: Bool {
        guard let expiryDate = subscriptionExpiryDate else { return false }
        return Date() > expiryDate
    }
    
    /// Returns the number of days remaining in the trial (if on trial)
    var trialDaysRemaining: Int {
        guard isOnFreeTrial, let expiryDate = subscriptionExpiryDate else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expiryDate)
        return max(0, components.day ?? 0)
    }
    
    /// Returns the number of stories remaining in the current month for free users
    var remainingStoriesThisMonth: Int {
        let limit = FreeTierLimits.storiesPerMonth
        return max(0, limit - monthlyStoryCount)
    }
    
    /// Returns true if the user has reached their monthly story limit
    var hasReachedMonthlyLimit: Bool {
        return monthlyStoryCount >= FreeTierLimits.storiesPerMonth && !hasActiveSubscription
    }
    
    /// Returns the subscription status for display
    var subscriptionStatusText: String {
        if hasActiveSubscription {
            if isOnFreeTrial {
                return "Free Trial (\(trialDaysRemaining) days left)"
            } else if let productId = subscriptionProductId {
                if productId.contains("monthly") {
                    return "Premium Monthly"
                } else if productId.contains("yearly") {
                    return "Premium Yearly"
                }
            }
            return "Premium Active"
        } else if isSubscriptionExpired {
            return "Subscription Expired"
        } else {
            return "Free Plan"
        }
    }

    // --- Initializer ---
    // Provide a default initializer or one based on essential info
    init(
        id: UUID = UUID(), // Default ID
        childName: String = "Adventurer", // Default name
        dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -5, to: Date()) ?? Date() // Default DOB (e.g., 5 years ago)
    ) {
        self.id = id
        self.childName = childName
        self.dateOfBirth = dateOfBirth
        self.createdAt = Date()
        self.interests = []
        self.preferredThemes = []
        self.favoriteCharacters = []
        self.useTextToSpeech = true
        self.darkModePreferenceRaw = DarkModePreference.system.rawValue
        self.totalStoriesRead = 0
        self.totalReadingTime = 0.0
        // self.achievements = [] // If relationship is active

        // Initialize new analytics fields
        self.storyGenerationCount = 0
        self.lastGenerationDate = nil
        self.lastGeneratedStoryId = nil
        
        // Initialize subscription and usage tracking fields
        self.monthlyStoryCount = 0
        self.currentPeriodStart = Date()
        self.subscriptionExpiryDate = nil
        self.hasActiveSubscription = false
        self.subscriptionProductId = nil
        self.lastUsageReset = Date()
        self.premiumFeaturesUsed = []
        self.hasCompletedOnboarding = false
        self.hasCompletedFirstStory = false
        self.hasSeenPremiumFeatures = false
        self.trialStartDate = nil
        self.subscriptionCancelledDate = nil
    }

    // Convenience initializer for migration
    
    // MARK: - Subscription Management Methods
    
    /// Updates the subscription status and related fields
    /// - Parameters:
    ///   - isActive: Whether the subscription is currently active
    ///   - productId: The product ID of the subscription
    ///   - expiryDate: When the subscription expires
    func updateSubscriptionStatus(isActive: Bool, productId: String?, expiryDate: Date?) {
        // Store current expiry for comparison before updating
        let currentExpiry = self.subscriptionExpiryDate
        
        self.hasActiveSubscription = isActive
        self.subscriptionProductId = productId
        self.subscriptionExpiryDate = expiryDate
        
        // If subscription becomes active, reset monthly count
        if isActive && !hasActiveSubscription {
            self.monthlyStoryCount = 0
        }
        
        // If converting from trial to paid subscription, clear trial date
        if isActive && trialStartDate != nil {
            // Check if this is a conversion from trial to paid by comparing dates
            // If the new expiry is later than the current one, it's likely a conversion
            if let oldExpiry = currentExpiry,
               let newExpiry = expiryDate,
               newExpiry > oldExpiry {
                self.trialStartDate = nil
            }
        }
    }
    
    /// Starts a free trial
    /// - Parameters:
    ///   - productId: The product ID for the trial
    ///   - expiryDate: When the trial expires
    func startFreeTrial(productId: String, expiryDate: Date) {
        self.trialStartDate = Date()
        self.hasActiveSubscription = true
        self.subscriptionProductId = productId
        self.subscriptionExpiryDate = expiryDate
        self.monthlyStoryCount = 0 // Reset usage for trial
    }
    
    /// Cancels the subscription (sets cancellation date but doesn't immediately revoke access)
    func cancelSubscription() {
        self.subscriptionCancelledDate = Date()
        // Don't immediately set hasActiveSubscription to false - wait for expiry
    }
    
    /// Increments the monthly story count
    func incrementMonthlyStoryCount() {
        self.monthlyStoryCount += 1
        self.storyGenerationCount += 1
        self.lastGenerationDate = Date()
    }
    
    /// Resets the monthly usage counters (called at the start of each month)
    func resetMonthlyUsage() {
        self.monthlyStoryCount = 0
        self.currentPeriodStart = Date()
        self.lastUsageReset = Date()
    }
    
    /// Marks a premium feature as used
    /// - Parameter feature: The premium feature that was used
    func markPremiumFeatureUsed(_ feature: PremiumFeature) {
        if !premiumFeaturesUsed.contains(feature.rawValue) {
            premiumFeaturesUsed.append(feature.rawValue)
        }
    }
    
    /// Completes the onboarding flow
    func completeOnboarding() {
        self.hasCompletedOnboarding = true
    }
    
    /// Marks the first story as completed
    func completeFirstStory() {
        self.hasCompletedFirstStory = true
    }
    
    /// Marks that the user has seen premium features
    func markPremiumFeaturesSeen() {
        self.hasSeenPremiumFeatures = true
    }
    
    /// Checks if the user should see onboarding
    /// - Returns: True if onboarding should be shown
    func shouldShowOnboarding() -> Bool {
        return !hasCompletedOnboarding
    }
    
    /// Gets the age of the child in years
    var childAgeInYears: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return ageComponents.year ?? 5
    }
}

// MARK: - Supporting Enums (Copied from Schema for completeness)

enum DarkModePreference: String, Codable, CaseIterable, Sendable {
    case light
    case dark
    case system
}

// MARK: - UserDefaults Keys (Internal)
// Keep these keys consistent with the ones being removed from PersistenceService
