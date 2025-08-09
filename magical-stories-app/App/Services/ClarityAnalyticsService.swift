import Foundation
import OSLog
import Clarity

/// Centralized analytics service using Microsoft Clarity
/// Provides privacy-first analytics with comprehensive user behavior tracking
@MainActor
final class ClarityAnalyticsService: ObservableObject {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.magicalstories.app", category: "ClarityAnalytics")
    private var isInitialized = false
    
    // MARK: - Singleton
    
    static let shared = ClarityAnalyticsService()
    
    private init() {}
    
    // MARK: - Initialization
    
    func initialize(projectId: String) {
        guard !isInitialized else {
            logger.info("Clarity Analytics already initialized")
            return
        }
        
        logger.info("Initializing Microsoft Clarity Analytics with project ID: \(projectId)")
        
        let clarityConfig = ClarityConfig(projectId: projectId)
        clarityConfig.logLevel = .info
        clarityConfig.applicationFramework = .native
        
        ClaritySDK.initialize(config: clarityConfig)
        
        isInitialized = true
        logger.info("Clarity Analytics initialized successfully")
    }
    
    // MARK: - Screen Tracking
    
    func trackScreenView(_ screenName: String, parameters: [String: Any]? = nil) {
        guard isInitialized else { return }
        
        logger.info("Tracking screen view: \(screenName)")
        
        ClaritySDK.setCurrentScreenName(screenName)
        
        if let params = parameters {
            logger.debug("Screen parameters: \(String(describing: params))")
        }
    }
    
    // MARK: - User Events
    
    func trackUserAction(_ action: String, parameters: [String: Any]? = nil) {
        guard isInitialized else { return }
        
        logger.info("Tracking user action: \(action)")
        
        ClaritySDK.sendCustomEvent(value: action)
        
        if let params = parameters {
            logger.debug("Action parameters: \(String(describing: params))")
        }
    }
    
    // MARK: - Story Generation Events
    
