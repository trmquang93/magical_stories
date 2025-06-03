import Foundation
import CryptoKit

// MARK: - Access Code Type Definitions

/// Represents different types of access codes available in the system
enum AccessCodeType: String, CaseIterable, Identifiable, Codable {
    case reviewer = "reviewer"
    case press = "press"
    case demo = "demo"
    case unlimited = "unlimited"
    case specialAccess = "special_access"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .reviewer:
            return "Reviewer Access"
        case .press:
            return "Press Access"
        case .demo:
            return "Demo Access"
        case .unlimited:
            return "Unlimited Access"
        case .specialAccess:
            return "Special Access"
        }
    }
    
    var description: String {
        switch self {
        case .reviewer:
            return "Limited-time access for app reviewers and testers"
        case .press:
            return "Access for media and press representatives"
        case .demo:
            return "Demonstration access for showcasing app features"
        case .unlimited:
            return "Full unlimited access to all premium features"
        case .specialAccess:
            return "Custom access with specific feature permissions"
        }
    }
    
    /// Default expiration period for each access code type
    var defaultExpirationPeriod: TimeInterval {
        switch self {
        case .reviewer:
            return 30 * 24 * 60 * 60 // 30 days
        case .press:
            return 14 * 24 * 60 * 60 // 14 days
        case .demo:
            return 7 * 24 * 60 * 60  // 7 days
        case .unlimited:
            return 365 * 24 * 60 * 60 // 1 year
        case .specialAccess:
            return 30 * 24 * 60 * 60 // 30 days
        }
    }
    
    /// Default features granted by this access code type
    var defaultGrantedFeatures: [PremiumFeature] {
        switch self {
        case .reviewer:
            return [.unlimitedStoryGeneration, .advancedIllustrations]
        case .press:
            return [.unlimitedStoryGeneration, .growthPathCollections, .advancedIllustrations]
        case .demo:
            return [.unlimitedStoryGeneration]
        case .unlimited:
            return PremiumFeature.allCases
        case .specialAccess:
            return [] // Must be explicitly defined
        }
    }
}

// MARK: - Access Code Data Model

/// Represents an access code with its configuration and validation data
struct AccessCode: Identifiable, Equatable, Hashable {
    let id: UUID
    let code: String
    let type: AccessCodeType
    let grantedFeatures: [PremiumFeature]
    let createdAt: Date
    let expiresAt: Date?
    let usageLimit: Int? // nil means unlimited usage
    var usageCount: Int
    let isActive: Bool
    let metadata: AccessCodeMetadata?
    
    /// Computed property to check if the access code is currently valid
    var isValid: Bool {
        guard isActive else { return false }
        
        // Check expiration
        if let expiresAt = expiresAt, expiresAt <= Date() {
            return false
        }
        
        // Check usage limit
        if let usageLimit = usageLimit, usageCount >= usageLimit {
            return false
        }
        
        return true
    }
    
    /// Computed property to check if the access code is expired
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return expiresAt <= Date()
    }
    
    /// Computed property to check if usage limit is reached
    var isUsageLimitReached: Bool {
        guard let usageLimit = usageLimit else { return false }
        return usageCount >= usageLimit
    }
    
    /// Time remaining until expiration
    var timeRemaining: TimeInterval? {
        guard let expiresAt = expiresAt else { return nil }
        let remaining = expiresAt.timeIntervalSince(Date())
        return remaining > 0 ? remaining : 0
    }
    
    /// Days remaining until expiration
    var daysRemaining: Int? {
        guard let timeRemaining = timeRemaining else { return nil }
        return Int(ceil(timeRemaining / (24 * 60 * 60)))
    }
    
    /// Usage remaining before limit is reached
    var usageRemaining: Int? {
        guard let usageLimit = usageLimit else { return nil }
        return max(0, usageLimit - usageCount)
    }
    
    init(
        id: UUID = UUID(),
        code: String,
        type: AccessCodeType,
        grantedFeatures: [PremiumFeature]? = nil,
        createdAt: Date = Date(),
        expiresAt: Date? = nil,
        usageLimit: Int? = nil,
        usageCount: Int = 0,
        isActive: Bool = true,
        metadata: AccessCodeMetadata? = nil
    ) {
        self.id = id
        self.code = code
        self.type = type
        self.grantedFeatures = grantedFeatures ?? type.defaultGrantedFeatures
        self.createdAt = createdAt
        self.expiresAt = expiresAt ?? Date().addingTimeInterval(type.defaultExpirationPeriod)
        self.usageLimit = usageLimit
        self.usageCount = usageCount
        self.isActive = isActive
        self.metadata = metadata
    }
    
}

