import Foundation

@testable import magical_stories

// MARK: - In-Memory Collection Repository Mock

/// An in-memory mock of CollectionRepository for use in integration tests.
/// Supports create, fetch, get, update, delete, and filtering/sorting.
actor InMemoryCollectionRepository {
    private var collections: [StoryCollection] = []

    func create(_ collection: StoryCollection) async throws {
        // Remove any existing with same id, then append
        collections.removeAll { $0.id == collection.id }
        collections.append(collection)
    }

    func get(byId id: UUID) async throws -> StoryCollection? {
        return collections.first { $0.id == id }
    }

    func update(_ collection: StoryCollection) async throws {
        guard
            let idx =
                collections
                .firstIndex(where: { $0.id == collection.id })
        else {
            throw NSError(
                domain: "InMemoryCollectionRepository",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Collection not found"]
            )
        }
        collections[idx] = collection
    }

    func delete(byId id: UUID) async throws {
        collections.removeAll { $0.id == id }
    }

    func fetch(filter: CollectionFilter) async throws -> [StoryCollection] {
        switch filter {
        case let .growthCategory(category):
            return collections.filter { $0.growthCategory == category }
        case let .targetAgeGroup(ageGroup):
            return collections.filter { $0.targetAgeGroup == ageGroup }
        }
    }

    func fetchSorted(by sort: CollectionSort) async throws
        -> [StoryCollection]
    {
        switch sort {
        case .createdAtDescending:
            return
                collections
                .sorted {
                    ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast)
                }
        }
    }

    // Generic fetch for compatibility with FetchDescriptor (returns all)
    func fetch(_: Any? = nil) async throws -> [StoryCollection] {
        return collections
    }
}

// MARK: - MockStoryGenerationResponse

/// Minimal mock for story generation response used in tests.
struct MockStoryGenerationResponse {
    let text: String?
}

// MARK: - MockGenerativeModel

/// Mock generative model for simulating AI content generation.
class MockGenerativeModel {
    /// Handler to control the output of generateContent.
    var generateContentHandler: ((String) -> MockStoryGenerationResponse)?
    /// Optional result for alternate test patterns.
    var generateContentResult: Result<MockStoryGenerationResponse, Error>?

    func generateContent(prompt: String) -> MockStoryGenerationResponse {
        if let handler = generateContentHandler {
            return handler(prompt)
        }
        if let result = generateContentResult {
            switch result {
            case let .success(response): return response
            case .failure: return MockStoryGenerationResponse(text: nil)
            }
        }
        return MockStoryGenerationResponse(text: nil)
    }
}

// MARK: - MockPersistenceService

/// In-memory mock for PersistenceServiceProtocol.
class MockPersistenceService: PersistenceServiceProtocol {
    var storiesToLoad: [Story] = []
    var savedStories: [Story] = []
    var deletedStoryIds: [UUID] = []

    func saveStories(_ stories: [Story]) async throws {
        savedStories = stories
    }

    func loadStories() async throws -> [Story] {
        return storiesToLoad
    }

    func saveStory(_ story: Story) async throws {
        savedStories.append(story)
    }

    func deleteStory(withId id: UUID) async throws {
        deletedStoryIds.append(id)
        savedStories.removeAll { $0.id == id }
    }
}

// MARK: - MockCollectionService

/// Minimal mock for CollectionServiceProtocol.
@MainActor
class MockCollectionService: CollectionServiceProtocol {
    var collections: [GrowthCollection] = []
    var isGenerating: Bool = false

    // Handler closures for full customization in tests
    var generateCollectionHandler:
        (
            (CollectionParameters) async throws
                -> GrowthCollection
        )?
    var loadCollectionsHandler: (() async -> Void)?
    var updateProgressHandler: ((UUID, Float) async throws -> Void)?
    var deleteCollectionHandler: ((UUID) async throws -> Void)?
    var checkAchievementsHandler: ((UUID) async throws -> [Achievement])?

    func generateCollection(parameters: CollectionParameters) async throws
        -> GrowthCollection
    {
        if let handler = generateCollectionHandler {
            return try await handler(parameters)
        }
        return GrowthCollection(
            id: UUID(), title: "Mock", description: "Mock",
            theme: "Mock",
            targetAgeGroup: AgeGroup.threeToFive.rawValue, stories: []
        )
    }

    func loadCollections() async {
        if let handler = loadCollectionsHandler {
            await handler()
        }
    }

    func updateProgress(for collectionId: UUID, progress: Float) async throws {
        if let handler = updateProgressHandler {
            try await handler(collectionId, progress)
        }
    }

    func deleteCollection(_ collectionId: UUID) async throws {
        if let handler = deleteCollectionHandler {
            try await handler(collectionId)
        }
    }

    func checkAchievements(for collectionId: UUID) async throws
        -> [Achievement]
    {
        if let handler = checkAchievementsHandler {
            return try await handler(collectionId)
        }
        return []
    }
}

// MARK: - MockCollectionRepository

/// Minimal mock for a collection repository, can be expanded as needed.
class MockCollectionRepository {
    var collections: [StoryCollection] = []

    func add(_ collection: StoryCollection) {
        collections.append(collection)
    }

    func get(byId id: UUID) -> StoryCollection? {
        return collections.first { $0.id == id }
    }
}
