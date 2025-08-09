import Foundation
import os

// MARK: - Security Event Types

/// Enum representing different types of security events
public enum SecurityEventType: String, CaseIterable, Sendable {
    case certificateValidationFailure = "certificate_validation_failure"
    case certificateValidationSuccess = "certificate_validation_success"
    case generic = "generic_security_event"
}

// MARK: - Security Event Model

/// Model representing a security event
public struct SecurityEvent: Sendable {
    public let eventType: SecurityEventType
    public let eventName: String?
    public let host: String?
    public let timestamp: Date
    public let details: [String: String] // Changed to String: String for Sendable compliance
    
    public init(
        eventType: SecurityEventType,
        eventName: String? = nil,
        host: String? = nil,
        timestamp: Date = Date(),
        details: [String: String] = [:]
    ) {
        self.eventType = eventType
        self.eventName = eventName
        self.host = host
        self.timestamp = timestamp
        self.details = details
    }
}

// MARK: - Security Analytics Protocol

/// Protocol for security analytics operations
public protocol SecurityAnalyticsProtocol: Sendable {
    nonisolated func logCertificateValidationFailure(host: String, reason: String)
    nonisolated func logCertificateValidationSuccess(host: String)
    nonisolated func logSecurityEvent(event: String, details: [String: String])
}

// MARK: - Security Analytics Implementation

/// Service for logging and analyzing security events
@MainActor
public final class SecurityAnalytics: SecurityAnalyticsProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    
    private var securityEvents: [SecurityEvent] = []
    private let maxEventCount: Int = 1000
    nonisolated private let logger = Logger(subsystem: "com.magicalstories.security", category: "SecurityAnalytics")
    
    // MARK: - Initialization
    
    nonisolated public init() {}
    
    // MARK: - Public Methods
    
    /// Logs a certificate validation failure
    /// - Parameters:
    ///   - host: The host where validation failed
    ///   - reason: The reason for the failure
    nonisolated public func logCertificateValidationFailure(host: String, reason: String) {
        logger.error("Certificate validation failed for host: \(host), reason: \(reason)")
        
        let event = SecurityEvent(
            eventType: .certificateValidationFailure,
            host: host,
            details: ["reason": reason]
        )
        
        Task { @MainActor in
            addEvent(event)
        }
    }
    
    /// Logs a successful certificate validation
    /// - Parameter host: The host where validation succeeded
    nonisolated public func logCertificateValidationSuccess(host: String) {
        logger.info("Certificate validation succeeded for host: \(host)")
        
        let event = SecurityEvent(
            eventType: .certificateValidationSuccess,
            host: host
        )
        
        Task { @MainActor in
            addEvent(event)
        }
    }
    
    /// Logs a generic security event
    /// - Parameters:
    ///   - event: The event name
    ///   - details: Additional event details
    nonisolated public func logSecurityEvent(event: String, details: [String: String]) {
        logger.info("Security event: \(event)")
        
        let securityEvent = SecurityEvent(
            eventType: .generic,
            eventName: event,
            details: details
        )
        
        Task { @MainActor in
            addEvent(securityEvent)
        }
    }
    
    // MARK: - Internal Methods for Testing
    
    /// Returns all security events (for testing purposes)
    internal func getSecurityEvents() -> [SecurityEvent] {
        return securityEvents
    }
    
    /// Returns security events filtered by type (for testing purposes)
    internal func getSecurityEvents(ofType eventType: SecurityEventType) -> [SecurityEvent] {
        return securityEvents.filter { $0.eventType == eventType }
    }
    
    /// Returns serialized events for reporting (for testing purposes)
    internal func getSerializedEvents() -> String {
        do {
            let serializedEvents = try serializeEvents()
            return serializedEvents
        } catch {
            logger.error("Failed to serialize events: \(error.localizedDescription)")
            return "[]"
        }
    }
    
    /// Clears all security events (for testing purposes)
    internal func clearEvents() {
        securityEvents.removeAll()
        logger.info("Security events cleared")
    }
    
    // MARK: - Private Methods
    
    /// Adds a security event to the internal collection
    /// - Parameter event: The security event to add
    private func addEvent(_ event: SecurityEvent) {
        securityEvents.append(event)
        
        // Enforce maximum event count to prevent memory issues
        if securityEvents.count > maxEventCount {
            securityEvents.removeFirst(securityEvents.count - maxEventCount)
        }
    }
    
    /// Serializes security events to JSON string
    /// - Returns: JSON string representation of events
    /// - Throws: Serialization errors
    private func serializeEvents() throws -> String {
        let eventDictionaries = securityEvents.map { event in
            var dict: [String: Any] = [
                "eventType": event.eventType.rawValue,
                "timestamp": event.timestamp.timeIntervalSince1970
            ]
            
            if let eventName = event.eventName {
                dict["eventName"] = eventName
            }
            
            if let host = event.host {
                dict["host"] = host
            }
            
            // Merge details
            for (key, value) in event.details {
                dict[key] = value
            }
            
            return dict
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: eventDictionaries, options: .prettyPrinted)
        return String(data: jsonData, encoding: .utf8) ?? "[]"
    }
}

// MARK: - Thread Safety Extensions

extension SecurityAnalytics {
    /// Thread-safe method to get event count
    nonisolated func getEventCount() async -> Int {
        return await Task { @MainActor in
            return securityEvents.count
        }.value
    }
}

