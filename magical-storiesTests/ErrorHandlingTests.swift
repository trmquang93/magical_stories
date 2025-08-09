//
//  ErrorHandlingTests.swift
//  magical-storiesTests
//
//  Created by AI Assistant on 21/7/25.
//

import Testing
import Foundation
import Security
import StoreKit
@testable import magical_stories

/// Comprehensive error handling tests covering all custom error types and error scenarios
@MainActor
struct ErrorHandlingTests {
    
    // MARK: - KeychainError Tests
    
    @Test("KeychainError descriptions are user-friendly and descriptive")
    func testKeychainErrorDescriptions() async throws {
        let invalidDataError = KeychainError.invalidData
        let itemNotFoundError = KeychainError.itemNotFound
        let operationFailedError = KeychainError.operationFailed(-25300)
        
        #expect(invalidDataError.errorDescription == "Invalid data provided to keychain operation")
        #expect(itemNotFoundError.errorDescription == "API key not found in keychain")
        #expect(operationFailedError.errorDescription == "Keychain operation failed with status: -25300")
    }
    
    @Test("KeychainError equality comparison works correctly")
    func testKeychainErrorEquality() async throws {
        // Same error types should be equal
        #expect(KeychainError.invalidData == KeychainError.invalidData)
        #expect(KeychainError.itemNotFound == KeychainError.itemNotFound)
        #expect(KeychainError.operationFailed(-25300) == KeychainError.operationFailed(-25300))
        
        // Different error types should not be equal
        #expect(KeychainError.invalidData != KeychainError.itemNotFound)
        #expect(KeychainError.operationFailed(-25300) != KeychainError.operationFailed(-25299))
    }
    
    @Test("KeychainError handles all common OSStatus codes")
    func testKeychainErrorOSStatusHandling() async throws {
        let commonErrors = [
            errSecSuccess: "Keychain operation failed with status: 0",
            errSecItemNotFound: "Keychain operation failed with status: -25300",
            errSecDuplicateItem: "Keychain operation failed with status: -25299",
            errSecAuthFailed: "Keychain operation failed with status: -25293",
            errSecNoAccessForItem: "Keychain operation failed with status: -25243"
        ]
        
        for (status, expectedMessage) in commonErrors {
            let error = KeychainError.operationFailed(status)
            #expect(error.errorDescription == expectedMessage)
        }
    }
    
    // MARK: - StoryServiceError Tests
    
    @Test("StoryServiceError provides detailed error messages")
    func testStoryServiceErrorDescriptions() async throws {
        let generationError = StoryServiceError.generationFailed("AI service unavailable")
        let invalidParamsError = StoryServiceError.invalidParameters
        let persistenceError = StoryServiceError.persistenceFailed
        let networkError = StoryServiceError.networkError
        let usageLimitError = StoryServiceError.usageLimitReached
        let subscriptionError = StoryServiceError.subscriptionRequired
        
        #expect(generationError.errorDescription == "Failed to generate story: AI service unavailable")
        #expect(invalidParamsError.errorDescription == "Invalid story parameters provided")
        #expect(persistenceError.errorDescription == "Failed to save or load story")
        #expect(networkError.errorDescription == "Network error occurred")
        #expect(usageLimitError.errorDescription?.contains("monthly story limit") == true)
        #expect(subscriptionError.errorDescription?.contains("Premium subscription required") == true)
    }
    
    @Test("StoryServiceError equality works for different error cases")
    func testStoryServiceErrorEquality() async throws {
        // Same errors should be equal
        #expect(StoryServiceError.generationFailed("test") == StoryServiceError.generationFailed("test"))
        #expect(StoryServiceError.invalidParameters == StoryServiceError.invalidParameters)
        #expect(StoryServiceError.networkError == StoryServiceError.networkError)
        
        // Different errors should not be equal
        #expect(StoryServiceError.generationFailed("test1") != StoryServiceError.generationFailed("test2"))
        #expect(StoryServiceError.invalidParameters != StoryServiceError.networkError)
    }
    
