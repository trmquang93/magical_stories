//
//  BasicSecurityTests.swift
//  magical-storiesTests
//
//  Created by AI Assistant on 19/7/25.
//

import Testing
import Foundation
import Security
@testable import magical_stories

/// Simple tests for basic security functionality without complex mocking
@MainActor
struct BasicSecurityTests {
    
    // MARK: - KeychainService Basic Tests
    
    @Test("KeychainService can be initialized with default parameters")
    func testKeychainServiceInitialization() async throws {
        let keychainService = KeychainService()
        
        #expect(keychainService.account == "GeminiAPIKey")
        #expect(keychainService.service == "com.magical-stories.api-keys")
    }
    
    @Test("KeychainService can be initialized with custom parameters")
    func testKeychainServiceCustomInitialization() async throws {
        let customAccount = "TestAccount"
        let customService = "com.test.service"
        
        let keychainService = KeychainService(account: customAccount, service: customService)
        
        #expect(keychainService.account == customAccount)
        #expect(keychainService.service == customService)
    }
    
    @Test("KeychainError provides correct error descriptions")
    func testKeychainErrorDescriptions() async throws {
        let invalidDataError = KeychainError.invalidData
        let itemNotFoundError = KeychainError.itemNotFound
        let operationFailedError = KeychainError.operationFailed(-25300)
        
        #expect(invalidDataError.errorDescription?.contains("Invalid data") == true)
        #expect(itemNotFoundError.errorDescription?.contains("not found") == true)
        #expect(operationFailedError.errorDescription?.contains("failed with status") == true)
    }
    
    @Test("KeychainError equality works correctly")
    func testKeychainErrorEquality() async throws {
        let error1 = KeychainError.invalidData
        let error2 = KeychainError.invalidData
        let error3 = KeychainError.itemNotFound
        let error4 = KeychainError.operationFailed(-25300)
        let error5 = KeychainError.operationFailed(-25300)
        let error6 = KeychainError.operationFailed(-25301)
        
        #expect(error1 == error2)
        #expect(error1 != error3)
        #expect(error4 == error5)
        #expect(error4 != error6)
    }
    
    // MARK: - SecurityAnalytics Basic Tests
    
    @Test("SecurityAnalytics can be initialized")
    func testSecurityAnalyticsInitialization() async throws {
        let analytics = SecurityAnalytics()
        #expect(analytics != nil)
    }
    
    @Test("SecurityAnalytics can record events without crashing")
    func testSecurityAnalyticsEventRecording() async throws {
        let analytics = SecurityAnalytics()
        
        // These should not crash
        analytics.logCertificateValidationSuccess(host: "example.com")
        analytics.logCertificateValidationFailure(host: "example.com", reason: "test failure")
        analytics.logSecurityEvent(event: "test_event", details: ["key": "value"])
    }
    
    @Test("SecurityEventType has correct values")
    func testSecurityEventTypes() async throws {
        let validationFailure = SecurityEventType.certificateValidationFailure
        let validationSuccess = SecurityEventType.certificateValidationSuccess
        let generic = SecurityEventType.generic
        
        #expect(validationFailure.rawValue == "certificate_validation_failure")
        #expect(validationSuccess.rawValue == "certificate_validation_success")
        #expect(generic.rawValue == "generic_security_event")
    }
    
    // MARK: - Basic Security Event Tests
    
    @Test("SecurityEvent can be created with required fields")
    func testSecurityEventCreation() async throws {
        let event = SecurityEvent(
            eventType: .generic,
            eventName: "test_event",
            host: "example.com",
            timestamp: Date(),
            details: ["key": "value"]
        )
        
        #expect(event.eventType == .generic)
        #expect(event.eventName == "test_event")
        #expect(event.host == "example.com")
        #expect(event.details["key"] == "value")
    }
    
    @Test("SecurityEvent can be created with minimal parameters")
    func testSecurityEventMinimalCreation() async throws {
        let event = SecurityEvent(eventType: .generic)
        
        #expect(event.eventType == .generic)
        #expect(event.eventName == nil)
        #expect(event.host == nil)
        #expect(event.details.isEmpty)
    }
}