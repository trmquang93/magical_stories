import Foundation
import SwiftData

// MARK: - Persistence Service Protocol
protocol PersistenceServiceProtocol {
    func saveStory(_ story: Story) async throws
    func loadStories() async throws -> [Story]
    func deleteStory(_ story: Story) async throws
    func deleteAllStories() async throws
}

// MARK: - Persistence Service
actor PersistenceService: PersistenceServiceProtocol {
    private let container: ModelContainer
    private let context: ModelContext
    
    init() {
        do {
            let schema = Schema([Story.self])
            let modelConfiguration = ModelConfiguration(schema: schema)
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            context = ModelContext(container)
        } catch {
            fatalError("Failed to initialize SwiftData: \(error)")
        }
    }
    
    func saveStory(_ story: Story) async throws {
        context.insert(story)
        try context.save()
    }
    
    func loadStories() async throws -> [Story] {
        let descriptor = FetchDescriptor<Story>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    func deleteStory(_ story: Story) async throws {
        context.delete(story)
        try context.save()
    }
    
    func deleteAllStories() async throws {
        let descriptor = FetchDescriptor<Story>()
        let stories = try context.fetch(descriptor)
        stories.forEach { context.delete($0) }
        try context.save()
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