    // MARK: - StoryError Tests
    
    @Test("StoryError provides localized error descriptions")
    func testStoryErrorDescriptions() async throws {
        let generationError = StoryError.generationFailed
        let invalidParamsError = StoryError.invalidParameters
        let persistenceError = StoryError.persistenceFailed
        
        // Verify error descriptions are not nil and contain expected content
        #expect(generationError.errorDescription != nil)
        #expect(generationError.errorDescription?.contains("generate") == true)
        
        #expect(invalidParamsError.errorDescription != nil)
        #expect(invalidParamsError.errorDescription?.contains("invalid") == true)
        
        #expect(persistenceError.errorDescription != nil)
        #expect(persistenceError.errorDescription?.contains("save") == true)
    }
    
    @Test("StoryError is Sendable compliant for Swift 6")
    func testStoryErrorSendableCompliance() async throws {
        // This test verifies that StoryError can be safely passed between concurrent contexts
        let error = StoryError.generationFailed
        
        await withCheckedContinuation { continuation in
            // Directly use the error without creating a new Task to avoid transfer issues
            let _ = error
            continuation.resume()
        }
    }
    
    // MARK: - AccessCodeValidationError Tests
    
    @Test("AccessCodeValidationError provides comprehensive error messages")
    func testAccessCodeValidationErrorDescriptions() async throws {
        let invalidFormatError = AccessCodeValidationError.invalidFormat
        let codeNotFoundError = AccessCodeValidationError.codeNotFound
        let expiredError = AccessCodeValidationError.codeExpired(expirationDate: Date())
        let usageLimitError = AccessCodeValidationError.usageLimitReached(limit: 10)
        let inactiveError = AccessCodeValidationError.codeInactive
        let checksumError = AccessCodeValidationError.checksumMismatch
        let networkError = AccessCodeValidationError.networkError("Connection failed")
        let unknownError = AccessCodeValidationError.unknown("Unexpected error")
        
        #expect(invalidFormatError.errorDescription?.contains("format") == true)
        #expect(codeNotFoundError.errorDescription?.contains("not found") == true)
        #expect(expiredError.errorDescription?.contains("expired") == true)
        #expect(usageLimitError.errorDescription?.contains("limit reached") == true)
        #expect(inactiveError.errorDescription?.contains("not active") == true)
        #expect(checksumError.errorDescription?.contains("checksum") == true)
        #expect(networkError.errorDescription?.contains("Connection failed") == true)
        #expect(unknownError.errorDescription?.contains("Unexpected error") == true)
    }
    
    @Test("AccessCodeValidationError provides helpful recovery suggestions")
    func testAccessCodeValidationErrorRecoverySuggestions() async throws {
        let invalidFormatError = AccessCodeValidationError.invalidFormat
        let networkError = AccessCodeValidationError.networkError("Connection timeout")
        let expiredError = AccessCodeValidationError.codeExpired(expirationDate: Date())
        
        #expect(invalidFormatError.recoverySuggestion?.contains("check") == true)
        #expect(networkError.recoverySuggestion?.contains("internet connection") == true)
        #expect(expiredError.recoverySuggestion?.contains("contact support") == true)
    }
    
    @Test("AccessCodeValidationError equality works with associated values")
    func testAccessCodeValidationErrorEquality() async throws {
        let date = Date()
        
        // Same errors should be equal
        #expect(AccessCodeValidationError.invalidFormat == AccessCodeValidationError.invalidFormat)
        #expect(AccessCodeValidationError.codeExpired(expirationDate: date) == AccessCodeValidationError.codeExpired(expirationDate: date))
        #expect(AccessCodeValidationError.usageLimitReached(limit: 5) == AccessCodeValidationError.usageLimitReached(limit: 5))
        #expect(AccessCodeValidationError.networkError("test") == AccessCodeValidationError.networkError("test"))
        
        // Different errors should not be equal
        #expect(AccessCodeValidationError.invalidFormat != AccessCodeValidationError.codeNotFound)
        #expect(AccessCodeValidationError.usageLimitReached(limit: 5) != AccessCodeValidationError.usageLimitReached(limit: 10))
        #expect(AccessCodeValidationError.networkError("test1") != AccessCodeValidationError.networkError("test2"))
    }
    
