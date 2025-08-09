import Foundation

/// Analytics events specific to the rating system
public enum RatingAnalyticsEvent: String, CaseIterable, Codable, Sendable {
    // Rating request events
    case ratingRequested = "rating_requested"
    case ratingRequestShown = "rating_request_shown"
    case ratingRequestDismissed = "rating_request_dismissed"
    case ratingCompleted = "rating_completed"
    case ratingDeclined = "rating_declined"
    
    // Trigger evaluation events
    case ratingTriggerEvaluated = "rating_trigger_evaluated"
    case ratingTriggerPassed = "rating_trigger_passed"
    case ratingTriggerFailed = "rating_trigger_failed"
    
    // Configuration events
    case ratingConfigurationUpdated = "rating_configuration_updated"
    case ratingDataReset = "rating_data_reset"
    
    // Auto-prompt events
    case ratingAutoEvaluationStarted = "rating_auto_evaluation_started"
    case ratingAutoEvaluationSkipped = "rating_auto_evaluation_skipped"
    case ratingAutoEvaluationTriggered = "rating_auto_evaluation_triggered"
    case ratingAutoRequestSucceeded = "rating_auto_request_succeeded"
    case ratingAutoRequestFailed = "rating_auto_request_failed"
    
    // Error events
    case ratingRequestFailed = "rating_request_failed"
    case ratingServiceError = "rating_service_error"
    
    /// Display name for the analytics event
    public var displayName: String {
        switch self {
        case .ratingRequested: return "Rating Requested"
        case .ratingRequestShown: return "Rating Request Shown"
        case .ratingRequestDismissed: return "Rating Request Dismissed"
        case .ratingCompleted: return "Rating Completed"
        case .ratingDeclined: return "Rating Declined"
        case .ratingTriggerEvaluated: return "Rating Trigger Evaluated"
        case .ratingTriggerPassed: return "Rating Trigger Passed"
        case .ratingTriggerFailed: return "Rating Trigger Failed"
        case .ratingConfigurationUpdated: return "Rating Configuration Updated"
        case .ratingDataReset: return "Rating Data Reset"
        case .ratingAutoEvaluationStarted: return "Auto Evaluation Started"
        case .ratingAutoEvaluationSkipped: return "Auto Evaluation Skipped"
        case .ratingAutoEvaluationTriggered: return "Auto Evaluation Triggered"
        case .ratingAutoRequestSucceeded: return "Auto Request Succeeded"
        case .ratingAutoRequestFailed: return "Auto Request Failed"
        case .ratingRequestFailed: return "Rating Request Failed"
        case .ratingServiceError: return "Rating Service Error"
        }
    }
    
    /// Category for grouping analytics events
    public var category: RatingAnalyticsCategory {
        switch self {
        case .ratingRequested, .ratingRequestShown, .ratingRequestDismissed, .ratingCompleted, .ratingDeclined:
            return .userInteraction
        case .ratingTriggerEvaluated, .ratingTriggerPassed, .ratingTriggerFailed:
            return .triggerEvaluation
        case .ratingAutoEvaluationStarted, .ratingAutoEvaluationSkipped, .ratingAutoEvaluationTriggered:
            return .triggerEvaluation
        case .ratingAutoRequestSucceeded:
            return .userInteraction
        case .ratingConfigurationUpdated, .ratingDataReset:
            return .configuration
        case .ratingRequestFailed, .ratingServiceError, .ratingAutoRequestFailed:
            return .error
        }
    }
}

/// Categories for organizing rating analytics events
public enum RatingAnalyticsCategory: String, CaseIterable, Codable, Sendable {
    case userInteraction = "user_interaction"
    case triggerEvaluation = "trigger_evaluation"
    case configuration = "configuration"
    case error = "error"
    
    /// Display name for the category
    public var displayName: String {
        switch self {
        case .userInteraction: return "User Interaction"
        case .triggerEvaluation: return "Trigger Evaluation"
        case .configuration: return "Configuration"
        case .error: return "Error"
        }
    }
}

/// Represents a rating analytics event with metadata
public struct RatingAnalyticsRecord: Codable, Sendable {
    public let event: RatingAnalyticsEvent
    public let timestamp: Date
    public let engagementScore: Double?
    public let triggerReason: String?
    public let metadata: [String: String]
    
    public init(
        event: RatingAnalyticsEvent,
        timestamp: Date = Date(),
        engagementScore: Double? = nil,
        triggerReason: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.event = event
        self.timestamp = timestamp
        self.engagementScore = engagementScore
        self.triggerReason = triggerReason
        self.metadata = metadata
    }
}

/// Configuration for rating analytics tracking
public struct RatingAnalyticsConfiguration: Codable, Sendable {
    /// Whether analytics tracking is enabled
    public let isEnabled: Bool
    
    /// Categories of events to track
    public let trackedCategories: Set<RatingAnalyticsCategory>
    
    /// Maximum number of analytics records to store locally
    public let maxLocalRecords: Int
    
    /// Whether to include detailed metadata in analytics
    public let includeDetailedMetadata: Bool
    
    public init(
        isEnabled: Bool = true,
        trackedCategories: Set<RatingAnalyticsCategory> = Set(RatingAnalyticsCategory.allCases),
        maxLocalRecords: Int = 1000,
        includeDetailedMetadata: Bool = true
    ) {
        self.isEnabled = isEnabled
        self.trackedCategories = trackedCategories
        self.maxLocalRecords = maxLocalRecords
        self.includeDetailedMetadata = includeDetailedMetadata
    }
}