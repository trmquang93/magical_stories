import Foundation
import SwiftData
import Testing

@testable import magical_stories

extension Tag {
    @Tag static var collectionIntegration: Self { "CollectionIntegration" }
}

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

        // Override the generateStory method to return a mock story
        let originalGenerateStory = storyService.generateStory
        storyService.generateStory = { parameters in
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

        // Create collection service
        let collectionService = CollectionService(
            repository: collectionRepository,
            storyService: storyService,
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

    @Test("End-to-end Collection flow: create, generate stories, mark completed, get achievement")
    @Tag(Tag.collectionIntegration)
    func testEndToEndCollectionFlow() async throws {
        // Setup
        let (
            _,
            collectionService,
            collectionRepository,
            _,
            achievementRepository
        ) = try setupTestEnvironment()

        // 1. Create a collection
        let collection = StoryCollection(
            title: "Integration Test Collection",
            descriptionText: "Test collection for integration testing",
            category: "emotionalIntelligence",
            ageGroup: "elementary"
        )
        try collectionService.createCollection(collection)

        // Verify collection was created
        let savedCollection = try collectionRepository.fetchCollection(id: collection.id)
        #require(savedCollection != nil, "Collection should be saved successfully")

        // 2. Generate stories for the collection
        let parameters = CollectionParameters(
            childAgeGroup: "elementary",
            developmentalFocus: "Emotional Intelligence",
            interests: "Space, Dinosaurs",
            childName: "Alex"
        )

        try await collectionService.generateStoriesForCollection(collection, parameters: parameters)

        // Verify stories were generated
        let collectionWithStories = try collectionRepository.fetchCollection(id: collection.id)
        #require(
            collectionWithStories != nil, "Collection should still exist after generating stories")
        #require(collectionWithStories!.stories != nil, "Collection should have stories")
        #expect(
            collectionWithStories!.stories!.count > 0, "Collection should have at least one story")

        // Print story details for debugging
        for (index, story) in (collectionWithStories!.stories ?? []).enumerated() {
            print("Story \(index+1): \(story.title), Completed: \(story.isCompleted)")
        }

        // Save reference to stories for later
        let stories = collectionWithStories!.stories!
        #expect(stories.count == 3, "Collection should have exactly 3 stories")

        // 3. Verify initial progress is 0
        let initialProgress = try await collectionService.updateCollectionProgressBasedOnReadCount(
            collectionId: collection.id)
        #expect(initialProgress == 0.0, "Initial progress should be 0.0")

        // 4. Mark first story as completed
        try await collectionService.markStoryAsCompleted(
            storyId: stories[0].id, collectionId: collection.id)

        // Verify progress updated
        let progressAfterOne = try await collectionService.updateCollectionProgressBasedOnReadCount(
            collectionId: collection.id)
        #expect(
            progressAfterOne == 1.0 / 3.0, "Progress should be 1/3 after completing first story")

        // 5. Mark second story as completed
        try await collectionService.markStoryAsCompleted(
            storyId: stories[1].id, collectionId: collection.id)

        // Verify progress updated
        let progressAfterTwo = try await collectionService.updateCollectionProgressBasedOnReadCount(
            collectionId: collection.id)
        #expect(
            progressAfterTwo == 2.0 / 3.0, "Progress should be 2/3 after completing second story")

        // Verify no achievement yet
        var achievements = try achievementRepository.fetchAllAchievements()
        #expect(achievements.isEmpty, "Should not have any achievements yet")

        // 6. Mark third (final) story as completed
        try await collectionService.markStoryAsCompleted(
            storyId: stories[2].id, collectionId: collection.id)

        // Verify progress is now 100%
        let finalProgress = try await collectionService.updateCollectionProgressBasedOnReadCount(
            collectionId: collection.id)
        #expect(finalProgress == 1.0, "Progress should be 1.0 after completing all stories")

        // 7. Verify achievement was created
        achievements = try achievementRepository.fetchAllAchievements()
        #expect(achievements.count == 1, "Should have one achievement")

        let achievement = achievements.first
        #require(achievement != nil, "Achievement should exist")
        #expect(
            achievement!.name == "Completed Integration Test Collection",
            "Achievement should have correct name")
        #expect(achievement!.type == .growthPathProgress, "Achievement should have correct type")
        #expect(achievement!.earnedAt != nil, "Achievement should have an earned date")

        // 8. Verify no duplicate achievements if progress is updated again
        try await collectionService.updateCollectionProgressBasedOnReadCount(
            collectionId: collection.id)
        let finalAchievements = try achievementRepository.fetchAllAchievements()
        #expect(finalAchievements.count == 1, "Should still have only one achievement")
    }
}
