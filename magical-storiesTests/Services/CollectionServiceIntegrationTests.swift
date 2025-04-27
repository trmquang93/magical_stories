import Foundation
import SwiftData
import Testing

@testable import magical_stories

@Suite("Collection Service Integration Tests")
@MainActor
struct CollectionServiceIntegrationTests {

    // Helper function to create a test model container
    private func createTestContainer() -> ModelContainer {
        let schema = Schema([
            StoryCollection.self,
            Story.self,
            Page.self,
            AchievementModel.self,
            StoryModel.self,
        ])

        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: true,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Failed to create test ModelContainer: \(error)")
        }
    }

    // Helper function to setup test environment with dependencies
    private func setupTestEnvironment() throws -> (
        modelContext: ModelContext,
        collectionService: CollectionService,
        collectionRepository: CollectionRepository,
        storyService: StoryService,
        achievementRepository: AchievementRepository
    ) {
        let container = createTestContainer()
        let context = container.mainContext

        let collectionRepository = CollectionRepository(modelContext: context)
        let achievementRepository = AchievementRepository(modelContext: context)

        // Create a mock API key
        let apiKey = "test-api-key"

        // Create a persistence service
        let persistenceService = PersistenceService(context: context)

        // Create an illustration service (using a fake API key, won't be used in tests)
        let illustrationService: IllustrationService
        do {
            illustrationService = try IllustrationService(apiKey: apiKey)
        } catch {
            throw error
        }

        // Create a story processor
        let storyProcessor = StoryProcessor(illustrationService: illustrationService)

        // Create a story service
        let storyService: StoryService
        do {
            storyService = try StoryService(
                apiKey: apiKey,
                context: context,
                persistenceService: persistenceService,
                storyProcessor: storyProcessor
            )
        } catch {
            throw error
        }

        // Use a MockStoryService instead of overriding the method
        // Create a test-specific implementation that doesn't try to override methods
        let testStoryService: TestStoryService
        do {
            testStoryService = try TestStoryService(
                apiKey: apiKey,
                context: context,
                persistenceService: persistenceService,
                storyProcessor: storyProcessor
            )
        } catch {
            throw error
        }

        // Create collection service with the test story service
        let collectionService = CollectionService(
            repository: collectionRepository,
            storyService: testStoryService,
            achievementRepository: achievementRepository
        )

        return (
            context,
            collectionService,
            collectionRepository,
            storyService,
            achievementRepository
        )
    }
}

// Test-specific implementation of StoryService that doesn't override methods
class TestStoryService: StoryService {
    init(
        apiKey: String, context: ModelContext, persistenceService: PersistenceService,
        storyProcessor: StoryProcessor
    ) throws {
        try super.init(
            apiKey: apiKey, context: context, persistenceService: persistenceService,
            storyProcessor: storyProcessor)
    }

    override func generateStory(parameters: StoryParameters) async throws -> Story {
        print("Integration test using mocked story generation")
        let storyTitle = "Test Story for \(parameters.childName) - \(parameters.theme)"

        let pages = [
            Page(
                content:
                    "Once upon a time, there was a child named \(parameters.childName) who loved \(parameters.theme).",
                pageNumber: 1,
                illustrationStatus: .placeholder
            ),
            Page(
                content:
                    "They had many adventures with their friend, the \(parameters.favoriteCharacter).",
                pageNumber: 2,
                illustrationStatus: .placeholder
            ),
            Page(
                content: "The end.",
                pageNumber: 3,
                illustrationStatus: .placeholder
            ),
        ]

        return Story(
            title: storyTitle,
            pages: pages,
            parameters: parameters,
            timestamp: Date(),
            categoryName: "Integration Test"
        )
    }
}
