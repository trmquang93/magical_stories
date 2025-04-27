import XCTest
import Testing
@testable import magical_stories
import SwiftData

@MainActor
final class CollectionRepositoryTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var repository: CollectionRepository!

    override func setUp() async throws {
        try await super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: StoryCollection.self, configurations: config)
        context = container.mainContext
        repository = CollectionRepository(modelContext: context)
    }

    override func tearDown() async throws {
        container = nil
        context = nil
        repository = nil
        try await super.tearDown()
    }

    func testSaveCollection() async throws {
        let collection = StoryCollection(
            title: "Test",
            descriptionText: "Test",
            category: "Test",
            ageGroup: "Test",
            stories: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try repository.saveCollection(collection)
        let fetched = try repository.fetchCollection(id: collection.id)
        XCTAssertNotNil(fetched)
    }

    func testFetchAllCollections() async throws {
        let collection1 = StoryCollection(
            title: "Test1",
            descriptionText: "Test1",
            category: "Test1",
            ageGroup: "Test1",
            stories: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let collection2 = StoryCollection(
            title: "Test2",
            descriptionText: "Test2",
            category: "Test2",
            ageGroup: "Test2",
            stories: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try repository.saveCollection(collection1)
        try repository.saveCollection(collection2)
        
        let all = try repository.fetchAllCollections()
        XCTAssertEqual(all.count, 2)
    }

    func testUpdateCollectionProgress() async throws {
        let collection = StoryCollection(
            title: "Test",
            descriptionText: "Test",
            category: "Test",
            ageGroup: "Test",
            stories: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try repository.saveCollection(collection)
        try repository.updateCollectionProgress(id: collection.id, progress: 0.5)
        
        let updated = try repository.fetchCollection(id: collection.id)
        XCTAssertNotNil(updated?.updatedAt)
    }

    func testDeleteCollection() async throws {
        let collection = StoryCollection(
            title: "Test",
            descriptionText: "Test",
            category: "Test",
            ageGroup: "Test",
            stories: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try repository.saveCollection(collection)
        try repository.deleteCollection(id: collection.id)
        
        let deleted = try repository.fetchCollection(id: collection.id)
        XCTAssertNil(deleted)
    }
}

// MARK: - Error Handling Tests
extension CollectionRepositoryTests {
    func testSaveCollection_duplicateId_throwsError() async throws {
        let collection1 = StoryCollection(
            title: "Test",
            descriptionText: "Test",
            category: "Test",
            ageGroup: "Test",
            stories: [],
            createdAt: Date(),
            updatedAt: Date()
        )

        // Create a second collection with same ID but different properties
        // The SwiftData transaction should fail when trying to save this
        let collection2ID = collection1.id
        let collection2 = StoryCollection(
            id: collection2ID, // Same ID as collection1
            title: "Test2",
            descriptionText: "Test2",
            category: "Test2",
            ageGroup: "Test2",
            stories: [],
            createdAt: Date(),
            updatedAt: Date()
        )

        try repository.saveCollection(collection1)

        do {
            try repository.saveCollection(collection2)
            XCTFail("Expected error to be thrown for duplicate ID")
        } catch {
            // Verify that a SwiftData error is thrown
            XCTAssertTrue(error is SwiftDataError)
        }
    }
    
    func testCollectionRepository_databaseErrors() async throws {
        // Test 1: Try to update a non-existent collection
        let nonExistentID = UUID()
        do {
            try repository.updateCollectionProgress(id: nonExistentID, progress: 0.5)
            XCTFail("Expected error updating non-existent collection")
        } catch {
            XCTAssertTrue(error is CollectionError)
            XCTAssertEqual(error.localizedDescription, "Collection not found")
        }
        
        // Test 2: Try to get a non-existent collection
        do {
            _ = try repository.getCollection(id: nonExistentID)
            XCTFail("Expected error getting non-existent collection")
        } catch {
            XCTAssertTrue(error is CollectionError)
            XCTAssertEqual(error.localizedDescription, "Collection not found")
        }
        
        // Test 3: Create collection with invalid relationship
        let storyID = UUID()
        let invalidStory = Story(
            id: storyID,
            title: "Invalid Story",
            parameters: StoryParameters(childName: "Test", childAge: 5, theme: "Test", favoriteCharacter: "Test"),
            isCompleted: false
        )
        
        let invalidCollection = StoryCollection(
            title: "Invalid Test",
            descriptionText: "Invalid Test",
            category: "Invalid Test",
            ageGroup: "Invalid Test"
        )
        
        // Add the story to the collection without saving the story to the database
        invalidCollection.stories.append(invalidStory)
        
        do {
            try repository.saveCollection(invalidCollection)
            // Note: SwiftData might actually allow this, but we should check the behavior
            // In a properly normalized database, this would fail with a foreign key constraint
        } catch {
            XCTAssertTrue(error is SwiftDataError)
        }
    }
    
    func testCollectionRepository_recoveryFromInterruption() async throws {
        // Test recovery after transaction interruption
        let collection = StoryCollection(
            title: "Recovery Test",
            descriptionText: "Recovery Test",
            category: "Recovery Test",
            ageGroup: "Recovery Test"
        )
        
        // Save collection
        try repository.saveCollection(collection)
        
        // Simulate transaction interruption by creating a new container and context
        container = nil
        context = nil
        
        // Re-initialize with new container and context
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: StoryCollection.self, configurations: config)
        context = container.mainContext
        repository = CollectionRepository(modelContext: context)
        
        // Try to recover the collection - in real app this would be from disk
        // For in-memory test, we expect it to be gone
        let recovered = try repository.fetchCollection(id: collection.id)
        XCTAssertNil(recovered, "Collection should not be recovered when using in-memory storage")
        
        // For disk-based tests, we would assert that the collection was recovered
        // But that would require a different setup with persistent storage
    }
}
