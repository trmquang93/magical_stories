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

    // Updated fetch method to use category and ageGroup instead of growthCategory and targetAgeGroup
    func fetch(filter: String) async throws -> [StoryCollection] {
        // Since we don't have a CollectionFilter enum yet, we'll just do a simple string match
        return collections.filter { $0.title.contains(filter) || $0.category.contains(filter) }
    }

    func fetchSorted() async throws -> [StoryCollection] {
        return collections.sorted {
            $0.createdAt > $1.createdAt
        }
    }

    // Generic fetch for compatibility with FetchDescriptor (returns all)
    func fetch(_: Any? = nil) async throws -> [StoryCollection] {
        return collections
    }
}

// MARK: - MockStoryGenerationResponse

/// Minimal mock for story generation response used in tests.
struct MockStoryGenerationResponse: StoryGenerationResponse {
    let text: String?
}

// MARK: - MockGenerativeModel

/// Mock generative model for simulating AI content generation.
class MockGenerativeModel: GenerativeModelProtocol {
    var generatedText: String?
    var error: Error?
    var lastPrompt: String?
    /// Handler to control the output of generateContent.
    var generateContentHandler: ((String) -> MockStoryGenerationResponse)?
    /// Optional result for alternate test patterns.
    var generateContentResult: Result<MockStoryGenerationResponse, Error>?
    /// Tracks if generateContent was called
    var generateContentCalled: Bool = false

    // Protocol requirement: async throws -> StoryGenerationResponse
    func generateContent(_ prompt: String) async throws -> StoryGenerationResponse {
        lastPrompt = prompt
        if let error = error {
            throw error
        }
        if let generatedText {
            return MockStoryGenerationResponse(text: generatedText)
        }
        generateContentCalled = true
        if let handler = generateContentHandler {
            return handler(prompt)
        }
        if let result = generateContentResult {
            switch result {
            case let .success(response): return response
            case let .failure(error): throw error
            }
        }
        return MockStoryGenerationResponse(text: nil)
    }

    // For legacy sync test usage (if any)
    func generateContent(prompt: String) -> MockStoryGenerationResponse {
        generateContentCalled = true
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

// MARK: - MockCollectionService

/// Minimal mock for CollectionServiceProtocol.
class CollectionServiceMock: CollectionServiceProtocol {
    var collections: [StoryCollection] = []

    // Handler closures for testing callbacks
    var updateProgressHandler: ((UUID, Float) async throws -> Void)?
    var checkAchievementsHandler: ((UUID) async throws -> [Achievement])?

    // Core CollectionServiceProtocol methods
    func createCollection(_ collection: StoryCollection) throws {
        collections.append(collection)
    }

    func fetchCollection(id: UUID) throws -> StoryCollection? {
        return collections.first { $0.id == id }
    }

    func fetchAllCollections() throws -> [StoryCollection] {
        return collections
    }

    func updateCollectionProgress(id: UUID, progress: Float) throws {
        if let index = collections.firstIndex(where: { $0.id == id }) {
            collections[index].completionProgress = Double(progress)
        }
    }

    func deleteCollection(id: UUID) throws {
        collections.removeAll { $0.id == id }
    }

    // Additional methods needed for StoryDetailViewTests
    func updateProgress(for collectionId: UUID, progress: Float) async throws {
        if let handler = updateProgressHandler {
            try await handler(collectionId, progress)
        } else {
            // Default implementation if no handler is set
            if let index = collections.firstIndex(where: { $0.id == collectionId }) {
                collections[index].completionProgress = Double(progress)
            }
        }
    }

    func checkAchievements(for collectionId: UUID) async throws -> [Achievement] {
        if let handler = checkAchievementsHandler {
            return try await handler(collectionId)
        }
        return []  // Default empty array if no handler
    }

    // Method to simulate loadCollections from the real CollectionService
    func loadCollections(forceReload: Bool = false) {
        // This mock implementation just keeps the collections as is
        // No need to do anything since the collections are already set directly in the test
    }
}

// MARK: - MockAIService
/// Mock AI service for testing
class MockAIService {
    var generateStoryShouldFail = false
    var generateIllustrationShouldFail = false
    var generatedStoryContent = "Once upon a time..."
    var generatedIllustrationPath = "path/to/illustration.png"

    func generateStory(parameters: StoryParameters) async throws -> String {
        if generateStoryShouldFail {
            throw NSError(
                domain: "MockAIService", code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Story generation failed"])
        }
        return generatedStoryContent
    }

    func generateIllustration(for pageText: String, theme: String) async throws -> String? {
        if generateIllustrationShouldFail {
            throw NSError(
                domain: "MockAIService", code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Illustration generation failed"])
        }
        return generatedIllustrationPath
    }
}
