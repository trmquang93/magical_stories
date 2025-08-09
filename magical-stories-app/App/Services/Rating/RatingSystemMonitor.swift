import Foundation
import OSLog
import Combine

/// Comprehensive system health monitoring and alerting for the rating system
@MainActor
final class RatingSystemMonitor: ObservableObject {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.magicalstories.app", category: "RatingSystemMonitor")
    private let analyticsService: RatingAnalyticsService
    private let ratingService: RatingService
    
    // Health Status
    @Published private(set) var systemHealth = SystemHealthStatus()
    @Published private(set) var performanceMetrics = RatingPerformanceMetrics()
    @Published private(set) var alerts: [SystemAlert] = []
    
    // Monitoring Configuration
    private let monitoringConfig = MonitoringConfiguration()
    private var healthCheckTimer: Timer?
    private var performanceTimer: Timer?
    private var alertCleanupTimer: Timer?
    
    // Performance Tracking
    private var recentResponseTimes: [TimeInterval] = []
    private var recentErrorCounts: [Date: Int] = [:]
    private let metricsQueue = DispatchQueue(label: "com.magicalstories.rating.monitoring", qos: .utility)
    
    // MARK: - Initialization
    
    init(analyticsService: RatingAnalyticsService, ratingService: RatingService) {
        self.analyticsService = analyticsService
        self.ratingService = ratingService
        
        startMonitoring()
        setupAlertCleanup()
    }
    
    deinit {
        // Timer cleanup handled by stopMonitoring() which should be called explicitly
        // Note: Cannot access Timer properties from deinit due to Swift 6 concurrency
    }
    
    // MARK: - Public Interface
    
