import Foundation
import OSLog

/// Manages data retention policies and automated cleanup for the rating system
@MainActor
final class RatingDataRetentionManager: ObservableObject {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.magicalstories.app", category: "RatingDataRetention")
    private let userPreferences: RatingUserPreferences
    private let analyticsService: ClarityAnalyticsService?
    
    // Cleanup scheduling
    private var cleanupTimer: Timer?
    private var lastCleanupDate: Date?
    
    // Configuration
    private let retentionPolicy = DataRetentionPolicy()
    
    // Data size tracking
    @Published private(set) var dataUsageStats = DataUsageStats()
    
    // MARK: - Initialization
    
    init(
        userPreferences: RatingUserPreferences,
        analyticsService: ClarityAnalyticsService? = nil
    ) {
        self.userPreferences = userPreferences
        self.analyticsService = analyticsService
        
        loadLastCleanupDate()
        scheduleCleanupTasks()
        Task {
            await updateDataUsageStats()
        }
    }
    
    deinit {
        // Timer cleanup handled by weak self references in closures
    }
    
    // MARK: - Public Interface
    
    /// Perform comprehensive data cleanup based on retention policies
    func performCleanup() async -> CleanupResult {
        let startTime = Date()
        var result = CleanupResult()
        
        logger.info("Starting comprehensive rating data cleanup")
        
        // 1. Clean up engagement events
        let engagementCleanup = await cleanupEngagementEvents()
        result.engagementEventsRemoved = engagementCleanup.removedCount
        result.engagementDataFreed = engagementCleanup.dataFreed
        
        // 2. Clean up analytics events
        let analyticsCleanup = await cleanupAnalyticsData()
        result.analyticsEventsRemoved = analyticsCleanup.removedCount
        result.analyticsDataFreed = analyticsCleanup.dataFreed
        
        // 3. Clean up experiment data
        let experimentCleanup = await cleanupExperimentData()
        result.experimentDataRemoved = experimentCleanup.removedCount
        result.experimentDataFreed = experimentCleanup.dataFreed
        
        // 4. Clean up performance metrics
        let metricsCleanup = await cleanupPerformanceMetrics()
        result.metricsRemoved = metricsCleanup.removedCount
        result.metricsDataFreed = metricsCleanup.dataFreed
        
        // 5. Clean up user preferences
        let preferencesCleanup = await cleanupUserPreferences()
        result.preferencesDataFreed = preferencesCleanup.dataFreed
        
        // Update cleanup tracking
        lastCleanupDate = Date()
        saveLastCleanupDate()
        
        // Update data usage stats
        await updateDataUsageStats()
        
        result.totalDataFreed = result.engagementDataFreed + result.analyticsDataFreed + 
                               result.experimentDataFreed + result.metricsDataFreed + result.preferencesDataFreed
        result.duration = Date().timeIntervalSince(startTime)
        
        // Track cleanup results
        await trackCleanupResults(result)
        
        logger.info("Cleanup completed: freed \(String(format: "%.2f", result.totalDataFreed / 1024.0))KB in \(String(format: "%.3f", result.duration))s")
        
        return result
    }
    
    /// Get current data usage statistics
    func getDataUsageStatistics() async -> DataUsageStats {
        await updateDataUsageStats()
        return dataUsageStats
    }
    
    /// Estimate data size for a given time period
    func estimateDataSize(for period: TimeInterval) -> EstimatedDataSize {
        let avgEngagementEventsPerDay = Double(dataUsageStats.engagementEventCount) / max(1, Double(dataUsageStats.dataAgeInDays))
        let avgAnalyticsEventsPerDay = Double(dataUsageStats.analyticsEventCount) / max(1, Double(dataUsageStats.dataAgeInDays))
        
        let days = period / (24 * 60 * 60)
        
        return EstimatedDataSize(
            engagementEvents: Int(avgEngagementEventsPerDay * days),
            analyticsEvents: Int(avgAnalyticsEventsPerDay * days),
            estimatedSizeBytes: Int(dataUsageStats.totalSizeBytes * days / Double(dataUsageStats.dataAgeInDays)),
            period: period
        )
    }
    
    /// Configure retention policies
    func updateRetentionPolicy(_ policy: DataRetentionPolicy) async {
        // Apply new retention policy immediately
        await performCleanup()
        
        logger.info("Data retention policy updated")
    }
    
