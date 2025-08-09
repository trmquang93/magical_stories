import Foundation
import OSLog

/// Performance optimization and production enhancement service for the rating system
@MainActor
final class RatingSystemOptimizer: ObservableObject {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.magicalstories.app", category: "RatingSystemOptimizer")
    
    // Performance tracking
    private var operationMetrics: [String: OperationMetrics] = [:]
    private var cacheHitRates: [String: Double] = [:]
    private var memoryPressureHandler: (any DispatchSourceMemoryPressure)?
    
    // Optimization settings
    private let config = OptimizationConfiguration()
    
    // Cache management
    private var engagementCache: LRUCache<String, Double>
    private var triggerResultCache: LRUCache<String, Bool>
    private var analyticsEventBuffer: CircularBuffer<AnalyticsEvent>
    
    // Background processing
    private let backgroundQueue = DispatchQueue(label: "com.magicalstories.rating.optimization", qos: .utility)
    private let analyticsQueue = DispatchQueue(label: "com.magicalstories.rating.analytics", qos: .background)
    
    // MARK: - Initialization
    
    init() {
        self.engagementCache = LRUCache<String, Double>(capacity: config.cacheCapacity)
        self.triggerResultCache = LRUCache<String, Bool>(capacity: config.cacheCapacity)
        self.analyticsEventBuffer = CircularBuffer<AnalyticsEvent>(capacity: config.analyticsBufferSize)
        
        setupMemoryPressureHandling()
        startPerformanceMonitoring()
    }
    
    deinit {
        // Memory pressure handler cleanup handled by stopOptimization() which should be called explicitly
        // Note: Cannot access handler properties from deinit due to Swift 6 concurrency
    }
    
    // MARK: - Public Interface
    
    /// Optimize engagement score calculation with caching
    func optimizedEngagementScore(for userId: String, calculator: () async -> Double) async -> Double {
        let cacheKey = "engagement_\(userId)"
        
        // Check cache first
        if let cachedScore = engagementCache.get(cacheKey) {
            await recordCacheHit("engagement_score")
            return cachedScore
        }
        
        // Calculate and cache
        let startTime = Date()
        let score = await calculator()
        let duration = Date().timeIntervalSince(startTime)
        
        // Cache the result
        engagementCache.set(cacheKey, score)
        
        // Record metrics
        await recordOperationMetrics("engagement_calculation", duration: duration)
        await recordCacheMiss("engagement_score")
        
        return score
    }
    
    /// Optimize trigger evaluation with intelligent caching
    func optimizedTriggerEvaluation(
        for userId: String,
        engagementScore: Double,
        evaluator: () async -> Bool
    ) async -> Bool {
        let cacheKey = "trigger_\(userId)_\(Int(engagementScore * 1000))"
        
        // Check cache for recent evaluations
        if let cachedResult = triggerResultCache.get(cacheKey) {
            await recordCacheHit("trigger_evaluation")
            return cachedResult
        }
        
        // Evaluate and cache
        let startTime = Date()
        let result = await evaluator()
        let duration = Date().timeIntervalSince(startTime)
        
        // Cache with shorter TTL for trigger results
        triggerResultCache.set(cacheKey, result, ttl: config.triggerCacheTTL)
        
        // Record metrics
        await recordOperationMetrics("trigger_evaluation", duration: duration)
        await recordCacheMiss("trigger_evaluation")
        
        return result
    }
    
    /// Buffer analytics events for batch processing
    func bufferAnalyticsEvent(_ event: AnalyticsEvent) {
        Task { @MainActor in
            analyticsEventBuffer.append(event)
            
            // Flush buffer if it's full or after timeout
            if analyticsEventBuffer.count >= config.analyticsFlushThreshold {
                await self.flushAnalyticsBuffer()
            }
        }
    }
    
