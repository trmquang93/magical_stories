import SwiftData
import Testing

@testable import magical_stories

@MainActor
struct StoryService_CategoryTests {

    @Test("StoryService should extract category from XML response")
    func testStoryServiceExtractsCategoryFromXML() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Story.self, StoryCollection.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let mockModel = MockGenerativeModel()
        let mockPersistenceService = MockPersistenceService()

        // Simulate XML response from AI with title, content, and category
        let xmlResponse = """
            <title>Test Story</title>
            <content>This is the content of the story.
            ---
            This is the second page.</content>
            <category>Fantasy</category>
            <illustrations>
              <illustration page="1">A detailed illustration of a character on an adventure in a fantasy setting.</illustration>
              <illustration page="2">A vibrant scene showing the conclusion of the story with magical elements.</illustration>
            </illustrations>
            """

        mockModel.generatedText = xmlResponse

        let storyService = try StoryService(
            context: context,
            persistenceService: mockPersistenceService,
            model: mockModel
        )

        let parameters = StoryParameters(
            theme: "Adventure",
            childAge: 7,
            childName: "Alex",
            favoriteCharacter: "Dragon"
        )

        // Act
        let story = try await storyService.generateStory(parameters: parameters)

        // Assert
        #expect(story.categoryName == "Fantasy")
        #expect(story.title == "Test Story")
        #expect(story.pages.count > 0)
        #expect(mockPersistenceService.saveStoryCalled)
        #expect(mockPersistenceService.storyToSave?.categoryName == "Fantasy")
    }

    @Test("StoryService should handle missing category in XML response")
    func testStoryServiceHandlesMissingCategory() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Story.self, StoryCollection.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let mockModel = MockGenerativeModel()
        let mockPersistenceService = MockPersistenceService()

        // Simulate XML response from AI with title and content but no category
        let xmlResponse = """
            <title>Test Story</title>
            <content>This is the content of the story.
            ---
            This is the second page.</content>
            <illustrations>
              <illustration page="1">A detailed illustration depicting the first page.</illustration>
              <illustration page="2">A colorful scene showing the second page content.</illustration>
            </illustrations>
            """

        mockModel.generatedText = xmlResponse

        let storyService = try StoryService(
            context: context,
            persistenceService: mockPersistenceService,
            model: mockModel
        )

        let parameters = StoryParameters(
            theme: "Adventure",
            childAge: 7,
            childName: "Alex",
            favoriteCharacter: "Dragon"
        )

        // Act
        let story = try await storyService.generateStory(parameters: parameters)

        // Assert
        #expect(story.categoryName == nil)
        #expect(story.title == "Test Story")
    }

    @Test("StoryService should handle non-XML response gracefully")
    func testStoryServiceHandlesNonXMLResponse() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Story.self, StoryCollection.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let mockModel = MockGenerativeModel()
        let mockPersistenceService = MockPersistenceService()

        // Simulate plain text response from AI with no XML tags
        mockModel.generatedText =
            "Title: Test Story\n\nThis is the content of the story.\n---\nThis is the second page."

        let storyService = try StoryService(
            context: context,
            persistenceService: mockPersistenceService,
            model: mockModel
        )

        let parameters = StoryParameters(
            theme: "Adventure",
            childAge: 7,
            childName: "Alex",
            favoriteCharacter: "Dragon"
        )

        // Act
        let story = try await storyService.generateStory(parameters: parameters)

        // Assert
        #expect(story.categoryName == nil)  // Fallback category extraction might still find something, but title should be fallback
        #expect(story.title == "Magical Story")  // Expect fallback title when no XML/Title found
    }

    @Test("StoryService should extract illustrations from XML response")
    func testStoryServiceExtractsIllustrationsFromXML() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Story.self, StoryCollection.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let mockModel = MockGenerativeModel()
        let mockPersistenceService = MockPersistenceService()

        // Simulate XML response from AI with title, content, category, and illustrations
        let xmlResponse = """
            <title>Test Story</title>
            <content>This is the content of the story.
            ---
            This is the second page.</content>
            <category>Fantasy</category>
            <illustrations>
              <illustration page="1">A detailed magical forest scene.</illustration>
              <illustration page="2">Characters crossing a rainbow bridge.</illustration>
            </illustrations>
            """

        mockModel.generatedText = xmlResponse

        let storyService = try StoryService(
            context: context,
            persistenceService: mockPersistenceService,
            model: mockModel
        )

        let parameters = StoryParameters(
            theme: "Adventure",
            childAge: 7,
            childName: "Alex",
            favoriteCharacter: "Dragon"
        )

        // Act
        let story = try await storyService.generateStory(parameters: parameters)

        // Assert
        #expect(story.pages.count == 2)
        #expect(story.pages[0].imagePrompt == "A detailed magical forest scene.")
        #expect(story.pages[1].imagePrompt == "Characters crossing a rainbow bridge.")
    }
}
