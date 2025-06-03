import Foundation
import OSLog
import CryptoKit

/// Service responsible for validating and managing access codes
class AccessCodeValidator: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var isValidating = false
    @Published private(set) var validationError: AccessCodeValidationError?
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicalstories", 
                               category: "AccessCodeValidator")
    
    // MARK: - Initialization
    
    init() {
        logger.info("AccessCodeValidator initialized")
    }
    
    // MARK: - Public API
    
    /// Validates an access code string and returns the validation result
    /// - Parameter codeString: The access code string to validate
    /// - Returns: AccessCodeValidationResult indicating success or failure
    @MainActor
    func validateAccessCode(_ codeString: String) async -> AccessCodeValidationResult {
        logger.info("Validating access code: \(codeString.prefix(4))...")
        
        isValidating = true
        validationError = nil
        
        defer {
            isValidating = false
        }
        
        // Clean the input code
        let cleanedCode = cleanAccessCode(codeString)
        
        // Step 1: Format validation
        guard AccessCodeFormat.isValidFormat(cleanedCode) else {
            let error = AccessCodeValidationError.invalidFormat
            validationError = error
            logger.warning("Access code format validation failed: \(cleanedCode)")
            return .invalid(error)
        }
        
        // Step 2: Checksum validation
        guard AccessCodeFormat.validateChecksum(cleanedCode) else {
            let error = AccessCodeValidationError.checksumMismatch
            validationError = error
            logger.warning("Access code checksum validation failed: \(cleanedCode)")
            return .invalid(error)
        }
        
        // Step 3: Extract type and validate
        guard let codeType = AccessCodeFormat.extractType(from: cleanedCode) else {
            let error = AccessCodeValidationError.invalidFormat
            validationError = error
            logger.warning("Could not extract access code type: \(cleanedCode)")
            return .invalid(error)
        }
        
        // Step 4: Create access code object and validate properties
        let accessCode = createAccessCodeFromString(cleanedCode, type: codeType)
        
        // Step 5: Validate access code state
        let validationResult = validateAccessCodeState(accessCode)
        
        if case .valid = validationResult {
            logger.info("Access code validation successful: \(codeType.displayName)")
        } else if case .invalid(let error) = validationResult {
            validationError = error
            logger.warning("Access code validation failed: \(error.localizedDescription)")
        }
        
        return validationResult
    }
    
    /// Validates an access code format without full validation
    /// - Parameter codeString: The access code string to check
    /// - Returns: True if format is valid, false otherwise
    func isValidFormat(_ codeString: String) -> Bool {
        let cleanedCode = cleanAccessCode(codeString)
        return AccessCodeFormat.isValidFormat(cleanedCode)
    }
    
    /// Extracts the access code type from a string
    /// - Parameter codeString: The access code string
    /// - Returns: The access code type, or nil if invalid
    func extractCodeType(from codeString: String) -> AccessCodeType? {
        let cleanedCode = cleanAccessCode(codeString)
        return AccessCodeFormat.extractType(from: cleanedCode)
    }
    
    /// Generates a preview of what features would be unlocked by this code
    /// - Parameter codeString: The access code string
    /// - Returns: Array of premium features that would be granted
    func previewFeatures(for codeString: String) -> [PremiumFeature] {
        guard let codeType = extractCodeType(from: codeString) else {
            return []
        }
        return codeType.defaultGrantedFeatures
    }
    
    // MARK: - Private Methods
    
    /// Cleans and formats an access code string
    /// - Parameter codeString: The raw access code string
    /// - Returns: Cleaned access code string
    private func cleanAccessCode(_ codeString: String) -> String {
        // Remove spaces, dashes, and convert to uppercase
        return codeString
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .uppercased()
    }
    
    /// Creates an AccessCode object from a validated string
    /// - Parameters:
    ///   - codeString: The validated access code string
    ///   - type: The extracted access code type
    /// - Returns: AccessCode object
    private func createAccessCodeFromString(_ codeString: String, type: AccessCodeType) -> AccessCode {
        // Extract metadata from the code (this is a simplified implementation)
        // In a real-world scenario, you might decode more information from the code
        let metadata = AccessCodeMetadata(
            issuer: "System",
            purpose: type.description,
            recipientEmail: nil,
            notes: "Generated access code",
            allowFeatureSubset: true
        )
        
        // Create access code with default configuration for the type
        return AccessCode(
            code: codeString,
            type: type,
            grantedFeatures: type.defaultGrantedFeatures,
            expiresAt: Date().addingTimeInterval(type.defaultExpirationPeriod),
            usageLimit: getDefaultUsageLimit(for: type),
            usageCount: 0,
            isActive: true,
            metadata: metadata
        )
    }
    
    /// Gets the default usage limit for an access code type
    /// - Parameter type: The access code type
    /// - Returns: Usage limit, or nil for unlimited
    private func getDefaultUsageLimit(for type: AccessCodeType) -> Int? {
        switch type {
        case .demo:
            return 10 // Demo codes have limited usage
        case .reviewer:
            return 50 // Reviewer codes have moderate usage
        case .press:
            return 25 // Press codes have limited usage
        case .unlimited, .specialAccess:
            return nil // Unlimited usage
        }
    }
    
    /// Validates the state of an access code
    /// - Parameter accessCode: The access code to validate
    /// - Returns: Validation result
    private func validateAccessCodeState(_ accessCode: AccessCode) -> AccessCodeValidationResult {
        // Check if code is active
        guard accessCode.isActive else {
            return .invalid(.codeInactive)
        }
        
        // Check expiration
        if let expiresAt = accessCode.expiresAt, expiresAt <= Date() {
            return .invalid(.codeExpired(expirationDate: expiresAt))
        }
        
        // Check usage limit
        if let usageLimit = accessCode.usageLimit, accessCode.usageCount >= usageLimit {
            return .invalid(.usageLimitReached(limit: usageLimit))
        }
        
        // All validations passed
        return .valid(accessCode)
    }
}