    /// Flush analytics buffer immediately
    func flushAnalyticsBuffer() async {
        let events = analyticsQueue.sync {
            let bufferedEvents = Array(analyticsEventBuffer.elements)
            analyticsEventBuffer.clear()
            return bufferedEvents
        }
        
        guard !events.isEmpty else { return }
        
        let startTime = Date()
        
        // Process events in batches
        for batch in events.chunked(into: config.analyticsBatchSize) {
            await processBatchedAnalyticsEvents(batch)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        await recordOperationMetrics("analytics_flush", duration: duration)
        
        logger.info("Flushed \(events.count) analytics events in \(String(format: "%.3f", duration))s")
    }
    
    /// Clean up old cached data and optimize memory usage
    func performMaintenanceCleanup() async {
        let startTime = Date()
        
        await backgroundQueue.sync {
            // Clear expired cache entries
            engagementCache.cleanup()
            triggerResultCache.cleanup()
            
            // Clear old operation metrics
            let cutoffTime = Date().addingTimeInterval(-config.metricsRetentionPeriod)
            operationMetrics = operationMetrics.compactMapValues { metrics in
                guard metrics.lastUpdated > cutoffTime else { return nil }
                return metrics
            }
        }
        
        // Memory pressure cleanup if needed
        if await isUnderMemoryPressure() {
            await handleMemoryPressure()
        }
        
        let duration = Date().timeIntervalSince(startTime)
        logger.info("Maintenance cleanup completed in \(String(format: "%.3f", duration))s")
    }
    
    /// Get performance optimization report
    func getOptimizationReport() -> OptimizationReport {
        let totalOperations = operationMetrics.values.reduce(0) { $0 + $1.callCount }
        let averageResponseTime = operationMetrics.values.isEmpty ? 0.0 : 
            operationMetrics.values.reduce(0.0) { $0 + $1.averageDuration } / Double(operationMetrics.count)
        
        let cacheEfficiency = cacheHitRates.values.isEmpty ? 0.0 : 
            cacheHitRates.values.reduce(0.0, +) / Double(cacheHitRates.count)
        
        return OptimizationReport(
            totalOperations: totalOperations,
            averageResponseTime: averageResponseTime,
            cacheHitRate: cacheEfficiency,
            memoryUsage: getCurrentMemoryUsage(),
            bufferedEventCount: analyticsEventBuffer.count,
            optimizationRecommendations: generateOptimizationRecommendations()
        )
    }
    
    /// Configure optimization settings
    func updateConfiguration(_ newConfig: OptimizationConfiguration) {
        // Update cache capacities
        engagementCache.updateCapacity(newConfig.cacheCapacity)
        triggerResultCache.updateCapacity(newConfig.cacheCapacity)
        analyticsEventBuffer.updateCapacity(newConfig.analyticsBufferSize)
        
        logger.info("Optimization configuration updated")
    }
    
    // MARK: - Private Implementation
    
    private func setupMemoryPressureHandling() {
        memoryPressureHandler = DispatchSource.makeMemoryPressureSource(eventMask: .all, queue: backgroundQueue)
        
        memoryPressureHandler?.setEventHandler { [weak self] in
            Task { @MainActor in
                await self?.handleMemoryPressure()
            }
        }
        
        memoryPressureHandler?.activate()
    }
    
    private func startPerformanceMonitoring() {
        // Monitor performance every minute
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updatePerformanceMetrics()
            }
        }
        
