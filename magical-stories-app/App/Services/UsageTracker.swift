import Foundation
import OSLog

/// Service responsible for tracking usage limits for free tier users
@MainActor
final class UsageTracker: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var currentMonthUsage: UsageStats
    @Published private(set) var isLimitReached = false
    
    // MARK: - Data Models
    
    struct UsageStats: Codable, Equatable {
        var storiesGenerated: Int = 0
        var collectionsCreated: Int = 0
        var periodStart: Date = Date()
        var lastResetDate: Date = Date()
        
        var remainingStories: Int {
            return max(0, FreeTierLimits.storiesPerMonth - storiesGenerated)
        }
        
        var usagePercentage: Double {
            return min(1.0, Double(storiesGenerated) / Double(FreeTierLimits.storiesPerMonth))
        }
        
        var isAtLimit: Bool {
            return storiesGenerated >= FreeTierLimits.storiesPerMonth
        }
    }
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicalstories", 
                               category: "UsageTracker")
    private let userDefaults = UserDefaults.standard
    
    // User defaults keys for persistence
    private enum UserDefaultsKeys {
        static let usageStats = "usage_stats"
        static let lastUsageReset = "last_usage_reset"
        static let monthlyResetScheduled = "monthly_reset_scheduled"
    }
    
    // MARK: - Dependencies
    
    private let usageAnalyticsService: UsageAnalyticsServiceProtocol
    
    // MARK: - Initialization
    
    init(usageAnalyticsService: UsageAnalyticsServiceProtocol) {
        self.usageAnalyticsService = usageAnalyticsService
        
        // Load or initialize usage stats
        self.currentMonthUsage = Self.loadUsageStats()
        self.isLimitReached = currentMonthUsage.isAtLimit
        
        // Check if we need to reset for new month
        Task {
            await resetMonthlyUsageIfNeeded()
        }
        
        logger.info("UsageTracker initialized with \(self.currentMonthUsage.storiesGenerated) stories used this month")
    }
    
    // MARK: - Public API
    
    /// Increments the story generation count
    func incrementStoryGeneration() async {
        logger.info("Incrementing story generation count")
        
        currentMonthUsage.storiesGenerated += 1
        isLimitReached = currentMonthUsage.isAtLimit
        
        // Save to UserDefaults
        saveUsageStats()
        
        // Also update the analytics service
        await usageAnalyticsService.incrementStoryGenerationCount()
        await usageAnalyticsService.updateLastGenerationDate(date: Date())
        
        logger.info("Story count incremented to \(self.currentMonthUsage.storiesGenerated)/\(FreeTierLimits.storiesPerMonth)")
        
        // Track analytics if limit reached
        if isLimitReached {
            trackAnalyticsEvent(.usageLimitReached)
        }
    }
    
    /// Checks if the user can generate a story based on current usage
    /// - Returns: True if user can generate a story, false if limit reached
    func canGenerateStory() async -> Bool {
        // Reset if new month
        await resetMonthlyUsageIfNeeded()
        
        let canGenerate = !currentMonthUsage.isAtLimit
        
        if !canGenerate {
            logger.info("User cannot generate story - limit reached (\(self.currentMonthUsage.storiesGenerated)/\(FreeTierLimits.storiesPerMonth))")
        }
        
        return canGenerate
    }
    
    /// Gets the number of remaining stories for this month
    /// - Returns: Number of stories remaining
    func getRemainingStories() async -> Int {
        await resetMonthlyUsageIfNeeded()
        return currentMonthUsage.remainingStories
    }
    
    /// Gets the current usage count
    /// - Returns: Number of stories generated this month
    func getCurrentUsage() async -> Int {
        await resetMonthlyUsageIfNeeded()
        return currentMonthUsage.storiesGenerated
    }
    
    /// Gets usage statistics for display
    /// - Returns: Current usage statistics
    func getUsageStatistics() async -> UsageStats {
        await resetMonthlyUsageIfNeeded()
        return currentMonthUsage
    }
    
    /// Resets monthly usage counters (called automatically on month boundary)
    func resetMonthlyUsage() async {
        logger.info("Resetting monthly usage counters")
        
        let oldUsage = currentMonthUsage.storiesGenerated
        
        currentMonthUsage = UsageStats(
            storiesGenerated: 0,
            collectionsCreated: 0,
            periodStart: Date(),
            lastResetDate: Date()
        )
        
        isLimitReached = false
        
        // Save to UserDefaults
        saveUsageStats()
        
        // Update last reset timestamp
        userDefaults.set(Date(), forKey: UserDefaultsKeys.lastUsageReset)
        
        logger.info("Monthly usage reset completed. Previous usage: \(oldUsage) stories")
    }
    
    /// Resets usage when user upgrades to premium
    func resetUsageForPremiumUpgrade() async {
        logger.info("Resetting usage for premium upgrade")
        
        // Don't reset counters, but remove the limit restriction
        isLimitReached = false
        
        logger.info("Usage limit removed for premium user")
    }
    
    /// Resets usage when user downgrades from premium
    func resetForDowngrade() async {
        logger.info("Handling downgrade from premium")
        
        // Reapply limit checking
        isLimitReached = currentMonthUsage.isAtLimit
        
        if isLimitReached {
            logger.info("User downgraded and is now at usage limit")
        }
    }
    
    /// Checks if monthly reset is needed and performs it
    func resetMonthlyUsageIfNeeded() async {
        let calendar = Calendar.current
        let now = Date()
        let periodStart = currentMonthUsage.periodStart
        
        // Check if we're in a new month
        let periodStartComponents = calendar.dateComponents([.year, .month], from: periodStart)
        let nowComponents = calendar.dateComponents([.year, .month], from: now)
        
        if periodStartComponents.year != nowComponents.year || 
           periodStartComponents.month != nowComponents.month {
            
            logger.info("New month detected, resetting usage counters")
            await resetMonthlyUsage()
        }
    }
    
    // MARK: - Private Methods
    
    /// Loads usage stats from UserDefaults
    private static func loadUsageStats() -> UsageStats {
        guard let data = UserDefaults.standard.data(forKey: UserDefaultsKeys.usageStats),
              let stats = try? JSONDecoder().decode(UsageStats.self, from: data) else {
            // Return default stats for new users
            return UsageStats()
        }
        
        return stats
    }
    
    /// Saves current usage stats to UserDefaults
    private func saveUsageStats() {
        do {
            let data = try JSONEncoder().encode(currentMonthUsage)
            userDefaults.set(data, forKey: UserDefaultsKeys.usageStats)
            logger.debug("Usage stats saved successfully")
        } catch {
            logger.error("Failed to save usage stats: \(error.localizedDescription)")
        }
    }
    
    /// Tracks analytics events for usage actions
    /// - Parameter event: The analytics event to track
    private func trackAnalyticsEvent(_ event: SubscriptionAnalyticsEvent) {
        // TODO: Implement analytics tracking
        logger.debug("Analytics event: \(event.eventName)")
    }
}