// MARK: - Access Code Generator

/// Utility for generating new access codes
struct AccessCodeGenerator {
    
    /// Generates a new access code with the specified configuration
    /// - Parameter config: Configuration for the access code
    /// - Returns: Generated access code
    static func generateAccessCode(with config: AccessCodeGenerationConfig) -> AccessCode {
        let codeString = generateCodeString(for: config.type)
        
        return AccessCode(
            code: codeString,
            type: config.type,
            grantedFeatures: config.grantedFeatures ?? config.type.defaultGrantedFeatures,
            expiresAt: config.expirationDate ?? Date().addingTimeInterval(config.type.defaultExpirationPeriod),
            usageLimit: config.usageLimit,
            usageCount: 0,
            isActive: true,
            metadata: config.metadata
        )
    }
    
    /// Generates multiple access codes of the same type
    /// - Parameters:
    ///   - count: Number of codes to generate
    ///   - config: Configuration for the access codes
    /// - Returns: Array of generated access codes
    static func generateAccessCodes(count: Int, with config: AccessCodeGenerationConfig) -> [AccessCode] {
        return (0..<count).map { _ in generateAccessCode(with: config) }
    }
    
    /// Generates a batch of access codes with different configurations
    /// - Parameter configs: Array of configurations for different access codes
    /// - Returns: Array of generated access codes
    static func generateBatchAccessCodes(with configs: [AccessCodeGenerationConfig]) -> [AccessCode] {
        return configs.map { generateAccessCode(with: $0) }
    }
    
    // MARK: - Private Methods
    
    /// Generates a code string for the specified type
    /// - Parameter type: The access code type
    /// - Returns: Generated code string with proper format and checksum
    private static func generateCodeString(for type: AccessCodeType) -> String {
        guard let prefix = AccessCodeFormat.typePrefixes[type] else {
            fatalError("No prefix defined for access code type: \(type)")
        }
        
        // Generate random data portion
        let dataLength = AccessCodeFormat.dataLength
        let allowedChars = AccessCodeFormat.allowedCharacters
        let randomData = (0..<dataLength).map { _ in
            allowedChars.randomElement()!
        }
        let dataString = String(randomData)
        
        // Combine prefix and data
        let baseCode = prefix + dataString
        
        // Calculate and append checksum
        let checksum = AccessCodeFormat.calculateChecksum(for: baseCode)
        
        return baseCode + checksum
    }
}

// MARK: - Access Code Utilities

extension AccessCodeValidator {
    
    /// Validates multiple access codes in batch
    /// - Parameter codes: Array of access code strings to validate
    /// - Returns: Dictionary mapping code strings to validation results
    @MainActor
    func validateBatchAccessCodes(_ codes: [String]) async -> [String: AccessCodeValidationResult] {
        var results: [String: AccessCodeValidationResult] = [:]
        
        for code in codes {
            results[code] = await validateAccessCode(code)
        }
        
        return results
    }
    
    /// Checks if an access code would grant access to a specific feature
    /// - Parameters:
    ///   - codeString: The access code string
    ///   - feature: The premium feature to check
    /// - Returns: True if the code would grant access to the feature
    func wouldGrantAccess(codeString: String, to feature: PremiumFeature) -> Bool {
        guard let codeType = extractCodeType(from: codeString) else {
            return false
        }
        return codeType.defaultGrantedFeatures.contains(feature)
    }
    
    /// Gets a human-readable description of what an access code provides
    /// - Parameter codeString: The access code string
    /// - Returns: Description string
    func getCodeDescription(for codeString: String) -> String {
        guard let codeType = extractCodeType(from: codeString) else {
            return "Invalid access code"
        }
        
        let features = codeType.defaultGrantedFeatures
        let expirationDays = Int(codeType.defaultExpirationPeriod / (24 * 60 * 60))
        
        if features.count == PremiumFeature.allCases.count {
            return "\(codeType.displayName) - All premium features for \(expirationDays) days"
        } else {
            return "\(codeType.displayName) - \(features.count) premium features for \(expirationDays) days"
        }
    }
}