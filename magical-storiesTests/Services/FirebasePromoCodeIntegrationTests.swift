import XCTest
import Foundation
@testable import magical_stories

/// Tests for Firebase promo code integration
/// These tests verify the Firebase implementation works with our abstraction layer
final class FirebasePromoCodeIntegrationTests: XCTestCase {
    
    var firebaseService: FirebasePromoCodeService!
    var firebaseRepository: FirebasePromoCodeRepository!
    var mockSession: MockURLSession!
    
    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        firebaseService = FirebasePromoCodeService(
            projectId: "test-project",
            apiKey: "test-api-key",
            session: mockSession
        )
        firebaseRepository = FirebasePromoCodeRepository(
            projectId: "test-project",
            apiKey: "test-api-key",
            session: mockSession
        )
    }
    
    override func tearDown() {
        firebaseService = nil
        firebaseRepository = nil
        mockSession = nil
        super.tearDown()
    }
    
    // MARK: - Firebase Service Tests
    
    func testFirebaseServiceValidation() async throws {
        // Mock successful Firebase response
        let mockFirebaseDoc = """
        {
            "name": "projects/test-project/databases/(default)/documents/promoCodes/TESTCODE123",
            "fields": {
                "code": {"stringValue": "TESTCODE123"},
                "type": {"stringValue": "demo"},
                "isActive": {"booleanValue": true},
                "usageCount": {"integerValue": "0"},
                "grantedFeatures": {
                    "arrayValue": {
                        "values": [
                            {"stringValue": "unlimitedStoryGeneration"}
                        ]
                    }
                }
            },
            "createTime": "2025-06-08T12:00:00Z",
            "updateTime": "2025-06-08T12:00:00Z"
        }
        """
        
        mockSession.mockData = mockFirebaseDoc.data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        let result = try await firebaseService.validateCodeAsync("TESTCODE123")
        
        XCTAssertEqual(result.accessCode.code, "TESTCODE123")
        XCTAssertEqual(result.accessCode.type, .demo)
        XCTAssertEqual(result.backendProvider, .firebase)
        XCTAssertFalse(result.isOfflineValidation)
        XCTAssertNotNil(result.serverMetadata)
        XCTAssertEqual(result.serverMetadata?["validation_server"] as? String, "firebase-firestore")
    }
    
    func testFirebaseServiceCodeNotFound() async {
        // Mock 404 response from Firebase
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )
        
        do {
            _ = try await firebaseService.validateCodeAsync("NONEXISTENT")
            XCTFail("Should have thrown codeNotFound error")
        } catch AccessCodeValidationError.codeNotFound {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testFirebaseServiceUsageTracking() async throws {
        // Mock successful Firebase response
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        let metadata = UsageMetadata(
            userId: "user123",
            deviceId: "device456",
            appVersion: "1.0.0",
            platform: "iOS"
        )
        
        try await firebaseService.trackUsageAsync("TESTCODE123", metadata)
        
        // Verify request was made
        XCTAssertNotNil(mockSession.lastRequest)
        XCTAssertEqual(mockSession.lastRequest?.httpMethod, "POST")
    }
    
    func testFirebaseServiceAnalytics() async throws {
        // Mock Firebase analytics response
        let mockAnalyticsResponse = """
        {
            "documents": [
                {
                    "name": "projects/test-project/databases/(default)/documents/promoCodeAnalytics/doc1",
                    "fields": {
                        "codeId": {"stringValue": "TESTCODE123"},
                        "userId": {"stringValue": "user1"},
                        "platform": {"stringValue": "iOS"},
                        "appVersion": {"stringValue": "1.0.0"},
                        "timestamp": {"timestampValue": "2025-06-08T12:00:00Z"}
                    },
                    "createTime": "2025-06-08T12:00:00Z",
                    "updateTime": "2025-06-08T12:00:00Z"
                }
            ]
        }
        """
        
        mockSession.mockData = mockAnalyticsResponse.data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        let filters = AnalyticsFilters(codeType: .demo)
        let analytics = try await firebaseService.getAnalyticsAsync(filters)
        
        XCTAssertEqual(analytics.totalCodes, 1)
        XCTAssertEqual(analytics.usedCodes, 1)
        XCTAssertEqual(analytics.activeUsers, 1)
    }
    
    func testFirebaseServiceAvailability() async {
        // Mock successful health check
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://firebase.googleapis.com/")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        let isAvailable = await firebaseService.isBackendAvailable()
        XCTAssertTrue(isAvailable)
        
        // Mock failed health check
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://firebase.googleapis.com/")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )
        
        let isUnavailable = await firebaseService.isBackendAvailable()
        XCTAssertFalse(isUnavailable)
    }
    
    // MARK: - Firebase Repository Tests
    
    func testFirebaseRepositoryStore() async throws {
        // Mock successful Firebase storage response
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        let accessCode = AccessCode(
            code: "TESTCODE123",
            type: .demo,
            grantedFeatures: [.unlimitedStoryGeneration]
        )
        let storedCode = StoredAccessCode(accessCode: accessCode)
        
        try await firebaseRepository.storeCodeAsync(storedCode)
        
        // Verify request was made
        XCTAssertNotNil(mockSession.lastRequest)
        XCTAssertEqual(mockSession.lastRequest?.httpMethod, "PATCH")
    }
    
    func testFirebaseRepositoryFetch() async throws {
        // Mock successful Firebase fetch response
        let mockFirebaseDoc = """
        {
            "name": "projects/test-project/databases/(default)/documents/promoCodes/TESTCODE123",
            "fields": {
                "code": {"stringValue": "TESTCODE123"},
                "type": {"stringValue": "demo"},
                "isActive": {"booleanValue": true},
                "usageCount": {"integerValue": "0"},
                "activatedAt": {"timestampValue": "2025-06-08T12:00:00Z"},
                "grantedFeatures": {
                    "arrayValue": {
                        "values": [
                            {"stringValue": "unlimitedStoryGeneration"}
                        ]
                    }
                }
            },
            "createTime": "2025-06-08T12:00:00Z",
            "updateTime": "2025-06-08T12:00:00Z"
        }
        """
        
        mockSession.mockData = mockFirebaseDoc.data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        let storedCode = try await firebaseRepository.fetchCodeAsync("TESTCODE123")
        
        XCTAssertNotNil(storedCode)
        XCTAssertEqual(storedCode?.accessCode.code, "TESTCODE123")
        XCTAssertEqual(storedCode?.accessCode.type, .demo)
    }
    
    func testFirebaseRepositoryFetchNotFound() async throws {
        // Mock 404 response from Firebase
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )
        
        let storedCode = try await firebaseRepository.fetchCodeAsync("NONEXISTENT")
        XCTAssertNil(storedCode)
    }
    
    func testFirebaseRepositoryGetAllCodes() async throws {
        // Mock Firebase collection response
        let mockCollectionResponse = """
        {
            "documents": [
                {
                    "name": "projects/test-project/databases/(default)/documents/promoCodes/CODE1",
                    "fields": {
                        "code": {"stringValue": "CODE1"},
                        "type": {"stringValue": "demo"},
                        "isActive": {"booleanValue": true},
                        "usageCount": {"integerValue": "0"},
                        "activatedAt": {"timestampValue": "2025-06-08T12:00:00Z"},
                        "grantedFeatures": {"arrayValue": {"values": []}}
                    },
                    "createTime": "2025-06-08T12:00:00Z",
                    "updateTime": "2025-06-08T12:00:00Z"
                },
                {
                    "name": "projects/test-project/databases/(default)/documents/promoCodes/CODE2",
                    "fields": {
                        "code": {"stringValue": "CODE2"},
                        "type": {"stringValue": "reviewer"},
                        "isActive": {"booleanValue": true},
                        "usageCount": {"integerValue": "5"},
                        "activatedAt": {"timestampValue": "2025-06-08T12:00:00Z"},
                        "grantedFeatures": {"arrayValue": {"values": []}}
                    },
                    "createTime": "2025-06-08T12:00:00Z",
                    "updateTime": "2025-06-08T12:00:00Z"
                }
            ]
        }
        """
        
        mockSession.mockData = mockCollectionResponse.data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        let allCodes = try await firebaseRepository.getAllCodesAsync()
        
        XCTAssertEqual(allCodes.count, 2)
        XCTAssertEqual(allCodes[0].accessCode.code, "CODE1")
        XCTAssertEqual(allCodes[1].accessCode.code, "CODE2")
    }
    
    // MARK: - Integration Tests
    
    func testServiceFactoryFirebaseIntegration() {
        // Test that service factory creates Firebase services when enabled
        let factory = PromoCodeServiceFactory.shared
        let config = BackendConfiguration.shared
        
        // Set Firebase provider
        config.setProvider(.firebase)
        
        let service = factory.createBackendService()
        let repository = factory.createRepository()
        
        // With feature flag disabled, should still get offline services
        XCTAssertTrue(service is OfflinePromoCodeService)
        XCTAssertTrue(repository is OfflinePromoCodeRepository)
        
        // Note: When enableFirebaseIntegration is true, these would be Firebase services
    }
    
    func testBackendSwitchingWithNetworkFailure() async {
        // Test graceful fallback when Firebase is unavailable
        let config = BackendConfiguration.shared
        config.setProvider(.firebase)
        
        // Mock network failure
        mockSession.mockError = URLError(.networkConnectionLost)
        
        // Service should handle errors gracefully
        do {
            _ = try await firebaseService.validateCodeAsync("TEST")
            XCTFail("Should have thrown network error")
        } catch AccessCodeValidationError.networkError {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testFirebaseErrorHandling() async {
        // Test various Firebase error responses
        
        // 409 Conflict (duplicate)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 409,
            httpVersion: nil,
            headerFields: nil
        )
        
        let accessCode = AccessCode(code: "DUPLICATE", type: .demo)
        let storedCode = StoredAccessCode(accessCode: accessCode)
        
        do {
            try await firebaseRepository.storeCodeAsync(storedCode)
            XCTFail("Should have thrown duplicate error")
        } catch RepositoryError.duplicateCode(let code) {
            XCTAssertEqual(code, "DUPLICATE")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // 500 Server Error
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )
        
        do {
            try await firebaseRepository.storeCodeAsync(storedCode)
            XCTFail("Should have thrown storage unavailable error")
        } catch RepositoryError.storageUnavailable {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - Mock URL Session

class MockURLSession: URLSessionProtocol {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    var lastRequest: URLRequest?
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        
        if let error = mockError {
            throw error
        }
        
        let data = mockData ?? Data()
        let response = mockResponse ?? HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        return (data, response)
    }
    
    func data(from url: URL) async throws -> (Data, URLResponse) {
        let request = URLRequest(url: url)
        return try await data(for: request)
    }
}