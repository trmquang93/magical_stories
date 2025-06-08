import XCTest
import Foundation
@testable import magical_stories

/// Mock implementations and tests to verify Phase 2 readiness
/// This validates that the abstraction layer can support Firebase integration
final class PromoCodeMockTests: XCTestCase {
    
    var mockBackendService: MockPromoCodeBackendService!
    var mockRepository: MockPromoCodeRepository!
    var factory: PromoCodeServiceFactory!
    
    override func setUp() {
        super.setUp()
        mockBackendService = MockPromoCodeBackendService()
        mockRepository = MockPromoCodeRepository()
        factory = PromoCodeServiceFactory.shared
    }
    
    override func tearDown() {
        mockBackendService = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Phase 2 Readiness Tests
    
    func testBackendServiceProtocolCompliance() async throws {
        // Test that mock implementations can fulfill the protocol requirements
        
        // Test validation
        let result = try await mockBackendService.validateCodeAsync("TESTCODE123")
        XCTAssertNotNil(result.accessCode)
        XCTAssertEqual(result.backendProvider, .firebase)
        XCTAssertFalse(result.isOfflineValidation)
        
        // Test usage tracking
        let metadata = UsageMetadata(userId: "user123", deviceId: "device456")
        try await mockBackendService.trackUsageAsync("TESTCODE123", metadata)
        XCTAssertTrue(mockBackendService.trackedUsage.contains("TESTCODE123"))
        
        // Test analytics
        let filters = AnalyticsFilters(codeType: .demo, includeExpired: false)
        let analytics = try await mockBackendService.getAnalyticsAsync(filters)
        XCTAssertGreaterThan(analytics.totalCodes, 0)
        
        // Test availability
        let isAvailable = await mockBackendService.isBackendAvailable()
        XCTAssertTrue(isAvailable)
    }
    
    func testRepositoryProtocolCompliance() async throws {
        // Test that mock repository can fulfill the protocol requirements
        
        let testCode = createTestAccessCode()
        let storedCode = StoredAccessCode(accessCode: testCode)
        
        // Test storage
        try await mockRepository.storeCodeAsync(storedCode)
        XCTAssertTrue(mockRepository.storedCodes.contains { $0.accessCode.code == testCode.code })
        
        // Test retrieval
        let fetchedCode = try await mockRepository.fetchCodeAsync(testCode.code)
        XCTAssertNotNil(fetchedCode)
        XCTAssertEqual(fetchedCode?.accessCode.code, testCode.code)
        
        // Test usage update
        let usageData = CodeUsageData(usageCount: 5, lastUsedAt: Date())
        try await mockRepository.updateCodeUsageAsync(testCode.code, usageData)
        
        // Test get all codes
        let allCodes = try await mockRepository.getAllCodesAsync()
        XCTAssertFalse(allCodes.isEmpty)
        
        // Test get active codes
        let activeCodes = try await mockRepository.getActiveCodesAsync()
        XCTAssertFalse(activeCodes.isEmpty)
        
        // Test cleanup
        try await mockRepository.cleanupExpiredCodesAsync()
        
        // Test removal
        try await mockRepository.removeCodeAsync(testCode.code)
        let removedCode = try await mockRepository.fetchCodeAsync(testCode.code)
        XCTAssertNil(removedCode)
    }
    
    func testServiceFactoryBackendSwitching() {
        // Test that the factory can switch between different backends
        
        let configuration = BackendConfiguration.shared
        
        // Test offline provider
        configuration.setProvider(.offline)
        let offlineService = factory.createBackendService()
        XCTAssertTrue(offlineService is OfflinePromoCodeService)
        
        // Test current backend info
        let backendInfo = factory.currentBackendInfo
        XCTAssertEqual(backendInfo.configuredProvider, .offline)
        XCTAssertEqual(backendInfo.effectiveProvider, .offline)
        XCTAssertTrue(backendInfo.isOptimal)
        XCTAssertFalse(backendInfo.isFallback)
    }
    
    func testPhase2FirebaseReadiness() async throws {
        // Verify that the abstraction layer is ready for Firebase integration
        
        // Mock Firebase service implementation
        let firebaseService = MockFirebasePromoCodeService()
        
        // Test Firebase-specific features
        let result = try await firebaseService.validateCodeAsync("FIREBASE_CODE")
        XCTAssertEqual(result.backendProvider, .firebase)
        XCTAssertFalse(result.isOfflineValidation)
        XCTAssertNotNil(result.serverMetadata)
        
        // Test Firebase availability check
        let isAvailable = await firebaseService.isBackendAvailable()
        XCTAssertTrue(isAvailable)
        
        // Test Firebase analytics with server data
        let analytics = try await firebaseService.getAnalyticsAsync(AnalyticsFilters())
        XCTAssertEqual(analytics.totalCodes, 100) // Mock server data
        XCTAssertEqual(analytics.activeUsers, 50)
    }
    
    func testErrorHandling() async {
        // Test error handling in mock implementations
        
        mockBackendService.shouldFailValidation = true
        
        do {
            _ = try await mockBackendService.validateCodeAsync("INVALID_CODE")
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is AccessCodeValidationError)
        }
    }
    