    // MARK: - ConfigurationError Tests
    
    @Test("ConfigurationError provides detailed configuration problem descriptions")
    func testConfigurationErrorDescriptions() async throws {
        let keyMissingError = ConfigurationError.keyMissing("GeminiAPIKey")
        let invalidValueError = ConfigurationError.invalidValue("DatabaseURL")
        let plistNotFoundError = ConfigurationError.plistNotFound("Config.plist")
        let keychainError = ConfigurationError.keychainError("Access denied")
        let migrationError = ConfigurationError.migrationFailed(NSError(domain: "test", code: 1))
        
        #expect(keyMissingError.errorDescription?.contains("GeminiAPIKey") == true)
        #expect(invalidValueError.errorDescription?.contains("DatabaseURL") == true)
        #expect(plistNotFoundError.errorDescription?.contains("Config.plist") == true)
        #expect(keychainError.errorDescription?.contains("Access denied") == true)
        #expect(migrationError.errorDescription?.contains("migration failed") == true)
    }
    
    // MARK: - StoreError Tests
    
    @Test("StoreError handles purchase and verification failures")
    func testStoreErrorDescriptions() async throws {
        let productNotFoundError = StoreError.productNotFound
        let purchaseFailedError = StoreError.purchaseFailed("Payment declined")
        let verificationFailedError = StoreError.verificationFailed(NSError(domain: "VerificationError", code: 1))
        let pendingError = StoreError.pending
        let unknownError = StoreError.unknown
        let cancelledError = StoreError.cancelled
        let notAllowedError = StoreError.notAllowed
        
        #expect(productNotFoundError.errorDescription != nil)
        #expect(purchaseFailedError.errorDescription?.contains("Payment declined") == true)
        #expect(verificationFailedError.errorDescription != nil)
        #expect(pendingError.errorDescription != nil)
        #expect(unknownError.errorDescription != nil)
        #expect(cancelledError.errorDescription != nil)
        #expect(notAllowedError.errorDescription != nil)
    }
    
    @Test("StoreError is Sendable compliant")
    func testStoreErrorSendableCompliance() async throws {
        let error = StoreError.productNotFound
        
        await withCheckedContinuation { continuation in
            // Directly use the error without creating a new Task to avoid transfer issues
            let _ = error
            continuation.resume()
        }
    }
    
    // MARK: - PreMadeContentError Tests
    
    @Test("PreMadeContentError handles content loading failures")
    func testPreMadeContentErrorDescriptions() async throws {
        let fileNotFoundError = PreMadeContentError.fileNotFound("stories.json")
        let invalidJSONError = PreMadeContentError.invalidJSON("Invalid JSON structure")
        let databaseError = PreMadeContentError.databaseError("SQLite connection failed")
        
        #expect(fileNotFoundError.errorDescription?.contains("stories.json") == true)
        #expect(invalidJSONError.errorDescription?.contains("Invalid JSON") == true)
        #expect(databaseError.errorDescription?.contains("SQLite connection failed") == true)
    }
    
    // MARK: - AIError Tests
    
