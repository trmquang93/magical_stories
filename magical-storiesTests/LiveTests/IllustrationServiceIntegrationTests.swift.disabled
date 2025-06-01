import Foundation  // Needed for ProcessInfo
// magical-storiesTests/Services/IllustrationServiceIntegrationTests.swift
import Testing

@testable import magical_stories


/// Integration tests for the IllustrationService, interacting with the actual
/// Google AI API.
@Suite(
    "IllustrationService Integration Tests",
    .disabled("These tests require a valid API key and network access.")
)  // Reverted to simplest form due to persistent build errors
struct IllustrationServiceIntegrationTests {
    /// Tests the live API call to generate an illustration.
    /// This test requires a valid API key configured in AppConfig or via
    /// environment variables
    /// and network connectivity to the Google AI API endpoint.
    @Test func testGenerateIllustrationAPI() async throws {
        // Arrange: Instantiate the service using the default initializer,
        // which relies on AppConfig.geminiApiKey.
        // Ensure the API key is valid in the test environment.
        let service: IllustrationService
        do {
            // Check for the test-specific API key environment variable
            if let testApiKey = ProcessInfo.processInfo
                .environment["TEST_GEMINI_API_KEY"],
                !testApiKey.isEmpty
            {
                print(
                    "--- Integration Test: Found TEST_GEMINI_API_KEY environment variable. Initializing service with it. ---"
                )
                service = try IllustrationService(apiKey: testApiKey)
                //                Issue.record("Using TEST_GEMINI_API_KEY for initialization.")
            } else {
                // Fallback to the default initializer (uses
                // AppConfig.geminiApiKey)
                print(
                    "--- Integration Test: TEST_GEMINI_API_KEY not set or empty. Initializing service with default API key from AppConfig. ---"
                )
                service = try IllustrationService()
                //                Issue.record("Using default AppConfig.geminiApiKey for
                //                initialization.")
            }
        } catch let error as ConfigurationError {
            // This catch block now handles errors from both initialization
            // paths (test key or default key)
            let keySource =
                ProcessInfo.processInfo
                    .environment["TEST_GEMINI_API_KEY"] != nil
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
                ProcessInfo.processInfo
                    .environment["TEST_GEMINI_API_KEY"] != nil
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
        let resultPath: String?
        do {
            resultPath = try await service.generateIllustration(
                for: promptText,
                theme: storyTheme
            )
            print(
                "--- Integration Test: API call completed. Result path: \(resultPath ?? "nil") ---"
            )
        } catch {
            print("--- Integration Test: ERROR CAUGHT in generateIllustration API call ---")
            print("--- Integration Test: Error Description: \(error.localizedDescription) ---")
            print("--- Integration Test: Error Type: \(type(of: error)) ---")
            if let illustrationError = error as? IllustrationError {
                print("--- Integration Test: Caught IllustrationError Type: \(illustrationError) ---")
                print("--- Integration Test: IllustrationError Detail: \(illustrationError.errorDescription ?? "No specific description provided") ---")
            } else {
                print("--- Integration Test: Caught error is NOT an IllustrationError. ---")
            }
            throw error
        }

        let unwrappedPath = try #require(
            resultPath,
            "The generateIllustration method should return a non-nil relative path on success."
        )
        let appSupportURL = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let fullURL = appSupportURL.appendingPathComponent(unwrappedPath)

        print("--- Integration Test: Full image URL: \(fullURL.path) ---")

        let fileManager = FileManager.default
        #expect(
            fileManager.fileExists(atPath: fullURL.path),
            "The saved image file should exist at the constructed path."
        )
        print("--- Integration Test: Verified saved file exists at path: \(fullURL.path) ---")

        do {
            let fileData = try Data(contentsOf: fullURL)
            #expect(
                !fileData.isEmpty,
                "The saved image file should not be empty."
            )
            print("--- Integration Test: Verified saved file is not empty (\(fileData.count) bytes). ---")
            try? fileManager.removeItem(at: fullURL)
            print("--- Integration Test: Cleaned up saved file. ---")
        } catch {
            print("--- Integration Test: Failed to read or delete saved file - \(error.localizedDescription) ---")
            Issue.record("Failed to read or clean up saved file: \(fullURL.path). Error: \(error.localizedDescription)")
        }
    }
}

// Note: Assumes ConfigurationError is accessible via @testable import.
// If not, define it locally within this file or ensure it's public in the main
// target.
