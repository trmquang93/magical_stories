import Foundation
import SwiftData
import OSLog // For logging

// MARK: - Protocol Definition
@MainActor // Ensure methods interacting with SwiftData/UI are on the main actor
protocol UsageAnalyticsServiceProtocol {
    func getStoryGenerationCount() async -> Int
    func incrementStoryGenerationCount() async
    func updateLastGenerationDate(date: Date?) async
    func getLastGenerationDate() async -> Date?
    func updateLastGeneratedStoryId(id: UUID?) async
    func getLastGeneratedStoryId() async -> UUID?
    
    // Monthly usage tracking methods
    func getMonthlyUsageCount() async -> Int
    func canGenerateStoryThisMonth() async -> Bool
    func resetMonthlyUsageIfNeeded() async
    func updateSubscriptionStatus(isActive: Bool, productId: String?, expiryDate: Date?) async
    func trackPremiumFeatureUsage(_ feature: String) async
    // Add other necessary methods as needed
}

// MARK: - Service Implementation
@MainActor
class UsageAnalyticsService: UsageAnalyticsServiceProtocol {

    private var isMigrating = false

    private let userProfileRepository: UserProfileRepository
    private var cachedUserProfile: UserProfile? // Cache the profile after initial load
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example.magicalstories", category: "UsageAnalyticsService")

    init(
        userProfileRepository: UserProfileRepository
    ) {
        self.userProfileRepository = userProfileRepository
        // Don't load profile during init - defer until first access
    }

    private func loadProfileIntoCache() async {
         guard cachedUserProfile == nil else { return } // Avoid reloading if already cached
         do {
             // Use fetchOrCreate to ensure a profile exists even if migration failed somehow
             cachedUserProfile = try await userProfileRepository.fetchOrCreateUserProfile()
             logger.info("UserProfile loaded into cache.")
         } catch {
             logger.error("Failed to load UserProfile into cache: \(error.localizedDescription)")
             // cachedUserProfile remains nil, methods might return defaults or handle nil profile
         }
     }

    // MARK: - Public API Methods

    func getStoryGenerationCount() async -> Int {
        await loadProfileIntoCache() // Ensure profile is loaded
        return cachedUserProfile?.storyGenerationCount ?? 0
    }

    func incrementStoryGenerationCount() async {
        await loadProfileIntoCache()
        guard let profile = cachedUserProfile else {
            logger.error("Cannot increment story count: UserProfile not loaded.")
            return
        }
        
        // Increment total count
        profile.storyGenerationCount += 1
        
        // Also increment monthly count for free users
        if !profile.hasActiveSubscription {
            profile.monthlyStoryCount += 1
        }
        
        do {
            try await userProfileRepository.update(profile) // Saves context
            logger.debug("Incremented story generation count to \(profile.storyGenerationCount), monthly: \(profile.monthlyStoryCount)")
        } catch {
            logger.error("Failed to save updated story generation count: \(error.localizedDescription)")
            // Optionally revert the in-memory changes
            profile.storyGenerationCount -= 1
            if !profile.hasActiveSubscription {
                profile.monthlyStoryCount -= 1
            }
        }
    }

    func updateLastGenerationDate(date: Date?) async {
        await loadProfileIntoCache()
        guard let profile = cachedUserProfile else {
            logger.error("Cannot update last generation date: UserProfile not loaded.")
            return
        }
        profile.lastGenerationDate = date
        do {
            try await userProfileRepository.update(profile)
            logger.debug("Updated last generation date.")
        } catch {
            logger.error("Failed to save updated last generation date: \(error.localizedDescription)")
            // Revert? Depends on desired consistency.
        }
    }

    func getLastGenerationDate() async -> Date? {
        await loadProfileIntoCache()
        return cachedUserProfile?.lastGenerationDate
    }

    func updateLastGeneratedStoryId(id: UUID?) async {
        await loadProfileIntoCache()
        guard let profile = cachedUserProfile else {
            logger.error("Cannot update last generated story ID: UserProfile not loaded.")
            return
        }
        profile.lastGeneratedStoryId = id
        do {
            try await userProfileRepository.update(profile)
            logger.debug("Updated last generated story ID.")
        } catch {
            logger.error("Failed to save updated last generated story ID: \(error.localizedDescription)")
        }
    }

    func getLastGeneratedStoryId() async -> UUID? {
        await loadProfileIntoCache()
        return cachedUserProfile?.lastGeneratedStoryId
    }
    
    // MARK: - Monthly Usage Tracking Methods
    
    func getMonthlyUsageCount() async -> Int {
        await loadProfileIntoCache()
        await resetMonthlyUsageIfNeeded()
        return cachedUserProfile?.monthlyStoryCount ?? 0
    }
    
    func canGenerateStoryThisMonth() async -> Bool {
        await resetMonthlyUsageIfNeeded()
        let monthlyCount = await getMonthlyUsageCount()
        let hasActiveSubscription = cachedUserProfile?.hasActiveSubscription ?? false
        
        // Premium users have unlimited access
        if hasActiveSubscription {
            return true
        }
        
        // Free users are limited to FreeTierLimits.storiesPerMonth per month
        return monthlyCount < FreeTierLimits.storiesPerMonth
    }
    
    func resetMonthlyUsageIfNeeded() async {
        await loadProfileIntoCache()
        guard let profile = cachedUserProfile else {
            logger.error("Cannot check monthly reset: UserProfile not loaded.")
            return
        }
        
        guard let lastReset = profile.lastUsageReset else {
            // First time setup - set reset date to start of current month
            let calendar = Calendar.current
            let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
            
            profile.lastUsageReset = startOfMonth
            profile.currentPeriodStart = startOfMonth
            
            do {
                try await userProfileRepository.update(profile)
                logger.info("Initialized monthly usage tracking")
            } catch {
                logger.error("Failed to initialize monthly usage: \(error.localizedDescription)")
            }
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Check if we're in a new month
        if !calendar.isDate(lastReset, equalTo: now, toGranularity: .month) {
            logger.info("New month detected, resetting monthly usage count")
            
            profile.monthlyStoryCount = 0
            profile.lastUsageReset = now
            profile.currentPeriodStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
            
            do {
                try await userProfileRepository.update(profile)
                logger.info("Monthly usage reset completed")
            } catch {
                logger.error("Failed to reset monthly usage: \(error.localizedDescription)")
            }
        }
    }
    
    func updateSubscriptionStatus(isActive: Bool, productId: String?, expiryDate: Date?) async {
        await loadProfileIntoCache()
        guard let profile = cachedUserProfile else {
            logger.error("Cannot update subscription status: UserProfile not loaded.")
            return
        }
        
        profile.hasActiveSubscription = isActive
        profile.subscriptionProductId = productId
        profile.subscriptionExpiryDate = expiryDate
        
        do {
            try await userProfileRepository.update(profile)
            logger.info("Updated subscription status: active=\(isActive), product=\(productId ?? "none")")
        } catch {
            logger.error("Failed to update subscription status: \(error.localizedDescription)")
        }
    }
    
    func trackPremiumFeatureUsage(_ feature: String) async {
        await loadProfileIntoCache()
        guard let profile = cachedUserProfile else {
            logger.error("Cannot track premium feature usage: UserProfile not loaded.")
            return
        }
        
        if !profile.premiumFeaturesUsed.contains(feature) {
            profile.premiumFeaturesUsed.append(feature)
            
            do {
                try await userProfileRepository.update(profile)
                logger.debug("Tracked premium feature usage: \(feature)")
            } catch {
                logger.error("Failed to track premium feature usage: \(error.localizedDescription)")
            }
        }
    }
    
}
