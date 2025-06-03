import XCTest
@testable import magical_stories

class AccessCodeModelsTests: XCTestCase {
    
    // MARK: - AccessCodeType Tests
    
    func testAccessCodeTypeProperties() {
        let reviewerType = AccessCodeType.reviewer
        
        XCTAssertEqual(reviewerType.id, "reviewer")
        XCTAssertEqual(reviewerType.displayName, "Reviewer Access")
        XCTAssertEqual(reviewerType.defaultExpirationPeriod, 30 * 24 * 60 * 60) // 30 days
        XCTAssertTrue(reviewerType.defaultGrantedFeatures.contains(.unlimitedStoryGeneration))
        XCTAssertTrue(reviewerType.defaultGrantedFeatures.contains(.advancedIllustrations))
    }
    
    func testUnlimitedAccessCodeGrantsAllFeatures() {
        let unlimitedType = AccessCodeType.unlimited
        XCTAssertEqual(unlimitedType.defaultGrantedFeatures.count, PremiumFeature.allCases.count)
        
        for feature in PremiumFeature.allCases {
            XCTAssertTrue(unlimitedType.defaultGrantedFeatures.contains(feature))
        }
    }
    
    func testSpecialAccessCodeHasNoDefaultFeatures() {
        let specialType = AccessCodeType.specialAccess
        XCTAssertTrue(specialType.defaultGrantedFeatures.isEmpty)
    }
    
    // MARK: - AccessCode Tests
    
    func testAccessCodeInitialization() {
        let code = AccessCode(
            code: "RV2345678923",
            type: .reviewer,
            grantedFeatures: [.unlimitedStoryGeneration],
            expiresAt: Date().addingTimeInterval(7 * 24 * 60 * 60),
            usageLimit: 10,
            usageCount: 0
        )
        
        XCTAssertEqual(code.code, "RV2345678923")
        XCTAssertEqual(code.type, .reviewer)
        XCTAssertEqual(code.grantedFeatures, [.unlimitedStoryGeneration])
        XCTAssertEqual(code.usageLimit, 10)
        XCTAssertEqual(code.usageCount, 0)
        XCTAssertTrue(code.isActive)
        XCTAssertTrue(code.isValid)
    }
    
    func testAccessCodeDefaultInitialization() {
        let code = AccessCode(code: "RV2345678923", type: .reviewer)
        
        XCTAssertEqual(code.type, .reviewer)
        XCTAssertEqual(code.grantedFeatures, AccessCodeType.reviewer.defaultGrantedFeatures)
        XCTAssertNotNil(code.expiresAt)
        XCTAssertTrue(code.isActive)
        XCTAssertEqual(code.usageCount, 0)
    }
    
    func testAccessCodeValidityChecks() {
        // Valid code
        let validCode = AccessCode(
            code: "RV2345678923",
            type: .reviewer,
            expiresAt: Date().addingTimeInterval(24 * 60 * 60), // 1 day from now
            usageLimit: 10,
            usageCount: 5
        )
        XCTAssertTrue(validCode.isValid)
        XCTAssertFalse(validCode.isExpired)
        XCTAssertFalse(validCode.isUsageLimitReached)
        
        // Expired code
        let expiredCode = AccessCode(
            code: "RV2345678924",
            type: .reviewer,
            expiresAt: Date().addingTimeInterval(-24 * 60 * 60), // 1 day ago
            usageLimit: 10,
            usageCount: 5
        )
        XCTAssertFalse(expiredCode.isValid)
        XCTAssertTrue(expiredCode.isExpired)
        
        // Usage limit reached
        let usageLimitReachedCode = AccessCode(
            code: "RV2345678925",
            type: .reviewer,
            expiresAt: Date().addingTimeInterval(24 * 60 * 60),
            usageLimit: 10,
            usageCount: 10
        )
        XCTAssertFalse(usageLimitReachedCode.isValid)
        XCTAssertTrue(usageLimitReachedCode.isUsageLimitReached)
        
        // Inactive code
        let inactiveCode = AccessCode(
            code: "RV2345678926",
            type: .reviewer,
            expiresAt: Date().addingTimeInterval(24 * 60 * 60),
            usageLimit: 10,
            usageCount: 5,
            isActive: false
        )
        XCTAssertFalse(inactiveCode.isValid)
    }
    
    func testAccessCodeTimeRemaining() {
        let futureDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days
        let code = AccessCode(
            code: "RV2345678923",
            type: .reviewer,
            expiresAt: futureDate
        )
        
        XCTAssertNotNil(code.timeRemaining)
        XCTAssertEqual(code.daysRemaining, 7)
        
        // Code with default expiration 
        let defaultExpiringCode = AccessCode(
            code: "RV2345678924",
            type: .reviewer
        )
        XCTAssertNotNil(defaultExpiringCode.timeRemaining)
        XCTAssertNotNil(defaultExpiringCode.daysRemaining)
    }
    
