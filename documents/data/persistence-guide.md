# Persistence Implementation Guide

## Overview
This document outlines the persistence strategy for the Magical Stories app, focusing on data storage, caching, and state management using SwiftData.

## SwiftData Setup

### Model Container Configuration
```swift
struct PersistenceConfig {
    static var modelContainer: ModelContainer = {
        let schema = Schema([
            Story.self,
            StoryCollection.self,
            Achievement.self,
            UserProfile.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none // Consider CloudKit for future versions
        )
        
        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
```

### App Integration
```swift
@main
struct MagicalStoriesApp: App {
    let container: ModelContainer
    
    init() {
        container = PersistenceConfig.modelContainer
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
```

## Data Access Layer

### Repository Protocol
```swift
protocol Repository<T> {
    associatedtype T
    
    func fetch(_ descriptor: FetchDescriptor<T>) async throws -> [T]
    func save(_ item: T) async throws
    func delete(_ item: T) async throws
    func update(_ item: T) async throws
}
```

### Story Repository Implementation
```swift
class StoryRepository: Repository {
    typealias T = Story
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetch(_ descriptor: FetchDescriptor<Story>) async throws -> [Story] {
        try await modelContext.perform {
            try self.modelContext.fetch(descriptor)
        }
    }
    
    func save(_ story: Story) async throws {
        try await modelContext.perform {
            self.modelContext.insert(story)
            try self.modelContext.save()
        }
    }
    
    // Additional implementation...
}
```

## Caching Strategy

### Memory Cache
```swift
actor StoryCache {
    private var cache: [UUID: Story] = [:]
    private let maxSize = 100
    
    func cache(_ story: Story) {
        if cache.count >= maxSize {
            cache.removeValue(forKey: cache.keys.first!)
        }
        cache[story.id] = story
    }
    
    func getCached(id: UUID) -> Story? {
        cache[id]
    }
    
    func clearCache() {
        cache.removeAll()
    }
}
```

### Persistent Cache
```swift
class PersistentCache {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    init() throws {
        cacheDirectory = try fileManager
            .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("StoryCache")
        
        try fileManager.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
    }
    
    func cacheStory(_ story: Story) throws {
        let url = cacheDirectory.appendingPathComponent(story.id.uuidString)
        let data = try JSONEncoder().encode(story)
        try data.write(to: url)
    }
    
    func getCachedStory(id: UUID) throws -> Story? {
        let url = cacheDirectory.appendingPathComponent(id.uuidString)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Story.self, from: data)
    }
}
```

## State Management

### Observable Storage
```swift
@MainActor
class StoryStorage: ObservableObject {
    private let repository: StoryRepository
    private let cache: StoryCache
    
    @Published private(set) var recentStories: [Story] = []
    @Published private(set) var isLoading = false
    
    init(repository: StoryRepository, cache: StoryCache) {
        self.repository = repository
        self.cache = cache
    }
    
    func loadRecentStories() async throws {
        isLoading = true
        defer { isLoading = false }
        
        let stories = try await repository.fetch(Story.recentStories())
        await MainActor.run {
            self.recentStories = stories
        }
        
        // Cache stories
        for story in stories {
            await cache.cache(story)
        }
    }
}
```

## Error Handling

### Persistence Errors
```swift
enum PersistenceError: LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case cacheFailed(Error)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .cacheFailed(let error):
            return "Cache operation failed: \(error.localizedDescription)"
        case .invalidData:
            return "The data is invalid or corrupted"
        }
    }
}
```

### Error Recovery
```swift
extension StoryRepository {
    func saveWithRetry(_ story: Story, attempts: Int = 3) async throws {
        var lastError: Error?
        
        for attempt in 1...attempts {
            do {
                try await save(story)
                return
            } catch {
                lastError = error
                if attempt < attempts {
                    try await Task.sleep(nanoseconds: UInt64(1_000_000_000 * attempt))
                }
            }
        }
        
        throw PersistenceError.saveFailed(lastError ?? PersistenceError.invalidData)
    }
}
```

## Data Migration

### Migration Manager
```swift
class MigrationManager {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func migrateIfNeeded() async throws {
        let currentVersion = try await getCurrentVersion()
        let targetVersion = SchemaVersion.v2
        
        guard currentVersion.rawValue < targetVersion.rawValue else { return }
        
        try await migrate(from: currentVersion, to: targetVersion)
    }
    
    private func migrate(
        from currentVersion: SchemaVersion,
        to targetVersion: SchemaVersion
    ) async throws {
        switch (currentVersion, targetVersion) {
        case (.v1, .v2):
            try await migrateV1ToV2()
        default:
            break
        }
    }
    
    private func migrateV1ToV2() async throws {
        // Implementation details...
    }
}
```

## Performance Optimization

### Batch Operations
```swift
extension StoryRepository {
    func batchSave(_ stories: [Story]) async throws {
        try await modelContext.perform {
            for story in stories {
                self.modelContext.insert(story)
            }
            try self.modelContext.save()
        }
    }
    
    func batchDelete(_ stories: [Story]) async throws {
        try await modelContext.perform {
            for story in stories {
                self.modelContext.delete(story)
            }
            try self.modelContext.save()
        }
    }
}
```

### Query Optimization
```swift
extension StoryRepository {
    func fetchOptimized(_ descriptor: FetchDescriptor<Story>) async throws -> [Story] {
        var optimizedDescriptor = descriptor
        optimizedDescriptor.includePendingChanges = false
        
        return try await modelContext.perform {
            try self.modelContext.fetch(optimizedDescriptor)
        }
    }
}
```

## Testing

### Mock Repository
```swift
class MockStoryRepository: Repository {
    typealias T = Story
    private var stories: [Story] = []
    
    func fetch(_ descriptor: FetchDescriptor<Story>) async throws -> [Story] {
        stories
    }
    
    func save(_ story: Story) async throws {
        stories.append(story)
    }
    
    func delete(_ story: Story) async throws {
        stories.removeAll { $0.id == story.id }
    }
}
```

### Test Examples
```swift
class PersistenceTests: XCTestCase {
    var repository: MockStoryRepository!
    var storage: StoryStorage!
    
    override func setUp() {
        super.setUp()
        repository = MockStoryRepository()
        storage = StoryStorage(repository: repository)
    }
    
    func testStorySave() async throws {
        let story = Story(title: "Test", content: "Content")
        try await repository.save(story)
        
        let stories = try await repository.fetch(Story.recentStories())
        XCTAssertEqual(stories.count, 1)
        XCTAssertEqual(stories.first?.title, "Test")
    }
}
```

## Best Practices

1. **Data Access**
   - Use repository pattern for all data access
   - Implement caching for frequently accessed data
   - Use batch operations for multiple items
   - Handle errors gracefully

2. **Performance**
   - Monitor memory usage
   - Implement proper caching strategies
   - Use batch operations when possible
   - Optimize queries with appropriate descriptors

3. **Testing**
   - Create mock repositories for testing
   - Test error conditions
   - Verify data integrity
   - Test migration paths

4. **Maintenance**
   - Regular backup strategies
   - Clear cache periodically
   - Monitor storage usage
   - Log important operations

---

This guide should be updated when:
- Persistence strategy changes
- New storage requirements emerge
- Performance optimizations are implemented
- Cache policies are modified
