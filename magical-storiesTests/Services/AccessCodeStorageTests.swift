import XCTest
@testable import magical_stories

@MainActor
class AccessCodeStorageTests: XCTestCase {
    
    var storage: AccessCodeStorage!
    var testAccessCode: AccessCode!
    
    override func setUp() async throws {
        try await super.setUp()
        storage = AccessCodeStorage()
        
        // Create a test access code
        testAccessCode = AccessCode(
            code: "RV23456789AB",
            type: .reviewer,
            grantedFeatures: [.unlimitedStoryGeneration, .advancedIllustrations],
            expiresAt: Date().addingTimeInterval(30 * 24 * 60 * 60), // 30 days
            usageLimit: 10,
            usageCount: 0
        )
        
        // Clear any existing data
        await storage.clearAllAccessCodes()
    }
    
    override func tearDown() async throws {
        // Clean up
        await storage.clearAllAccessCodes()
        storage = nil
        testAccessCode = nil
        try await super.tearDown()
    }
    
    // MARK: - Basic Storage Tests
    
    func testStoreAccessCode() async throws {
        XCTAssertEqual(storage.activeAccessCodes.count, 0)
        
        try await storage.storeAccessCode(testAccessCode)
        
        XCTAssertEqual(storage.activeAccessCodes.count, 1)
        XCTAssertEqual(storage.activeAccessCodes.first?.accessCode.code, testAccessCode.code)
        XCTAssertEqual(storage.activeAccessCodes.first?.accessCode.type, testAccessCode.type)
    }
    
    func testStoreExistingAccessCode() async throws {
        // Store the code initially
        try await storage.storeAccessCode(testAccessCode)
        XCTAssertEqual(storage.activeAccessCodes.count, 1)
        
        // Store the same code again (should update, not duplicate)
        let updatedCode = AccessCode(
            id: testAccessCode.id,
            code: testAccessCode.code,
            type: testAccessCode.type,
            grantedFeatures: testAccessCode.grantedFeatures,
            usageCount: 5 // Different usage count
        )
        
        try await storage.storeAccessCode(updatedCode)
        XCTAssertEqual(storage.activeAccessCodes.count, 1) // Still only one code
        XCTAssertNotNil(storage.activeAccessCodes.first?.lastUsedAt) // Should have lastUsedAt set
    }
    
    func testGetActiveAccessCodes() async throws {
        // Store valid code
        try await storage.storeAccessCode(testAccessCode)
        
        // Store expired code
        let expiredCode = AccessCode(
            code: "PR23456789CD",
            type: .press,
            expiresAt: Date().addingTimeInterval(-24 * 60 * 60) // Expired yesterday
        )
        try await storage.storeAccessCode(expiredCode)
        
        let activeCodes = storage.getActiveAccessCodes()
        
        // Only the valid code should be returned
        XCTAssertEqual(activeCodes.count, 1)
        XCTAssertEqual(activeCodes.first?.accessCode.code, testAccessCode.code)
    }
    
    // MARK: - Feature Access Tests
    
    func testGetAccessCodesGranting() async throws {
        try await storage.storeAccessCode(testAccessCode)
        
        let unlimitedCodes = storage.getAccessCodesGranting(.unlimitedStoryGeneration)
        XCTAssertEqual(unlimitedCodes.count, 1)
        XCTAssertEqual(unlimitedCodes.first?.accessCode.code, testAccessCode.code)
        
        let parentalAnalyticsCodes = storage.getAccessCodesGranting(.parentalAnalytics)
        XCTAssertEqual(parentalAnalyticsCodes.count, 0) // Reviewer code doesn't grant this
    }
    
    func testHasAccessTo() async throws {
        XCTAssertFalse(storage.hasAccessTo(.unlimitedStoryGeneration))
        
        try await storage.storeAccessCode(testAccessCode)
        
        XCTAssertTrue(storage.hasAccessTo(.unlimitedStoryGeneration))
        XCTAssertTrue(storage.hasAccessTo(.advancedIllustrations))
        XCTAssertFalse(storage.hasAccessTo(.parentalAnalytics))
    }
    
    func testGetAccessibleFeatures() async throws {
        let initialFeatures = storage.getAccessibleFeatures()
        XCTAssertTrue(initialFeatures.isEmpty)
        
        try await storage.storeAccessCode(testAccessCode)
        
        let accessibleFeatures = storage.getAccessibleFeatures()
        XCTAssertEqual(accessibleFeatures.count, 2)
        XCTAssertTrue(accessibleFeatures.contains(.unlimitedStoryGeneration))
        XCTAssertTrue(accessibleFeatures.contains(.advancedIllustrations))
    }
    
