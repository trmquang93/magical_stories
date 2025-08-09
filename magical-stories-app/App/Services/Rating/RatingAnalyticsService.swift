import Foundation
import OSLog

/// Comprehensive analytics service for rating system with KPI tracking and health monitoring
@MainActor
final class RatingAnalyticsService: ObservableObject {
    
    // MARK: - Properties
    
    private let clarityService: ClarityAnalyticsService
    private let logger = Logger(subsystem: "com.magicalstories.app", category: "RatingAnalytics")
    private let metricsQueue = DispatchQueue(label: "com.magicalstories.rating.metrics", qos: .utility)
    
    // KPI Tracking
    @Published private(set) var dailyMetrics = RatingDailyMetrics()
    @Published private(set) var weeklyMetrics = RatingWeeklyMetrics()
    @Published private(set) var monthlyMetrics = RatingMonthlyMetrics()
    
    // Health Monitoring
    @Published private(set) var healthStatus = RatingSystemHealthStatus()
    private var healthCheckTimer: Timer?
    
    // MARK: - Initialization
    
    init(clarityService: ClarityAnalyticsService = .shared) {
        self.clarityService = clarityService
        startHealthMonitoring()
        loadStoredMetrics()
    }
    
    deinit {
        // Timer cleanup handled by weak self references in closures
    }
    
    // MARK: - Core Analytics Events
    
    func trackRatingTriggerEvaluation(
        passed: Bool,
        engagementScore: Double,
        requiredScore: Double,
        failureReason: String? = nil,
        experimentVariant: String? = nil
    ) {
        clarityService.trackRatingTriggerEvaluation(
            passed: passed,
            engagementScore: engagementScore,
            requiredScore: requiredScore,
            failureReason: failureReason,
            metadata: experimentVariant.map { ["experiment_variant": $0] } ?? [:]
        )
        
        // Update KPIs
        Task {
            await updateTriggerMetrics(passed: passed, score: engagementScore)
        }
    }
    
    func trackRatingPromptShown(
        method: String,
        engagementScore: Double,
        triggerType: String,
        experimentVariant: String? = nil
    ) {
        clarityService.trackRatingPromptShown(
            method: method,
            engagementScore: engagementScore,
            triggerType: triggerType,
            experimentVariant: experimentVariant
        )
        
        // Update KPIs
        Task {
            await updatePromptMetrics(shown: true, variant: experimentVariant)
        }
    }
    
    func trackRatingPromptInteraction(
        action: RatingPromptAction,
        method: String,
        timeSinceShown: TimeInterval,
        experimentVariant: String? = nil
    ) {
        clarityService.trackRatingPromptInteraction(
            action: action.rawValue,
            method: method,
            timeSinceShown: timeSinceShown,
            experimentVariant: experimentVariant
        )
        
        // Update KPIs
        Task {
            await updateInteractionMetrics(action: action, variant: experimentVariant)
        }
    }
    
    func trackEngagementEvent(
        event: String,
        weight: Double,
        currentScore: Double
    ) {
        clarityService.trackRatingEngagementEvent(
            event: event,
            weight: weight,
            currentScore: currentScore
        )
        
        // Update engagement metrics
        Task {
            await updateEngagementMetrics(event: event, score: currentScore)
        }
    }
    
    // MARK: - A/B Testing Analytics
    
