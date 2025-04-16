import Foundation
import XCTest
import SwiftData

@testable import magical_stories

// Minimal mock StoryService to satisfy CollectionService initializer
class MockStoryService: StoryService {
    init(context: ModelContext, apiKey: String = "") throws {
        try super.init(apiKey: apiKey, context: context)
    }
}

@MainActor
final class CollectionServiceTests: XCTestCase {

    // Renamed mock to avoid conflict with existing MockCollectionRepository
    class MockCollectionRepositoryForTests: CollectionRepositoryProtocol {
        var collections: [UUID: StoryCollection] = [:]
        var shouldThrowError = false
        var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: nil)

        func saveCollection(_ collection: StoryCollection) throws {
            if shouldThrowError { throw errorToThrow }
            collections[collection.id] = collection
        }

        func fetchCollection(id: UUID) throws -> StoryCollection? {
            if shouldThrowError { throw errorToThrow }
            return collections[id]
        }

        func fetchAllCollections() throws -> [StoryCollection] {
            if shouldThrowError { throw errorToThrow }
            return Array(collections.values)
        }

        func updateCollectionProgress(id: UUID, progress: Float) throws {
            if shouldThrowError { throw errorToThrow }
            guard let collection = collections[id] else {
                throw NSError(
                    domain: "MockError", code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Collection not found"])
            }
            collection.completionProgress = Double(progress)
            collections[id] = collection
        }

        func deleteCollection(id: UUID) throws {
            if shouldThrowError { throw errorToThrow }
            collections.removeValue(forKey: id)
        }
    }

    var mockRepository: MockCollectionRepositoryForTests!
    var mockStoryService: StoryService!
    var service: CollectionService!

    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockCollectionRepositoryForTests()
        // Provide a dummy ModelContext for StoryService mock
        let container = try ModelContainer(for: StoryCollection.self)
        let modelContext = ModelContext(container)
        mockStoryService = try MockStoryService(context: modelContext, apiKey: "")
        service = CollectionService(repository: mockRepository, storyService: mockStoryService)
    }

    override func tearDown() async throws {
        mockRepository = nil
        mockStoryService = nil
        service = nil
        try await super.tearDown()
    }

    func testCreateCollectionSuccess() async throws {
        let collection = StoryCollection(
            id: UUID(),
            title: "Test Collection",
            descriptionText: "Description",
            category: "Category",
            ageGroup: "AgeGroup"
        )
        try await service.createCollection(collection)
        let saved = try await service.fetchCollection(id: collection.id)
        XCTAssertNotNil(saved)
        XCTAssertEqual(saved?.title, "Test Collection")
    }

    func testCreateCollectionThrowsError() async throws {
        mockRepository.shouldThrowError = true
        let collection = StoryCollection(
            id: UUID(),
            title: "Test Collection",
            descriptionText: "Description",
            category: "Category",
            ageGroup: "AgeGroup"
        )
        do {
            try await service.createCollection(collection)
            XCTFail("Expected error not thrown")
        } catch {
            // Expected error thrown
        }
    }

    func testFetchCollectionSuccess() async throws {
        let collection = StoryCollection(
            id: UUID(),
            title: "Fetch Test",
            descriptionText: "Description",
            category: "Category",
            ageGroup: "AgeGroup"
        )
        try mockRepository.saveCollection(collection)
        let fetched = try await service.fetchCollection(id: collection.id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.title, "Fetch Test")
    }

    func testFetchCollectionNotFound() async throws {
        let fetched = try await service.fetchCollection(id: UUID())
        XCTAssertNil(fetched)
    }

    func testFetchCollectionThrowsError() async throws {
        mockRepository.shouldThrowError = true
        do {
            _ = try await service.fetchCollection(id: UUID())
            XCTFail("Expected error not thrown")
        } catch {
            // Expected error thrown
        }
    }

    func testFetchAllCollectionsSuccess() async throws {
        let c1 = StoryCollection(
            id: UUID(),
            title: "C1",
            descriptionText: "Description",
            category: "Category",
            ageGroup: "AgeGroup"
        )
        let c2 = StoryCollection(
            id: UUID(),
            title: "C2",
            descriptionText: "Description",
            category: "Category",
            ageGroup: "AgeGroup"
        )
        try mockRepository.saveCollection(c1)
        try mockRepository.saveCollection(c2)
        let all = try await service.fetchAllCollections()
        XCTAssertEqual(all.count, 2)
        XCTAssertTrue(all.contains(where: { $0.title == "C1" }))
        XCTAssertTrue(all.contains(where: { $0.title == "C2" }))
    }

    func testFetchAllCollectionsEmpty() async throws {
        let all = try await service.fetchAllCollections()
        XCTAssertTrue(all.isEmpty)
    }

    func testFetchAllCollectionsThrowsError() async throws {
        mockRepository.shouldThrowError = true
        do {
            _ = try await service.fetchAllCollections()
            XCTFail("Expected error not thrown")
        } catch {
            // Expected error thrown
        }
    }

    func testUpdateCollectionProgressSuccess() async throws {
        let collection = StoryCollection(
            id: UUID(),
            title: "Progress Test",
            descriptionText: "Description",
            category: "Category",
            ageGroup: "AgeGroup"
        )
        try mockRepository.saveCollection(collection)
        try await service.updateCollectionProgress(id: collection.id, progress: 0.75)
        let updated = try await service.fetchCollection(id: collection.id)
        XCTAssertEqual(updated?.completionProgress, 0.75)
    }

    func testUpdateCollectionProgressCollectionNotFound() async throws {
        do {
            try await service.updateCollectionProgress(id: UUID(), progress: 0.5)
            XCTFail("Expected error not thrown")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.code, 404)
        }
    }

    func testUpdateCollectionProgressThrowsError() async throws {
        mockRepository.shouldThrowError = true
        do {
            try await service.updateCollectionProgress(id: UUID(), progress: 0.5)
            XCTFail("Expected error not thrown")
        } catch {
            // Expected error thrown
        }
    }

    func testDeleteCollectionSuccess() async throws {
        let collection = StoryCollection(
            id: UUID(),
            title: "Delete Test",
            descriptionText: "Description",
            category: "Category",
            ageGroup: "AgeGroup"
        )
        try mockRepository.saveCollection(collection)
        try await service.deleteCollection(id: collection.id)
        let deleted = try await service.fetchCollection(id: collection.id)
        XCTAssertNil(deleted)
    }

    func testDeleteCollectionThrowsError() async throws {
        mockRepository.shouldThrowError = true
        do {
            try await service.deleteCollection(id: UUID())
            XCTFail("Expected error not thrown")
        } catch {
            // Expected error thrown
        }
    }
}