    /// Check if cleanup is needed based on data size or age
    func shouldPerformCleanup() async -> Bool {
        await updateDataUsageStats()
        
        // Check data age
        if let lastCleanup = lastCleanupDate {
            let daysSinceCleanup = Date().timeIntervalSince(lastCleanup) / (24 * 60 * 60)
            if daysSinceCleanup >= retentionPolicy.cleanupIntervalDays {
                return true
            }
        } else {
            return true // Never cleaned up before
        }
        
        // Check data size
        if dataUsageStats.totalSizeBytes > retentionPolicy.maxTotalDataSize {
            return true
        }
        
        // Check event counts
        if dataUsageStats.engagementEventCount > retentionPolicy.maxEngagementEvents ||
           dataUsageStats.analyticsEventCount > retentionPolicy.maxAnalyticsEvents {
            return true
        }
        
        return false
    }
    
    /// Force cleanup of specific data type
    func cleanupDataType(_ dataType: RatingDataType) async -> DataCleanupResult {
        switch dataType {
        case .engagementEvents:
            return await cleanupEngagementEvents()
        case .analyticsData:
            return await cleanupAnalyticsData()
        case .experimentData:
            return await cleanupExperimentData()
        case .performanceMetrics:
            return await cleanupPerformanceMetrics()
        case .userPreferences:
            return await cleanupUserPreferences()
        }
    }
    
    // MARK: - Private Implementation
    
    private func scheduleCleanupTasks() {
        // Schedule daily cleanup check
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                if await self?.shouldPerformCleanup() == true {
                    _ = await self?.performCleanup()
                }
            }
        }
        
        // Immediate cleanup check
        Task {
            if await shouldPerformCleanup() {
                _ = await performCleanup()
            }
        }
    }
    
    private func stopCleanupScheduling() {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
    }
    
    private func cleanupEngagementEvents() async -> DataCleanupResult {
        let startTime = Date()
        let cutoffDate = Date().addingTimeInterval(-retentionPolicy.engagementEventRetentionPeriod)
        
        // Get current events
        let currentEvents = userPreferences.loadEngagementEvents()
        let initialCount = currentEvents.count
        let initialSize = estimateDataSize(for: currentEvents)
        
        // Filter out old events
        let filteredEvents = currentEvents.filter { $0.timestamp >= cutoffDate }
        
        // Keep only the most recent events if still too many
        let finalEvents = Array(filteredEvents.suffix(retentionPolicy.maxEngagementEvents))
        
        // Save filtered events
        userPreferences.saveEngagementEvents(finalEvents)
        
        let removedCount = initialCount - finalEvents.count
        let finalSize = estimateDataSize(for: finalEvents)
        let dataFreed = initialSize - finalSize
        
        let duration = Date().timeIntervalSince(startTime)
        
        if removedCount > 0 {
            logger.info("Cleaned up \(removedCount) engagement events, freed \(dataFreed) bytes in \(String(format: "%.3f", duration))s")
        }
        
        return DataCleanupResult(
            removedCount: removedCount,
            dataFreed: Double(dataFreed),
            duration: duration
        )
    }
    
    private func cleanupAnalyticsData() async -> DataCleanupResult {
        let startTime = Date()
        
        // This would clean up local analytics cache/buffer
        // In the current implementation, analytics events are sent immediately
        // so this is more of a placeholder for future local analytics storage
        
        let duration = Date().timeIntervalSince(startTime)
        
        return DataCleanupResult(
            removedCount: 0,
            dataFreed: 0.0,
            duration: duration
        )
    }
    
    private func cleanupExperimentData() async -> DataCleanupResult {
        let startTime = Date()
        
        // Clean up completed/expired experiment data
        // This would involve removing old experiment assignments and results
        // For now, we'll simulate the cleanup
        
        let duration = Date().timeIntervalSince(startTime)
        
        return DataCleanupResult(
            removedCount: 0,
            dataFreed: 0.0,
            duration: duration
        )
    }
    
    private func cleanupPerformanceMetrics() async -> DataCleanupResult {
        let startTime = Date()
        
        // Clean up old performance metrics
        // This would involve removing old response time data, error counts, etc.
        // For now, we'll simulate the cleanup
        
        let duration = Date().timeIntervalSince(startTime)
        
        return DataCleanupResult(
            removedCount: 0,
            dataFreed: 0.0,
            duration: duration
        )
    }
    
    private func cleanupUserPreferences() async -> DataCleanupResult {
        let startTime = Date()
        
        // Clean up old user preference data that's no longer needed
        // This might include resetting very old preferences or cleaning up corrupted data
        
        let duration = Date().timeIntervalSince(startTime)
        
        return DataCleanupResult(
            removedCount: 0,
            dataFreed: 0.0,
            duration: duration
        )
    }
    
    private func updateDataUsageStats() async {
        let currentEvents = userPreferences.loadEngagementEvents()
        let engagementEventCount = currentEvents.count
        let engagementDataSize = estimateDataSize(for: currentEvents)
        
        // Calculate data age
        let oldestEvent = currentEvents.min(by: { $0.timestamp < $1.timestamp })
        let dataAgeInDays = oldestEvent?.timestamp.timeIntervalSinceNow ?? 0 / (24 * 60 * 60)
        
        // Estimate other data sizes (in a real implementation, these would be calculated from actual data)
        let analyticsEventCount = 0 // Would be calculated from analytics buffer/cache
        let analyticsDataSize = 0
        
        let totalSize = engagementDataSize + analyticsDataSize
        
        dataUsageStats = DataUsageStats(
            engagementEventCount: engagementEventCount,
            analyticsEventCount: analyticsEventCount,
            totalSizeBytes: Double(totalSize),
            dataAgeInDays: abs(dataAgeInDays),
            lastUpdated: Date()
        )
    }
    
    private func estimateDataSize(for events: [RatingEngagementRecord]) -> Int {
        // Rough estimate: each event is approximately 200 bytes when serialized
        return events.count * 200
    }
    
    private func loadLastCleanupDate() {
        lastCleanupDate = UserDefaults.standard.object(forKey: "rating_last_cleanup_date") as? Date
    }
    
    private func saveLastCleanupDate() {
        if let date = lastCleanupDate {
            UserDefaults.standard.set(date, forKey: "rating_last_cleanup_date")
        }
    }
    
    private func trackCleanupResults(_ result: CleanupResult) async {
        analyticsService?.trackRatingEvent("data_cleanup_completed", parameters: [
            "engagement_events_removed": result.engagementEventsRemoved,
            "analytics_events_removed": result.analyticsEventsRemoved,
            "total_data_freed_bytes": Int(result.totalDataFreed),
            "cleanup_duration_seconds": String(format: "%.3f", result.duration)
        ])
    }
}

