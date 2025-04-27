import Foundation
import SwiftData
import Testing

@testable import magical_stories

@Suite("Collection Service Integration Tests")
@MainActor
class CollectionServiceIntegrationTests {

    var collectionService: CollectionService!
    var repository: CollectionRepository!

    init() {
        // Setup for integration test - using new CollectionService API with appropriate mocks
        // Use in-memory ModelContext for repository
        let modelContext: ModelContext = {
            do {
                return try ModelContext(ModelContainer(for: StoryCollection.self))
            } catch {
                fatalError("Failed to create ModelContext/ModelContainer: \(error)")
            }
        }()
        repository = CollectionRepository(modelContext: modelContext)
        // Provide a dummy ModelContext for StoryService mock
        let container = try! ModelContainer(for: StoryCollection.self)
        let modelContextForStoryService = ModelContext(container)
        let storyService = try! MockStoryService(context: modelContextForStoryService)
        let achievementRepository = AchievementRepository(modelContext: modelContext)
        collectionService = CollectionService(repository: repository, storyService: storyService, achievementRepository: achievementRepository)
        // Clean up any existing test data if needed (implementation may be updated in later subtasks)
    }

    // Removed unused cleanupTestData function

    @Test("Can create and fetch a collection")
    func testCreateAndFetch() throws {
        // Arrange
        let testCollection = StoryCollection(
            title: "Test Collection",
            descriptionText: "Test Description",
            category: "Test Category",
            ageGroup: "3-5 years"
        )

        // Act & Assert
        try collectionService.createCollection(testCollection)

        // Fetch all collections
        let collections = try collectionService.fetchAllCollections()

        // Verify the collection was saved
        #expect(collections.count > 0)
        #expect(collections.contains { $0.id == testCollection.id })

        // Fetch the specific collection
        let fetchedCollection = try collectionService.fetchCollection(id: testCollection.id)
        #expect(fetchedCollection != nil)
        #expect(fetchedCollection?.title == testCollection.title)
    }
}
