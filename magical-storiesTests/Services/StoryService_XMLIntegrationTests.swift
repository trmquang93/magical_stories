import Foundation
import SwiftData
import Testing

@testable import magical_stories

@Suite("StoryService XML Integration")
@MainActor
struct StoryService_XMLIntegrationTests {

    @Test("StoryService parses category from XML response")
    func testParseCategoryFromXmlResponse() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Story.self, StoryCollection.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let mockModel = MockGenerativeModel()
        let mockPersistenceService = MockPersistenceService()

        // XML response with title, content, and category tags
        let xmlResponse = """
            <title>The Dragon's Quest</title>
            <content>Once upon a time, Alex and Brave Bear embarked on an adventure.
            ---
            They met a friendly dragon who needed help finding a treasure.
            ---
            Together, they found the treasure and learned about teamwork.</content>
            <category>Fantasy</category>
            """

        mockModel.generatedText = xmlResponse

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
            theme: "Adventure",
            childAge: 7,
            childName: "Alex",
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
        #expect(mockModel.lastPrompt?.contains("Return your response as XML with the following tags:") == true)
    }

    @Test("StoryService handles malformed XML")
    func testHandleMalformedXml() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Story.self, StoryCollection.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let mockModel = MockGenerativeModel()
        let mockPersistenceService = MockPersistenceService()

        // Malformed XML with unclosed tags
        let xmlResponse = """
            <title>Broken XML Story</title>
            <content>This is a story with broken XML format.
            ---
            Second page content.
            <category>Fantasy</category>
            """

        mockModel.generatedText = xmlResponse

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
            theme: "Adventure",
            childAge: 7,
            childName: "Alex",
            favoriteCharacter: "Brave Bear"
        )

        // Act & Assert - Expect a generationFailed error because content cannot be extracted
        do {
            _ = try await storyService.generateStory(parameters: parameters)
            Issue.record("Expected generateStory to throw, but it did not.")
        } catch let error as StoryServiceError {
            switch error {
            case .generationFailed(let message):
                #expect(message.contains("Could not extract story content"))
            default:
                Issue.record("Expected .generationFailed but got \(error)")
            }
        } catch {
            Issue.record("Expected StoryServiceError but got different error type: \(error)")
        }
    }

    @Test("StoryService handles XML with missing category tag")
    func testHandleXmlWithMissingCategory() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Story.self, StoryCollection.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let mockModel = MockGenerativeModel()
        let mockPersistenceService = MockPersistenceService()

        // Valid XML but missing the category tag
        let xmlResponse = """
            <title>The Missing Category</title>
            <content>This story has valid XML but is missing the category tag.
            ---
            Second page content.</content>
            """

        mockModel.generatedText = xmlResponse

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
            theme: "Adventure",
            childAge: 7,
            childName: "Alex",
            favoriteCharacter: "Brave Bear"
        )

        // Act
        let story = try await storyService.generateStory(parameters: parameters)

        // Assert
        #expect(story.categoryName == nil)
        #expect(story.title == "The Missing Category")
        #expect(story.pages.count > 0)
    }

    @Test("Test XML parsing with code blocks")
    func testXmlInCodeBlock() async throws {
        // Create a mock XML response inside code block (common in AI responses)
        let xmlResponse = """
            ```xml
            <title>E and Super Sparkle's Surprise</title>
            <content>E is four. E likes to play! E likes to play with blocks. Sometimes, E gets sad when the blocks fall down. It makes E feel grumpy.

            ---

            One day, E was building a big, big tower. It was the biggest tower ever! But then, WHOOSH! The tower fell. E felt very, very grumpy. E stomped her foot. "I don't like blocks!" she said.

            Suddenly, Super Sparkle zoomed down from the sky! She was wearing a sparkly cape and a big smile. "Hello, E! Why are you grumpy?"

            ---

            E showed Super Sparkle the fallen tower. "It fell down!" E said, with a sad face. Super Sparkle smiled. "It's okay, E! Building is hard. But it's more fun with a friend!"

            Super Sparkle picked up some blocks. "Let's build together!" she said.

            ---

            E and Super Sparkle started building. Super Sparkle helped E put the blocks on top. This time, the tower was even bigger! They worked together, and they laughed a lot. E wasn't grumpy anymore.

            "Wow!" said E. "We did it!"</content>
            <category>Friendship</category>
            ```
            """

        // Setup a mock model that returns our predefined XML
        let mockModel = MockGenerativeModel()
        mockModel.generatedText = xmlResponse

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
            theme: "Friendship",
            childAge: 4,
            childName: "E",
            favoriteCharacter: "Super Sparkle"
        )

        // Call generate story which will use our mock model
        let story = try await storyService.generateStory(parameters: parameters)

        // Assert
        #expect(story.title == "E and Super Sparkle's Surprise")
        #expect(story.pages.count > 0)
        #expect(story.categoryName == "Friendship")
        #expect(mockPersistenceService.storyToSave?.categoryName == "Friendship")
    }
}