        // Flush analytics buffer every 30 seconds
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.flushAnalyticsBuffer()
            }
        }
        
        // Maintenance cleanup every 10 minutes
        Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performMaintenanceCleanup()
            }
        }
    }
    
    private func stopOptimization() {
        memoryPressureHandler?.cancel()
        memoryPressureHandler = nil
    }
    
    private func recordOperationMetrics(_ operation: String, duration: TimeInterval) async {
        await backgroundQueue.sync {
            var metrics = operationMetrics[operation] ?? OperationMetrics(operation: operation)
            metrics.addMeasurement(duration)
            operationMetrics[operation] = metrics
        }
    }
    
    private func recordCacheHit(_ cacheType: String) async {
        await backgroundQueue.sync {
            let currentHitRate = cacheHitRates[cacheType] ?? 0.0
            cacheHitRates[cacheType] = (currentHitRate * 0.9) + (1.0 * 0.1) // Exponential moving average
        }
    }
    
    private func recordCacheMiss(_ cacheType: String) async {
        await backgroundQueue.sync {
            let currentHitRate = cacheHitRates[cacheType] ?? 0.0
            cacheHitRates[cacheType] = (currentHitRate * 0.9) + (0.0 * 0.1) // Exponential moving average
        }
    }
    
    private func processBatchedAnalyticsEvents(_ events: [AnalyticsEvent]) async {
        // In a real implementation, this would send batched events to analytics service
        // For now, we'll simulate the processing
        
        let startTime = Date()
        
        // Group events by type for efficient processing
        let groupedEvents = Dictionary(grouping: events) { $0.eventType }
        
        for (eventType, eventGroup) in groupedEvents {
            // Process events of the same type together
            await processEventGroup(eventType: eventType, events: eventGroup)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        await recordOperationMetrics("batch_analytics_processing", duration: duration)
    }
    
    private func processEventGroup(eventType: String, events: [AnalyticsEvent]) async {
        // Simulate analytics processing
        // In production, this would call the actual analytics service
        logger.debug("Processing \(events.count) events of type \(eventType)")
    }
    
    private func handleMemoryPressure() async {
        logger.warning("Memory pressure detected, performing aggressive cleanup")
        
        await backgroundQueue.sync {
            // Reduce cache sizes
            engagementCache.reduceCapacity(by: 0.5)
            triggerResultCache.reduceCapacity(by: 0.5)
            
            // Clear analytics buffer
            analyticsEventBuffer.clear()
            
            // Clear old metrics
            let cutoffTime = Date().addingTimeInterval(-3600) // Keep only last hour
            operationMetrics = operationMetrics.compactMapValues { metrics in
                guard metrics.lastUpdated > cutoffTime else { return nil }
                return metrics
            }
        }
        
        // Force garbage collection
        DispatchQueue.global(qos: .utility).async {
            // Simulate memory cleanup operations
            Thread.sleep(forTimeInterval: 0.1)
        }
    }
    
    private func isUnderMemoryPressure() async -> Bool {
        let memoryUsage = getCurrentMemoryUsage()
        return memoryUsage > config.memoryPressureThreshold
    }
    
    nonisolated(unsafe) private func getCurrentMemoryUsage() -> Double {
        // Simplified memory usage approximation - return a fixed reasonable value
        // In production, this would use proper memory profiling APIs
        return 50.0 // 50MB approximate baseline
    }
    
    private func updatePerformanceMetrics() async {
        // Update cache hit rates display
        for (cacheType, hitRate) in cacheHitRates {
            logger.debug("Cache hit rate for \(cacheType): \(String(format: "%.1f", hitRate * 100))%")
        }
        
        // Log top slow operations
        let slowOperations = operationMetrics.values
            .filter { $0.averageDuration > 0.1 } // Operations slower than 100ms
            .sorted { $0.averageDuration > $1.averageDuration }
            .prefix(3)
        
        for operation in slowOperations {
            logger.warning("Slow operation: \(operation.operation) - \(String(format: "%.3f", operation.averageDuration))s avg")
        }
    }
    
    private func generateOptimizationRecommendations() -> [OptimizationRecommendation] {
        var recommendations: [OptimizationRecommendation] = []
        
        // Check cache hit rates
        for (cacheType, hitRate) in cacheHitRates {
            if hitRate < 0.7 { // Less than 70% hit rate
                recommendations.append(OptimizationRecommendation(
                    type: .cacheOptimization,
                    priority: .medium,
                    description: "Low cache hit rate for \(cacheType): \(String(format: "%.1f", hitRate * 100))%",
                    suggestion: "Consider increasing cache size or adjusting cache TTL"
                ))
            }
        }
        
        // Check for slow operations
        let slowOperations = operationMetrics.values.filter { $0.averageDuration > 0.5 }
        for operation in slowOperations {
            recommendations.append(OptimizationRecommendation(
                type: .performanceOptimization,
                priority: .high,
                description: "Slow operation: \(operation.operation) (\(String(format: "%.3f", operation.averageDuration))s)",
                suggestion: "Profile and optimize the \(operation.operation) operation"
            ))
        }
        
        // Check memory usage
        let memoryUsage = getCurrentMemoryUsage()
        if memoryUsage > 100.0 { // > 100MB
            recommendations.append(OptimizationRecommendation(
                type: .memoryOptimization,
                priority: .medium,
                description: "High memory usage: \(String(format: "%.1f", memoryUsage))MB",
                suggestion: "Reduce cache sizes or implement more aggressive cleanup"
            ))
        }
        
        return recommendations
    }
}

