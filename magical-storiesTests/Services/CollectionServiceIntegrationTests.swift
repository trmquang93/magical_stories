import Foundation
import SwiftData
import Testing

@testable import magical_stories

@Suite("Collection Service Integration Tests")
@MainActor
class CollectionServiceIntegrationTests {

    var collectionService: CollectionService!
    var aiService: MockAIService
    var repository: CollectionRepository!

    init() {
        // Setup for integration test - using new CollectionService API with appropriate mocks
        aiService = MockAIService()
        // Use in-memory ModelContext for repository
        let modelContext: ModelContext = {
            do {
                return try ModelContext(ModelContainer(for: StoryCollection.self))
            } catch {
                fatalError("Failed to create ModelContext/ModelContainer: \(error)")
            }
        }()
        repository = CollectionRepository(context: modelContext)
        collectionService = CollectionService(aiService: aiService, repository: repository)
        // Clean up any existing test data if needed (implementation may be updated in later subtasks)
    }

    // FIX: No macro named 'Test' in Swift Testing. Use #Test as a function attribute, not as a statement.
    @Test("Full generation success path")
    func testCollectionGenerationFlow_Success() async throws {
        // Arrange
        let title = "Integration Test Collection"
        let growthCategory = "Learning"
        let targetAgeGroup = "5-7"

        // Arrange AI mock response
        aiService.collectionResponseToReturn = CollectionGenerationResponse(
            title: title,
            description: "A collection for testing the integration flow",
            achievementIds: [],
            storyOutlines: [
                .init(context: "Context 1"),
                .init(context: "Context 2"),
                .init(context: "Context 3"),
                .init(context: "Context 4"),
                .init(context: "Context 5"),
            ]
        )

        // Act - Create a collection using the new API
        let collection = try await collectionService.createCollection(
            title: title,
            theme: growthCategory,
            ageGroup: targetAgeGroup,
            focusArea: "IntegrationTest"
        )

        // Assert
        // 1. Collection properties
        #expect(collection.title == "Integration Test Collection")
        #expect(collection.descriptionText == "A collection for testing the integration flow")
        #expect(collection.stories.count == 5)
        #expect(collection.growthCategory == "Learning")
        #expect(collection.targetAgeGroup == "5-7")

        // 2. Stories were generated
        for story in collection.stories {
            #expect(story.title == "Integration Test Story")
            #expect(story.pages.count == 2)
            // collectionId property removed from Story; no assertion needed
        }

        // Clean up after test
        await cleanupTestData()
    }

    @Test("Generation with AI error handling")
    func testCollectionGenerationFlow_AIErrorHandling() async throws {
        // Arrange
        let title = "Retry Collection"
        let growthCategory = "Social Skills"
        let targetAgeGroup = "8-10"

        // Use a new mock for error simulation
        let errorAIService = MockAIService()
        errorAIService.collectionResponseToReturn = CollectionGenerationResponse(
            title: title,
            description: "Collection after retry",
            achievementIds: ["retry_badge"],
            storyOutlines: [
                .init(context: "Trying again context"),
                .init(context: "Not giving up context"),
                .init(context: "Success after failure context"),
                .init(context: "Learning from mistakes context"),
                .init(context: "Achieving goals context"),
            ]
        )
        errorAIService.collectionErrorCountBeforeSuccess = 2

        // Track error count by wrapping the mock's generateCollection method
        var errorCount = 0
        if let originalGenerateCollection = errorAIService.generateCollection {
            errorAIService.generateCollection = { theme, ageGroup in
                errorCount += 1
                return try await originalGenerateCollection(theme, ageGroup)
            }
        } else {
            errorAIService.generateCollection = { theme, ageGroup in
                errorCount += 1
                return try await errorAIService.generateCollection(for: theme, ageGroup: ageGroup)
            }
        }

        collectionService = CollectionService(aiService: errorAIService, repository: repository)

        // Act - Create a collection which should trigger retries
        let collection = try await collectionService.createCollection(
            title: title,
            theme: growthCategory,
            ageGroup: targetAgeGroup,
            focusArea: "AIErrorTest"
        )

        // Assert
        #expect(errorCount == 3)  // Two failures + one success
        #expect(collection.title == "Retry Collection")
        #expect(collection.descriptionText == "Collection after retry")
        #expect(collection.stories.count == 5)
        #expect(collection.targetAgeGroup == "8-10")
        #expect(collection.growthCategory == "Social Skills")

        // Clean up after test
        await cleanupTestData()
    }

    // Helper function to clean up test data
    private func cleanupTestData() async {
        // Clean up collections created for testing
        // Implementation will be updated in a later subtask to use the new repository
    }
}