    func trackExperimentAssignment(
        experimentId: String,
        variant: String,
        userId: String
    ) {
        clarityService.trackRatingEvent("experiment_assigned", parameters: [
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
        
        clarityService.trackRatingEvent("experiment_conversion", parameters: params)
    }
    
    // MARK: - Health Monitoring
    
    func trackHealthCheck(
        component: RatingSystemComponent,
        status: HealthStatus,
        responseTime: TimeInterval? = nil,
        errorDetails: String? = nil
    ) {
        clarityService.trackRatingSystemHealthCheck(
            component: component.rawValue,
            status: status.rawValue,
            responseTime: responseTime,
            errorDetails: errorDetails
        )
        
        // Update health status
        Task {
            await updateHealthStatus(component: component, status: status, responseTime: responseTime)
        }
    }
    
    func performSystemHealthCheck() async {
        let startTime = Date()
        
        // Check RatingService health
        let ratingServiceHealth = await checkRatingServiceHealth()
        await trackHealthCheck(
            component: .ratingService,
            status: ratingServiceHealth.status,
            responseTime: ratingServiceHealth.responseTime,
            errorDetails: ratingServiceHealth.error
        )
        
        // Check TriggerManager health
        let triggerManagerHealth = await checkTriggerManagerHealth()
        await trackHealthCheck(
            component: .triggerManager,
            status: triggerManagerHealth.status,
            responseTime: triggerManagerHealth.responseTime,
            errorDetails: triggerManagerHealth.error
        )
        
        // Check Analytics health
        let analyticsHealth = await checkAnalyticsHealth()
        await trackHealthCheck(
            component: .analytics,
            status: analyticsHealth.status,
            responseTime: analyticsHealth.responseTime,
            errorDetails: analyticsHealth.error
        )
        
        let totalTime = Date().timeIntervalSince(startTime)
        logger.info("System health check completed in \(String(format: "%.2f", totalTime))s")
    }
    
    // MARK: - KPI Reporting
    
    func generateDailyReport() -> RatingSystemDailyReport {
        return RatingSystemDailyReport(
            date: Date(),
            metrics: dailyMetrics,
            healthStatus: healthStatus
        )
    }
    
    func generateWeeklyReport() -> RatingSystemWeeklyReport {
        return RatingSystemWeeklyReport(
            weekStart: Calendar.current.startOfWeek(for: Date()) ?? Date(),
            metrics: weeklyMetrics,
            trends: calculateWeeklyTrends()
        )
    }
    
    func generateMonthlyReport() -> RatingSystemMonthlyReport {
        return RatingSystemMonthlyReport(
            monthStart: Calendar.current.startOfMonth(for: Date()) ?? Date(),
            metrics: monthlyMetrics,
            trends: calculateMonthlyTrends()
        )
    }
    
    // MARK: - Dashboard Metrics
    
    func getDashboardMetrics() -> RatingSystemDashboardMetrics {
        return RatingSystemDashboardMetrics(
            promptShowRate: calculatePromptShowRate(),
            conversionRate: calculateConversionRate(),
            engagementScore: dailyMetrics.averageEngagementScore,
            systemHealth: healthStatus.overallHealth,
            activeExperiments: getActiveExperimentCount(),
            lastUpdated: Date()
        )
    }
    
    // MARK: - Private Implementation
    
    private func startHealthMonitoring() {
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performSystemHealthCheck()
            }
        }
    }
    
