import Foundation

// MARK: - Required Types Import
// Import the existing access code models and the configuration types
// AccessCode, AccessCodeType are from AccessCodeModels.swift
// BackendProvider is from BackendConfiguration.swift

/// Protocol defining backend operations for promo code validation and management
/// This abstraction allows switching between different backend providers (offline, Firebase, custom API)
@MainActor
protocol PromoCodeBackendService {
    
    /// Validates a promo code asynchronously against the backend
    /// - Parameter code: The promo code string to validate
    /// - Returns: ValidationResult containing code details if valid
    /// - Throws: AccessCodeValidationError if validation fails
    func validateCodeAsync(_ code: String) async throws -> BackendValidationResult
    
    /// Tracks usage of a promo code for analytics and monitoring
    /// - Parameters:
    ///   - code: The promo code that was used
    ///   - metadata: Additional usage information (user, device, etc.)
    /// - Throws: Error if tracking fails
    func trackUsageAsync(_ code: String, _ metadata: UsageMetadata) async throws
    
    /// Gets analytics data for promo code usage
    /// - Parameter filters: Filters for the analytics query
    /// - Returns: Analytics data
    /// - Throws: Error if analytics retrieval fails
    func getAnalyticsAsync(_ filters: AnalyticsFilters) async throws -> CodeAnalytics
    
    /// Checks if the backend service is available and healthy
    /// - Returns: True if backend is accessible, false otherwise
    func isBackendAvailable() async -> Bool
}

/// Enhanced validation result that includes backend-specific information
struct BackendValidationResult: Sendable {
    let accessCode: AccessCode
    let validatedAt: Date
    let backendProvider: BackendProvider
    let isOfflineValidation: Bool
    let serverMetadata: [String: String]?
    
    init(accessCode: AccessCode, 
         validatedAt: Date = Date(),
         backendProvider: BackendProvider = .offline,
         isOfflineValidation: Bool = true,
         serverMetadata: [String: String]? = nil) {
        self.accessCode = accessCode
        self.validatedAt = validatedAt
        self.backendProvider = backendProvider
        self.isOfflineValidation = isOfflineValidation
        self.serverMetadata = serverMetadata
    }
}

/// Metadata for tracking promo code usage
struct UsageMetadata: Sendable {
    let userId: String?
    let deviceId: String?
    let appVersion: String
    let platform: String
    let timestamp: Date
    let location: String?
    
    init(userId: String? = nil,
         deviceId: String? = nil,
         appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
         platform: String = "iOS",
         timestamp: Date = Date(),
         location: String? = nil) {
        self.userId = userId
        self.deviceId = deviceId
        self.appVersion = appVersion
        self.platform = platform
        self.timestamp = timestamp
        self.location = location
    }
}

/// Filters for analytics queries
struct AnalyticsFilters: Sendable {
    let dateRange: ClosedRange<Date>?
    let codeType: AccessCodeType?
    let includeExpired: Bool
    
    init(dateRange: ClosedRange<Date>? = nil,
         codeType: AccessCodeType? = nil,
         includeExpired: Bool = false) {
        self.dateRange = dateRange
        self.codeType = codeType
        self.includeExpired = includeExpired
    }
}

/// Analytics data for promo codes
struct CodeAnalytics: Sendable {
    let totalCodes: Int
    let usedCodes: Int
    let activeUsers: Int
    let usageByType: [AccessCodeType: Int]
    let usageByDate: [Date: Int]
    let generatedAt: Date
    
    init(totalCodes: Int = 0,
         usedCodes: Int = 0,
         activeUsers: Int = 0,
         usageByType: [AccessCodeType: Int] = [:],
         usageByDate: [Date: Int] = [:],
         generatedAt: Date = Date()) {
        self.totalCodes = totalCodes
        self.usedCodes = usedCodes
        self.activeUsers = activeUsers
        self.usageByType = usageByType
        self.usageByDate = usageByDate
        self.generatedAt = generatedAt
    }
}