// MARK: - Usage Display Helpers

extension UsageTracker {
    
    /// Gets user-friendly text for current usage
    var usageDisplayText: String {
        let used = self.currentMonthUsage.storiesGenerated
        let total = FreeTierLimits.storiesPerMonth
        return "\(used) of \(total) stories used this month"
    }
    
    /// Gets progress value for progress indicators (0.0 to 1.0)
    var usageProgress: Double {
        return self.currentMonthUsage.usagePercentage
    }
    
    /// Gets remaining days in current period
    var daysUntilReset: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: calendar.startOfMonth(for: now))!
        let daysRemaining = calendar.dateComponents([.day], from: now, to: startOfNextMonth).day ?? 0
        return max(0, daysRemaining)
    }
    
    /// Gets user-friendly text for when limits reset
    var resetDisplayText: String {
        let days = daysUntilReset
        if days == 0 {
            return "Resets tomorrow"
        } else if days == 1 {
            return "Resets in 1 day"
        } else {
            return "Resets in \(days) days"
        }
    }
}

// MARK: - Calendar Extension

private extension Calendar {
    
    /// Gets the start of the month for a given date
    /// - Parameter date: The date to get the start of month for
    /// - Returns: The start of the month
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}

// MARK: - Integration with Existing Analytics

extension UsageTracker {
    
    /// Synchronizes with existing UsageAnalyticsService
    func syncWithAnalyticsService() async {
        logger.info("Syncing with analytics service")
        
        // Get current count from analytics service
        let analyticsCount = await usageAnalyticsService.getStoryGenerationCount()
        
        // If analytics service has higher count, update our tracking
        if analyticsCount > self.currentMonthUsage.storiesGenerated {
            logger.info("Updating usage count from analytics service: \(analyticsCount)")
            
            self.currentMonthUsage.storiesGenerated = analyticsCount
            self.isLimitReached = self.currentMonthUsage.isAtLimit
            
            saveUsageStats()
        }
        
        logger.info("Sync completed - current usage: \(self.currentMonthUsage.storiesGenerated)")
    }
    
    /// Gets the last generation date from analytics service
    func getLastGenerationDate() async -> Date? {
        return await self.usageAnalyticsService.getLastGenerationDate()
    }
}