    /// Start the monitoring system
    func startMonitoring() {
        guard healthCheckTimer == nil else { return }
        
        // Health checks every 5 minutes
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performHealthCheck()
            }
        }
        
        // Performance metrics every minute
        performanceTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updatePerformanceMetrics()
            }
        }
        
        logger.info("Rating system monitoring started")
    }
    
    /// Stop the monitoring system
    func stopMonitoring() {
        healthCheckTimer?.invalidate()
        performanceTimer?.invalidate()
        alertCleanupTimer?.invalidate()
        
        healthCheckTimer = nil
        performanceTimer = nil
        alertCleanupTimer = nil
        
        logger.info("Rating system monitoring stopped")
    }
    
    /// Force a comprehensive health check
    func performHealthCheck() async {
        let startTime = Date()
        
        // Component health checks
        let ratingServiceHealth = await checkRatingServiceHealth()
        let triggerManagerHealth = await checkTriggerManagerHealth()
        let analyticsHealth = await checkAnalyticsServiceHealth()
        let userPreferencesHealth = await checkUserPreferencesHealth()
        
        // Update system health
        systemHealth = SystemHealthStatus(
            ratingService: ratingServiceHealth,
            triggerManager: triggerManagerHealth,
            analytics: analyticsHealth,
            userPreferences: userPreferencesHealth,
            lastCheckTime: Date()
        )
        
        // Check for critical issues
        await checkForCriticalIssues()
        
        // Update performance tracking
        let checkDuration = Date().timeIntervalSince(startTime)
        await recordPerformanceMetric(.healthCheckDuration, value: checkDuration)
        
        // Send health data to analytics
        analyticsService.trackRatingSystemHealthCheck(
            component: "system_monitor",
            status: systemHealth.overallStatus.rawValue,
            responseTime: checkDuration
        )
        
        logger.info("Health check completed in \(String(format: "%.2f", checkDuration))s - Status: \(self.systemHealth.overallStatus.rawValue)")
    }
    
    /// Record a performance metric
    func recordPerformanceMetric(_ metric: PerformanceMetricType, value: Double) async {
        await metricsQueue.sync {
            let timestamp = Date()
            
            switch metric {
            case .responseTime:
                recentResponseTimes.append(value)
                if recentResponseTimes.count > 100 {
                    recentResponseTimes.removeFirst()
                }
            case .errorRate:
                let minute = Calendar.current.dateInterval(of: .minute, for: timestamp)?.start ?? timestamp
                recentErrorCounts[minute, default: 0] += Int(value)
            case .engagementScore:
                performanceMetrics.averageEngagementScore = value
            case .conversionRate:
                performanceMetrics.conversionRate = value
            case .healthCheckDuration:
                performanceMetrics.averageHealthCheckDuration = value
            }
            
            performanceMetrics.lastUpdated = timestamp
        }
    }
    
    /// Get current system status summary
    func getSystemStatusSummary() -> SystemStatusSummary {
        return SystemStatusSummary(
            overallHealth: systemHealth.overallStatus,
            componentCount: systemHealth.componentStatuses.count,
            healthyComponents: systemHealth.componentStatuses.values.filter { $0.status == .healthy }.count,
            warningComponents: systemHealth.componentStatuses.values.filter { $0.status == .warning }.count,
            criticalComponents: systemHealth.componentStatuses.values.filter { $0.status == .critical }.count,
            activeAlerts: alerts.filter { !$0.isResolved }.count,
            averageResponseTime: performanceMetrics.averageResponseTime,
            errorRate: performanceMetrics.errorRate,
            lastHealthCheck: systemHealth.lastCheckTime
        )
    }
    
    /// Resolve an alert
    func resolveAlert(_ alertId: String) {
        if let index = alerts.firstIndex(where: { $0.id == alertId }) {
            alerts[index].isResolved = true
            alerts[index].resolvedAt = Date()
            
            logger.info("Alert resolved: \(alertId)")
            
            // Track resolution
            analyticsService.trackRatingEvent("alert_resolved", parameters: [
                "alert_id": alertId,
                "alert_type": alerts[index].type.rawValue
            ])
        }
    }
    
    /// Get performance trends
    func getPerformanceTrends(period: TrendPeriod = .last24Hours) -> PerformanceTrends {
        let now = Date()
        let startTime: Date
        
        switch period {
        case .last24Hours:
            startTime = now.addingTimeInterval(-24 * 60 * 60)
        case .lastWeek:
            startTime = now.addingTimeInterval(-7 * 24 * 60 * 60)
        case .lastMonth:
            startTime = now.addingTimeInterval(-30 * 24 * 60 * 60)
        }
        
        // Calculate trends (simplified implementation)
        return PerformanceTrends(
            period: period,
            responseTimeTrend: calculateResponseTimeTrend(since: startTime),
            errorRateTrend: calculateErrorRateTrend(since: startTime),
            conversionRateTrend: 0.0, // Would calculate from historical data
            engagementScoreTrend: 0.0 // Would calculate from historical data
        )
    }
    
    // MARK: - Private Implementation
    
    private func checkRatingServiceHealth() async -> ComponentHealthStatus {
        let startTime = Date()
        
        do {
            // Test basic rating service functionality
            let engagementScore = await ratingService.getCurrentEngagementScore()
            let canTrigger = await ratingService.shouldRequestRating()
            
            let responseTime = Date().timeIntervalSince(startTime)
            await recordPerformanceMetric(.responseTime, value: responseTime)
            
            // Determine health status
            let status: HealthStatus
            if responseTime > 5.0 {
                status = .critical
            } else if responseTime > 2.0 {
                status = .warning
            } else {
                status = .healthy
            }
            
            return ComponentHealthStatus(
                component: .ratingService,
                status: status,
                lastCheck: Date(),
                responseTime: responseTime,
                details: "Engagement score: \(String(format: "%.3f", engagementScore)), Can trigger: \(canTrigger)"
            )
            
        } catch {
            await recordPerformanceMetric(.errorRate, value: 1)
            
            return ComponentHealthStatus(
                component: .ratingService,
                status: .critical,
                lastCheck: Date(),
                responseTime: Date().timeIntervalSince(startTime),
                error: error.localizedDescription
            )
        }
    }
    
    private func checkTriggerManagerHealth() async -> ComponentHealthStatus {
        let startTime = Date()
        
        do {
            // Test trigger manager functionality
            let engagementAnalysis = await ratingService.getEngagementAnalysis()
            let recentEvents = await ratingService.getRecentEvents(limit: 5)
            
            let responseTime = Date().timeIntervalSince(startTime)
            
            let status: HealthStatus = responseTime > 1.0 ? .warning : .healthy
            
            return ComponentHealthStatus(
                component: .triggerManager,
                status: status,
                lastCheck: Date(),
                responseTime: responseTime,
                details: "Total events: \(engagementAnalysis.totalEvents), Recent events: \(recentEvents.count)"
            )
            
        } catch {
            return ComponentHealthStatus(
                component: .triggerManager,
                status: .critical,
                lastCheck: Date(),
                responseTime: Date().timeIntervalSince(startTime),
                error: error.localizedDescription
            )
        }
    }
    
    private func checkAnalyticsServiceHealth() async -> ComponentHealthStatus {
        let startTime = Date()
        
        // Test analytics service
        analyticsService.trackRatingEvent("health_check_test")
        
        let responseTime = Date().timeIntervalSince(startTime)
        let status: HealthStatus = responseTime > 0.5 ? .warning : .healthy
        
        return ComponentHealthStatus(
            component: .analytics,
            status: status,
            lastCheck: Date(),
            responseTime: responseTime
        )
    }
    
    private func checkUserPreferencesHealth() async -> ComponentHealthStatus {
        let startTime = Date()
        
        // Test user preferences access
        // This would normally test UserDefaults or other persistence
        let responseTime = Date().timeIntervalSince(startTime)
        
        return ComponentHealthStatus(
            component: .userPreferences,
            status: .healthy,
            lastCheck: Date(),
            responseTime: responseTime
        )
    }
    
    private func checkForCriticalIssues() async {
        var newAlerts: [SystemAlert] = []
        
        // Check for critical component failures
        for (component, status) in systemHealth.componentStatuses {
            if status.status == .critical {
                let alert = SystemAlert(
                    type: .componentFailure,
                    severity: .critical,
                    title: "\(component.displayName) Critical Failure",
                    message: status.error ?? "Component is in critical state",
                    component: component,
                    timestamp: Date()
                )
                newAlerts.append(alert)
            }
        }
        
        // Check performance issues
        let avgResponseTime = await metricsQueue.sync { () -> Double in
            guard !recentResponseTimes.isEmpty else { return 0.0 }
            return recentResponseTimes.reduce(0, +) / Double(recentResponseTimes.count)
        }
        
        if avgResponseTime > monitoringConfig.responseTimeThreshold {
            let alert = SystemAlert(
                type: .performanceDegradation,
                severity: .warning,
                title: "High Response Times Detected",
                message: "Average response time: \(String(format: "%.2f", avgResponseTime))s (threshold: \(String(format: "%.2f", monitoringConfig.responseTimeThreshold))s)",
                timestamp: Date()
            )
            newAlerts.append(alert)
        }
        
        // Check error rates
        let currentErrorRate = await calculateCurrentErrorRate()
        if currentErrorRate > monitoringConfig.errorRateThreshold {
            let alert = SystemAlert(
                type: .highErrorRate,
                severity: .warning,
                title: "High Error Rate Detected",
                message: "Current error rate: \(String(format: "%.1f", currentErrorRate * 100))% (threshold: \(String(format: "%.1f", monitoringConfig.errorRateThreshold * 100))%)",
                timestamp: Date()
            )
            newAlerts.append(alert)
        }
        
        // Add new alerts and track them
        for alert in newAlerts {
            if !alerts.contains(where: { $0.type == alert.type && !$0.isResolved }) {
                alerts.append(alert)
                
                // Track alert creation
                analyticsService.trackRatingEvent("alert_created", parameters: [
                    "alert_type": alert.type.rawValue,
                    "severity": alert.severity.rawValue,
                    "component": alert.component?.rawValue ?? "system"
                ])
                
                logger.warning("New alert created: \(alert.title)")
            }
        }
    }
    
    private func updatePerformanceMetrics() async {
        let avgResponseTime = await metricsQueue.sync { () -> Double in
            guard !recentResponseTimes.isEmpty else { return 0.0 }
            return recentResponseTimes.reduce(0, +) / Double(recentResponseTimes.count)
        }
        
        let errorRate = await calculateCurrentErrorRate()
        
        performanceMetrics = RatingPerformanceMetrics(
            averageResponseTime: avgResponseTime,
            errorRate: errorRate,
            averageEngagementScore: performanceMetrics.averageEngagementScore,
            conversionRate: performanceMetrics.conversionRate,
            averageHealthCheckDuration: performanceMetrics.averageHealthCheckDuration,
            lastUpdated: Date()
        )
        
        // Track performance metrics
        analyticsService.trackRatingKPI(metric: "avg_response_time", value: avgResponseTime, period: "realtime")
        analyticsService.trackRatingKPI(metric: "error_rate", value: errorRate, period: "realtime")
    }
    
    private func calculateCurrentErrorRate() async -> Double {
        return await metricsQueue.sync { () -> Double in
            let now = Date()
            let fiveMinutesAgo = now.addingTimeInterval(-300)
            
            let recentErrors = recentErrorCounts.filter { $0.key >= fiveMinutesAgo }.values.reduce(0, +)
            let totalRequests = max(recentResponseTimes.count, 1) // Approximate total requests
            
            return Double(recentErrors) / Double(totalRequests)
        }
    }
    
    private func calculateResponseTimeTrend(since startTime: Date) -> Double {
        // Simplified trend calculation - in production, use proper time series analysis
        return 0.0
    }
    
    private func calculateErrorRateTrend(since startTime: Date) -> Double {
        // Simplified trend calculation - in production, use proper time series analysis
        return 0.0
    }
    
    private func setupAlertCleanup() {
        // Clean up resolved alerts every hour
        alertCleanupTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.cleanupOldAlerts()
            }
        }
    }
    
    private func cleanupOldAlerts() {
        let cutoffTime = Date().addingTimeInterval(-monitoringConfig.alertRetentionPeriod)
        let oldAlertCount = alerts.count
        
        alerts.removeAll { alert in
            alert.isResolved && alert.resolvedAt?.addingTimeInterval(3600) ?? alert.timestamp < cutoffTime
        }
        
        let removedCount = oldAlertCount - alerts.count
        if removedCount > 0 {
            logger.info("Cleaned up \(removedCount) old alerts")
        }
    }
}

