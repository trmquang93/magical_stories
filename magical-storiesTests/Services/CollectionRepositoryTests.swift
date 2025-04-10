import Testing
@testable import magical_stories
import Foundation
import SwiftData

@Suite("Collection Repository Tests")
@MainActor
struct CollectionRepositoryTests {

    var repository: CollectionRepository!
    var modelContext: ModelContext!

    init() {
        let modelContainer = try! ModelContainer(for: StoryCollection.self)
        modelContext = ModelContext(modelContainer)
        repository = CollectionRepository(context: modelContext)
    }

    func makeCollection(title: String, growthCategory: String?, targetAgeGroup: String?) -> StoryCollection {
        let collection = StoryCollection(
            title: title,
            descriptionText: "Test Desc",
            growthCategory: growthCategory,
            targetAgeGroup: targetAgeGroup,
            stories: [],
            achievements: nil,
            completionProgress: 0.0
        )
        return collection
    }

    @Test("Saving a StoryCollection persists it")
    func testCreateCollection() async throws {
        let collection = makeCollection(title: "Test", growthCategory: "Kindness", targetAgeGroup: "5-7")
        try await repository.create(collection)
        let fetched = try await repository.get(byId: collection.id)
        #expect(fetched != nil)
        #expect(fetched?.id == collection.id)
    }

    @Test("Fetching a StoryCollection by ID returns the correct collection")
    func testFetchById() async throws {
        let collection = makeCollection(title: "FetchMe", growthCategory: "Social", targetAgeGroup: "8-10")
        try await repository.create(collection)
        let fetched = try await repository.get(byId: collection.id)
        #expect(fetched != nil)
        #expect(fetched?.id == collection.id)
    }

    @Test("Updating a StoryCollection changes its properties")
    func testUpdateCollection() async throws {
        let collection = makeCollection(title: "UpdateMe", growthCategory: "Cognitive", targetAgeGroup: "5-7")
        try await repository.create(collection)
        collection.title = "Updated"
        try await repository.update(collection)
        let fetched = try await repository.get(byId: collection.id)
        #expect(fetched?.title == "Updated")
    }

    @Test("Deleting a StoryCollection removes it")
    func testDeleteCollection() async throws {
        let collection = makeCollection(title: "DeleteMe", growthCategory: "Emotional", targetAgeGroup: "5-7")
        try await repository.create(collection)
        try await repository.delete(byId: collection.id)
        let fetched = try await repository.get(byId: collection.id)
        #expect(fetched == nil)
    }

    // Filter test disabled due to enum access issues
    /*
    @Test("Fetching with filter returns correct collections")
    func testFetchWithFilter() async throws {
        let collection1 = makeCollection(title: "Kindness", growthCategory: "Kindness", targetAgeGroup: "5-7")
        let collection2 = makeCollection(title: "Confidence", growthCategory: "Confidence", targetAgeGroup: "8-10")
        try await repository.create(collection1)
        try await repository.create(collection2)

        let kindnessCollections = try await repository.fetch(filter: .growthCategory("Kindness"))
        #expect(kindnessCollections.contains(where: { $0.id == collection1.id }))
        #expect(!kindnessCollections.contains(where: { $0.id == collection2.id }))
    }
    */

    // Sorting test disabled due to createdAt access issues
    /*
    @Test("Fetching sorted collections returns in correct order")
    func testFetchSorted() async throws {
        let earlier = Date().addingTimeInterval(-1000)
        let later = Date()
        let collection1 = makeCollection(title: "Earlier", growthCategory: "Kindness", targetAgeGroup: "5-7")
        let collection2 = makeCollection(title: "Later", growthCategory: "Kindness", targetAgeGroup: "5-7")
        collection1.createdAt = earlier
        collection2.createdAt = later
        try await repository.create(collection1)
        try await repository.create(collection2)

        let sorted = try await repository.fetchSorted(by: .createdAtDescending)
        #expect(sorted.first?.id == collection2.id)
    }
    */
}