    private func stopHealthMonitoring() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
    }
    
    private func updateTriggerMetrics(passed: Bool, score: Double) async {
        await metricsQueue.sync {
            dailyMetrics.triggerEvaluations += 1
            if passed {
                dailyMetrics.triggersPassed += 1
            }
            dailyMetrics.totalEngagementScore += score
            dailyMetrics.averageEngagementScore = dailyMetrics.totalEngagementScore / Double(dailyMetrics.triggerEvaluations)
        }
        
        // Track KPI
        clarityService.trackRatingKPI(
            metric: "trigger_pass_rate",
            value: Double(dailyMetrics.triggersPassed) / Double(dailyMetrics.triggerEvaluations),
            period: "daily"
        )
    }
    
    private func updatePromptMetrics(shown: Bool, variant: String?) async {
        await metricsQueue.sync {
            if shown {
                dailyMetrics.promptsShown += 1
                if let variant = variant {
                    dailyMetrics.variantMetrics[variant, default: VariantMetrics()].promptsShown += 1
                }
            }
        }
    }
    
    private func updateInteractionMetrics(action: RatingPromptAction, variant: String?) async {
        await metricsQueue.sync {
            switch action {
            case .rated:
                dailyMetrics.ratingsCompleted += 1
                if let variant = variant {
                    dailyMetrics.variantMetrics[variant, default: VariantMetrics()].conversions += 1
                }
            case .dismissed:
                dailyMetrics.promptsDismissed += 1
            case .remindLater:
                dailyMetrics.remindLaterClicks += 1
            case .dontAskAgain:
                dailyMetrics.dontAskAgainClicks += 1
            }
        }
        
        // Update conversion rate KPI
        let conversionRate = Double(dailyMetrics.ratingsCompleted) / Double(max(dailyMetrics.promptsShown, 1))
        clarityService.trackRatingKPI(
            metric: "conversion_rate",
            value: conversionRate,
            period: "daily"
        )
    }
    
    private func updateEngagementMetrics(event: String, score: Double) async {
        await metricsQueue.sync {
            dailyMetrics.engagementEvents += 1
            dailyMetrics.engagementEventBreakdown[event, default: 0] += 1
        }
    }
    
    private func updateHealthStatus(component: RatingSystemComponent, status: HealthStatus, responseTime: TimeInterval?) async {
        await MainActor.run {
            healthStatus.componentStatus[component] = ComponentHealthStatus(
                component: component,
                status: status,
                lastCheck: Date(),
                responseTime: responseTime ?? 0.0
            )
            
            // Update overall health
            let allStatuses = healthStatus.componentStatus.values.map { $0.status }
            if allStatuses.contains(.critical) {
                healthStatus.overallHealth = .critical
            } else if allStatuses.contains(.warning) {
                healthStatus.overallHealth = .warning
            } else {
                healthStatus.overallHealth = .healthy
            }
        }
    }
    
    // Health Check Implementations
    private func checkRatingServiceHealth() async -> HealthCheckResult {
        let startTime = Date()
        // Simulate health check - in real implementation, test actual service methods
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        let responseTime = Date().timeIntervalSince(startTime)
        
        return HealthCheckResult(
            status: responseTime < 0.1 ? .healthy : .warning,
            responseTime: responseTime,
            error: responseTime > 0.5 ? "Slow response time" : nil
        )
    }
    
    private func checkTriggerManagerHealth() async -> HealthCheckResult {
        let startTime = Date()
        // Simulate health check
        try? await Task.sleep(nanoseconds: 5_000_000) // 5ms
        let responseTime = Date().timeIntervalSince(startTime)
        
        return HealthCheckResult(
            status: .healthy,
            responseTime: responseTime,
            error: nil
        )
    }
    
    private func checkAnalyticsHealth() async -> HealthCheckResult {
        let startTime = Date()
        // Check if analytics service is initialized and responsive
        let isHealthy = clarityService != nil
        let responseTime = Date().timeIntervalSince(startTime)
        
        return HealthCheckResult(
            status: isHealthy ? .healthy : .critical,
            responseTime: responseTime,
            error: isHealthy ? nil : "Analytics service not available"
        )
    }
    
    private func calculatePromptShowRate() -> Double {
        let evaluations = max(dailyMetrics.triggerEvaluations, 1)
        return Double(dailyMetrics.promptsShown) / Double(evaluations)
    }
    
    private func calculateConversionRate() -> Double {
        let prompts = max(dailyMetrics.promptsShown, 1)
        return Double(dailyMetrics.ratingsCompleted) / Double(prompts)
    }
    
    private func getActiveExperimentCount() -> Int {
        // In a real implementation, this would query active A/B tests
        return dailyMetrics.variantMetrics.keys.count
    }
    
    private func calculateWeeklyTrends() -> [String: Double] {
        // Calculate week-over-week changes
        return [
            "prompt_show_rate_change": 0.0, // Would compare to previous week
            "conversion_rate_change": 0.0,
            "engagement_score_change": 0.0
        ]
    }
    
    private func calculateMonthlyTrends() -> [String: Double] {
        // Calculate month-over-month changes
        return [
            "prompt_show_rate_change": 0.0, // Would compare to previous month
            "conversion_rate_change": 0.0,
            "engagement_score_change": 0.0
        ]
    }
    
    private func loadStoredMetrics() {
        // In a real implementation, load from persistent storage
        logger.info("Loading stored rating metrics")
    }
    
    private func saveMetrics() {
        // In a real implementation, save to persistent storage
        Task {
            await metricsQueue.sync {
                // Save current metrics
                logger.debug("Saving rating metrics to persistent storage")
            }
        }
    }
    
    // MARK: - Delegate Methods for Compatibility
    
    /// Delegate method to ClarityAnalyticsService for compatibility
    func trackRatingEvent(_ event: String, parameters: [String: Any] = [:]) {
        clarityService.trackRatingEvent(event, parameters: parameters)
    }
    
    func trackRatingSystemHealthCheck(
        component: String,
        status: String,
        responseTime: TimeInterval? = nil,
        errorDetails: String? = nil
    ) {
        clarityService.trackRatingSystemHealthCheck(
            component: component,
            status: status,
            responseTime: responseTime,
            errorDetails: errorDetails
        )
    }
    
    func trackRatingKPI(
        metric: String,
        value: Double,
        period: String, // "daily", "weekly", "monthly"
        metadata: [String: Any] = [:]
    ) {
        clarityService.trackRatingKPI(
            metric: metric,
            value: value,
            period: period,
            metadata: metadata
        )
    }
}

