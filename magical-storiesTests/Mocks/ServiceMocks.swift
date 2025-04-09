// MARK: - Mock Story Generation Response
struct MockStoryGenerationResponse: StoryGenerationResponse {
    var text: String?
}

// MARK: - Mock Generative Model
class MockGenerativeModel: GenerativeModelProtocol {
    var generateContentHandler: ((String) async throws -> StoryGenerationResponse)?
    var generateContentCallCount = 0
    var generateContentLastPrompt: String?
    
    func generateContent(_ prompt: String) async throws -> StoryGenerationResponse {
        generateContentCallCount += 1
        generateContentLastPrompt = prompt
        if let handler = generateContentHandler {
            return try await handler(prompt)
        } else {
            // Default mock response or throw error if not configured
            return MockStoryGenerationResponse(text: "{\"title\":\"Default Mock Title\", \"description\":\"Mock Desc\", \"storyOutlines\":[]}") // Basic valid JSON
        }
    }
}

// MARK: - Mock Story Service
@MainActor
class MockStoryService: StoryServiceProtocol {
    var stories: [Story] = []
    var isGenerating: Bool = false
    
    var generateStoryHandler: ((StoryParameters) async throws -> Story)?
    var loadStoriesHandler: (() async -> Void)?
    
    func generateStory(parameters: StoryParameters) async throws -> Story {
        if let handler = generateStoryHandler {
            return try await handler(parameters)
        } else {
            // Return a default mock story
            return Story.previewStory(title: "Generated Mock Story")
        }
    }
    
    func loadStories() async {
        await loadStoriesHandler?()
    }
}

// MARK: - Mock Persistence Service
class MockPersistenceService: PersistenceServiceProtocol {
    var savedStories: [UUID: Story] = [:]
    var savedCollections: [UUID: GrowthCollection] = [:]
    var savedAchievements: [UUID: Achievement] = [:]
    
    var saveStoryError: Error? = nil
    var loadStoriesError: Error? = nil
    var saveCollectionError: Error? = nil
    var fetchAllCollectionsError: Error? = nil
    var updateCollectionProgressError: Error? = nil
    var deleteCollectionError: Error? = nil
    var fetchAchievementError: Error? = nil
    var saveAchievementError: Error? = nil
    
    func saveStories(_ stories: [Story]) async throws { /* Simplified */ }
    
    func loadStories() async throws -> [Story] {
        if let error = loadStoriesError { throw error }
        return Array(savedStories.values)
    }
    
    func saveStory(_ story: Story) async throws {
        if let error = saveStoryError { throw error }
        savedStories[story.id] = story
    }
    
    func deleteStory(withId id: UUID) async throws { savedStories.removeValue(forKey: id) }
    
    // --- Collection Methods ---
    func saveCollection(_ collection: GrowthCollection) async throws {
        if let error = saveCollectionError { throw error }
        savedCollections[collection.id] = collection
    }
    
    func fetchAllCollections() async throws -> [GrowthCollection] {
        if let error = fetchAllCollectionsError { throw error }
        return Array(savedCollections.values)
    }
    
    func updateCollectionProgress(id: UUID, progress: Float) async throws {
        if let error = updateCollectionProgressError { throw error }
        guard savedCollections[id] != nil else { throw CollectionError.collectionNotFound }
        savedCollections[id]?.progress = progress
    }
    
    func deleteCollection(id: UUID) async throws {
        if let error = deleteCollectionError { throw error }
        savedCollections.removeValue(forKey: id)
    }
    
    // --- Achievement Methods ---
    func fetchAchievement(id: UUID) async throws -> Achievement {
        if let error = fetchAchievementError { throw error }
        guard let achievement = savedAchievements[id] else { throw MockError.notFound }
        return achievement
    }
    
    func saveAchievement(_ achievement: Achievement) async throws {
        if let error = saveAchievementError { throw error }
        savedAchievements[achievement.id] = achievement
    }
    
    func fetchAllAchievements() async throws -> [Achievement] {
        return Array(savedAchievements.values)
    }
}

enum MockError: Error {
    case notFound
} 