    func testGetAccessibleFeaturesMultipleCodes() async throws {
        // Store reviewer code
        try await storage.storeAccessCode(testAccessCode)
        
        // Store press code with different features
        let pressCode = AccessCode(
            code: "PR23456789CD",
            type: .press,
            grantedFeatures: [.unlimitedStoryGeneration, .growthPathCollections, .advancedIllustrations]
        )
        try await storage.storeAccessCode(pressCode)
        
        let accessibleFeatures = storage.getAccessibleFeatures()
        
        // Should have union of all features
        XCTAssertTrue(accessibleFeatures.contains(.unlimitedStoryGeneration))
        XCTAssertTrue(accessibleFeatures.contains(.advancedIllustrations))
        XCTAssertTrue(accessibleFeatures.contains(.growthPathCollections))
    }
    
    // MARK: - Usage Tracking Tests
    
    func testIncrementUsage() async throws {
        try await storage.storeAccessCode(testAccessCode)
        
        let initialUsage = storage.activeAccessCodes.first?.accessCode.usageCount
        XCTAssertEqual(initialUsage, 0)
        
        await storage.incrementUsage(for: testAccessCode.code)
        
        let updatedUsage = storage.activeAccessCodes.first?.accessCode.usageCount
        XCTAssertEqual(updatedUsage, 1)
        XCTAssertNotNil(storage.activeAccessCodes.first?.lastUsedAt)
    }
    
    func testIncrementUsageNonExistentCode() async throws {
        await storage.incrementUsage(for: "NONEXISTENT123")
        // Should not crash and should not add any codes
        XCTAssertEqual(storage.activeAccessCodes.count, 0)
    }
    
    func testIncrementUsageToLimit() async throws {
        let limitedCode = AccessCode(
            code: "DM23456789EF",
            type: .demo,
            usageLimit: 2,
            usageCount: 1
        )
        try await storage.storeAccessCode(limitedCode)
        
        // Increment to reach limit
        await storage.incrementUsage(for: limitedCode.code)
        
        let storedCode = storage.activeAccessCodes.first?.accessCode
        XCTAssertEqual(storedCode?.usageCount, 2)
        XCTAssertFalse(storedCode?.isValid ?? true) // Should be invalid due to usage limit
        
        let activeCodes = storage.getActiveAccessCodes()
        XCTAssertEqual(activeCodes.count, 0) // Should not be in active codes
    }
    
    // MARK: - Removal Tests
    
    func testRemoveAccessCode() async throws {
        try await storage.storeAccessCode(testAccessCode)
        XCTAssertEqual(storage.activeAccessCodes.count, 1)
        
        await storage.removeAccessCode(testAccessCode.code)
        XCTAssertEqual(storage.activeAccessCodes.count, 0)
    }
    
    func testRemoveNonExistentCode() async throws {
        await storage.removeAccessCode("NONEXISTENT123")
        XCTAssertEqual(storage.activeAccessCodes.count, 0) // Should not crash
    }
    
    func testClearAllAccessCodes() async throws {
        // Store multiple codes
        try await storage.storeAccessCode(testAccessCode)
        
        let pressCode = AccessCode(code: "PR23456789CD", type: .press)
        try await storage.storeAccessCode(pressCode)
        
        XCTAssertEqual(storage.activeAccessCodes.count, 2)
        
        await storage.clearAllAccessCodes()
        XCTAssertEqual(storage.activeAccessCodes.count, 0)
    }
    
    // MARK: - Statistics Tests
    
    func testGetUsageStatistics() async throws {
        try await storage.storeAccessCode(testAccessCode)
        
        // Increment usage a few times
        await storage.incrementUsage(for: testAccessCode.code)
        await storage.incrementUsage(for: testAccessCode.code)
        
        let stats = storage.getUsageStatistics()
        
        XCTAssertEqual(stats["totalCodes"] as? Int, 1)
        XCTAssertEqual(stats["activeCodes"] as? Int, 1)
        XCTAssertEqual(stats["expiredCodes"] as? Int, 0)
        XCTAssertNotNil(stats["featureUsage"])
        XCTAssertNotNil(stats["lastUpdated"])
    }
    
    func testGetUsageStatisticsWithExpiredCodes() async throws {
        // Store active code
        try await storage.storeAccessCode(testAccessCode)
        
        // Store expired code
        let expiredCode = AccessCode(
            code: "PR23456789CD",
            type: .press,
            expiresAt: Date().addingTimeInterval(-24 * 60 * 60)
        )
        try await storage.storeAccessCode(expiredCode)
        
        let stats = storage.getUsageStatistics()
        
        XCTAssertEqual(stats["totalCodes"] as? Int, 2)
        XCTAssertEqual(stats["activeCodes"] as? Int, 1) // Only the valid one
        XCTAssertEqual(stats["expiredCodes"] as? Int, 1)
    }
    
    // MARK: - Maintenance Tests
    
