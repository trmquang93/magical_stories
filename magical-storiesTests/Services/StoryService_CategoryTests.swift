import SwiftData
import Testing

@testable import magical_stories

@MainActor
struct StoryService_CategoryTests {

    @Test("StoryService should extract category from JSON response")
    func testStoryServiceExtractsCategoryFromJSON() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Story.self, StoryCollection.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let mockModel = MockGenerativeModel()
        let mockPersistenceService = MockPersistenceService()

        // Simulate JSON response from AI with story and category
        let jsonResponse = """
            {
                "story": "Title: Test Story\\n\\nThis is the content of the story.\\n---\\nThis is the second page.",
                "category": "Fantasy"
            }
            """

        mockModel.generatedText = jsonResponse

        let storyService = try StoryService(
            context: context,
            persistenceService: mockPersistenceService,
            model: mockModel
        )

        let parameters = StoryParameters(
            childName: "Alex",
            childAge: 7,
            theme: "Adventure",
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

    @Test("StoryService should handle missing category in JSON response")
    func testStoryServiceHandlesMissingCategory() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Story.self, StoryCollection.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let mockModel = MockGenerativeModel()
        let mockPersistenceService = MockPersistenceService()

        // Simulate JSON response from AI with story but no category
        let jsonResponse = """
            {
                "story": "Title: Test Story\\n\\nThis is the content of the story.\\n---\\nThis is the second page."
            }
            """

        mockModel.generatedText = jsonResponse

        let storyService = try StoryService(
            context: context,
            persistenceService: mockPersistenceService,
            model: mockModel
        )

        let parameters = StoryParameters(
            childName: "Alex",
            childAge: 7,
            theme: "Adventure",
            favoriteCharacter: "Dragon"
        )

        // Act
        let story = try await storyService.generateStory(parameters: parameters)

        // Assert
        #expect(story.categoryName == nil)
        #expect(story.title == "Test Story")
    }

    @Test("StoryService should handle invalid JSON response gracefully")
    func testStoryServiceHandlesInvalidJSONResponse() async throws {
        // Arrange
        let container = try ModelContainer(
            for: Story.self, StoryCollection.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let mockModel = MockGenerativeModel()
        let mockPersistenceService = MockPersistenceService()

        // Simulate non-JSON response from AI
        mockModel.generatedText =
            "Title: Test Story\n\nThis is the content of the story.\n---\nThis is the second page."

        let storyService = try StoryService(
            context: context,
            persistenceService: mockPersistenceService,
            model: mockModel
        )

        let parameters = StoryParameters(
            childName: "Alex",
            childAge: 7,
            theme: "Adventure",
            favoriteCharacter: "Dragon"
        )

        // Act
        let story = try await storyService.generateStory(parameters: parameters)

        // Assert
        #expect(story.categoryName == nil)
        #expect(story.title == "Test Story")
    }
}