// MARK: - AccessCode Codable Implementation

extension AccessCode: Codable {
    enum CodingKeys: String, CodingKey {
        case id, code, type, grantedFeatures, createdAt, expiresAt, usageLimit, usageCount, isActive, metadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        code = try container.decode(String.self, forKey: .code)
        type = try container.decode(AccessCodeType.self, forKey: .type)
        grantedFeatures = try container.decode([PremiumFeature].self, forKey: .grantedFeatures)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
        usageLimit = try container.decodeIfPresent(Int.self, forKey: .usageLimit)
        usageCount = try container.decode(Int.self, forKey: .usageCount)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        metadata = try container.decodeIfPresent(AccessCodeMetadata.self, forKey: .metadata)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(code, forKey: .code)
        try container.encode(type, forKey: .type)
        try container.encode(grantedFeatures as [PremiumFeature], forKey: .grantedFeatures)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(expiresAt, forKey: .expiresAt)
        try container.encodeIfPresent(usageLimit, forKey: .usageLimit)
        try container.encode(usageCount, forKey: .usageCount)
        try container.encode(isActive, forKey: .isActive)
        try container.encodeIfPresent(metadata, forKey: .metadata)
    }
}

// MARK: - Access Code Metadata

/// Additional metadata for access codes
struct AccessCodeMetadata: Codable, Equatable, Hashable {
    let issuer: String?
    let purpose: String?
    let recipientEmail: String?
    let notes: String?
    let allowFeatureSubset: Bool // If true, code grants subset of features; if false, all features
    
    init(
        issuer: String? = nil,
        purpose: String? = nil,
        recipientEmail: String? = nil,
        notes: String? = nil,
        allowFeatureSubset: Bool = true
    ) {
        self.issuer = issuer
        self.purpose = purpose
        self.recipientEmail = recipientEmail
        self.notes = notes
        self.allowFeatureSubset = allowFeatureSubset
    }
}

// MARK: - Access Code Generation Configuration

/// Configuration for generating new access codes
struct AccessCodeGenerationConfig {
    let type: AccessCodeType
    let grantedFeatures: [PremiumFeature]?
    let expirationDate: Date?
    let usageLimit: Int?
    let metadata: AccessCodeMetadata?
    
    init(
        type: AccessCodeType,
        grantedFeatures: [PremiumFeature]? = nil,
        expirationDate: Date? = nil,
        usageLimit: Int? = nil,
        metadata: AccessCodeMetadata? = nil
    ) {
        self.type = type
        self.grantedFeatures = grantedFeatures
        self.expirationDate = expirationDate
        self.usageLimit = usageLimit
        self.metadata = metadata
    }
}

// MARK: - Access Code Storage Model

/// Model for storing access codes securely in UserDefaults
struct StoredAccessCode: Codable {
    let accessCode: AccessCode
    let activatedAt: Date
    let lastUsedAt: Date?
    
    init(accessCode: AccessCode, activatedAt: Date = Date(), lastUsedAt: Date? = nil) {
        self.accessCode = accessCode
        self.activatedAt = activatedAt
        self.lastUsedAt = lastUsedAt
    }
}

// MARK: - Access Code Validation Errors

/// Errors that can occur during access code validation
enum AccessCodeValidationError: LocalizedError, Equatable {
    case invalidFormat
    case codeNotFound
    case codeExpired(expirationDate: Date)
    case usageLimitReached(limit: Int)
    case codeInactive
    case checksumMismatch
    case networkError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Access code format is invalid"
        case .codeNotFound:
            return "Access code not found or invalid"
        case .codeExpired(let expirationDate):
            return "Access code expired on \(DateFormatter.shortDate.string(from: expirationDate))"
        case .usageLimitReached(let limit):
            return "Access code usage limit reached (\(limit) uses)"
        case .codeInactive:
            return "Access code is not active"
        case .checksumMismatch:
            return "Access code checksum validation failed"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidFormat:
            return "Please check the access code format and try again"
        case .codeNotFound:
            return "Please verify the access code is correct"
        case .codeExpired:
            return "Please contact support for a new access code"
        case .usageLimitReached:
            return "This access code has reached its usage limit"
        case .codeInactive:
            return "This access code is no longer active"
        case .checksumMismatch:
            return "Please re-enter the access code carefully"
        case .networkError:
            return "Please check your internet connection and try again"
        case .unknown:
            return "Please try again or contact support"
        }
    }
}

// MARK: - Access Code Validation Result

