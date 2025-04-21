import SwiftData
import Testing

@testable import magical_stories

@MainActor
struct StoryServiceTests {

    @Test("StoryService generates varied stories")
    func testStoryVariability() async throws {
        let container = try ModelContainer(
            for: Story.self, StoryCollection.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        // Arrange
        let mockModel = MockGenerativeModel()
        var callCount = 0
        mockModel.generateContentHandler = { prompt in
            callCount += 1
            // Return different content for each call
            return MockStoryGenerationResponse(
                text:
                    "Title: Generated story #\(callCount)\n\nGenerated story content #\(callCount)")
        }
        let mockPersistenceService = MockPersistenceService()
        let promptBuilder = PromptBuilder()
        let storyService = try StoryService(
            context: context,
            persistenceService: mockPersistenceService,
            model: mockModel,
            promptBuilder: promptBuilder
        )

        let parameters = StoryParameters(
            childName: "Alex",
            childAge: 7,
            theme: "Adventure",
            favoriteCharacter: "Dragon",
            storyLength: "short",
            developmentalFocus: nil,
            emotionalThemes: nil
        )

        // Act
        let story1 = try await storyService.generateStory(parameters: parameters)
        let story2 = try await storyService.generateStory(parameters: parameters)

        // Assert
        #expect(
            story1.pages.first?.content != story2.pages.first?.content,
            "Generated stories should have different content")
        #expect(story1.title != story2.title, "Generated story titles should be different")
    }
}