// MARK: - Supporting Types

enum RatingPromptAction: String, CaseIterable, Sendable {
    case rated = "rated"
    case dismissed = "dismissed"
    case remindLater = "remind_later"
    case dontAskAgain = "dont_ask_again"
}

enum RatingSystemComponent: String, CaseIterable, Sendable {
    case ratingService = "rating_service"
    case triggerManager = "trigger_manager"
    case analytics = "analytics"
    case userPreferences = "user_preferences"
    case abTesting = "ab_testing"
}

enum HealthStatus: String, CaseIterable, Sendable {
    case healthy = "healthy"
    case warning = "warning"
    case critical = "critical"
}

struct HealthCheckResult: Sendable {
    let status: HealthStatus
    let responseTime: TimeInterval
    let error: String?
}


struct RatingSystemHealthStatus: Sendable {
    var overallHealth: HealthStatus = .healthy
    var componentStatus: [RatingSystemComponent: ComponentHealthStatus] = [:]
    var lastSystemCheck: Date = Date()
}

struct VariantMetrics: Sendable {
    var promptsShown: Int = 0
    var conversions: Int = 0
    var averageEngagementScore: Double = 0.0
    
    var conversionRate: Double {
        guard promptsShown > 0 else { return 0.0 }
        return Double(conversions) / Double(promptsShown)
    }
}

struct RatingDailyMetrics: Sendable {
    var date: Date = Date()
    var triggerEvaluations: Int = 0
    var triggersPassed: Int = 0
    var promptsShown: Int = 0
    var ratingsCompleted: Int = 0
    var promptsDismissed: Int = 0
    var remindLaterClicks: Int = 0
    var dontAskAgainClicks: Int = 0
    var engagementEvents: Int = 0
    var totalEngagementScore: Double = 0.0
    var averageEngagementScore: Double = 0.0
    var engagementEventBreakdown: [String: Int] = [:]
    var variantMetrics: [String: VariantMetrics] = [:]
    
    var triggerPassRate: Double {
        guard triggerEvaluations > 0 else { return 0.0 }
        return Double(triggersPassed) / Double(triggerEvaluations)
    }
    
    var conversionRate: Double {
        guard promptsShown > 0 else { return 0.0 }
        return Double(ratingsCompleted) / Double(promptsShown)
    }
}

struct RatingWeeklyMetrics: Sendable {
    var weekStart: Date = Date()
    var totalTriggerEvaluations: Int = 0
    var totalPromptsShown: Int = 0
    var totalRatingsCompleted: Int = 0
    var averageEngagementScore: Double = 0.0
    var dailyBreakdown: [Date: RatingDailyMetrics] = [:]
}

struct RatingMonthlyMetrics: Sendable {
    var monthStart: Date = Date()
    var totalTriggerEvaluations: Int = 0
    var totalPromptsShown: Int = 0
    var totalRatingsCompleted: Int = 0
    var averageEngagementScore: Double = 0.0
    var weeklyBreakdown: [Date: RatingWeeklyMetrics] = [:]
}

struct RatingSystemDailyReport: Sendable {
    let date: Date
    let metrics: RatingDailyMetrics
    let healthStatus: RatingSystemHealthStatus
}

struct RatingSystemWeeklyReport: Sendable {
    let weekStart: Date
    let metrics: RatingWeeklyMetrics
    let trends: [String: Double]
}

struct RatingSystemMonthlyReport: Sendable {
    let monthStart: Date
    let metrics: RatingMonthlyMetrics
    let trends: [String: Double]
}

struct RatingSystemDashboardMetrics: Sendable {
    let promptShowRate: Double
    let conversionRate: Double
    let engagementScore: Double
    let systemHealth: HealthStatus
    let activeExperiments: Int
    let lastUpdated: Date
}

// MARK: - Calendar Extensions

private extension Calendar {
    func startOfWeek(for date: Date) -> Date? {
        dateInterval(of: .weekOfYear, for: date)?.start
    }
    
    func startOfMonth(for date: Date) -> Date? {
        dateInterval(of: .month, for: date)?.start
    }
}