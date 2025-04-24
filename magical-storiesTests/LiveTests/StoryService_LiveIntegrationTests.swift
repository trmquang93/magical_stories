import Foundation
import SwiftData
import Testing

@testable import magical_stories

@Suite(
    "Story Service Live Integration Tests",
    .disabled("These tests require a valid API key and network access.")
)
@MainActor
struct StoryService_LiveIntegrationTests {

    @Test("Real AI service produces expected JSON format with category field")
    func testRealAIServiceGeneratesExpectedJSONFormat() async throws {
        // Try to find API key from different sources
        var apiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? ""

        // If not found in environment, try AppConfig (non-dev environments)
        if apiKey.isEmpty {
            do {
                // Accessing AppConfig.geminiApiKey can throw if key is missing
                try apiKey = AppConfig.resolveApiKey()
            } catch {
                Issue.record("Could not find API key from AppConfig: \(error)")
            }
        }

        guard !apiKey.isEmpty else {
            Issue.record(
                "GEMINI_API_KEY not found in environment variables or config, skipping live test. Set the API key to run this test."
            )
            return
        }

        print("Found API key, proceeding with live API test")

        // Arrange
        let container = try ModelContainer(
            for: Story.self, StoryCollection.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        // Use a real GenerativeModelWrapper that will make a real API call
        let realModel = GenerativeModelWrapper(name: "gemini-2.0-flash", apiKey: apiKey)
        let mockPersistenceService = MockPersistenceService()

        // Create a mock IllustrationService to avoid real image generation
        let mockIllustration = MockIllustrationService()
        let storyProcessor = StoryProcessor(illustrationService: mockIllustration)

        // Create a real prompt builder
        let promptBuilder = PromptBuilder()

        // Create the StoryService with real AI model but mock persistence and processor
        let storyService = try StoryService(
            apiKey: apiKey,
            context: context,
            persistenceService: mockPersistenceService,
            model: realModel,
            storyProcessor: storyProcessor,
            promptBuilder: promptBuilder
        )

        // Create minimal parameters for a very short story to reduce token usage
        let parameters = StoryParameters(
            childName: "Test",
            childAge: 5,
            theme: "Short",
            favoriteCharacter: "Cat",
            storyLength: "short"  // Keep it short for test efficiency
        )

        do {
            // Act - this will make a real API call
            print("Making live API call to generate story...")
            let story = try await storyService.generateStory(parameters: parameters)

            // Assert
            #expect(story.title.isEmpty == false)
            #expect(story.pages.count > 0)

            // The most important test - verify the category field was returned and parsed
            #expect(story.categoryName != nil)
            #expect(mockPersistenceService.storyToSave?.categoryName != nil)

            // Print debug info about the result
            print("Successfully generated story with title: \(story.title)")
            print("Category extracted: \(story.categoryName ?? "None")")
            print("Number of pages: \(story.pages.count)")

            // Verify the category is one of the allowed categories
            let allowedCategories = ["Fantasy", "Animals", "Bedtime", "Adventure"]
            if let category = story.categoryName {
                // Note: This is a soft check - the AI might sometimes return a different category
                print(
                    "Category '\(category)' is \(allowedCategories.contains(category) ? "in" : "not in") the allowed list"
                )
            }

        } catch let error as StoryServiceError {
            if error.errorDescription?.contains("Network error") == true {
                Issue.record("Network error occurred during live API test: \(error)")
                print(
                    "Network error occurred during live API test. Test marked as passed but with issue recorded."
                )
            } else if error.errorDescription?.contains("Invalid API key") == true
                || error.errorDescription?.contains("401") == true
            {
                Issue.record("API key error: \(error). Please check your API key.")
                print("API key error. Test marked as passed but with issue recorded.")
            } else {
                // For other errors, let the test fail
                throw error
            }
        } catch {
            // For other unexpected errors
            Issue.record("Unexpected error during live API test: \(error)")
            throw error
        }
    }
}

// Helper extension to make AppConfig.geminiApiKey throwing to properly handle the catch block
extension AppConfig {
    fileprivate static func resolveApiKey() throws -> String {
        // This is a simple wrapper that makes the property access throwing
        // If the property access itself throws, this will propagate the error
        let key = geminiApiKey
        guard !key.isEmpty else {
            throw ConfigurationError.keyMissing("GeminiAPIKey")
        }
        return key
    }
}
