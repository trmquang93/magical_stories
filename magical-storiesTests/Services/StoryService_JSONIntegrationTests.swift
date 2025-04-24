import Foundation
import SwiftData
import Testing

@testable import magical_stories

@Suite("StoryService JSON Integration")
@MainActor
struct StoryService_JSONIntegrationTests {

    @Test("StoryService parses category from JSON response")
    func testParseCategoryFromJsonResponse() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Story.self, StoryCollection.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let mockModel = MockGenerativeModel()
        let mockPersistenceService = MockPersistenceService()

        // JSON response with both story and category fields
        let jsonResponse = """
            {
              "story": "Title: The Dragon's Quest\\n\\nOnce upon a time, Alex and Brave Bear embarked on an adventure.\\n---\\nThey met a friendly dragon who needed help finding a treasure.\\n---\\nTogether, they found the treasure and learned about teamwork.",
              "category": "Fantasy"
            }
            """

        mockModel.generatedText = jsonResponse

        // Create a services
        let mockIllustration = MockIllustrationService()
        let storyProcessor = StoryProcessor(illustrationService: mockIllustration)

        let storyService = try StoryService(
            context: context,
            persistenceService: mockPersistenceService,
            model: mockModel,
            storyProcessor: storyProcessor
        )

        let parameters = StoryParameters(
            childName: "Alex",
            childAge: 7,
            theme: "Adventure",
            favoriteCharacter: "Brave Bear"
        )

        // Act
        let story = try await storyService.generateStory(parameters: parameters)

        // Assert
        #expect(story.categoryName == "Fantasy")
        #expect(story.title == "The Dragon's Quest")
        #expect(story.pages.count == 3)

        // Verify prompt format
        #expect(mockModel.lastPrompt?.contains("Category Selection Instructions:") == true)
        #expect(
            mockModel.lastPrompt?.contains("Return your response as a JSON object with two fields:")
                == true)
    }

    @Test("StoryService handles malformed JSON")
    func testHandleMalformedJson() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Story.self, StoryCollection.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let mockModel = MockGenerativeModel()
        let mockPersistenceService = MockPersistenceService()

        // Malformed JSON and also missing Title prefix
        let jsonResponse = """
            {
              "story": "Broken JSON Story\\n\\nThis is a story with broken JSON format.\\n---\\nSecond page content.",
              "category": "Fantasy"
            }
            """

        mockModel.generatedText = jsonResponse

        // Create services
        let mockIllustration = MockIllustrationService()
        let storyProcessor = StoryProcessor(illustrationService: mockIllustration)

        let storyService = try StoryService(
            context: context,
            persistenceService: mockPersistenceService,
            model: mockModel,
            storyProcessor: storyProcessor
        )

        let parameters = StoryParameters(
            childName: "Alex",
            childAge: 7,
            theme: "Adventure",
            favoriteCharacter: "Brave Bear"
        )

        // Act - expect an error about missing "Title: " prefix
        do {
            _ = try await storyService.generateStory(parameters: parameters)
            #expect(false, "Expected an error but none was thrown")
        } catch let error as StoryServiceError {
            // Should throw a generation failed error due to missing Title: prefix
            if case .generationFailed(let message) = error {
                #expect(message.contains("Invalid story format") || message.contains("Title:"))
            } else {
                #expect(false, "Expected a generationFailed error but got \(error)")
            }
        }
    }

    @Test("StoryService handles JSON with missing category field")
    func testHandleJsonWithMissingCategory() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Story.self, StoryCollection.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let mockModel = MockGenerativeModel()
        let mockPersistenceService = MockPersistenceService()

        // Valid JSON but missing the category field
        let jsonResponse = """
            {
              "story": "Title: The Missing Category\\n\\nThis story has valid JSON but is missing the category field.\\n---\\nSecond page content."
            }
            """

        mockModel.generatedText = jsonResponse

        // Create services
        let mockIllustration = MockIllustrationService()
        let storyProcessor = StoryProcessor(illustrationService: mockIllustration)

        let storyService = try StoryService(
            context: context,
            persistenceService: mockPersistenceService,
            model: mockModel,
            storyProcessor: storyProcessor
        )

        let parameters = StoryParameters(
            childName: "Alex",
            childAge: 7,
            theme: "Adventure",
            favoriteCharacter: "Brave Bear"
        )

        // Act
        let story = try await storyService.generateStory(parameters: parameters)

        // Assert
        #expect(story.categoryName == nil)
        #expect(story.title == "The Missing Category")
        #expect(story.pages.count > 0)
    }

    @Test("StoryService includes developmental focus in prompt")
    func testIncludeDevelopmentalFocusInPrompt() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Story.self, StoryCollection.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let mockModel = MockGenerativeModel()
        let mockPersistenceService = MockPersistenceService()

        // Valid JSON response
        let jsonResponse = """
            {
              "story": "Title: Learning Adventure\\n\\nEmily and her dragon solved puzzles together.\\n---\\nThey helped others solve problems too.",
              "category": "Adventure"
            }
            """

        mockModel.generatedText = jsonResponse

        // Create a minimal mock StoryProcessor
        let mockIllustration = MockIllustrationService()
        let storyProcessor = StoryProcessor(illustrationService: mockIllustration)

        let storyService = try StoryService(
            context: context,
            persistenceService: mockPersistenceService,
            model: mockModel,
            storyProcessor: storyProcessor
        )

        // Parameters with developmental focus and emotional themes
        let parameters = StoryParameters(
            childName: "Emily",
            childAge: 6,
            theme: "Learning",
            favoriteCharacter: "Dragon",
            developmentalFocus: [.cognitiveDevelopment, .problemSolving],
            emotionalThemes: ["Joy", "Curiosity"]
        )

        // Act
        let story = try await storyService.generateStory(parameters: parameters)

        // Assert
        #expect(story.categoryName == "Adventure")

        // Verify developmental focus and emotional themes were included in prompt
        #expect(mockModel.lastPrompt?.contains("Developmental Focus:") == true)
        #expect(mockModel.lastPrompt?.contains("Cognitive Development") == true)
        #expect(mockModel.lastPrompt?.contains("Problem Solving") == true)
        #expect(mockModel.lastPrompt?.contains("Emotional Elements:") == true)
        #expect(mockModel.lastPrompt?.contains("Joy") == true)
        #expect(mockModel.lastPrompt?.contains("Curiosity") == true)
    }
}