    func trackStoryGenerationStarted(ageGroup: String, category: String) {
        trackUserAction("story_generation_started", parameters: [
            "age_group": ageGroup,
            "category": category,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackStoryGenerationCompleted(ageGroup: String, category: String, duration: TimeInterval) {
        trackUserAction("story_generation_completed", parameters: [
            "age_group": ageGroup,
            "category": category,
            "duration_seconds": duration,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackStoryGenerationFailed(ageGroup: String, category: String, error: String) {
        trackUserAction("story_generation_failed", parameters: [
            "age_group": ageGroup,
            "category": category,
            "error": error,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // MARK: - Illustration Events
    
    func trackIllustrationGenerationStarted(storyId: String) {
        trackUserAction("illustration_generation_started", parameters: [
            "story_id": storyId,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackIllustrationGenerationCompleted(storyId: String, duration: TimeInterval) {
        trackUserAction("illustration_generation_completed", parameters: [
            "story_id": storyId,
            "duration_seconds": duration,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackIllustrationGenerationFailed(storyId: String, error: String) {
        trackUserAction("illustration_generation_failed", parameters: [
            "story_id": storyId,
            "error": error,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // MARK: - Subscription Events
    
    func trackPaywallShown(source: String) {
        trackUserAction("paywall_shown", parameters: [
            "source": source,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackSubscriptionStarted(productId: String, source: String) {
        trackUserAction("subscription_started", parameters: [
            "product_id": productId,
            "source": source,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackSubscriptionCompleted(productId: String, source: String) {
        trackUserAction("subscription_completed", parameters: [
            "product_id": productId,
            "source": source,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackSubscriptionFailed(productId: String, source: String, error: String) {
        trackUserAction("subscription_failed", parameters: [
            "product_id": productId,
            "source": source,
            "error": error,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackUsageLimitReached(limitType: String, currentUsage: Int) {
        trackUserAction("usage_limit_reached", parameters: [
            "limit_type": limitType,
            "current_usage": currentUsage,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // MARK: - Collection Events
    
    func trackCollectionCreated(collectionId: String, category: String) {
        trackUserAction("collection_created", parameters: [
            "collection_id": collectionId,
            "category": category,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackCollectionViewed(collectionId: String, storyCount: Int) {
        trackUserAction("collection_viewed", parameters: [
            "collection_id": collectionId,
            "story_count": storyCount,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // MARK: - Rating System Analytics
    
    func trackRatingEvent(_ event: String, parameters: [String: Any]? = nil) {
        var eventParams = parameters ?? [:]
        eventParams["timestamp"] = Date().timeIntervalSince1970
        eventParams["event_category"] = "rating_system"
        trackUserAction("rating_\(event)", parameters: eventParams)
    }
    
    func trackRatingTriggerEvaluation(
        passed: Bool, 
        engagementScore: Double,
        requiredScore: Double,
        failureReason: String? = nil,
        metadata: [String: Any] = [:]
    ) {
        var params = metadata
        params["trigger_passed"] = passed
        params["engagement_score"] = String(format: "%.3f", engagementScore)
        params["required_score"] = String(format: "%.3f", requiredScore)
        if let reason = failureReason {
            params["failure_reason"] = reason
        }
        trackRatingEvent("trigger_evaluated", parameters: params)
    }
    
    func trackRatingPromptShown(
        method: String,
        engagementScore: Double,
        triggerType: String,
        experimentVariant: String? = nil
    ) {
        var params: [String: Any] = [
            "rating_method": method,
            "engagement_score": String(format: "%.3f", engagementScore),
            "trigger_type": triggerType
        ]
        if let variant = experimentVariant {
            params["experiment_variant"] = variant
        }
        trackRatingEvent("prompt_shown", parameters: params)
    }
    
    func trackRatingPromptInteraction(
        action: String,
        method: String,
        timeSinceShown: TimeInterval,
        experimentVariant: String? = nil
    ) {
        var params: [String: Any] = [
            "action": action, // "rated", "dismissed", "remind_later", "dont_ask_again"
            "rating_method": method,
            "interaction_time_seconds": timeSinceShown
        ]
        if let variant = experimentVariant {
            params["experiment_variant"] = variant
        }
        trackRatingEvent("prompt_interaction", parameters: params)
    }
    
    func trackRatingEngagementEvent(
        event: String,
        weight: Double,
        currentScore: Double,
        metadata: [String: Any] = [:]
    ) {
        var params = metadata
        params["engagement_event"] = event
        params["event_weight"] = String(format: "%.2f", weight)
        params["current_score"] = String(format: "%.3f", currentScore)
        trackRatingEvent("engagement_event", parameters: params)
    }
    
    func trackRatingSystemHealthCheck(
        component: String,
        status: String,
        responseTime: TimeInterval? = nil,
        errorDetails: String? = nil
    ) {
        var params: [String: Any] = [
            "component": component,
            "health_status": status
        ]
        if let responseTime = responseTime {
            params["response_time_ms"] = Int(responseTime * 1000)
        }
        if let error = errorDetails {
            params["error_details"] = error
        }
        trackRatingEvent("health_check", parameters: params)
    }
    
    func trackRatingKPI(
        metric: String,
        value: Double,
        period: String, // "daily", "weekly", "monthly"
        metadata: [String: Any] = [:]
    ) {
        var params = metadata
        params["kpi_metric"] = metric
        params["kpi_value"] = String(format: "%.3f", value)
        params["measurement_period"] = period
        trackRatingEvent("kpi_measurement", parameters: params)
    }
    
    func trackExperimentAssignment(
        experimentId: String,
        variant: String,
        userId: String
    ) {
        trackRatingEvent("experiment_assigned", parameters: [
            "experiment_id": experimentId,
            "variant": variant,
            "user_id": userId
        ])
    }
    
    func trackExperimentConversion(
        experimentId: String,
        variant: String,
        conversionType: String,
        value: Double? = nil
    ) {
        var params: [String: Any] = [
            "experiment_id": experimentId,
            "variant": variant,
            "conversion_type": conversionType
        ]
        if let value = value {
            params["conversion_value"] = String(format: "%.3f", value)
        }
        
        trackRatingEvent("experiment_conversion", parameters: params)
    }
    
    // MARK: - User Journey Events
    
    func trackOnboardingStep(step: String, completed: Bool) {
        trackUserAction("onboarding_step", parameters: [
            "step": step,
            "completed": completed,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackFeatureDiscovered(feature: String, source: String) {
        trackUserAction("feature_discovered", parameters: [
            "feature": feature,
            "source": source,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // MARK: - Performance Events
    
    func trackAppLaunchTime(duration: TimeInterval) {
        trackUserAction("app_launch_time", parameters: [
            "duration_seconds": duration,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackAPIResponse(endpoint: String, duration: TimeInterval, success: Bool) {
        trackUserAction("api_response", parameters: [
            "endpoint": endpoint,
            "duration_seconds": duration,
            "success": success,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // MARK: - Error Tracking
    
    func trackError(error: any Error, context: String) {
        trackUserAction("error_occurred", parameters: [
            "error_description": error.localizedDescription,
            "context": context,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // MARK: - User Properties
    
    func setUserProperty(key: String, value: String) {
        guard isInitialized else { return }
        
        logger.info("Setting user property: \(key) = \(value)")
        
        ClaritySDK.setCustomUserId(value)
    }
    
    func setSubscriptionStatus(isPremium: Bool, productId: String?) {
        setUserProperty(key: "subscription_status", value: isPremium ? "premium" : "free")
        if let productId = productId {
            setUserProperty(key: "product_id", value: productId)
        }
    }
    
    // MARK: - Session Management
    
    func startNewSession() {
        guard isInitialized else { return }
        
        logger.info("Starting new analytics session")
        
        ClaritySDK.startNewSession(callback: nil)
    }
    
    func pauseSession() {
        guard isInitialized else { return }
        
        logger.info("Pausing analytics session")
        
        ClaritySDK.pause()
    }
    
    func resumeSession() {
        guard isInitialized else { return }
        
        logger.info("Resuming analytics session")
        
        ClaritySDK.resume()
    }
}

// MARK: - Analytics Event Extensions

extension ClarityAnalyticsService {
    
    /// Convenience method for tracking subscription funnel events
    func trackSubscriptionFunnelEvent(_ event: SubscriptionAnalyticsEvent, parameters: [String: Any]? = nil) {
        let eventName = event.eventName
        trackUserAction(eventName, parameters: parameters)
    }
    
    /// Convenience method for tracking story lifecycle events
    func trackStoryLifecycleEvent(_ event: String, storyId: String, parameters: [String: Any]? = nil) {
        var eventParams = parameters ?? [:]
        eventParams["story_id"] = storyId
        trackUserAction(event, parameters: eventParams)
    }
}