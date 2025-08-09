import Foundation
import OSLog

/// Manages rating trigger evaluation and user engagement scoring
final class RatingTriggerManager: RatingTriggerManagerProtocol, @unchecked Sendable {
    
    // MARK: - Private Properties
    
    private let userPreferences: RatingUserPreferences
    private let logger = Logger(subsystem: "com.magicalstories.app", category: "RatingTriggerManager")
    private var configuration: RatingConfiguration
    private let dateProvider: () -> Date
    
    // Thread-safe event storage
    private let eventQueue = DispatchQueue(label: "com.magicalstories.rating.events", qos: .utility)
    private var _engagementEvents: [RatingEngagementRecord] = []
    
    // MARK: - Initialization
    
    init(
        userPreferences: RatingUserPreferences,
        configuration: RatingConfiguration = .default,
        dateProvider: @escaping () -> Date = { Date() }
    ) {
        self.userPreferences = userPreferences
        self.configuration = configuration
        self.dateProvider = dateProvider
        
        // Load existing events asynchronously to avoid main actor issues
        self._engagementEvents = []
        
        // We'll load events later in an async context to avoid MainActor issues in init
        Task { @MainActor in
            let events = userPreferences.loadEngagementEvents()
            await eventQueue.sync {
                self._engagementEvents = events
            }
        }
        
        logger.info("RatingTriggerManager initialized with \(self._engagementEvents.count) existing events")
    }
    
    // MARK: - RatingTriggerManagerProtocol Implementation
    
    func shouldTriggerRating() async -> Bool {
        let currentDate = dateProvider()
        
        // Check if rating system is enabled
        guard configuration.isRatingSystemEnabled else {
            logger.debug("Rating system is disabled")
            return false
        }
        
        // Check if user has opted out
        if await MainActor.run(body: { userPreferences.hasOptedOutOfRatings }) {
            logger.debug("User has opted out of ratings")
            return false
        }
        
        // Check yearly limit
        let requestsThisYear = await MainActor.run(body: { userPreferences.getRatingRequestsThisYear() })
        if requestsThisYear >= configuration.maxRatingRequestsPerYear {
            logger.debug("Yearly rating request limit reached: \(requestsThisYear)/\(self.configuration.maxRatingRequestsPerYear)")
            return false
        }
        
        // Check time since last request
        if let daysSinceLastRequest = await MainActor.run(body: { userPreferences.getDaysSinceLastRatingRequest() }) {
            let userFrequency = await MainActor.run(body: { userPreferences.ratingFrequencyPreference })
            let adjustedMinimumDays = Int(Double(self.configuration.minimumDaysBetweenRequests) * userFrequency.daysBetweenRequestsMultiplier)
            
            if daysSinceLastRequest < adjustedMinimumDays {
                logger.debug("Too soon since last request: \(daysSinceLastRequest) days (minimum: \(adjustedMinimumDays))")
                return false
            }
        }
        
        // Check minimum app usage requirements
        let appLaunches = await MainActor.run(body: { userPreferences.getTotalAppLaunches() })
        if appLaunches < configuration.minimumAppLaunches {
            logger.debug("Insufficient app launches: \(appLaunches)/\(self.configuration.minimumAppLaunches)")
            return false
        }
        
        let storiesCreated = await MainActor.run(body: { userPreferences.getTotalStoriesCreated() })
        if storiesCreated < configuration.minimumStoriesCreated {
            logger.debug("Insufficient stories created: \(storiesCreated)/\(self.configuration.minimumStoriesCreated)")
            return false
        }
        
        let daysSinceFirstLaunch = await MainActor.run(body: { userPreferences.getDaysSinceFirstLaunch() })
        if daysSinceFirstLaunch < configuration.minimumDaysSinceFirstLaunch {
            logger.debug("Too soon since first launch: \(daysSinceFirstLaunch)/\(self.configuration.minimumDaysSinceFirstLaunch) days")
            return false
        }
        
        // Check engagement score
        let engagementScore = await calculateEngagementScore()
        let userFrequency = await MainActor.run(body: { userPreferences.ratingFrequencyPreference })
        let adjustedMinimumScore = self.configuration.minimumEngagementScore * userFrequency.engagementScoreMultiplier
        
        if engagementScore < adjustedMinimumScore {
            logger.debug("Insufficient engagement score: \(String(format: "%.3f", engagementScore))/\(String(format: "%.3f", adjustedMinimumScore))")
            return false
        }
        
        logger.info("Rating trigger conditions met - engagement score: \(String(format: "%.3f", engagementScore))")
        return true
    }
    
