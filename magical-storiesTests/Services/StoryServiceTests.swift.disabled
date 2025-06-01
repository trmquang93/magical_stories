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
            // Return different XML content for each call
            let xmlResponse = """
                <title>Generated story #\(callCount)</title>
                <content>Generated story content #\(callCount)</content>
                <category>Adventure</category>
                """
            return MockStoryGenerationResponse(text: xmlResponse)
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
            theme: "Adventure",
            childAge: 7,
            childName: "Alex",
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

@Suite("StoryService Developmental Enhancement Tests")
@MainActor
struct StoryServiceDevelopmentalTests {

    func createTestModelContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Story.self, StoryCollection.self, configurations: config)
        return ModelContext(container)
    }

    @Test("testStoryServiceRespectsSettingsServiceVocabularyBoostSetting")
    func testStoryServiceRespectsSettingsServiceVocabularyBoostSetting() throws {
        // Arrange
        // Create a mock settings service
        class MockSettingsService: SettingsServiceProtocol {
            var vocabularyBoostEnabled: Bool

            init(vocabularyBoostEnabled: Bool) {
                self.vocabularyBoostEnabled = vocabularyBoostEnabled
            }

            // Implement required protocol methods with minimal implementations
            var parentalControlsEnabled: Bool = false
            var maxStoriesPerDay: Int = 10
            var saveSettingsCalled = false

            func saveSettings() throws {
                saveSettingsCalled = true
            }

            func loadSettings() {}

            func isContentAllowed(theme: String, age: Int) -> Bool {
                return true
            }

            func canReadMoreStoriesToday() -> Bool {
                return true
            }

            func recordStoryRead() {}

            func resetDailyCount() {}
        }

        // Create instances with different settings
        let settingsWithBoostDisabled = MockSettingsService(vocabularyBoostEnabled: false)
        let settingsWithBoostEnabled = MockSettingsService(vocabularyBoostEnabled: true)

        // Create a StoryService with the settings service
        let modelContext = try createTestModelContext()
        let serviceWithBoostDisabled = try StoryService(
            context: modelContext, settingsService: settingsWithBoostDisabled)
        let serviceWithBoostEnabled = try StoryService(
            context: modelContext, settingsService: settingsWithBoostEnabled)

        // Parameters for testing
        let params = StoryParameters(
            theme: "Nature",
            childAge: 7,
            childName: "Riley",
            favoriteCharacter: "Fox",
            developmentalFocus: [.creativityImagination]
        )

        // Act
        let promptWithBoostDisabled = serviceWithBoostDisabled.buildPrompt(with: params)
        let promptWithBoostEnabled = serviceWithBoostEnabled.buildPrompt(with: params)

        // Assert
        #expect(!promptWithBoostDisabled.contains("Include more advanced vocabulary words"))
        #expect(promptWithBoostEnabled.contains("Include more advanced vocabulary words"))
        #expect(promptWithBoostEnabled.contains("Creativity & Imagination"))
    }
}
