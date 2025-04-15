import XCTest
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