    func recordEvent(_ event: RatingTriggerEvent) async {
        let record = RatingEngagementRecord(event: event, timestamp: dateProvider())
        
        await eventQueue.sync {
            self._engagementEvents.append(record)
            
            // Keep only recent events to prevent unlimited growth
            let cutoffDate = self.dateProvider().addingTimeInterval(-TimeInterval(self.configuration.engagementScoringConfig.evaluationWindowDays * 24 * 60 * 60))
            self._engagementEvents = self._engagementEvents.filter { $0.timestamp >= cutoffDate }
            
            // Limit total number of stored events
            if self._engagementEvents.count > self.configuration.engagementScoringConfig.maxEventsToConsider {
                self._engagementEvents = Array(self._engagementEvents.suffix(self.configuration.engagementScoringConfig.maxEventsToConsider))
            }
        }
        
        // Save to persistent storage
        await MainActor.run {
            userPreferences.saveEngagementEvents(self._engagementEvents)
        }
        
        if self.configuration.isDebugLoggingEnabled {
            logger.debug("Recorded engagement event: \(event.rawValue) (weight: \(String(format: "%.2f", event.engagementWeight)))")
        }
    }
    
    func calculateEngagementScore() async -> Double {
        let currentDate = dateProvider()
        let scoringConfig = configuration.engagementScoringConfig
        let evaluationWindow = TimeInterval(scoringConfig.evaluationWindowDays * 24 * 60 * 60)
        let cutoffDate = currentDate.addingTimeInterval(-evaluationWindow)
        
        let recentEvents = await eventQueue.sync { () -> [RatingEngagementRecord] in
            return self._engagementEvents.filter { $0.timestamp >= cutoffDate }
        }
        
        // Check minimum events threshold
        guard recentEvents.count >= scoringConfig.minimumEventsThreshold else {
            logger.debug("Insufficient events for scoring: \(recentEvents.count)/\(scoringConfig.minimumEventsThreshold)")
            return 0.0
        }
        
        // Calculate weighted score with time decay
        var totalScore = 0.0
        var totalWeight = 0.0
        
        for event in recentEvents {
            let eventAge = currentDate.timeIntervalSince(event.timestamp)
            let ageInDays = eventAge / (24 * 60 * 60)
            
            // Apply time decay: newer events have higher weight
            let decayFactor = max(0.0, 1.0 - (ageInDays / Double(scoringConfig.evaluationWindowDays)) * scoringConfig.timeDecayFactor)
            let adjustedWeight = event.event.engagementWeight * decayFactor
            
            totalScore += adjustedWeight
            totalWeight += decayFactor
        }
        
        // Normalize score
        let normalizedScore = totalWeight > 0 ? totalScore / totalWeight : 0.0
        
        // Apply logarithmic scaling to prevent score from being too high with many events
        let scaledScore = min(1.0, sqrt(normalizedScore))
        
        if self.configuration.isDebugLoggingEnabled {
            logger.debug("Engagement score calculated: \(String(format: "%.3f", scaledScore)) from \(recentEvents.count) events")
        }
        
        return scaledScore
    }
    
    func timeSinceLastRatingRequest() async -> TimeInterval? {
        guard let lastRequestDate = await MainActor.run(body: { userPreferences.getLastRatingRequestDate() }) else {
            return nil
        }
        return dateProvider().timeIntervalSince(lastRequestDate)
    }
    
    func ratingRequestsThisYear() async -> Int {
        return await MainActor.run(body: { userPreferences.getRatingRequestsThisYear() })
    }
    
    func recordRatingRequestShown() async {
        await MainActor.run {
            userPreferences.recordRatingRequestShown()
        }
        logger.info("Rating request shown recorded")
    }
    
    func resetTrackingData() async {
        await eventQueue.sync {
            self._engagementEvents.removeAll()
        }
        
        await MainActor.run {
            userPreferences.resetEngagementData()
        }
        
        logger.info("Rating tracking data reset")
    }
    