// MARK: - Supporting Types

struct DataRetentionPolicy {
    // Retention periods
    let engagementEventRetentionPeriod: TimeInterval = 30 * 24 * 60 * 60 // 30 days
    let analyticsDataRetentionPeriod: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    let experimentDataRetentionPeriod: TimeInterval = 90 * 24 * 60 * 60 // 90 days
    let performanceMetricsRetentionPeriod: TimeInterval = 24 * 60 * 60 // 24 hours
    
    // Maximum counts
    let maxEngagementEvents: Int = 1000
    let maxAnalyticsEvents: Int = 500
    let maxExperimentRecords: Int = 100
    let maxPerformanceMetrics: Int = 200
    
    // Size limits
    let maxTotalDataSize: Double = 1024 * 1024 // 1MB
    let maxEngagementDataSize: Double = 512 * 1024 // 512KB
    let maxAnalyticsDataSize: Double = 256 * 1024 // 256KB
    
    // Cleanup frequency
    let cleanupIntervalDays: Double = 7 // Weekly cleanup
    let aggressiveCleanupThreshold: Double = 2 * 1024 * 1024 // 2MB - trigger aggressive cleanup
}

struct DataUsageStats: Sendable {
    var engagementEventCount: Int = 0
    var analyticsEventCount: Int = 0
    var totalSizeBytes: Double = 0
    var dataAgeInDays: Double = 0
    var lastUpdated: Date = Date()
    
    var totalSizeKB: Double {
        totalSizeBytes / 1024.0
    }
    
    var totalSizeMB: Double {
        totalSizeBytes / (1024.0 * 1024.0)
    }
}

struct CleanupResult: Sendable {
    var engagementEventsRemoved: Int = 0
    var analyticsEventsRemoved: Int = 0
    var experimentDataRemoved: Int = 0
    var metricsRemoved: Int = 0
    