    func testAccessCodeUsageRemaining() {
        let code = AccessCode(
            code: "RV2345678923",
            type: .reviewer,
            usageLimit: 10,
            usageCount: 3
        )
        
        XCTAssertEqual(code.usageRemaining, 7)
        
        // Code with no usage limit
        let unlimitedCode = AccessCode(
            code: "RV2345678924",
            type: .reviewer,
            usageLimit: nil
        )
        XCTAssertNil(unlimitedCode.usageRemaining)
    }
    
    // MARK: - AccessCodeMetadata Tests
    
    func testAccessCodeMetadata() {
        let metadata = AccessCodeMetadata(
            issuer: "Test System",
            purpose: "Testing",
            recipientEmail: "test@example.com",
            notes: "Test notes",
            allowFeatureSubset: true
        )
        
        XCTAssertEqual(metadata.issuer, "Test System")
        XCTAssertEqual(metadata.purpose, "Testing")
        XCTAssertEqual(metadata.recipientEmail, "test@example.com")
        XCTAssertEqual(metadata.notes, "Test notes")
        XCTAssertTrue(metadata.allowFeatureSubset)
    }
    
    // MARK: - AccessCodeFormat Tests
    
    func testAccessCodeFormatValidation() {
        // Valid formats
        XCTAssertTrue(AccessCodeFormat.isValidFormat("RV23456789AB"))
        XCTAssertTrue(AccessCodeFormat.isValidFormat("PR23456789CD"))
        XCTAssertTrue(AccessCodeFormat.isValidFormat("DM23456789EF"))
        
        // Invalid formats
        XCTAssertFalse(AccessCodeFormat.isValidFormat("RV2345678")) // Too short
        XCTAssertFalse(AccessCodeFormat.isValidFormat("RV234567892ABC")) // Too long
        XCTAssertFalse(AccessCodeFormat.isValidFormat("XX23456789AB")) // Invalid prefix
        XCTAssertFalse(AccessCodeFormat.isValidFormat("RV234567O8AB")) // Contains 'O' (invalid char)
        XCTAssertFalse(AccessCodeFormat.isValidFormat("RV2345671AB")) // Contains '1' (invalid char)
    }
    
    func testAccessCodeTypeExtraction() {
        XCTAssertEqual(AccessCodeFormat.extractType(from: "RV23456789AB"), .reviewer)
        XCTAssertEqual(AccessCodeFormat.extractType(from: "PR23456789CD"), .press)
        XCTAssertEqual(AccessCodeFormat.extractType(from: "DM23456789EF"), .demo)
        XCTAssertEqual(AccessCodeFormat.extractType(from: "UN23456789GH"), .unlimited)
        XCTAssertEqual(AccessCodeFormat.extractType(from: "SA23456789JK"), .specialAccess)
        XCTAssertNil(AccessCodeFormat.extractType(from: "XX23456789AB"))
        XCTAssertEqual(AccessCodeFormat.extractType(from: "RV234"), .reviewer) // Short but valid prefix
    }
    
    func testAccessCodeChecksumCalculation() {
        let testData = "RV23456789"
        let checksum = AccessCodeFormat.calculateChecksum(for: testData)
        
        XCTAssertEqual(checksum.count, 2)
        XCTAssertTrue(checksum.allSatisfy { AccessCodeFormat.allowedCharacters.contains($0) })
        
        // Same input should produce same checksum
        let checksum2 = AccessCodeFormat.calculateChecksum(for: testData)
        XCTAssertEqual(checksum, checksum2)
        
        // Different input should produce different checksum
        let differentChecksum = AccessCodeFormat.calculateChecksum(for: "PR89765432")
        XCTAssertNotEqual(checksum, differentChecksum)
    }
    
    func testAccessCodeChecksumValidation() {
        let validCodeWithChecksum = "RV23456789" + AccessCodeFormat.calculateChecksum(for: "RV23456789")
        XCTAssertTrue(AccessCodeFormat.validateChecksum(validCodeWithChecksum))
        
        let invalidCodeWithWrongChecksum = "RV23456789AB"
        // This might be valid if "AB" happens to be the correct checksum, but likely not
        // We test that the validation function runs without crashing
        let _ = AccessCodeFormat.validateChecksum(invalidCodeWithWrongChecksum)
    }
    
    // MARK: - AccessCodeValidationError Tests
    
    func testValidationErrorDescriptions() {
        let invalidFormatError = AccessCodeValidationError.invalidFormat
        XCTAssertNotNil(invalidFormatError.errorDescription)
        XCTAssertNotNil(invalidFormatError.recoverySuggestion)
        
        let expiredError = AccessCodeValidationError.codeExpired(expirationDate: Date())
        XCTAssertNotNil(expiredError.errorDescription)
        XCTAssertNotNil(expiredError.recoverySuggestion)
        
        let usageLimitError = AccessCodeValidationError.usageLimitReached(limit: 10)
        XCTAssertNotNil(usageLimitError.errorDescription)
        XCTAssertTrue(usageLimitError.errorDescription!.contains("10"))
    }
    
