# Monitoring and Analytics Guide

## Overview
This document outlines monitoring, logging, and analytics implementation for the Magical Stories app to track performance, usage, and errors.

## Analytics Implementation

### Event Tracking
```swift
enum AnalyticsEvent {
    // User Actions
    case storyGenerated(theme: String, ageGroup: String)
    case storyRead(id: String, duration: TimeInterval)
    case storyFavorited(id: String)
    case achievementEarned(name: String)
    
    // App Lifecycle
    case appLaunched
    case sessionStarted
    case sessionEnded(duration: TimeInterval)
    
    // Performance
    case storyGenerationTime(duration: TimeInterval)
    case appLoadTime(duration: TimeInterval)
    case networkError(type: String)
    
    var name: String {
        switch self {
        case .storyGenerated: return "story_generated"
        case .storyRead: return "story_read"
        case .storyFavorited: return "story_favorited"
        case .achievementEarned: return "achievement_earned"
        case .appLaunched: return "app_launched"
        case .sessionStarted: return "session_started"
        case .sessionEnded: return "session_ended"
        case .storyGenerationTime: return "story_generation_time"
        case .appLoadTime: return "app_load_time"
        case .networkError: return "network_error"
        }
    }
    
    var parameters: [String: Any] {
        switch self {
        case .storyGenerated(let theme, let ageGroup):
            return ["theme": theme, "age_group": ageGroup]
        case .storyRead(let id, let duration):
            return ["story_id": id, "duration": duration]
        case .storyFavorited(let id):
            return ["story_id": id]
        case .achievementEarned(let name):
            return ["achievement": name]
        case .sessionEnded(let duration):
            return ["duration": duration]
        case .storyGenerationTime(let duration):
            return ["duration": duration]
        case .appLoadTime(let duration):
            return ["duration": duration]
        case .networkError(let type):
            return ["error_type": type]
        default:
            return [:]
        }
    }
}
```

### Analytics Service
```swift
class AnalyticsService {
    static let shared = AnalyticsService()
    
    func logEvent(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters)
    }
    
    func logError(_ error: Error, context: String? = nil) {
        var parameters: [String: Any] = [
            "error_description": error.localizedDescription,
            "error_code": (error as NSError).code
        ]
        
        if let context = context {
            parameters["context"] = context
        }
        
        Analytics.logEvent("error", parameters: parameters)
    }
}

// Usage Example
extension StoryViewModel {
    func generateStory() async throws {
        let startTime = Date()
        
        do {
            let story = try await storyService.generate()
            let duration = Date().timeIntervalSince(startTime)
            
            AnalyticsService.shared.logEvent(
                .storyGenerationTime(duration: duration)
            )
            
            AnalyticsService.shared.logEvent(
                .storyGenerated(
                    theme: story.theme,
                    ageGroup: story.ageGroup.rawValue
                )
            )
        } catch {
            AnalyticsService.shared.logError(error, context: "story_generation")
            throw error
        }
    }
}
```

## Performance Monitoring

### Performance Metrics
```swift
struct PerformanceMetrics {
    static func measureAppStartup() {
        let startTime = Date()
        
        // Register for did become active notification
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            let launchTime = Date().timeIntervalSince(startTime)
            
            AnalyticsService.shared.logEvent(
                .appLoadTime(duration: launchTime)
            )
        }
    }
    
    static func measureNetworkLatency() -> URLSessionTaskMetrics {
        // Implementation
        return URLSessionTaskMetrics()
    }
    
    static func measureMemoryUsage() -> Float {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        
        let usedMB = Float(taskInfo.phys_footprint) / 1048576.0
        return usedMB
    }
}
```

### Network Monitoring
```swift
class NetworkMonitor {
    static let shared = NetworkMonitor()
    private var monitor: NWPathMonitor
    private var queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published private(set) var isConnected = false
    @Published private(set) var connectionType: ConnectionType = .unknown
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(path) ?? .unknown
                
                self?.logNetworkStatus()
            }
        }
        monitor.start(queue: queue)
    }
    
    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) { return .wifi }
        if path.usesInterfaceType(.cellular) { return .cellular }
        if path.usesInterfaceType(.wiredEthernet) { return .ethernet }
        return .unknown
    }
    
    private func logNetworkStatus() {
        Analytics.logEvent("network_status", parameters: [
            "connected": isConnected,
            "type": connectionType
        ])
    }
}
```

## Error Tracking

