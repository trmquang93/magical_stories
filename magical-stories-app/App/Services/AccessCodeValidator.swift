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
        logger.info("🔍 Starting access code validation...")
        logger.info("📝 Original input: '\(codeString)'")
        
        isValidating = true
        validationError = nil
        
        defer {
            isValidating = false
        }
        
        // Clean the input code
        let cleanedCode = cleanAccessCode(codeString)
        logger.info("🧹 Cleaned code: '\(cleanedCode)' (length: \(cleanedCode.count))")
        
        // Step 1: Format validation
        logger.info("✅ Step 1: Checking format validation...")
        guard AccessCodeFormat.isValidFormat(cleanedCode) else {
            let error = AccessCodeValidationError.invalidFormat
            validationError = error
            logger.error("❌ Step 1 FAILED: Invalid format for code '\(cleanedCode)'")
            logger.error("   Expected: 12 characters with valid prefix")
            logger.error("   Received: \(cleanedCode.count) characters")
            return .invalid(error)
        }
        logger.info("✅ Step 1 PASSED: Format validation successful")
        
        // Step 2: Checksum validation
        logger.info("✅ Step 2: Checking checksum validation...")
        let expectedChecksum = AccessCodeFormat.calculateChecksum(for: String(cleanedCode.prefix(10)))
        let actualChecksum = String(cleanedCode.suffix(2))
        logger.info("   Expected checksum: '\(expectedChecksum)'")
        logger.info("   Actual checksum: '\(actualChecksum)'")
        
        guard AccessCodeFormat.validateChecksum(cleanedCode) else {
            let error = AccessCodeValidationError.checksumMismatch
            validationError = error
            logger.error("❌ Step 2 FAILED: Checksum mismatch for code '\(cleanedCode)'")
            logger.error("   This code may be invalid or corrupted")
            return .invalid(error)
        }
        logger.info("✅ Step 2 PASSED: Checksum validation successful")
        
        // Step 3: Extract type and validate
        logger.info("✅ Step 3: Extracting code type...")
        let prefix = String(cleanedCode.prefix(2))
        logger.info("   Code prefix: '\(prefix)'")
        
        guard let codeType = AccessCodeFormat.extractType(from: cleanedCode) else {
            let error = AccessCodeValidationError.invalidFormat
            validationError = error
            logger.error("❌ Step 3 FAILED: Unknown code type for prefix '\(prefix)'")
            logger.error("   Valid prefixes: RV (reviewer), PR (press), DM (demo), UN (unlimited), SA (special)")
            return .invalid(error)
        }
        logger.info("✅ Step 3 PASSED: Code type identified as '\(codeType.displayName)' (\(prefix))")
        
        // Step 4: Create access code object and validate properties
        logger.info("✅ Step 4: Creating access code object...")
        let accessCode = createAccessCodeFromString(cleanedCode, type: codeType)
        logger.info("   Code: '\(accessCode.code)'")
        logger.info("   Type: \(accessCode.type.displayName)")
        logger.info("   Features: \(accessCode.grantedFeatures.map { $0.rawValue }.joined(separator: ", "))")
        logger.info("   Expires: \(accessCode.expiresAt?.description ?? "Never")")
        logger.info("   Usage Limit: \(accessCode.usageLimit?.description ?? "Unlimited")")
        
        // Step 5: Validate access code state
        logger.info("✅ Step 5: Validating access code state...")
        let validationResult = validateAccessCodeState(accessCode)
        
        if case .valid(let validCode) = validationResult {
            logger.info("🎉 VALIDATION SUCCESSFUL! Code '\(validCode.code)' is valid")
            logger.info("   Type: \(validCode.type.displayName)")
            logger.info("   Features unlocked: \(validCode.grantedFeatures.map { $0.rawValue }.joined(separator: ", "))")
            logger.info("   Expires: \(validCode.expiresAt?.description ?? "Never")")
            logger.info("   Usage remaining: \(validCode.usageLimit.map { max(0, $0 - validCode.usageCount) }?.description ?? "Unlimited")")
        } else if case .invalid(let error) = validationResult {
            validationError = error
            logger.error("❌ VALIDATION FAILED: \(error.localizedDescription)")
            logger.error("   Code: '\(cleanedCode)'")
            logger.error("   Error details: \(error)")
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
        logger.info("     🔍 Checking access code state...")
        
        // Check if code is active
        logger.info("     ↳ Checking if code is active: \(accessCode.isActive)")
        guard accessCode.isActive else {
            logger.error("     ❌ Code is inactive")
            return .invalid(.codeInactive)
        }
        
        // Check expiration
        if let expiresAt = accessCode.expiresAt {
            let now = Date()
            logger.info("     ↳ Checking expiration: \(expiresAt) vs \(now)")
            if expiresAt <= now {
                logger.error("     ❌ Code has expired: \(expiresAt)")
                return .invalid(.codeExpired(expirationDate: expiresAt))
            }
            logger.info("     ✅ Code is not expired (expires in \(expiresAt.timeIntervalSince(now).formatted()) seconds)")
        } else {
            logger.info("     ✅ Code has no expiration date")
        }
        
        // Check usage limit
        if let usageLimit = accessCode.usageLimit {
            logger.info("     ↳ Checking usage: \(accessCode.usageCount)/\(usageLimit)")
            if accessCode.usageCount >= usageLimit {
                logger.error("     ❌ Usage limit reached: \(accessCode.usageCount)/\(usageLimit)")
                return .invalid(.usageLimitReached(limit: usageLimit))
            }
            let remaining = usageLimit - accessCode.usageCount
            logger.info("     ✅ Usage within limit: \(remaining) uses remaining")
        } else {
            logger.info("     ✅ Code has unlimited usage")
        }
        
        // All validations passed
        logger.info("     🎉 All state validations passed!")
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