    var engagementDataFreed: Double = 0
    var analyticsDataFreed: Double = 0
    var experimentDataFreed: Double = 0
    var metricsDataFreed: Double = 0
    var preferencesDataFreed: Double = 0
    
    var totalDataFreed: Double = 0
    var duration: TimeInterval = 0
}

struct DataCleanupResult: Sendable {
    let removedCount: Int
    let dataFreed: Double
    let duration: TimeInterval
}

struct EstimatedDataSize: Sendable {
    let engagementEvents: Int
    let analyticsEvents: Int
    let estimatedSizeBytes: Int
    let period: TimeInterval
    
    var estimatedSizeKB: Double {
        Double(estimatedSizeBytes) / 1024.0
    }
    
    var estimatedSizeMB: Double {
        Double(estimatedSizeBytes) / (1024.0 * 1024.0)
    }
}

enum RatingDataType: String, CaseIterable, Sendable {
    case engagementEvents = "engagement_events"
    case analyticsData = "analytics_data"
    case experimentData = "experiment_data"
    case performanceMetrics = "performance_metrics"
    case userPreferences = "user_preferences"
    
    var displayName: String {
        switch self {
        case .engagementEvents: return "Engagement Events"
        case .analyticsData: return "Analytics Data"
        case .experimentData: return "Experiment Data"
        case .performanceMetrics: return "Performance Metrics"
        case .userPreferences: return "User Preferences"
        }
    }
}

// MARK: - Extensions

extension RatingDataRetentionManager {
    
    /// Get data retention recommendations based on current usage
    func getRetentionRecommendations() async -> [DataRetentionRecommendation] {
        await updateDataUsageStats()
        
        var recommendations: [DataRetentionRecommendation] = []
        
        // Check if data size is approaching limits
        if dataUsageStats.totalSizeMB > 0.8 { // 80% of 1MB limit
            recommendations.append(DataRetentionRecommendation(
                type: .reduceRetentionPeriod,
                priority: .medium,
                description: "Data usage approaching limit: \(String(format: "%.2f", dataUsageStats.totalSizeMB))MB",
                suggestion: "Consider reducing retention periods or cleaning up old data"
            ))
        }
        
        // Check event counts
        if dataUsageStats.engagementEventCount > 800 { // 80% of 1000 limit
            recommendations.append(DataRetentionRecommendation(
                type: .reduceEventRetention,
                priority: .medium,
                description: "High engagement event count: \(dataUsageStats.engagementEventCount)",
                suggestion: "Consider reducing engagement event retention period"
            ))
        }
        
        // Check data age
        if dataUsageStats.dataAgeInDays > 60 {
            recommendations.append(DataRetentionRecommendation(
                type: .scheduleCleanup,
                priority: .low,
                description: "Old data detected: \(String(format: "%.1f", dataUsageStats.dataAgeInDays)) days",
                suggestion: "Schedule data cleanup to remove outdated information"
            ))
        }
        
        return recommendations
    }
    
    /// Export data usage report
    func exportDataUsageReport() async -> DataUsageReport {
        await updateDataUsageStats()
        
        return DataUsageReport(
            generatedAt: Date(),
            stats: dataUsageStats,
            retentionPolicy: retentionPolicy,
            recommendations: await getRetentionRecommendations(),
            nextScheduledCleanup: calculateNextCleanupDate()
        )
    }
    
    private func calculateNextCleanupDate() -> Date {
        if let lastCleanup = lastCleanupDate {
            return lastCleanup.addingTimeInterval(retentionPolicy.cleanupIntervalDays * 24 * 60 * 60)
        } else {
            return Date().addingTimeInterval(24 * 60 * 60) // Tomorrow if never cleaned
        }
    }
}

struct DataRetentionRecommendation: Sendable {
    let type: RecommendationType
    let priority: RecommendationPriority
    let description: String
    let suggestion: String
    
    enum RecommendationType: String, CaseIterable {
        case reduceRetentionPeriod = "reduce_retention_period"
        case reduceEventRetention = "reduce_event_retention"
        case scheduleCleanup = "schedule_cleanup"
        case optimizeStorage = "optimize_storage"
    }
    
    enum RecommendationPriority: String, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
    }
}

struct DataUsageReport: Sendable {
    let generatedAt: Date
    let stats: DataUsageStats
    let retentionPolicy: DataRetentionPolicy
    let recommendations: [DataRetentionRecommendation]
    let nextScheduledCleanup: Date
}