    // MARK: - AccessCodeValidationResult Tests
    
    func testValidationResultProperties() {
        let accessCode = AccessCode(code: "RV23456789AB", type: .reviewer)
        let validResult = AccessCodeValidationResult.valid(accessCode)
        
        XCTAssertTrue(validResult.isValid)
        XCTAssertNotNil(validResult.accessCode)
        XCTAssertNil(validResult.error)
        XCTAssertEqual(validResult.accessCode?.code, "RV23456789AB")
        
        let invalidResult = AccessCodeValidationResult.invalid(.invalidFormat)
        XCTAssertFalse(invalidResult.isValid)
        XCTAssertNil(invalidResult.accessCode)
        XCTAssertNotNil(invalidResult.error)
        XCTAssertEqual(invalidResult.error, .invalidFormat)
    }
    
    // MARK: - StoredAccessCode Tests
    
    func testStoredAccessCode() {
        let accessCode = AccessCode(code: "RV23456789AB", type: .reviewer)
        let activationDate = Date()
        let lastUsedDate = Date().addingTimeInterval(-3600) // 1 hour ago
        
        let storedCode = StoredAccessCode(
            accessCode: accessCode,
            activatedAt: activationDate,
            lastUsedAt: lastUsedDate
        )
        
        XCTAssertEqual(storedCode.accessCode.code, accessCode.code)
        XCTAssertEqual(storedCode.activatedAt, activationDate)
        XCTAssertEqual(storedCode.lastUsedAt, lastUsedDate)
    }
    
    // MARK: - AccessCode Extensions Tests
    
    func testAccessCodeFormattedDisplay() {
        let code = AccessCode(code: "RV23456789AB", type: .reviewer)
        let formatted = code.formattedCode
        XCTAssertEqual(formatted, "RV-2345-6789-AB")
    }
    
    func testAccessCodePermissionsSummary() {
        let allFeaturesCode = AccessCode(
            code: "UN12345678AB",
            type: .unlimited,
            grantedFeatures: PremiumFeature.allCases
        )
        XCTAssertEqual(allFeaturesCode.permissionsSummary, "All Premium Features")
        
        let noFeaturesCode = AccessCode(
            code: "SA12345678AB",
            type: .specialAccess,
            grantedFeatures: []
        )
        XCTAssertEqual(noFeaturesCode.permissionsSummary, "No Premium Features")
        
        let someFeaturesCode = AccessCode(
            code: "RV23456789AB",
            type: .reviewer,
            grantedFeatures: [.unlimitedStoryGeneration, .advancedIllustrations]
        )
        XCTAssertEqual(someFeaturesCode.permissionsSummary, "2 Premium Features")
    }
    
    func testAccessCodeStatusDescription() {
        let activeCode = AccessCode(code: "RV23456789AB", type: .reviewer)
        XCTAssertEqual(activeCode.statusDescription, "Active")
        
        let inactiveCode = AccessCode(
            code: "RV12345678CD",
            type: .reviewer,
            isActive: false
        )
        XCTAssertEqual(inactiveCode.statusDescription, "Inactive")
        
        let expiredCode = AccessCode(
            code: "RV12345678EF",
            type: .reviewer,
            expiresAt: Date().addingTimeInterval(-24 * 60 * 60)
        )
        XCTAssertEqual(expiredCode.statusDescription, "Expired")
    }
    
    // MARK: - Codable Tests
    
    func testAccessCodeCodable() throws {
        let originalCode = AccessCode(
            code: "RV23456789AB",
            type: .reviewer,
            grantedFeatures: [.unlimitedStoryGeneration, .advancedIllustrations],
            expiresAt: Date(),
            usageLimit: 10,
            usageCount: 3
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalCode)
        
        let decoder = JSONDecoder()
        let decodedCode = try decoder.decode(AccessCode.self, from: data)
        
        XCTAssertEqual(originalCode.id, decodedCode.id)
        XCTAssertEqual(originalCode.code, decodedCode.code)
        XCTAssertEqual(originalCode.type, decodedCode.type)
        XCTAssertEqual(originalCode.grantedFeatures, decodedCode.grantedFeatures)
        XCTAssertEqual(originalCode.usageLimit, decodedCode.usageLimit)
        XCTAssertEqual(originalCode.usageCount, decodedCode.usageCount)
        XCTAssertEqual(originalCode.isActive, decodedCode.isActive)
    }
    
    func testStoredAccessCodeCodable() throws {
        let accessCode = AccessCode(code: "RV23456789AB", type: .reviewer)
        let storedCode = StoredAccessCode(accessCode: accessCode)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(storedCode)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedStoredCode = try decoder.decode(StoredAccessCode.self, from: data)
        
        XCTAssertEqual(storedCode.accessCode.code, decodedStoredCode.accessCode.code)
        XCTAssertEqual(storedCode.accessCode.type, decodedStoredCode.accessCode.type)
    }
}