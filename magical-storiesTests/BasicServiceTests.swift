//
//  BasicServiceTests.swift
//  magical-storiesTests
//
//  Created by AI Assistant on 19/7/25.
//

import Testing
import Foundation
import SwiftData
@testable import magical_stories

/// Simple tests for basic service initialization and functionality without complex mocking
@MainActor
struct BasicServiceTests {
    
    // MARK: - SecurityAnalytics Service Tests
    
    @Test("SecurityAnalytics can be initialized")
    func testSecurityAnalyticsInitialization() async throws {
        let analytics = SecurityAnalytics()
        #expect(analytics != nil)
    }
    
    // MARK: - KeychainService Tests
    
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
    
    // MARK: - Basic Service Protocol Tests
    
    @Test("StoryService can be initialized in test configuration")
    func testStoryServiceInitialization() async throws {
        // Create test configuration for ModelContext
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Story.self, Page.self, 
            configurations: config
        )
        let context = ModelContext(container)
        
        let storyService = try StoryService(
            apiKey: "test_api_key",
            context: context
        )
        
        #expect(storyService != nil)
        #expect(storyService.isGenerating == false)
    }
    
    @Test("PersistenceService can be initialized")
    func testPersistenceServiceInitialization() async throws {
        // Create test configuration for ModelContext
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Story.self, Page.self, 
            configurations: config
        )
        let context = ModelContext(container)
        
        let persistenceService = PersistenceService(context: context)
        #expect(persistenceService != nil)
    }
    
    // MARK: - Service Configuration Tests
    
    @Test("Services can handle error conditions gracefully")
    func testServiceErrorHandling() async throws {
        // Test that services don't crash with invalid inputs
        let keychainService = KeychainService()
        
        // This should throw an error, not crash
        do {
            try keychainService.storeAPIKey("")
            #expect(false, "Should have thrown an error for empty key")
        } catch {
            #expect(error is KeychainError)
        }
    }
    
    @Test("Service initialization validates required parameters")
    func testServiceParameterValidation() async throws {
        // Create test configuration for ModelContext
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Story.self, Page.self, 
            configurations: config
        )
        let context = ModelContext(container)
        
        // Test that StoryService validates API key
        do {
            let _ = try StoryService(
                apiKey: "", // Empty API key should cause error
                context: context
            )
            #expect(false, "Should have thrown an error for empty API key")
        } catch {
            #expect(true, "Correctly threw error for empty API key")
        }
    }
}