### Error Monitoring
```swift
class ErrorMonitor {
    static let shared = ErrorMonitor()
    
    func setup() {
        // Set up global error handling
        NSSetUncaughtExceptionHandler { exception in
            self.handleUncaughtException(exception)
        }
    }
    
    private func handleUncaughtException(_ exception: NSException) {
        let userInfo = exception.userInfo ?? [:]
        
        Analytics.logEvent("uncaught_exception", parameters: [
            "name": exception.name.rawValue,
            "reason": exception.reason ?? "Unknown",
            "userInfo": userInfo,
            "stackTrace": exception.callStackSymbols
        ])
    }
    
    func logError(_ error: Error, severity: ErrorSeverity) {
        let nsError = error as NSError
        
        Analytics.logEvent("error", parameters: [
            "domain": nsError.domain,
            "code": nsError.code,
            "description": nsError.localizedDescription,
            "severity": severity.rawValue
        ])
    }
}

enum ErrorSeverity: String {
    case low
    case medium
    case high
    case critical
}
```

## Custom Metrics

### User Engagement
```swift
struct EngagementMetrics {
    static func trackStoryEngagement(
        storyID: String,
        startTime: Date,
        completionRate: Double
    ) {
        let duration = Date().timeIntervalSince(startTime)
        
        Analytics.logEvent("story_engagement", parameters: [
            "story_id": storyID,
            "duration": duration,
            "completion_rate": completionRate,
            "time_of_day": Calendar.current.component(.hour, from: startTime)
        ])
    }
    
    static func trackFeatureUsage(_ feature: Feature) {
        Analytics.logEvent("feature_usage", parameters: [
            "feature": feature.rawValue,
            "timestamp": Date()
        ])
    }
}

enum Feature: String {
    case storyGeneration
    case textToSpeech
    case favorites
    case sharing
    case achievements
}
```

### User Session
```swift
class SessionTracker {
    static let shared = SessionTracker()
    private var sessionStartTime: Date?
    
    func startSession() {
        sessionStartTime = Date()
        AnalyticsService.shared.logEvent(.sessionStarted)
    }
    
    func endSession() {
        guard let startTime = sessionStartTime else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        AnalyticsService.shared.logEvent(
            .sessionEnded(duration: duration)
        )
    }
}
```

## Logging

### Log Levels
```swift
enum LogLevel: String {
    case debug
    case info
    case warning
    case error
    case critical
}

class Logger {
    static let shared = Logger()
    
    func log(
        _ message: String,
        level: LogLevel,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let filename = (file as NSString).lastPathComponent
        
        let logMessage = """
            [\(timestamp)] [\(level.rawValue.uppercased())] \
            [\(filename):\(line)] \(function): \(message)
            """
        
        #if DEBUG
        print(logMessage)
        #endif
        
        if level >= .warning {
            Analytics.logEvent("app_log", parameters: [
                "level": level.rawValue,
                "message": message,
                "file": filename,
                "function": function,
                "line": line
            ])
        }
    }
}
```

## Dashboard Integration

### Custom Dashboard Events
```swift
struct DashboardMetrics {
    static func updateDashboard() {
        let metrics = gatherMetrics()
        
        Analytics.logEvent("dashboard_update", parameters: [
            "daily_active_users": metrics.dailyActiveUsers,
            "story_generation_count": metrics.storyGenerationCount,
            "average_session_duration": metrics.averageSessionDuration,
            "error_rate": metrics.errorRate
        ])
    }
    
    private static func gatherMetrics() -> AppMetrics {
        // Implementation
        return AppMetrics()
    }
}

struct AppMetrics {
    var dailyActiveUsers: Int = 0
    var storyGenerationCount: Int = 0
    var averageSessionDuration: TimeInterval = 0
    var errorRate: Double = 0
}
```

## Best Practices

1. **Event Tracking**
   - Use consistent naming conventions
   - Track meaningful user actions
   - Include relevant context
   - Respect user privacy

2. **Performance Monitoring**
   - Monitor key metrics
   - Set up alerts
   - Track trends
   - Optimize bottlenecks

3. **Error Handling**
   - Log all errors
   - Include stack traces
   - Set up crash reporting
   - Monitor error rates

4. **Privacy**
   - Anonymize user data
   - Follow GDPR/COPPA guidelines
   - Clear retention policies
   - Secure transmission

5. **Maintenance**
   - Regular log rotation
   - Data cleanup
   - Alert tuning
   - Dashboard updates

## Implementation Checklist

- [ ] Analytics setup
- [ ] Error tracking
- [ ] Performance monitoring
- [ ] Network monitoring
- [ ] Custom metrics
- [ ] Logging system
- [ ] Privacy compliance
- [ ] Dashboard integration
- [ ] Alert configuration
- [ ] Documentation

---

This document should be updated when:
- New metrics are added
- Monitoring requirements change
- Privacy regulations update
- Best practices evolve
