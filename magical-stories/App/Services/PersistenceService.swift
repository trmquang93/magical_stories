import Foundation

// MARK: - Persistence Error
enum PersistenceError: Error {
    case encodingFailed(Error)
    case decodingFailed(Error)
    case dataNotFound
}

// MARK: - Persistence Service
class PersistenceService: PersistenceServiceProtocol {
    private let userDefaults: UserDefaults
    private let storiesKey = "savedStories"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func saveStories(_ stories: [Story]) throws {
        do {
            let data = try encoder.encode(stories)
            userDefaults.set(data, forKey: storiesKey)
        } catch {
            throw PersistenceError.encodingFailed(error)
        }
    }

    func loadStories() throws -> [Story] {
        guard let data = userDefaults.data(forKey: storiesKey) else {
            // If no data is found, return an empty array (first launch scenario)
            return []
        }
        do {
            let stories = try decoder.decode([Story].self, from: data)
            // Sort stories by creation date, newest first
            // Corrected sorting: use 'timestamp' and add explicit types
            return stories.sorted { (story1: Story, story2: Story) in story1.timestamp > story2.timestamp }
        } catch {
            throw PersistenceError.decodingFailed(error)
        }
    }

    func saveStory(_ story: Story) throws {
        var currentStories = try loadStories()
        // Avoid duplicates if the story already exists (e.g., editing)
        if let index = currentStories.firstIndex(where: { $0.id == story.id }) {
            currentStories[index] = story
        } else {
            currentStories.append(story)
        }
        try saveStories(currentStories)
    }

    func deleteStory(withId id: UUID) throws {
        var currentStories = try loadStories()
        currentStories.removeAll { $0.id == id }
        try saveStories(currentStories)
    }
}

// MARK: - UserDefaults Keys
extension UserDefaults {
    private enum Keys {
        static let lastGeneratedStoryId = "lastGeneratedStoryId"
        static let storyGenerationCount = "storyGenerationCount"
        static let lastGenerationDate = "lastGenerationDate"
    }
    
    var lastGeneratedStoryId: UUID? {
        get { string(forKey: Keys.lastGeneratedStoryId).flatMap { UUID(uuidString: $0) } }
        set { set(newValue?.uuidString, forKey: Keys.lastGeneratedStoryId) }
    }
    
    var storyGenerationCount: Int {
        get { integer(forKey: Keys.storyGenerationCount) }
        set { set(newValue, forKey: Keys.storyGenerationCount) }
    }
    
    var lastGenerationDate: Date? {
        get { object(forKey: Keys.lastGenerationDate) as? Date }
        set { set(newValue, forKey: Keys.lastGenerationDate) }
    }
} 