// MARK: - Supporting Types

enum PerformanceMetricType {
    case responseTime
    case errorRate
    case engagementScore
    case conversionRate
    case healthCheckDuration
}

enum TrendPeriod: CaseIterable {
    case last24Hours
    case lastWeek
    case lastMonth
    
    var displayName: String {
        switch self {
        case .last24Hours: return "Last 24 Hours"
        case .lastWeek: return "Last Week"
        case .lastMonth: return "Last Month"
        }
    }
}

struct SystemHealthStatus: Sendable {
    var componentStatuses: [RatingSystemComponent: ComponentHealthStatus] = [:]
    var lastCheckTime: Date = Date()
    
    init() {}
    
    init(
        ratingService: ComponentHealthStatus,
        triggerManager: ComponentHealthStatus,
        analytics: ComponentHealthStatus,
        userPreferences: ComponentHealthStatus,
        lastCheckTime: Date
    ) {
        self.componentStatuses = [
            .ratingService: ratingService,
            .triggerManager: triggerManager,
            .analytics: analytics,
            .userPreferences: userPreferences
        ]
        self.lastCheckTime = lastCheckTime
    }
    
    var overallStatus: HealthStatus {
        let statuses = componentStatuses.values.map { $0.status }
        
        if statuses.contains(.critical) {
            return .critical
        } else if statuses.contains(.warning) {
            return .warning
        } else {
            return .healthy
        }
    }
}