// MARK: - Supporting Types

struct AnalyticsEvent: Sendable {
    let eventType: String
    let parameters: [String: String] // Changed to String: String for Sendable compliance
    let timestamp: Date
    
    init(eventType: String, parameters: [String: String] = [:]) {
        self.eventType = eventType
        self.parameters = parameters
        self.timestamp = Date()
    }
    
    // Convenience initializer that converts Any to String
    init(eventType: String, parameters: [String: Any]) {
        self.eventType = eventType
        var stringParams: [String: String] = [:]
        for (key, value) in parameters {
            stringParams[key] = String(describing: value)
        }
        self.parameters = stringParams
        self.timestamp = Date()
    }
}

struct OperationMetrics: Sendable {
    let operation: String
    var totalDuration: TimeInterval = 0
    var callCount: Int = 0
    var lastUpdated: Date = Date()
    
    var averageDuration: TimeInterval {
        guard callCount > 0 else { return 0 }
        return totalDuration / Double(callCount)
    }
    
    mutating func addMeasurement(_ duration: TimeInterval) {
        totalDuration += duration
        callCount += 1
        lastUpdated = Date()
    }
}

struct OptimizationReport: Sendable {
    let totalOperations: Int
    let averageResponseTime: TimeInterval
    let cacheHitRate: Double
    let memoryUsage: Double
    let bufferedEventCount: Int
    let optimizationRecommendations: [OptimizationRecommendation]
}

struct OptimizationRecommendation: Sendable {
    let type: RecommendationType
    let priority: RecommendationPriority
    let description: String
    let suggestion: String
}

enum RecommendationType: String, CaseIterable, Sendable {
    case cacheOptimization = "cache_optimization"
    case performanceOptimization = "performance_optimization"
    case memoryOptimization = "memory_optimization"
    case networkOptimization = "network_optimization"
}

enum RecommendationPriority: String, CaseIterable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

struct OptimizationConfiguration {
    let cacheCapacity: Int = 1000
    let triggerCacheTTL: TimeInterval = 300 // 5 minutes
    let analyticsBufferSize: Int = 100
    let analyticsFlushThreshold: Int = 50
    let analyticsBatchSize: Int = 25
    let metricsRetentionPeriod: TimeInterval = 24 * 60 * 60 // 24 hours
    let memoryPressureThreshold: Double = 150.0 // MB
}

// MARK: - Utility Data Structures

/// Least Recently Used cache implementation
final class LRUCache<Key: Hashable, Value>: @unchecked Sendable {
    private class CacheNode {
        let key: Key
        var value: Value
        var expiryTime: Date?
        var next: CacheNode?
        weak var prev: CacheNode?
        
        init(key: Key, value: Value, expiryTime: Date? = nil) {
            self.key = key
            self.value = value
            self.expiryTime = expiryTime
        }
    }
    
    private var capacity: Int
    private var cache: [Key: CacheNode] = [:]
    private var head: CacheNode?
    private var tail: CacheNode?
    private let queue = DispatchQueue(label: "lru_cache", qos: .utility)
    
    init(capacity: Int) {
        self.capacity = capacity
    }
    