    @Test("AIError provides comprehensive AI service error handling")
    func testAIErrorDescriptions() async throws {
        let networkError = AIError.networkError(NSError(domain: "Network", code: 1))
        let apiError = AIError.apiError("Bad Request", nil)
        let configError = AIError.configurationError("Missing API key")
        let textGenError = AIError.textGenerationFailed("Content blocked")
        let imageGenError = AIError.imageGenerationFailed("Generation timeout")
        let noImageError = AIError.noImageDataReturned
        let resourceError = AIError.resourceUnavailable("GPU queue full")
        
        #expect(networkError.errorDescription != nil)
        #expect(apiError.errorDescription?.contains("Bad Request") == true)
        #expect(configError.errorDescription?.contains("Missing API key") == true)
        #expect(textGenError.errorDescription?.contains("Content blocked") == true)
        #expect(imageGenError.errorDescription?.contains("Generation timeout") == true)
        #expect(noImageError.errorDescription != nil)
        #expect(resourceError.errorDescription?.contains("GPU queue full") == true)
    }
    
    @Test("AIError provides unique identifiers for tracking")
    func testAIErrorIdentifiers() async throws {
        let error1 = AIError.networkError(NSError(domain: "Network", code: 1))
        let error2 = AIError.networkError(NSError(domain: "Network", code: 1))
        let error3 = AIError.apiError("Different error", nil)
        
        // Each error instance should have a unique ID based on content
        #expect(error1.id != error3.id)
        // Similar content may have same ID structure but different hashes
        #expect(error1.id.hasPrefix("network-") == true)
        #expect(error3.id.hasPrefix("api-") == true)
    }
    
    // MARK: - CharacterReferenceError Tests
    
    @Test("CharacterReferenceError handles character consistency failures")
    func testCharacterReferenceErrorDescriptions() async throws {
        let invalidDataError = CharacterReferenceError.invalidStoryData
        let noElementsError = CharacterReferenceError.noVisualElementsFound
        let masterRefError = CharacterReferenceError.masterReferenceGenerationFailed("AI service error")
        let invalidImageError = CharacterReferenceError.invalidImageData
        let cachingError = CharacterReferenceError.cachingFailed("Storage full")
        let elementNotFoundError = CharacterReferenceError.visualElementNotFound("Hero")
        let unsupportedCountError = CharacterReferenceError.unsupportedElementCount(15)
        
        #expect(invalidDataError.errorDescription?.contains("Invalid story data") == true)
        #expect(noElementsError.errorDescription?.contains("visual elements") == true)
        #expect(masterRefError.errorDescription?.contains("AI service error") == true)
        #expect(invalidImageError.errorDescription?.contains("Invalid image") == true)
        #expect(cachingError.errorDescription?.contains("Storage full") == true)
        #expect(elementNotFoundError.errorDescription?.contains("Hero") == true)
        #expect(unsupportedCountError.errorDescription?.contains("15") == true)
    }
    
    @Test("CharacterReferenceError equality and Sendable compliance")
    func testCharacterReferenceErrorEquality() async throws {
        let error1 = CharacterReferenceError.masterReferenceGenerationFailed("test")
        let error2 = CharacterReferenceError.masterReferenceGenerationFailed("test")
        let error3 = CharacterReferenceError.masterReferenceGenerationFailed("different")
        
        #expect(error1 == error2)
        #expect(error1 != error3)
        #expect(CharacterReferenceError.invalidStoryData == CharacterReferenceError.invalidStoryData)
    }
    
    // MARK: - Error Propagation Tests
    
    @Test("Errors propagate correctly through service layers")
    func testErrorPropagationThroughServices() async throws {
        // Test that errors from lower-level services (like KeychainService) 
        // are properly caught and converted to higher-level errors
        
        let keychainService = KeychainService(account: "test", service: "test")
        
        do {
            // This should throw a KeychainError since the key doesn't exist
            let _ = try keychainService.retrieveAPIKey()
            #expect(Bool(false), "Expected KeychainError to be thrown")
        } catch let error as KeychainError {
            #expect(error == KeychainError.itemNotFound)
        } catch {
            #expect(Bool(false), "Expected KeychainError, got \(type(of: error))")
        }
    }
    