struct ComponentHealthStatus: Sendable {
    let component: RatingSystemComponent
    let status: HealthStatus
    let lastCheck: Date
    let responseTime: TimeInterval
    let error: String?
    let details: String?
    
    init(
        component: RatingSystemComponent,
        status: HealthStatus,
        lastCheck: Date,
        responseTime: TimeInterval,
        error: String? = nil,
        details: String? = nil
    ) {
        self.component = component
        self.status = status
        self.lastCheck = lastCheck
        self.responseTime = responseTime
        self.error = error
        self.details = details
    }
}

struct RatingPerformanceMetrics: Sendable {
    var averageResponseTime: Double = 0.0
    var errorRate: Double = 0.0
    var averageEngagementScore: Double = 0.0
    var conversionRate: Double = 0.0
    var averageHealthCheckDuration: Double = 0.0
    var lastUpdated: Date = Date()
}

struct SystemAlert: Sendable, Identifiable {
    let id = UUID().uuidString
    let type: AlertType
    let severity: AlertSeverity
    let title: String
    let message: String
    let component: RatingSystemComponent?
    let timestamp: Date
    var isResolved: Bool = false
    var resolvedAt: Date?
    
    init(
        type: AlertType,
        severity: AlertSeverity,
        title: String,
        message: String,
        component: RatingSystemComponent? = nil,
        timestamp: Date
    ) {
        self.type = type
        self.severity = severity
        self.title = title
        self.message = message
        self.component = component
        self.timestamp = timestamp
    }
}

enum AlertType: String, CaseIterable, Sendable {
    case componentFailure = "component_failure"
    case performanceDegradation = "performance_degradation"
    case highErrorRate = "high_error_rate"
    case configurationIssue = "configuration_issue"
    case dataIntegrityIssue = "data_integrity_issue"
}

enum AlertSeverity: String, CaseIterable, Sendable {
    case info = "info"
    case warning = "warning"
    case critical = "critical"
}

struct SystemStatusSummary: Sendable {
    let overallHealth: HealthStatus
    let componentCount: Int
    let healthyComponents: Int
    let warningComponents: Int
    let criticalComponents: Int
    let activeAlerts: Int
    let averageResponseTime: Double
    let errorRate: Double
    let lastHealthCheck: Date
}

struct PerformanceTrends: Sendable {
    let period: TrendPeriod
    let responseTimeTrend: Double // Percentage change
    let errorRateTrend: Double // Percentage change
    let conversionRateTrend: Double // Percentage change
    let engagementScoreTrend: Double // Percentage change
}

struct MonitoringConfiguration {
    let healthCheckInterval: TimeInterval = 300 // 5 minutes
    let performanceUpdateInterval: TimeInterval = 60 // 1 minute
    let responseTimeThreshold: TimeInterval = 2.0 // 2 seconds
    let errorRateThreshold: Double = 0.05 // 5%
    let alertRetentionPeriod: TimeInterval = 7 * 24 * 60 * 60 // 7 days
}

// MARK: - Extensions

extension RatingSystemComponent {
    var displayName: String {
        switch self {
        case .ratingService: return "Rating Service"
        case .triggerManager: return "Trigger Manager"
        case .analytics: return "Analytics"
        case .userPreferences: return "User Preferences"
        case .abTesting: return "A/B Testing"
        }
    }
}