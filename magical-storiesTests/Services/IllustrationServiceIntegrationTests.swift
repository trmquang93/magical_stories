import Foundation  // Needed for ProcessInfo
// magical-storiesTests/Services/IllustrationServiceIntegrationTests.swift
import Testing

@testable import magical_stories

// Define a custom tag for integration tests
extension Tag {
    @Tag static var integration: Self
}

/// Integration tests for the IllustrationService, interacting with the actual Google AI API.
@Suite("IllustrationService Integration Tests")  // Reverted to simplest form due to persistent build errors
struct IllustrationServiceIntegrationTests {

    /// Tests the live API call to generate an illustration.
    /// This test requires a valid API key configured in AppConfig or via environment variables
    /// and network connectivity to the Google AI API endpoint.
    @Test func testGenerateIllustrationAPI() async throws {
        // Arrange: Instantiate the service using the default initializer,
        // which relies on AppConfig.geminiApiKey.
        // Ensure the API key is valid in the test environment.
        let service: IllustrationService
        do {
            // Check for the test-specific API key environment variable
            if let testApiKey = ProcessInfo.processInfo.environment["TEST_GEMINI_API_KEY"],
                !testApiKey.isEmpty
            {
                print(
                    "--- Integration Test: Found TEST_GEMINI_API_KEY environment variable. Initializing service with it. ---"
                )
                service = try IllustrationService(apiKey: testApiKey)
//                Issue.record("Using TEST_GEMINI_API_KEY for initialization.")
            } else {
                // Fallback to the default initializer (uses AppConfig.geminiApiKey)
                print(
                    "--- Integration Test: TEST_GEMINI_API_KEY not set or empty. Initializing service with default API key from AppConfig. ---"
                )
                service = try IllustrationService()
//                Issue.record("Using default AppConfig.geminiApiKey for initialization.")
            }
        } catch let error as ConfigurationError {
            // This catch block now handles errors from both initialization paths (test key or default key)
            let keySource =
                ProcessInfo.processInfo.environment["TEST_GEMINI_API_KEY"] != nil
                ? "TEST_GEMINI_API_KEY" : "AppConfig.geminiApiKey"
            print(
                "--- Integration Test: Configuration Error initializing IllustrationService using \(keySource) - \(error.localizedDescription). Ensure the relevant API key is valid and non-empty. ---"
            )
            Issue.record(
                "Configuration Error initializing IllustrationService using \(keySource): \(error.localizedDescription)"
            )
            throw error  // Re-throw configuration error to fail the test clearly
        } catch {
            let keySource =
                ProcessInfo.processInfo.environment["TEST_GEMINI_API_KEY"] != nil
                ? "TEST_GEMINI_API_KEY" : "AppConfig.geminiApiKey"
            print(
                "--- Integration Test: Unexpected error initializing IllustrationService using \(keySource) - \(error.localizedDescription) ---"
            )
            Issue.record(
                "Unexpected error initializing IllustrationService using \(keySource): \(error.localizedDescription)"
            )
            throw error  // Re-throw other initialization errors
        }

        let promptText = "A curious robot exploring a vibrant alien jungle"
        let storyTheme = "Science Fiction Adventure"

        // Act: Call the generateIllustration method
        print("--- Integration Test: Calling generateIllustration API... ---")
        let resultURL: URL?
        do {
            resultURL = try await service.generateIllustration(for: promptText, theme: storyTheme)
            print(
                "--- Integration Test: API call completed. Result URL: \(resultURL?.absoluteString ?? "nil") ---"
            )
        } catch {
            // --- Enhanced Error Logging ---
            print("--- Integration Test: ERROR CAUGHT in generateIllustration API call ---")
            print("--- Integration Test: Error Description: \(error.localizedDescription) ---")
            // Always log the specific type
            print("--- Integration Test: Error Type: \(type(of: error)) ---")

            // Provide more context if it's an IllustrationError
            if let illustrationError = error as? IllustrationError {
                // Print the specific IllustrationError case
                print("--- Integration Test: Caught IllustrationError Type: \(illustrationError) ---")
                // Print the detailed description from the error enum
                print(
                    "--- Integration Test: IllustrationError Detail: \(illustrationError.errorDescription ?? "No specific description provided") ---"
                )
            } else {
                // Log that the error is not the expected IllustrationError type (type logged above)
                print("--- Integration Test: Caught error is NOT an IllustrationError. ---")
            }
            // --- End Enhanced Error Logging ---

            // Explicitly fail the test AND stop execution by re-throwing
            throw error // Re-throw the error to ensure the test fails and execution stops here
        }

        // Assert: Check if a valid file URL was returned and the file exists
        let unwrappedURL = try #require(
            resultURL, "The generateIllustration method should return a non-nil URL on success.")
        // Add more detailed logging about the unwrapped URL before file checks
        print(
            "--- Integration Test: Successfully unwrapped result URL. Path: \(unwrappedURL.path), isFileURL: \(unwrappedURL.isFileURL), Absolute: \(unwrappedURL.absoluteString) ---"
        )

        #expect(
            unwrappedURL.isFileURL,
            "The returned URL should be a file URL pointing to the temporary image.")

        let fileManager = FileManager.default
        #expect(
            fileManager.fileExists(atPath: unwrappedURL.path),
            "The temporary image file should exist at the returned URL path.")
        print(
            "--- Integration Test: Verified temporary file exists at path: \(unwrappedURL.path) ---"
        )

        // Optional: Check if the file has content and clean up
        do {
            let fileData = try Data(contentsOf: unwrappedURL)
            #expect(!fileData.isEmpty, "The temporary image file should not be empty.")
            print(
                "--- Integration Test: Verified temporary file is not empty (\(fileData.count) bytes). ---"
            )
            // Clean up the temporary file after verification
            try? fileManager.removeItem(at: unwrappedURL)
            print("--- Integration Test: Cleaned up temporary file. ---")
        } catch {
            print(
                "--- Integration Test: Failed to read or delete temporary file - \(error.localizedDescription) ---"
            )
            // Don't necessarily fail the test for cleanup issues, but log it.
            Issue.record(
                "Failed to read or clean up temporary file: \(unwrappedURL.path). Error: \(error.localizedDescription)"
            )
        }
    }
}

// Note: Assumes ConfigurationError is accessible via @testable import.
// If not, define it locally within this file or ensure it's public in the main target.
