import XCTest
import Foundation
@testable import magical_stories

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
            throw NSError(domain: "MockError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Collection not found"])
        }
        collection.completionProgress = Double(progress)
        collections[id] = collection
    }
    
    func deleteCollection(id: UUID) throws {
        if shouldThrowError { throw errorToThrow }
        collections.removeValue(forKey: id)
    }
}

final class CollectionServiceTests: XCTestCase {
    var mockRepository: MockCollectionRepositoryForTests!
    var service: CollectionService!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockCollectionRepositoryForTests()
        service = CollectionService(repository: mockRepository)
    }
    
    override func tearDown() {
        mockRepository = nil
        service = nil
        super.tearDown()
    }
    
    func testCreateCollectionSuccess() throws {
        let collection = StoryCollection(
            id: UUID(),
            title: "Test Collection",
            descriptionText: "Description",
            category: "Category",
            ageGroup: "AgeGroup"
        )
        try service.createCollection(collection)
        let saved = try service.fetchCollection(id: collection.id)
        XCTAssertNotNil(saved)
        XCTAssertEqual(saved?.title, "Test Collection")
    }
    
    func testCreateCollectionThrowsError() {
        mockRepository.shouldThrowError = true
        let collection = StoryCollection(
            id: UUID(),
            title: "Test Collection",
            descriptionText: "Description",
            category: "Category",
            ageGroup: "AgeGroup"
        )
        XCTAssertThrowsError(try service.createCollection(collection))
    }
    
    func testFetchCollectionSuccess() throws {
        let collection = StoryCollection(
            id: UUID(),
            title: "Fetch Test",
            descriptionText: "Description",
            category: "Category",
            ageGroup: "AgeGroup"
        )
        try mockRepository.saveCollection(collection)
        let fetched = try service.fetchCollection(id: collection.id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.title, "Fetch Test")
    }
    
    func testFetchCollectionNotFound() throws {
        let fetched = try service.fetchCollection(id: UUID())
        XCTAssertNil(fetched)
    }
    
    func testFetchCollectionThrowsError() {
        mockRepository.shouldThrowError = true
        XCTAssertThrowsError(try service.fetchCollection(id: UUID()))
    }
    
    func testFetchAllCollectionsSuccess() throws {
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
        let all = try service.fetchAllCollections()
        XCTAssertEqual(all.count, 2)
        XCTAssertTrue(all.contains(where: { $0.title == "C1" }))
        XCTAssertTrue(all.contains(where: { $0.title == "C2" }))
    }
    
    func testFetchAllCollectionsEmpty() throws {
        let all = try service.fetchAllCollections()
        XCTAssertTrue(all.isEmpty)
    }
    
    func testFetchAllCollectionsThrowsError() {
        mockRepository.shouldThrowError = true
        XCTAssertThrowsError(try service.fetchAllCollections())
    }
    
    func testUpdateCollectionProgressSuccess() throws {
        let collection = StoryCollection(
            id: UUID(),
            title: "Progress Test",
            descriptionText: "Description",
            category: "Category",
            ageGroup: "AgeGroup"
        )
        try mockRepository.saveCollection(collection)
        try service.updateCollectionProgress(id: collection.id, progress: 0.75)
        let updated = try service.fetchCollection(id: collection.id)
        XCTAssertEqual(updated?.completionProgress, 0.75)
    }
    
    func testUpdateCollectionProgressCollectionNotFound() {
        XCTAssertThrowsError(try service.updateCollectionProgress(id: UUID(), progress: 0.5)) { error in
            XCTAssertEqual((error as NSError).code, 404)
        }
    }
    
    func testUpdateCollectionProgressThrowsError() {
        mockRepository.shouldThrowError = true
        XCTAssertThrowsError(try service.updateCollectionProgress(id: UUID(), progress: 0.5))
    }
    
    func testDeleteCollectionSuccess() throws {
        let collection = StoryCollection(
            id: UUID(),
            title: "Delete Test",
            descriptionText: "Description",
            category: "Category",
            ageGroup: "AgeGroup"
        )
        try mockRepository.saveCollection(collection)
        try service.deleteCollection(id: collection.id)
        let deleted = try service.fetchCollection(id: collection.id)
        XCTAssertNil(deleted)
    }
    
    func testDeleteCollectionThrowsError() {
        mockRepository.shouldThrowError = true
        XCTAssertThrowsError(try service.deleteCollection(id: UUID()))
    }
}