    func testPerformMaintenance() async throws {
        // Store valid and invalid codes
        try await storage.storeAccessCode(testAccessCode)
        
        let expiredCode = AccessCode(
            code: "PR23456789CD",
            type: .press,
            expiresAt: Date().addingTimeInterval(-24 * 60 * 60)
        )
        try await storage.storeAccessCode(expiredCode)
        
        XCTAssertEqual(storage.activeAccessCodes.count, 2)
        
        await storage.performMaintenance()
        
        // Expired code should be removed
        XCTAssertEqual(storage.activeAccessCodes.count, 1)
        XCTAssertEqual(storage.activeAccessCodes.first?.accessCode.code, testAccessCode.code)
    }
    
    func testIsMaintenanceNeeded() {
        // Should need maintenance when no cleanup has been done
        XCTAssertTrue(storage.isMaintenanceNeeded())
    }
    
    // MARK: - Status Summary Tests
    
    func testStatusSummary() async throws {
        let initialSummary = storage.statusSummary
        XCTAssertEqual(initialSummary.totalActiveCodes, 0)
        XCTAssertTrue(initialSummary.accessibleFeatures.isEmpty)
        XCTAssertFalse(initialSummary.hasAnyAccess)
        XCTAssertFalse(initialSummary.hasUnlimitedAccess)
        
        try await storage.storeAccessCode(testAccessCode)
        
        let summary = storage.statusSummary
        XCTAssertEqual(summary.totalActiveCodes, 1)
        XCTAssertEqual(summary.accessibleFeatures.count, 2)
        XCTAssertTrue(summary.hasAnyAccess)
        XCTAssertFalse(summary.hasUnlimitedAccess)
        XCTAssertEqual(summary.statusDescription, "2 Premium Features")
    }
    
    func testStatusSummaryWithUnlimitedAccess() async throws {
        let unlimitedCode = AccessCode(
            code: "UN23456789AB",
            type: .unlimited,
            grantedFeatures: PremiumFeature.allCases
        )
        try await storage.storeAccessCode(unlimitedCode)
        
        let summary = storage.statusSummary
        XCTAssertTrue(summary.hasUnlimitedAccess)
        XCTAssertEqual(summary.statusDescription, "Full Premium Access")
    }
    
    func testStatusSummaryWithExpiringCodes() async throws {
        let expiringCode = AccessCode(
            code: "DM23456789EF",
            type: .demo,
            expiresAt: Date().addingTimeInterval(5 * 24 * 60 * 60) // 5 days
        )
        try await storage.storeAccessCode(expiringCode)
        
        let summary = storage.statusSummary
        XCTAssertEqual(summary.expiringCodesCount, 1)
    }
    
    // MARK: - Published Properties Tests
    
    func testPublishedProperties() async throws {
        XCTAssertFalse(storage.isLoading)
        XCTAssertEqual(storage.activeAccessCodes.count, 0)
        
        try await storage.storeAccessCode(testAccessCode)
        
        XCTAssertEqual(storage.activeAccessCodes.count, 1)
        XCTAssertFalse(storage.isLoading)
    }
}

// MARK: - AccessCodeStatusSummary Tests

class AccessCodeStatusSummaryTests: XCTestCase {
    
    func testStatusSummaryProperties() {
        let summary = AccessCodeStatusSummary(
            totalActiveCodes: 2,
            accessibleFeatures: [.unlimitedStoryGeneration, .advancedIllustrations],
            expiringCodesCount: 1,
            hasUnlimitedAccess: false
        )
        
        XCTAssertEqual(summary.totalActiveCodes, 2)
        XCTAssertEqual(summary.accessibleFeatures.count, 2)
        XCTAssertEqual(summary.expiringCodesCount, 1)
        XCTAssertFalse(summary.hasUnlimitedAccess)
        XCTAssertTrue(summary.hasAnyAccess)
        XCTAssertEqual(summary.statusDescription, "2 Premium Features")
    }
    
    func testStatusSummaryNoAccess() {
        let summary = AccessCodeStatusSummary(
            totalActiveCodes: 0,
            accessibleFeatures: [],
            expiringCodesCount: 0,
            hasUnlimitedAccess: false
        )
        
        XCTAssertFalse(summary.hasAnyAccess)
        XCTAssertEqual(summary.statusDescription, "No Premium Access")
    }
    
    func testStatusSummaryUnlimitedAccess() {
        let summary = AccessCodeStatusSummary(
            totalActiveCodes: 1,
            accessibleFeatures: PremiumFeature.allCases,
            expiringCodesCount: 0,
            hasUnlimitedAccess: true
        )
        
        XCTAssertTrue(summary.hasAnyAccess)
        XCTAssertTrue(summary.hasUnlimitedAccess)
        XCTAssertEqual(summary.statusDescription, "Full Premium Access")
    }
    
    func testStatusSummarySingleFeature() {
        let summary = AccessCodeStatusSummary(
            totalActiveCodes: 1,
            accessibleFeatures: [.unlimitedStoryGeneration],
            expiringCodesCount: 0,
            hasUnlimitedAccess: false
        )
        
        XCTAssertEqual(summary.statusDescription, "1 Premium Feature")
    }
}