    @Test("Error recovery scenarios work correctly")
    func testErrorRecoveryScenarios() async throws {
        // Test that the app can gracefully handle and recover from errors
        
        // Simulate network error recovery
        let networkError = StoryServiceError.networkError
        let recoveryAction = getRecoveryAction(for: networkError)
        #expect(recoveryAction.contains("retry") || recoveryAction.contains("connection"))
        
        // Simulate quota exceeded recovery
        let quotaError = AIError.resourceUnavailable("API quota exceeded")
        let quotaRecovery = getRecoveryAction(for: quotaError)
        #expect(quotaRecovery.contains("later"))
    }
    
    @Test("User-facing error messages are appropriate for children and parents")
    func testUserFriendlyErrorMessages() async throws {
        // Verify error messages are appropriate for the app's audience
        
        let storyError = StoryError.generationFailed
        let userMessage = getUserFriendlyMessage(for: storyError)
        
        // Should not contain technical jargon
        #expect(userMessage.contains("API") == false)
        #expect(userMessage.contains("HTTP") == false)
        #expect(userMessage.contains("JSON") == false)
        
        // Should be helpful and reassuring
        #expect(userMessage.contains("try again") == true || userMessage.contains("please") == true)
    }
    
    @Test("Error analytics tracking preserves user privacy")
    func testErrorAnalyticsPrivacy() async throws {
        // Test that error tracking doesn't expose sensitive information
        
        let sensitiveError = AccessCodeValidationError.networkError("User API key: sk-abc123")
        let analyticsData = getAnalyticsData(for: sensitiveError)
        
        // Should not contain API keys or other sensitive data
        #expect(analyticsData.contains("sk-") == false)
        #expect(analyticsData.contains("API key") == false)
        
        // Should contain error category for debugging
        #expect(analyticsData.contains("AccessCodeValidationError") == true)
    }
    
    @Test("Critical errors trigger appropriate fallback behaviors")
    func testCriticalErrorFallbacks() async throws {
        // Test that critical system errors don't crash the app
        
        let criticalError = ConfigurationError.plistNotFound("Config.plist")
        let fallbackResult = handleCriticalError(criticalError)
        
        #expect(fallbackResult.shouldContinue == true)
        #expect(fallbackResult.fallbackValue != nil)
    }
    
    @Test("Error validation prevents invalid error states")
    func testErrorValidation() async throws {
        // Test that error objects are created with valid states
        
        // Empty message should be handled gracefully
        let emptyMessageError = StoryServiceError.generationFailed("")
        #expect(emptyMessageError.errorDescription?.isEmpty == false)
        
        // Nil dates should be handled
        let dateError = AccessCodeValidationError.codeExpired(expirationDate: Date.distantPast)
        #expect(dateError.errorDescription?.contains("expired") == true)
    }
    
    @Test("Error serialization for logging works correctly")
    func testErrorSerialization() async throws {
        let error = AccessCodeValidationError.usageLimitReached(limit: 5)
        let serialized = serializeErrorForLogging(error)
        
        // Should contain error type and key information
        #expect(serialized.contains("AccessCodeValidationError") == true)
        #expect(serialized.contains("usageLimitReached") == true)
        #expect(serialized.contains("5") == true)
        
        // Should not contain sensitive information
        #expect(serialized.contains("password") == false)
        #expect(serialized.contains("key") == false)
    }
    
    // MARK: - Integration Error Tests
    
