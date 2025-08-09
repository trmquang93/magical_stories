import Foundation

/// Configuration for the rating system behavior
public struct RatingConfiguration: Sendable {
    // MARK: - Apple Guidelines Compliance
    
    /// Maximum number of rating requests allowed per year (Apple's limit)
    public let maxRatingRequestsPerYear: Int
    
    /// Minimum time between rating requests (in days)
    public let minimumDaysBetweenRequests: Int
    
    // MARK: - Engagement Requirements
    
    /// Minimum engagement score required before requesting rating (0.0 to 1.0)
    public let minimumEngagementScore: Double
    
    /// Minimum number of app launches before considering rating
    public let minimumAppLaunches: Int
    
    /// Minimum number of stories created before considering rating
    public let minimumStoriesCreated: Int
    
    /// Minimum number of days since first app launch
    public let minimumDaysSinceFirstLaunch: Int
    
    // MARK: - Feature Flags
    
    /// Whether the rating system is enabled
    public let isRatingSystemEnabled: Bool
    
    /// Whether to use iOS 18+ AppStore.requestReview when available
    public let useAppStoreReviewWhenAvailable: Bool
    
    /// Whether analytics tracking is enabled for rating events
    public let isAnalyticsEnabled: Bool
    
    /// Whether debug logging is enabled
    public let isDebugLoggingEnabled: Bool
    
    // MARK: - Advanced Settings
    
    /// Engagement scoring configuration
    public let engagementScoringConfig: EngagementScoringConfiguration
    
    /// Analytics configuration
    public let analyticsConfig: RatingAnalyticsConfiguration
    
    /// Custom trigger conditions (for advanced use cases)
    public let customTriggerConditions: [String: String]
    
    // MARK: - Initialization
    
    public init(
        maxRatingRequestsPerYear: Int = 3,
        minimumDaysBetweenRequests: Int = 30,
        minimumEngagementScore: Double = 0.6,
        minimumAppLaunches: Int = 5,
        minimumStoriesCreated: Int = 3,
        minimumDaysSinceFirstLaunch: Int = 3,
        isRatingSystemEnabled: Bool = true,
        useAppStoreReviewWhenAvailable: Bool = true,
        isAnalyticsEnabled: Bool = true,
        isDebugLoggingEnabled: Bool = false,
        engagementScoringConfig: EngagementScoringConfiguration = EngagementScoringConfiguration(),
        analyticsConfig: RatingAnalyticsConfiguration = RatingAnalyticsConfiguration(),
        customTriggerConditions: [String: String] = [:]
    ) {
        self.maxRatingRequestsPerYear = maxRatingRequestsPerYear
        self.minimumDaysBetweenRequests = minimumDaysBetweenRequests
        self.minimumEngagementScore = minimumEngagementScore
        self.minimumAppLaunches = minimumAppLaunches
        self.minimumStoriesCreated = minimumStoriesCreated
        self.minimumDaysSinceFirstLaunch = minimumDaysSinceFirstLaunch
        self.isRatingSystemEnabled = isRatingSystemEnabled
        self.useAppStoreReviewWhenAvailable = useAppStoreReviewWhenAvailable
        self.isAnalyticsEnabled = isAnalyticsEnabled
        self.isDebugLoggingEnabled = isDebugLoggingEnabled
        self.engagementScoringConfig = engagementScoringConfig
        self.analyticsConfig = analyticsConfig
        self.customTriggerConditions = customTriggerConditions
    }
    
    // MARK: - Preset Configurations
    
    /// Conservative configuration with higher thresholds
    public static let conservative = RatingConfiguration(
        maxRatingRequestsPerYear: 2,
        minimumDaysBetweenRequests: 45,
        minimumEngagementScore: 0.8,
        minimumAppLaunches: 10,
        minimumStoriesCreated: 5,
        minimumDaysSinceFirstLaunch: 7
    )
    
    /// Aggressive configuration with lower thresholds
    public static let aggressive = RatingConfiguration(
        maxRatingRequestsPerYear: 3,
        minimumDaysBetweenRequests: 14,
        minimumEngagementScore: 0.4,
        minimumAppLaunches: 3,
        minimumStoriesCreated: 2,
        minimumDaysSinceFirstLaunch: 1
    )
    
    /// Default balanced configuration
    public static let `default` = RatingConfiguration()
    
    /// Testing configuration with minimal requirements
    public static let testing = RatingConfiguration(
        maxRatingRequestsPerYear: 10,
        minimumDaysBetweenRequests: 0,
        minimumEngagementScore: 0.1,
        minimumAppLaunches: 1,
        minimumStoriesCreated: 1,
        minimumDaysSinceFirstLaunch: 0,
        isDebugLoggingEnabled: true
    )
}

// MARK: - Codable Implementation