    func get(_ key: Key) -> Value? {
        return queue.sync {
            guard let node = cache[key] else { return nil }
            
            // Check expiry
            if let expiryTime = node.expiryTime, expiryTime < Date() {
                removeNode(node)
                cache.removeValue(forKey: key)
                return nil
            }
            
            // Move to front
            moveToFront(node)
            return node.value
        }
    }
    
    func set(_ key: Key, _ value: Value, ttl: TimeInterval? = nil) {
        queue.sync {
            let expiryTime = ttl.map { Date().addingTimeInterval($0) }
            
            if let existingNode = cache[key] {
                existingNode.value = value
                existingNode.expiryTime = expiryTime
                moveToFront(existingNode)
            } else {
                let newNode = CacheNode(key: key, value: value, expiryTime: expiryTime)
                cache[key] = newNode
                addToFront(newNode)
                
                if cache.count > capacity {
                    removeLRU()
                }
            }
        }
    }
    
    func cleanup() {
        queue.sync {
            let now = Date()
            let expiredKeys = cache.compactMap { (key, node) in
                node.expiryTime.map { $0 < now } == true ? key : nil
            }
            
            for key in expiredKeys {
                if let node = cache[key] {
                    removeNode(node)
                    cache.removeValue(forKey: key)
                }
            }
        }
    }
    
    func updateCapacity(_ newCapacity: Int) {
        queue.sync {
            capacity = newCapacity
            while cache.count > capacity {
                removeLRU()
            }
        }
    }
    
    func reduceCapacity(by factor: Double) {
        let newCapacity = max(1, Int(Double(capacity) * (1.0 - factor)))
        updateCapacity(newCapacity)
    }
    
    private func moveToFront(_ node: CacheNode) {
        guard node !== head else { return }
        
        removeNode(node)
        addToFront(node)
    }
    
    private func addToFront(_ node: CacheNode) {
        node.next = head
        node.prev = nil
        head?.prev = node
        head = node
        
        if tail == nil {
            tail = node
        }
    }
    
    private func removeNode(_ node: CacheNode) {
        if node === head {
            head = node.next
        }
        if node === tail {
            tail = node.prev
        }
        
        node.prev?.next = node.next
        node.next?.prev = node.prev
    }
    
    private func removeLRU() {
        guard let tailNode = tail else { return }
        
        cache.removeValue(forKey: tailNode.key)
        removeNode(tailNode)
    }
}

/// Circular buffer for efficient event buffering
final class CircularBuffer<Element>: @unchecked Sendable {
    private var buffer: [Element?]
    private var head = 0
    private var tail = 0
    private var isFull = false
    private let queue = DispatchQueue(label: "circular_buffer", qos: .utility)
    
    var capacity: Int { buffer.count }
    
    var count: Int {
        queue.sync {
            if isFull { return capacity }
            return (tail - head + capacity) % capacity
        }
    }
    
    var elements: [Element] {
        queue.sync {
            var result: [Element] = []
            if !isEmpty {
                var index = head
                repeat {
                    if let element = buffer[index] {
                        result.append(element)
                    }
                    index = (index + 1) % capacity
                } while index != tail
            }
            return result
        }
    }
    
    private var isEmpty: Bool {
        !isFull && head == tail
    }
    
    init(capacity: Int) {
        self.buffer = Array(repeating: nil, count: capacity)
    }
    
    func append(_ element: Element) {
        queue.sync {
            buffer[tail] = element
            tail = (tail + 1) % capacity
            
            if isFull {
                head = (head + 1) % capacity
            }
            
            if tail == head {
                isFull = true
            }
        }
    }
    
    func clear() {
        queue.sync {
            head = 0
            tail = 0
            isFull = false
            buffer = Array(repeating: nil, count: capacity)
        }
    }
    
    func updateCapacity(_ newCapacity: Int) {
        queue.sync {
            let currentElements = elements
            buffer = Array(repeating: nil, count: newCapacity)
            head = 0
            tail = 0
            isFull = false
            
            for element in currentElements.prefix(newCapacity) {
                append(element)
            }
        }
    }
}

// MARK: - Array Extension for Chunking

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}