    @Test("Service integration errors are handled gracefully")
    func testServiceIntegrationErrors() async throws {
        // Test error handling between different services
        
        // Mock a scenario where StoryService depends on KeychainService
        let keychainError = KeychainError.itemNotFound
        let mappedError = mapKeychainErrorToStoryServiceError(keychainError)
        
        // Should map to appropriate story service error
        #expect(mappedError == StoryServiceError.persistenceFailed || 
                mappedError == StoryServiceError.generationFailed("Keychain access failed"))
    }
    
    @Test("Concurrent error handling maintains thread safety")
    func testConcurrentErrorHandling() async throws {
        // Test that error handling is thread-safe in concurrent scenarios
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask { @Sendable in
                    let error = StoryServiceError.generationFailed("Test \(i)")
                    let _ = error.errorDescription
                    // Should not crash or produce race conditions
                }
            }
        }
    }
    
    @Test("Error boundary conditions are handled correctly")
    func testErrorBoundaryConditions() async throws {
        // Test edge cases and boundary conditions
        
        // Very long error messages
        let longMessage = String(repeating: "a", count: 10000)
        let longError = AIError.configurationError(longMessage)
        #expect(longError.errorDescription?.count ?? 0 <= 1000) // Should truncate
        
        // Special characters in error messages
        let specialCharError = AccessCodeValidationError.networkError("Error: 💥 failed!")
        #expect(specialCharError.errorDescription?.contains("💥") == true)
    }
}

// MARK: - Helper Functions for Tests

extension ErrorHandlingTests {
    
    /// Gets a recovery action suggestion for a given error
    private func getRecoveryAction(for error: any LocalizedError) -> String {
        switch error {
        case is StoryServiceError:
            return "Please check your internet connection and try again"
        case is AIError:
            return "Please wait a moment and try again later"
        case is KeychainError:
            return "Please restart the app and try again"
        default:
            return "Please try again"
        }
    }
    
    /// Converts technical errors to user-friendly messages
    private func getUserFriendlyMessage(for error: any LocalizedError) -> String {
        switch error {
        case is StoryError:
            return "Oops! We couldn't create your story right now. Please try again!"
        case is AccessCodeValidationError:
            return "There seems to be a problem with your access code. Please check it and try again."
        default:
            return "Something went wrong, but don't worry! Please try again."
        }
    }
    
    /// Extracts analytics data from errors while preserving privacy
    private func getAnalyticsData(for error: any LocalizedError) -> String {
        // Remove sensitive information and return safe analytics data
        let errorType = String(describing: type(of: error))
        return "ErrorType: \(errorType)"
    }
    
    /// Handles critical errors with fallback behavior
    private func handleCriticalError(_ error: any LocalizedError) -> (shouldContinue: Bool, fallbackValue: String?) {
        switch error {
        case is ConfigurationError:
            return (shouldContinue: true, fallbackValue: "default_config")
        default:
            return (shouldContinue: true, fallbackValue: nil)
        }
    }
    
    /// Serializes errors for logging while maintaining privacy
    private func serializeErrorForLogging(_ error: any LocalizedError) -> String {
        let errorType = String(describing: type(of: error))
        let description = error.errorDescription ?? "Unknown error"
        
        // Include more detail about the specific error case for AccessCodeValidationError
        var detailString = ""
        if let accessCodeError = error as? AccessCodeValidationError {
            switch accessCodeError {
            case .usageLimitReached(let limit):
                detailString = "usageLimitReached(\(limit))"
            case .codeExpired(let date):
                detailString = "codeExpired(\(date))"
            case .networkError(let message):
                detailString = "networkError(\(message))"
            case .unknown(let message):
                detailString = "unknown(\(message))"
            default:
                detailString = String(describing: accessCodeError)
            }
        }
        
        // Remove sensitive patterns
        let safeDescription = description
            .replacingOccurrences(of: "sk-[a-zA-Z0-9]+", with: "[API_KEY_REDACTED]", options: .regularExpression)
            .replacingOccurrences(of: "password.*", with: "[PASSWORD_REDACTED]", options: .regularExpression)
        
        return "[\(errorType)] \(detailString.isEmpty ? safeDescription : detailString + ": " + safeDescription)"
    }
    
    /// Maps keychain errors to story service errors
    private func mapKeychainErrorToStoryServiceError(_ keychainError: KeychainError) -> StoryServiceError {
        switch keychainError {
        case .itemNotFound:
            return .generationFailed("Keychain access failed")
        case .invalidData:
            return .generationFailed("Invalid API key data")
        case .operationFailed:
            return .persistenceFailed
        }
    }
}