    func updateConfiguration(_ configuration: RatingConfiguration) async {
        self.configuration = configuration
        
        // Reload events with new configuration limits
        await eventQueue.sync {
            self._engagementEvents = []
        }
        
        let loadedEvents = await MainActor.run {
            userPreferences.loadEngagementEvents()
        }
        
        await eventQueue.sync { [self] in
            self._engagementEvents = loadedEvents
            
            // Apply new limits
            let cutoffDate = self.dateProvider().addingTimeInterval(-TimeInterval(self.configuration.engagementScoringConfig.evaluationWindowDays * 24 * 60 * 60))
            self._engagementEvents = self._engagementEvents.filter { $0.timestamp >= cutoffDate }
            
            if self._engagementEvents.count > self.configuration.engagementScoringConfig.maxEventsToConsider {
                self._engagementEvents = Array(self._engagementEvents.suffix(self.configuration.engagementScoringConfig.maxEventsToConsider))
            }
        }
        
        await MainActor.run {
            userPreferences.saveEngagementEvents(self._engagementEvents)
        }
        
        logger.info("Rating configuration updated")
    }
    
    // MARK: - Additional Public Methods
    
    /// Gets detailed engagement analysis for debugging or analytics
    func getEngagementAnalysis() async -> EngagementAnalysis {
        let currentDate = dateProvider()
        let scoringConfig = configuration.engagementScoringConfig
        let evaluationWindow = TimeInterval(scoringConfig.evaluationWindowDays * 24 * 60 * 60)
        let cutoffDate = currentDate.addingTimeInterval(-evaluationWindow)
        
        let recentEvents = await eventQueue.sync { () -> [RatingEngagementRecord] in
            return self._engagementEvents.filter { $0.timestamp >= cutoffDate }
        }
        
        let engagementScore = await calculateEngagementScore()
        
        // Calculate event breakdown
        var eventBreakdown: [RatingTriggerEvent: Int] = [:]
        for event in recentEvents {
            eventBreakdown[event.event, default: 0] += 1
        }
        
        // Get additional metrics from user preferences
        let appLaunches = await MainActor.run { userPreferences.getTotalAppLaunches() }
        let storiesCreated = await MainActor.run { userPreferences.getTotalStoriesCreated() }
        let ratingRequestsShown = await MainActor.run { userPreferences.getRatingRequestsThisYear() }
        
        return EngagementAnalysis(
            totalEvents: recentEvents.count,
            eventBreakdown: eventBreakdown,
            engagementScore: engagementScore,
            evaluationWindowDays: scoringConfig.evaluationWindowDays,
            oldestEventDate: recentEvents.first?.timestamp,
            newestEventDate: recentEvents.last?.timestamp,
            appLaunches: appLaunches,
            storiesCreated: storiesCreated,
            ratingRequestsShown: ratingRequestsShown
        )
    }
    
    /// Gets recent events for debugging
    func getRecentEvents(limit: Int = 20) async -> [RatingEngagementRecord] {
        return await eventQueue.sync {
            return Array(self._engagementEvents.suffix(limit))
        }
    }
}

// MARK: - Supporting Types

/// Detailed analysis of user engagement for debugging and analytics
public struct EngagementAnalysis: Sendable {
    public let totalEvents: Int
    public let eventBreakdown: [RatingTriggerEvent: Int]
    public let engagementScore: Double
    public let evaluationWindowDays: Int
    public let oldestEventDate: Date?
    public let newestEventDate: Date?
    
    // Additional debug properties
    public let appLaunches: Int
    public let storiesCreated: Int
    public let ratingRequestsShown: Int
    
    public init(
        totalEvents: Int = 0,
        eventBreakdown: [RatingTriggerEvent: Int] = [:],
        engagementScore: Double = 0.0,
        evaluationWindowDays: Int = 30,
        oldestEventDate: Date? = nil,
        newestEventDate: Date? = nil,
        appLaunches: Int = 0,
        storiesCreated: Int = 0,
        ratingRequestsShown: Int = 0
    ) {
        self.totalEvents = totalEvents
        self.eventBreakdown = eventBreakdown
        self.engagementScore = engagementScore
        self.evaluationWindowDays = evaluationWindowDays
        self.oldestEventDate = oldestEventDate
        self.newestEventDate = newestEventDate
        self.appLaunches = appLaunches
        self.storiesCreated = storiesCreated
        self.ratingRequestsShown = ratingRequestsShown
    }
    
    /// Summary description of the engagement analysis
    public var summary: String {
        return """
        Engagement Analysis:
        - Total Events: \(totalEvents)
        - Engagement Score: \(String(format: "%.3f", engagementScore))
        - Evaluation Window: \(evaluationWindowDays) days
        - Date Range: \(oldestEventDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A") - \(newestEventDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")
        - Top Events: \(topEvents)
        """
    }
    
    private var topEvents: String {
        let sortedEvents = eventBreakdown.sorted { $0.value > $1.value }
        return sortedEvents.prefix(3).map { "\($0.key.displayName): \($0.value)" }.joined(separator: ", ")
    }
}