import Foundation
import StoreKit
import OSLog

#if canImport(AppStore)
import AppStore
#endif

/// Main service for handling app rating requests with iOS 18 compatibility
@MainActor
final class RatingService: RatingServiceProtocol, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var isRatingRequestInProgress = false
    @Published private(set) var lastRatingRequestResult: RatingRequestResult?
    
    // MARK: - Dependencies
    
    private let userPreferences: RatingUserPreferences
    private let triggerManager: RatingTriggerManager
    private let analyticsService: ClarityAnalyticsService?
    private let ratingAnalytics: RatingAnalyticsService?
    private let experimentService: RatingExperimentService?
    private let featureFlagService: FeatureFlagService?
    private let logger = Logger(subsystem: "com.magicalstories.app", category: "RatingService")
    
    // MARK: - Configuration
    
    private var configuration: RatingConfiguration
    
    // MARK: - Initialization
    
    init(
        userPreferences: RatingUserPreferences? = nil,
        triggerManager: RatingTriggerManager? = nil,
        analyticsService: ClarityAnalyticsService? = nil,
        ratingAnalytics: RatingAnalyticsService? = nil,
        experimentService: RatingExperimentService? = nil,
        featureFlagService: FeatureFlagService? = nil,
        configuration: RatingConfiguration = .default
    ) {
        let prefs = userPreferences ?? RatingUserPreferences()
        self.userPreferences = prefs
        self.triggerManager = triggerManager ?? RatingTriggerManager(userPreferences: prefs, configuration: configuration)
        self.analyticsService = analyticsService ?? ClarityAnalyticsService.shared
        self.ratingAnalytics = ratingAnalytics
        self.experimentService = experimentService
        self.featureFlagService = featureFlagService ?? FeatureFlagService.shared
        self.configuration = configuration
        
        logger.info("RatingService initialized with configuration: \(configuration.isRatingSystemEnabled ? "enabled" : "disabled")")
    }
    
    // MARK: - RatingServiceProtocol Implementation
    
    func requestRating() async throws {
        guard !isRatingRequestInProgress else {
            throw RatingError.rateLimited
        }
        
        isRatingRequestInProgress = true
        defer { isRatingRequestInProgress = false }
        
        do {
            let engagementScore = await triggerManager.calculateEngagementScore()
            let experimentVariant = experimentService?.getVariant(for: "engagement_threshold_test")
            
            // Record analytics event with experiment context
            await recordAnalyticsEvent(.ratingRequested, metadata: [
                "trigger_type": "automatic",
                "engagement_score": String(format: "%.3f", engagementScore),
                "experiment_variant": experimentVariant ?? "none"
            ])
            
            // Use experiment-specific engagement threshold
            let requiredScore = experimentService?.getEngagementThreshold() ?? configuration.minimumEngagementScore
            let shouldTrigger = await triggerManager.shouldTriggerRating() && engagementScore >= requiredScore
            
            // Track trigger evaluation with experiment data
            ratingAnalytics?.trackRatingTriggerEvaluation(
                passed: shouldTrigger,
                engagementScore: engagementScore,
                requiredScore: requiredScore,
                failureReason: shouldTrigger ? nil : "insufficient_engagement",
                experimentVariant: experimentVariant
            )
            
            await recordAnalyticsEvent(.ratingTriggerEvaluated, metadata: [
                "result": shouldTrigger ? "passed" : "failed",
                "required_score": String(format: "%.3f", requiredScore),
                "experiment_variant": experimentVariant ?? "none"
            ])
            
            guard shouldTrigger else {
                await recordAnalyticsEvent(.ratingTriggerFailed)
                experimentService?.recordConversion(
                    experimentId: "engagement_threshold_test",
                    conversionType: .promptDismissed
                )
                throw RatingError.insufficientEngagement(
                    currentScore: engagementScore,
                    requiredScore: requiredScore
                )
            }
            
            await recordAnalyticsEvent(.ratingTriggerPassed)
            
            // Make the rating request with experiment-based configuration
            try await performRatingRequest(experimentVariant: experimentVariant)
            
            // Record successful request
            await triggerManager.recordRatingRequestShown()
            
            let result = RatingRequestResult.success
            lastRatingRequestResult = result
            
            let ratingMethod = getPreferredRatingMethod().rawValue
            
            // Track prompt shown with experiment data
            ratingAnalytics?.trackRatingPromptShown(
                method: ratingMethod,
                engagementScore: engagementScore,
                triggerType: "automatic",
                experimentVariant: experimentVariant
            )
            
            await recordAnalyticsEvent(.ratingRequestShown, metadata: [
                "method": ratingMethod,
                "experiment_variant": experimentVariant ?? "none"
            ])
            
            // Record experiment conversion
            experimentService?.recordConversion(
                experimentId: "engagement_threshold_test",
                conversionType: .promptShown
            )
            
            logger.info("Rating request completed successfully with variant: \(experimentVariant ?? "none")")
            
        } catch {
            let result = RatingRequestResult.failure(error)
            lastRatingRequestResult = result
            
            await recordAnalyticsEvent(.ratingRequestFailed, metadata: [
                "error": error.localizedDescription
            ])
            
            logger.error("Rating request failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    func forceRatingRequest() async throws {
        guard !isRatingRequestInProgress else {
            throw RatingError.rateLimited
        }
        
        isRatingRequestInProgress = true
        defer { isRatingRequestInProgress = false }
        
        do {
            await recordAnalyticsEvent(.ratingRequested, metadata: [
                "trigger_type": "forced",
                "bypass_conditions": "true"
            ])
            
            // Bypass normal trigger conditions for forced requests
            try await performRatingRequest()
            
            // Record the request (for tracking limits)
            await triggerManager.recordRatingRequestShown()
            
            let result = RatingRequestResult.success
            lastRatingRequestResult = result
            
            await recordAnalyticsEvent(.ratingRequestShown, metadata: [
                "method": getPreferredRatingMethod().rawValue,
                "forced": "true"
            ])
            
            logger.info("Forced rating request completed successfully")
            
        } catch {
            let result = RatingRequestResult.failure(error)
            lastRatingRequestResult = result
            
            await recordAnalyticsEvent(.ratingRequestFailed, metadata: [
                "error": error.localizedDescription,
                "forced": "true"
            ])
            
            logger.error("Forced rating request failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    func shouldRequestRating() async -> Bool {
        return await triggerManager.shouldTriggerRating()
    }
    
    func recordEngagementEvent(_ event: RatingTriggerEvent) async {
        await triggerManager.recordEvent(event)
        
        if configuration.isDebugLoggingEnabled {
            logger.debug("Engagement event recorded: \(event.rawValue)")
        }
    }
    
    func getCurrentEngagementScore() async -> Double {
        return await triggerManager.calculateEngagementScore()
    }
    
    func resetRatingData() async {
        await triggerManager.resetTrackingData()
        lastRatingRequestResult = nil
        
        await recordAnalyticsEvent(.ratingDataReset)
        logger.info("Rating data reset completed")
    }
    
    func updateConfiguration(_ configuration: RatingConfiguration) async {
        self.configuration = configuration
        await triggerManager.updateConfiguration(configuration)
        
        await recordAnalyticsEvent(.ratingConfigurationUpdated, metadata: [
            "enabled": String(configuration.isRatingSystemEnabled),
            "min_engagement_score": String(format: "%.2f", configuration.minimumEngagementScore)
        ])
        
        logger.info("Rating configuration updated")
    }
    
    // MARK: - Private Implementation
    
    private func performRatingRequest(experimentVariant: String? = nil) async throws {
        guard configuration.isRatingSystemEnabled else {
            throw RatingError.systemDisabled
        }
        
        let method = getPreferredRatingMethod()
        
        // Apply experiment-based timing if applicable
        if let timing = experimentService?.getPromptTiming() {
            try await applyPromptTiming(timing)
        }
        
        switch method {
        case .appStoreReview:
            try await performAppStoreReviewRequest()
        case .storeKitReview:
            try await performStoreKitReviewRequest()
        }
    }
    
    private func applyPromptTiming(_ timing: RatingPromptTiming) async throws {
        switch timing {
        case .immediate:
            // Show immediately - no delay
            break
        case .delayed:
            // Wait for additional engagement
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        case .smart:
            // Use ML-based timing - for now, use delayed
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        case .standard:
            // Default behavior - no delay
            break
        }
    }
    
    private func getPreferredRatingMethod() -> RatingMethod {
        // Check if iOS 18+ AppStore.requestReview is available and preferred
        if configuration.useAppStoreReviewWhenAvailable && isAppStoreReviewAvailable() {
            return .appStoreReview
        } else {
            return .storeKitReview
        }
    }
    
    private func isAppStoreReviewAvailable() -> Bool {
        #if canImport(AppStore)
        if #available(iOS 18.0, *) {
            return true
        }
        #endif
        return false
    }
    
    @available(iOS 18.0, *)
    private func performAppStoreReviewRequest() async throws {
        #if canImport(AppStore)
        do {
            try await AppStore.requestReview()
            logger.info("AppStore.requestReview completed successfully")
        } catch {
            logger.error("AppStore.requestReview failed: \(error.localizedDescription)")
            // Fall back to StoreKit if AppStore method fails
            try await performStoreKitReviewRequest()
        }
        #else
        throw RatingError.storeKitUnavailable
        #endif
    }
    
    private func performStoreKitReviewRequest() async throws {
        // StoreKit's requestReview must be called on the main actor
        await MainActor.run {
            SKStoreReviewController.requestReview()
        }
        logger.info("SKStoreReviewController.requestReview completed")
    }
    
    private func recordAnalyticsEvent(
        _ event: RatingAnalyticsEvent,
        engagementScore: Double? = nil,
        triggerReason: String? = nil,
        metadata: [String: String] = [:]
    ) async {
        guard configuration.isAnalyticsEnabled,
              let analyticsService = analyticsService else { return }
        
        let record = RatingAnalyticsRecord(
            event: event,
            engagementScore: engagementScore,
            triggerReason: triggerReason,
            metadata: metadata
        )
        
        // Send to analytics service using the correct method
        var params: [String: Any] = [
            "category": event.category.rawValue
        ]
        
        if let score = engagementScore {
            params["engagement_score"] = String(format: "%.3f", score)
        }
        
        if let reason = triggerReason {
            params["trigger_reason"] = reason
        }
        
        // Merge with metadata
        for (key, value) in metadata {
            params[key] = value
        }
        
        analyticsService.trackUserAction("rating_\(event.rawValue)", parameters: params)
        
        if configuration.isDebugLoggingEnabled {
            logger.debug("Analytics event recorded: \(event.rawValue)")
        }
    }
    
    // MARK: - Public Convenience Methods
    
    /// Records app launch and checks if rating should be requested
    func handleAppLaunch() async {
        userPreferences.recordAppLaunch()
        await recordEngagementEvent(.appLaunched)
        
        // Optionally auto-request rating on launch if conditions are met
        if configuration.customTriggerConditions["auto_request_on_launch"] as? Bool == true {
            do {
                try await requestRating()
            } catch {
                // Silently handle rating request failures on app launch
                logger.debug("Auto rating request on launch failed: \(error.localizedDescription)")
            }
        }
    }
    
    /// Records story creation event
    func handleStoryCreated() async {
        userPreferences.recordStoryCreation()
        await recordEngagementEvent(.storyCreated)
    }
    
    /// Records story completion event and evaluates rating eligibility
    func handleStoryCompleted() async {
        await recordEngagementEvent(.storyCompleted)
        
        // Auto-evaluate rating request if feature flag is enabled
        await evaluateAutoRatingRequest(after: .storyCompleted)
    }
    
    /// Records subscription event and evaluates rating eligibility
    func handleSubscriptionPurchased() async {
        await recordEngagementEvent(.subscribed)
        
        // Auto-evaluate rating request if feature flag is enabled
        await evaluateAutoRatingRequest(after: .subscribed)
    }
    
    /// Records app sharing event and evaluates rating eligibility
    func handleStoryShared() async {
        await recordEngagementEvent(.storyShared)
        
        // Auto-evaluate rating request if feature flag is enabled
        await evaluateAutoRatingRequest(after: .storyShared)
    }
    
    /// Gets engagement analysis for debugging
    func getEngagementAnalysis() async -> EngagementAnalysis {
        return await triggerManager.getEngagementAnalysis()
    }
    
    /// Gets recent engagement events for debugging
    func getRecentEvents(limit: Int = 20) async -> [RatingEngagementRecord] {
        return await triggerManager.getRecentEvents(limit: limit)
    }
    
    /// Gets current rating configuration for debugging
    func getCurrentConfiguration() -> RatingConfiguration {
        return configuration
    }
    
    /// Record rating prompt interaction for A/B testing
    func recordRatingInteraction(_ action: RatingPromptAction, timeSinceShown: TimeInterval = 0) async {
        let experimentVariant = experimentService?.getVariant(for: "engagement_threshold_test")
        let method = getPreferredRatingMethod().rawValue
        
        // Track with analytics service
        ratingAnalytics?.trackRatingPromptInteraction(
            action: action,
            method: method,
            timeSinceShown: timeSinceShown,
            experimentVariant: experimentVariant
        )
        
        // Record experiment conversion
        let conversionType: RatingConversionType
        switch action {
        case .rated:
            conversionType = .ratingCompleted
        case .dismissed:
            conversionType = .promptDismissed
        case .remindLater:
            conversionType = .remindLater
        case .dontAskAgain:
            conversionType = .dontAskAgain
        }
        
        experimentService?.recordConversion(
            experimentId: "engagement_threshold_test",
            conversionType: conversionType
        )
        
        logger.info("Recorded rating interaction: \(action.rawValue) with variant: \(experimentVariant ?? "none")")
    }
    
    /// Get experiment results for the rating system
    func getExperimentResults() async -> [RatingExperimentResults] {
        return experimentService?.getAllExperimentResults() ?? []
    }
    
    /// Get experiment recommendations
    func getExperimentRecommendations() async -> [String: RatingExperimentRecommendation] {
        guard let experimentService = experimentService else { return [:] }
        
        var recommendations: [String: RatingExperimentRecommendation] = [:]
        
        for experiment in await experimentService.activeExperiments {
            if experimentService.isExperimentReady(experimentId: experiment.id),
               let recommendation = experimentService.getExperimentRecommendation(experimentId: experiment.id) {
                recommendations[experiment.id] = recommendation
            }
        }
        
        return recommendations
    }
    
    // MARK: - Auto-Prompt Logic
    
    /// Evaluates whether to automatically request a rating after a high-value engagement event
    private func evaluateAutoRatingRequest(after event: RatingTriggerEvent) async {
        // Check if rating system is enabled globally
        guard configuration.isRatingSystemEnabled else {
            logger.debug("Auto-prompt evaluation skipped: rating system disabled")
            return
        }
        
        // Check if auto-prompting is enabled via feature flag
        guard featureFlagService?.isEnabled(.ratingAutoPrompt) ?? false else {
            logger.debug("Auto-prompt evaluation skipped: auto-prompt feature disabled")
            return
        }
        
        // Skip if we're already processing a rating request
        guard !isRatingRequestInProgress else {
            logger.debug("Auto-prompt evaluation skipped: rating request in progress")
            return
        }
        
        // Track auto-evaluation attempt
        await recordAnalyticsEvent(.ratingAutoEvaluationStarted, metadata: [
            "trigger_event": event.rawValue
        ])
        
        do {
            // Check if rating should be requested using existing logic
            let shouldRequest = await shouldRequestRating()
            
            guard shouldRequest else {
                await recordAnalyticsEvent(.ratingAutoEvaluationSkipped, metadata: [
                    "trigger_event": event.rawValue,
                    "reason": "conditions_not_met"
                ])
                
                if configuration.isDebugLoggingEnabled {
                    logger.debug("Auto rating evaluation: conditions not met after \(event.rawValue)")
                }
                return
            }
            
            // Attempt to request rating automatically
            await recordAnalyticsEvent(.ratingAutoEvaluationTriggered, metadata: [
                "trigger_event": event.rawValue
            ])
            
            try await requestRating()
            
            await recordAnalyticsEvent(.ratingAutoRequestSucceeded, metadata: [
                "trigger_event": event.rawValue
            ])
            
            logger.info("Auto rating request succeeded after \(event.rawValue)")
            
        } catch {
            // Handle and log rating request errors gracefully
            await recordAnalyticsEvent(.ratingAutoRequestFailed, metadata: [
                "trigger_event": event.rawValue,
                "error": error.localizedDescription
            ])
            
            logger.error("Auto rating request failed after \(event.rawValue): \(error.localizedDescription)")
            
            // Don't throw - auto rating failures should be silent to the user
        }
    }
}

// MARK: - Supporting Types

/// Method used for requesting app ratings
private enum RatingMethod: String, Sendable {
    case appStoreReview = "app_store_review"  // iOS 18+ AppStore.requestReview
    case storeKitReview = "store_kit_review"  // SKStoreReviewController.requestReview
}

/// Result of a rating request
public enum RatingRequestResult: Sendable {
    case success
    case failure(any Error)
    
    /// Whether the request was successful
    public var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
    
    /// Error if the request failed
    public var error: (any Error)? {
        switch self {
        case .success: return nil
        case .failure(let error): return error
        }
    }
}