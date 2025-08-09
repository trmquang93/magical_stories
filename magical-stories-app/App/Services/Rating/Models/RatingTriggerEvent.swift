import Foundation

/// Represents different types of user engagement events that can trigger rating requests
public enum RatingTriggerEvent: String, CaseIterable, Codable, Sendable {
    // Story-related events
    case storyCreated = "story_created"
    case storyCompleted = "story_completed"
    case storyShared = "story_shared"
    case storyFavorited = "story_favorited"
    
    // Collection-related events
    case collectionCreated = "collection_created"
    case collectionCompleted = "collection_completed"
    
    // Subscription-related events
    case subscribed = "subscribed"
    case subscriptionRenewed = "subscription_renewed"
    
    // App usage events
    case appLaunched = "app_launched"
    case sessionCompleted = "session_completed"
    case weeklyGoalReached = "weekly_goal_reached"
    case achievementUnlocked = "achievement_unlocked"
    
    // Engagement depth events
    case longSessionCompleted = "long_session_completed" // > 10 minutes
    case multipleStoriesInSession = "multiple_stories_session" // > 3 stories
    case returningUserSession = "returning_user_session" // user returned after 7+ days
    
    /// Weight of the event for engagement scoring (0.0 to 1.0)
    public var engagementWeight: Double {
        switch self {
        case .storyCreated: return 0.3
        case .storyCompleted: return 0.5
        case .storyShared: return 0.8
        case .storyFavorited: return 0.4
        case .collectionCreated: return 0.6
        case .collectionCompleted: return 0.9
        case .subscribed: return 1.0
        case .subscriptionRenewed: return 0.7
        case .appLaunched: return 0.1
        case .sessionCompleted: return 0.2
        case .weeklyGoalReached: return 0.8
        case .achievementUnlocked: return 0.6
        case .longSessionCompleted: return 0.7
        case .multipleStoriesInSession: return 0.6
        case .returningUserSession: return 0.5
        }
    }
    
    /// Display name for the event
    public var displayName: String {
        switch self {
        case .storyCreated: return "Story Created"
        case .storyCompleted: return "Story Completed"
        case .storyShared: return "Story Shared"
        case .storyFavorited: return "Story Favorited"
        case .collectionCreated: return "Collection Created"
        case .collectionCompleted: return "Collection Completed"
        case .subscribed: return "Subscribed"
        case .subscriptionRenewed: return "Subscription Renewed"
        case .appLaunched: return "App Launched"
        case .sessionCompleted: return "Session Completed"
        case .weeklyGoalReached: return "Weekly Goal Reached"
        case .achievementUnlocked: return "Achievement Unlocked"
        case .longSessionCompleted: return "Long Session Completed"
        case .multipleStoriesInSession: return "Multiple Stories in Session"
        case .returningUserSession: return "Returning User Session"
        }
    }
}

/// Represents a recorded engagement event with timestamp and metadata
public struct RatingEngagementRecord: Codable, Sendable {
    public let event: RatingTriggerEvent
    public let timestamp: Date
    public let metadata: [String: String]?
    
    public init(event: RatingTriggerEvent, timestamp: Date = Date(), metadata: [String: String]? = nil) {
        self.event = event
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

/// Configuration for engagement scoring parameters
public struct EngagementScoringConfiguration: Codable, Sendable {
    /// Time window for considering events (in days)
    public let evaluationWindowDays: Int
    
    /// Minimum events required before rating consideration
    public let minimumEventsThreshold: Int
    
    /// Minimum engagement score required (0.0 to 1.0)
    public let minimumEngagementScore: Double
    
    /// Weight decay factor for older events (0.0 to 1.0)
    public let timeDecayFactor: Double
    
    /// Maximum events to consider in scoring calculation
    public let maxEventsToConsider: Int
    
    public init(
        evaluationWindowDays: Int = 30,
        minimumEventsThreshold: Int = 5,
        minimumEngagementScore: Double = 0.6,
        timeDecayFactor: Double = 0.1,
        maxEventsToConsider: Int = 50
    ) {
        self.evaluationWindowDays = evaluationWindowDays
        self.minimumEventsThreshold = minimumEventsThreshold
        self.minimumEngagementScore = minimumEngagementScore
        self.timeDecayFactor = timeDecayFactor
        self.maxEventsToConsider = maxEventsToConsider
    }
}