extension RatingConfiguration: Codable {
    private enum CodingKeys: String, CodingKey {
        case maxRatingRequestsPerYear
        case minimumDaysBetweenRequests
        case minimumEngagementScore
        case minimumAppLaunches
        case minimumStoriesCreated
        case minimumDaysSinceFirstLaunch
        case isRatingSystemEnabled
        case useAppStoreReviewWhenAvailable
        case isAnalyticsEnabled
        case isDebugLoggingEnabled
        case engagementScoringConfig
        case analyticsConfig
        case customTriggerConditions
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        maxRatingRequestsPerYear = try container.decodeIfPresent(Int.self, forKey: .maxRatingRequestsPerYear) ?? 3
        minimumDaysBetweenRequests = try container.decodeIfPresent(Int.self, forKey: .minimumDaysBetweenRequests) ?? 30
        minimumEngagementScore = try container.decodeIfPresent(Double.self, forKey: .minimumEngagementScore) ?? 0.6
        minimumAppLaunches = try container.decodeIfPresent(Int.self, forKey: .minimumAppLaunches) ?? 5
        minimumStoriesCreated = try container.decodeIfPresent(Int.self, forKey: .minimumStoriesCreated) ?? 3
        minimumDaysSinceFirstLaunch = try container.decodeIfPresent(Int.self, forKey: .minimumDaysSinceFirstLaunch) ?? 3
        isRatingSystemEnabled = try container.decodeIfPresent(Bool.self, forKey: .isRatingSystemEnabled) ?? true
        useAppStoreReviewWhenAvailable = try container.decodeIfPresent(Bool.self, forKey: .useAppStoreReviewWhenAvailable) ?? true
        isAnalyticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .isAnalyticsEnabled) ?? true
        isDebugLoggingEnabled = try container.decodeIfPresent(Bool.self, forKey: .isDebugLoggingEnabled) ?? false
        engagementScoringConfig = try container.decodeIfPresent(EngagementScoringConfiguration.self, forKey: .engagementScoringConfig) ?? EngagementScoringConfiguration()
        analyticsConfig = try container.decodeIfPresent(RatingAnalyticsConfiguration.self, forKey: .analyticsConfig) ?? RatingAnalyticsConfiguration()
        customTriggerConditions = try container.decodeIfPresent([String: String].self, forKey: .customTriggerConditions) ?? [:]
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(maxRatingRequestsPerYear, forKey: .maxRatingRequestsPerYear)
        try container.encode(minimumDaysBetweenRequests, forKey: .minimumDaysBetweenRequests)
        try container.encode(minimumEngagementScore, forKey: .minimumEngagementScore)
        try container.encode(minimumAppLaunches, forKey: .minimumAppLaunches)
        try container.encode(minimumStoriesCreated, forKey: .minimumStoriesCreated)
        try container.encode(minimumDaysSinceFirstLaunch, forKey: .minimumDaysSinceFirstLaunch)
        try container.encode(isRatingSystemEnabled, forKey: .isRatingSystemEnabled)
        try container.encode(useAppStoreReviewWhenAvailable, forKey: .useAppStoreReviewWhenAvailable)
        try container.encode(isAnalyticsEnabled, forKey: .isAnalyticsEnabled)
        try container.encode(isDebugLoggingEnabled, forKey: .isDebugLoggingEnabled)
        try container.encode(engagementScoringConfig, forKey: .engagementScoringConfig)
        try container.encode(analyticsConfig, forKey: .analyticsConfig)
        try container.encode(customTriggerConditions, forKey: .customTriggerConditions)
    }
}

/// Error types for rating system operations
public enum RatingError: Error, LocalizedError, Sendable {
    case systemDisabled
    case rateLimited
    case insufficientEngagement(currentScore: Double, requiredScore: Double)
    case tooSoon(daysSinceLastRequest: Int, minimumDays: Int)
    case yearlyLimitReached(requestsThisYear: Int, maxRequests: Int)
    case storeKitUnavailable
    case requestFailed(underlyingError: (any Error)?)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .systemDisabled:
            return "Rating system is currently disabled"
        case .rateLimited:
            return "Rating requests are currently rate limited"
        case .insufficientEngagement(let current, let required):
            return "Insufficient user engagement (current: \(String(format: "%.2f", current)), required: \(String(format: "%.2f", required)))"
        case .tooSoon(let days, let minimum):
            return "Too soon since last rating request (\(days) days, minimum: \(minimum))"
        case .yearlyLimitReached(let requests, let max):
            return "Yearly rating request limit reached (\(requests)/\(max))"
        case .storeKitUnavailable:
            return "StoreKit rating functionality is not available"
        case .requestFailed(let error):
            return "Rating request failed: \(error?.localizedDescription ?? "Unknown error")"
        case .configurationError(let message):
            return "Rating configuration error: \(message)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .systemDisabled:
            return "The rating system has been disabled in configuration"
        case .rateLimited:
            return "Apple's rating request limits have been reached"
        case .insufficientEngagement:
            return "User has not shown sufficient engagement with the app"
        case .tooSoon:
            return "Not enough time has passed since the last rating request"
        case .yearlyLimitReached:
            return "Apple's yearly limit of rating requests has been reached"
        case .storeKitUnavailable:
            return "StoreKit framework is not available on this device"
        case .requestFailed:
            return "The underlying rating request failed"
        case .configurationError:
            return "Invalid rating system configuration"
        }
    }
}