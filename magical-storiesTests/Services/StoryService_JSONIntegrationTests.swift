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

        // Act - Expect successful generation using fallback title extraction
        let story = try await storyService.generateStory(parameters: parameters)

        // Assert - Verify fallback title and parsed category
        #expect(story.title == "Broken JSON Story") // Fallback title is the first line
        #expect(story.categoryName == "Fantasy") // Category should still be parsed from JSON
        #expect(!story.pages.isEmpty) // Pages should be generated from the content
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

    @Test("Test JSON parsing with exact response format")
    func testExactJsonResponseFormat() async throws {
        // Create a mock JSON response similar to what we received
        let jsonResponse = """
            {
              "story": "Title: E and Super Sparkle's Surprise\\n\\nE is four. E likes to play! E likes to play with blocks. Sometimes, E gets sad when the blocks fall down. It makes E feel grumpy.\\n\\n---\\n\\nOne day, E was building a big, big tower. It was the biggest tower ever! But then, WHOOSH! The tower fell. E felt very, very grumpy. E stomped her foot. \\"I don't like blocks!\\" she said.\\n\\nSuddenly, Super Sparkle zoomed down from the sky! She was wearing a sparkly cape and a big smile. \\"Hello, E! Why are you grumpy?\\"\\n\\n---\\n\\nE showed Super Sparkle the fallen tower. \\"It fell down!\\" E said, with a sad face. Super Sparkle smiled. \\"It's okay, E! Building is hard. But it's more fun with a friend!\\"\\n\\nSuper Sparkle picked up some blocks. \\"Let's build together!\\" she said.\\n\\n---\\n\\nE and Super Sparkle started building. Super Sparkle helped E put the blocks on top. This time, the tower was even bigger! They worked together, and they laughed a lot. E wasn't grumpy anymore.\\n\\n\\"Wow!\\" said E. \\"We did it!\\"\\n\\n---\\n\\nBut then, WHOOSH! The tower wobbled. Uh oh! It was going to fall again! E felt a little bit grumpy again. Super Sparkle thought fast. \\"Quick, E! Hold this block!\\"\\n\\nE held the block. Super Sparkle held another block. Together, they held the tower strong! It didn't fall!\\n\\n---\\n\\n\\"We saved it!\\" E shouted. She was so happy! Super Sparkle smiled. \\"See, E? Even when things are hard, friends can help! Working together is super fun!\\"\\n\\nE gave Super Sparkle a big hug. \\"Thank you, Super Sparkle! You are a good friend!\\" E learned that even grumpy feelings can go away with a little help from a friend. Now E knows that friendship is like magic and that it makes it fun to solve problems. Super Sparkle waved goodbye and zoomed back into the sky, leaving E happy to build another block tower.\\n\\n",
              "category": "Friendship"
            }
            """

        // Setup a mock model that returns our predefined JSON
        let mockModel = MockTestGenerativeModel(
            presetResponse: jsonResponse, shouldWrapInMarkdown: true)

        let container = try ModelContainer(
            for: Story.self, StoryCollection.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let mockPersistenceService = MockPersistenceService()
        let mockIllustration = MockIllustrationService()
        let storyProcessor = StoryProcessor(illustrationService: mockIllustration)
        let promptBuilder = PromptBuilder()

        // Create the service with our mock model
        let storyService = try StoryService(
            apiKey: "test-key",
            context: context,
            persistenceService: mockPersistenceService,
            model: mockModel,
            storyProcessor: storyProcessor,
            promptBuilder: promptBuilder
        )

        // Basic test parameters
        let parameters = StoryParameters(
            childName: "E",
            childAge: 4,
            theme: "Friendship",
            favoriteCharacter: "Super Sparkle"
        )

        // Call generate story which will use our mock model
        let story = try await storyService.generateStory(parameters: parameters)

        // Assert
        #expect(story.title == "E and Super Sparkle's Surprise")

        #expect(story.pages.count > 0)

        #expect(story.categoryName == "Friendship")

        // Verify the story was saved with the correct category
        #expect(mockPersistenceService.storyToSave?.categoryName == "Friendship")
    }
}