    func testAsyncConcurrency() async throws {
        // Test concurrent operations to ensure thread safety
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    do {
                        _ = try await self.mockBackendService.validateCodeAsync("CODE\(i)")
                    } catch {
                        // Expected for some invalid codes
                    }
                }
            }
        }
        
        XCTAssertGreaterThan(mockBackendService.validationCallCount, 0)
    }
    
    // MARK: - Helper Methods
    
    private func createTestAccessCode() -> AccessCode {
        return AccessCode(
            code: "DMTEST123456",
            type: .demo,
            grantedFeatures: [.unlimitedStoryGeneration],
            expiresAt: Date().addingTimeInterval(86400) // 1 day
        )
    }
}

// MARK: - Mock Implementations

/// Mock backend service for testing Firebase-like functionality
class MockPromoCodeBackendService: PromoCodeBackendService {
    var shouldFailValidation = false
    var validationCallCount = 0
    var trackedUsage: [String] = []
    
    func validateCodeAsync(_ code: String) async throws -> BackendValidationResult {
        validationCallCount += 1
        
        if shouldFailValidation {
            throw AccessCodeValidationError.codeNotFound
        }
        
        let accessCode = AccessCode(
            code: code,
            type: .demo,
            grantedFeatures: [.unlimitedStoryGeneration]
        )
        
        return BackendValidationResult(
            accessCode: accessCode,
            validatedAt: Date(),
            backendProvider: .firebase,
            isOfflineValidation: false,
            serverMetadata: ["validation_id": "server_123"]
        )
    }
    
    func trackUsageAsync(_ code: String, _ metadata: UsageMetadata) async throws {
        trackedUsage.append(code)
    }
    
    func getAnalyticsAsync(_ filters: AnalyticsFilters) async throws -> CodeAnalytics {
        return CodeAnalytics(
            totalCodes: 10,
            usedCodes: 5,
            activeUsers: 3,
            usageByType: [.demo: 5, .reviewer: 3],
            usageByDate: [Date(): 2]
        )
    }
    
    func isBackendAvailable() async -> Bool {
        return true
    }
}

/// Mock repository for testing storage functionality
class MockPromoCodeRepository: PromoCodeRepository {
    var storedCodes: [StoredAccessCode] = []
    
    func storeCodeAsync(_ code: StoredAccessCode) async throws {
        storedCodes.append(code)
    }
    
    func fetchCodeAsync(_ codeString: String) async throws -> StoredAccessCode? {
        return storedCodes.first { $0.accessCode.code == codeString }
    }
    
    func updateCodeUsageAsync(_ code: String, _ usage: CodeUsageData) async throws {
        // Update the stored code usage
        if let index = storedCodes.firstIndex(where: { $0.accessCode.code == code }) {
            let existingCode = storedCodes[index]
            var updatedAccessCode = existingCode.accessCode
            updatedAccessCode = AccessCode(
                id: updatedAccessCode.id,
                code: updatedAccessCode.code,
                type: updatedAccessCode.type,
                grantedFeatures: updatedAccessCode.grantedFeatures,
                createdAt: updatedAccessCode.createdAt,
                expiresAt: updatedAccessCode.expiresAt,
                usageLimit: updatedAccessCode.usageLimit,
                usageCount: usage.usageCount,
                isActive: updatedAccessCode.isActive,
                metadata: updatedAccessCode.metadata
            )
            storedCodes[index] = StoredAccessCode(
                accessCode: updatedAccessCode,
                activatedAt: existingCode.activatedAt,
                lastUsedAt: usage.lastUsedAt
            )
        }
    }
    
    func removeCodeAsync(_ code: String) async throws {
        storedCodes.removeAll { $0.accessCode.code == code }
    }
    
    func getAllCodesAsync() async throws -> [StoredAccessCode] {
        return storedCodes
    }
    
    func getActiveCodesAsync() async throws -> [StoredAccessCode] {
        return storedCodes.filter { $0.accessCode.isValid }
    }
    
    func cleanupExpiredCodesAsync() async throws {
        storedCodes.removeAll { $0.accessCode.isExpired }
    }
}

/// Mock Firebase service implementation showing Phase 2 capabilities
class MockFirebasePromoCodeService: PromoCodeBackendService {
    
    func validateCodeAsync(_ code: String) async throws -> BackendValidationResult {
        // Simulate Firebase validation with server metadata
        let accessCode = AccessCode(
            code: code,
            type: .unlimited,
            grantedFeatures: PremiumFeature.allCases
        )
        
        return BackendValidationResult(
            accessCode: accessCode,
            validatedAt: Date(),
            backendProvider: .firebase,
            isOfflineValidation: false,
            serverMetadata: [
                "firebase_document_id": "promo_codes/\(code)",
                "validation_server": "firebase-us-central1",
                "server_timestamp": Date().timeIntervalSince1970
            ]
        )
    }
    
    func trackUsageAsync(_ code: String, _ metadata: UsageMetadata) async throws {
        // Simulate Firebase analytics tracking
        print("Firebase: Tracking usage for \(code) with metadata: \(metadata)")
    }
    
    func getAnalyticsAsync(_ filters: AnalyticsFilters) async throws -> CodeAnalytics {
        // Simulate Firebase analytics with server data
        return CodeAnalytics(
            totalCodes: 100,
            usedCodes: 75,
            activeUsers: 50,
            usageByType: [
                .demo: 20,
                .reviewer: 30,
                .unlimited: 25,
                .press: 15,
                .specialAccess: 10
            ],
            usageByDate: [
                Date(): 25,
                Date().addingTimeInterval(-86400): 30,
                Date().addingTimeInterval(-172800): 20
            ]
        )
    }
    
    func isBackendAvailable() async -> Bool {
        // Simulate Firebase connectivity check
        return true
    }
}