/// Result of access code validation
enum AccessCodeValidationResult: Equatable {
    case valid(AccessCode)
    case invalid(AccessCodeValidationError)
    
    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
    
    var accessCode: AccessCode? {
        switch self {
        case .valid(let code):
            return code
        case .invalid:
            return nil
        }
    }
    
    var error: AccessCodeValidationError? {
        switch self {
        case .valid:
            return nil
        case .invalid(let error):
            return error
        }
    }
}

// MARK: - Access Code Format Specification

/// Defines the format and structure of access codes
struct AccessCodeFormat {
    static let codeLength = 12 // Total length including prefix and checksum
    static let prefixLength = 2
    static let checksumLength = 2
    static let dataLength = codeLength - prefixLength - checksumLength // 8 characters
    
    /// Prefixes for different access code types
    static let typePrefixes: [AccessCodeType: String] = [
        .reviewer: "RV",
        .press: "PR",
        .demo: "DM",
        .unlimited: "UN",
        .specialAccess: "SA"
    ]
    
    /// Characters allowed in access codes (excludes ambiguous characters)
    static let allowedCharacters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    
    /// Validates that a string matches the expected access code format
    /// - Parameter code: The access code string to validate
    /// - Returns: True if format is valid, false otherwise
    static func isValidFormat(_ code: String) -> Bool {
        // Check length
        guard code.count == codeLength else { return false }
        
        // Check prefix
        let prefix = String(code.prefix(prefixLength))
        guard typePrefixes.values.contains(prefix) else { return false }
        
        // Check characters
        return code.allSatisfy { allowedCharacters.contains($0) }
    }
    
    /// Extracts the access code type from the prefix
    /// - Parameter code: The access code string
    /// - Returns: The access code type, or nil if invalid
    static func extractType(from code: String) -> AccessCodeType? {
        guard code.count >= prefixLength else { return nil }
        let prefix = String(code.prefix(prefixLength))
        return typePrefixes.first { $0.value == prefix }?.key
    }
    
    /// Validates the checksum of an access code
    /// - Parameter code: The access code string
    /// - Returns: True if checksum is valid, false otherwise
    static func validateChecksum(_ code: String) -> Bool {
        guard code.count == codeLength else { return false }
        
        let dataPortion = String(code.dropLast(checksumLength))
        let providedChecksum = String(code.suffix(checksumLength))
        let calculatedChecksum = calculateChecksum(for: dataPortion)
        
        return providedChecksum == calculatedChecksum
    }
    
    /// Calculates a checksum for the given data
    /// - Parameter data: The data string to calculate checksum for
    /// - Returns: A two-character checksum string
    static func calculateChecksum(for data: String) -> String {
        let hash = SHA256.hash(data: Data(data.utf8))
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        // Convert hex to allowed characters and take first 2
        let checksumValue = hashString.prefix(4).reduce(0) { result, char in
            result + Int(String(char), radix: 16)!
        }
        
        let char1Index = checksumValue % allowedCharacters.count
        let char2Index = (checksumValue / allowedCharacters.count) % allowedCharacters.count
        
        let char1 = allowedCharacters[allowedCharacters.index(allowedCharacters.startIndex, offsetBy: char1Index)]
        let char2 = allowedCharacters[allowedCharacters.index(allowedCharacters.startIndex, offsetBy: char2Index)]
        
        return String([char1, char2])
    }
}

// MARK: - Extensions

extension AccessCode {
    /// Creates a display string for the access code with formatting
    var formattedCode: String {
        let code = self.code
        guard code.count == AccessCodeFormat.codeLength else { return code }
        
        // Format as XX-XXXX-XXXX-XX for better readability
        let prefix = String(code.prefix(2))
        let middle1 = String(code.dropFirst(2).prefix(4))
        let middle2 = String(code.dropFirst(6).prefix(4))
        let suffix = String(code.suffix(2))
        
        return "\(prefix)-\(middle1)-\(middle2)-\(suffix)"
    }
    
    /// Returns a summary of the access code's permissions
    var permissionsSummary: String {
        if grantedFeatures.count == PremiumFeature.allCases.count {
            return "All Premium Features"
        } else if grantedFeatures.isEmpty {
            return "No Premium Features"
        } else {
            return "\(grantedFeatures.count) Premium Feature\(grantedFeatures.count == 1 ? "" : "s")"
        }
    }
    
    /// Returns the status of the access code
    var statusDescription: String {
        if !isActive {
            return "Inactive"
        } else if isExpired {
            return "Expired"
        } else if isUsageLimitReached {
            return "Usage Limit Reached"
        } else {
            return "Active"
        }
    }
}