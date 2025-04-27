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

@Suite("StoryService Developmental Enhancement Tests")
@MainActor
struct StoryServiceDevelopmentalTests {

    func createTestModelContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Story.self, StoryCollection.self, configurations: config)
        return ModelContext(container)
    }

    @Test("testBuildEnhancedPromptAddsVocabularyGuidelines")
    func testBuildEnhancedPromptAddsVocabularyGuidelines() throws {
        // Arrange
        let modelContext = try createTestModelContext()
        let service = try StoryService(context: modelContext)

        // Parameters with and without vocabulary boost
        let baseParams = StoryParameters(
            childName: "Alex",
            childAge: 5,
            theme: "Adventure",
            favoriteCharacter: "Dragon"
        )

        let enhancedParams = StoryParameters(
            childName: "Alex",
            childAge: 5,
            theme: "Adventure",
            favoriteCharacter: "Dragon",
            developmentalFocus: [.cognitiveDevelopment],
            interactiveElements: true
        )

        // Act
        let basePrompt = service.buildPrompt(with: baseParams, vocabularyBoostEnabled: false)
        let enhancedPrompt = service.buildPrompt(with: enhancedParams, vocabularyBoostEnabled: true)

        // Assert
        #expect(basePrompt.contains("vocabulary appropriate for a 5-year-old"))
        #expect(!basePrompt.contains("Include more advanced vocabulary words"))

        #expect(enhancedPrompt.contains("vocabulary appropriate for a 5-year-old"))
        #expect(enhancedPrompt.contains("Include more advanced vocabulary words"))
        #expect(enhancedPrompt.contains("Cognitive Development"))
        #expect(enhancedPrompt.contains("interactive elements"))
    }

    @Test("testBuildEnhancedPromptAdaptsVocabularyToAgeGroup")
    func testBuildEnhancedPromptAdaptsVocabularyToAgeGroup() throws {
        // Arrange
        let modelContext = try createTestModelContext()
        let service = try StoryService(context: modelContext)

        // Parameters for different age groups
        let preschoolerParams = StoryParameters(
            childName: "Emma",
            childAge: 4,
            theme: "Animals",
            favoriteCharacter: "Cat"
        )

        let elementaryParams = StoryParameters(
            childName: "Jacob",
            childAge: 8,
            theme: "Space",
            favoriteCharacter: "Astronaut"
        )

        // Act
        let preschoolerPrompt = service.buildPrompt(
            with: preschoolerParams, vocabularyBoostEnabled: true)
        let elementaryPrompt = service.buildPrompt(
            with: elementaryParams, vocabularyBoostEnabled: true)

        // Assert
        // Verify preschooler vocabulary guidance
        #expect(preschoolerPrompt.contains("vocabulary appropriate for a 4-year-old"))
        #expect(preschoolerPrompt.contains("simple sentence structures"))
        #expect(preschoolerPrompt.contains("2-3 new vocabulary words"))

        // Verify elementary vocabulary guidance
        #expect(elementaryPrompt.contains("vocabulary appropriate for a 8-year-old"))
        #expect(elementaryPrompt.contains("varied sentence structures"))
        #expect(elementaryPrompt.contains("4-6 new vocabulary words"))
    }

    @Test("testBuildEnhancedPromptGeneratesRichNarrativeGuidance")
    func testBuildEnhancedPromptGeneratesRichNarrativeGuidance() throws {
        // Arrange
        let modelContext = try createTestModelContext()
        let service = try StoryService(context: modelContext)

        let params = StoryParameters(
            childName: "Maya",
            childAge: 6,
            theme: "Friendship",
            favoriteCharacter: "Unicorn",
            developmentalFocus: [.kindnessEmpathy, .socialSkills]
        )

        // Act
        let prompt = service.buildPrompt(with: params, vocabularyBoostEnabled: true)

        // Assert
        #expect(prompt.contains("clear narrative arc"))
        #expect(prompt.contains("beginning, middle, and end"))
        #expect(prompt.contains("Kindness & Empathy"))
        #expect(prompt.contains("Social Skills"))
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
            childName: "Riley",
            childAge: 7,
            theme: "Nature",
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
