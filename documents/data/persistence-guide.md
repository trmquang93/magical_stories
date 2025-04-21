# Persistence Implementation Guide: SwiftData

## 1. Overview
This document outlines the persistence strategy for the Magical Stories app, focusing on data storage, caching, and state management using **SwiftData** as the primary persistence framework, accessed via the **Repository Pattern**.

## 2. SwiftData Setup

### Model Container Configuration
The `ModelContainer` is configured centrally, defining the schema and storage options.

```swift
// PersistenceConfig.swift (or similar central location)
struct PersistenceConfig {
    static var modelContainer: ModelContainer = {
        // Define the SwiftData models included in the schema.
        // See documents/data/swift-data-schema.md for detailed model definitions.
        let schema = Schema([
            Story.self,         // Core story data
            // Add other planned @Model classes here:
            // StoryCollection.self,
            // Achievement.self,
            // UserProfile.self,
            // Page.self (if made a standalone @Model)
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false, // Use persistent storage
            cloudKitDatabase: .none      // CloudKit integration is a future consideration
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)") // Handle appropriately in production
        }
    }()
}
```

### App Integration
The `ModelContainer` is injected into the SwiftUI environment at the app's root.

```swift
// MagicalStoriesApp.swift
@main
struct MagicalStoriesApp: App {
    // Use the shared container instance
    let container = PersistenceConfig.modelContainer

    var body: some Scene {
        WindowGroup {
            RootView() // Or your main content view
                // Inject repositories/services initialized with the context
                // .environment(StoryRepository(modelContext: container.mainContext))
        }
        .modelContainer(container) // Make the container available to the environment
    }
}
```

## 3. Data Access Layer (Repository Pattern)

Data access is abstracted through repositories, decoupling services and UI from the underlying SwiftData implementation.

### Repository Protocol (Generic Example)
```swift
protocol Repository<T: PersistentModel> {
    associatedtype T
    var modelContext: ModelContext { get }

    func fetch(_ descriptor: FetchDescriptor<T>) async throws -> [T]
    func save(_ item: T) async throws
    func delete(_ item: T) async throws
    // Add other common methods like count, update, etc.
}

extension Repository {
    // Default implementations using modelContext
    func fetch(_ descriptor: FetchDescriptor<T>) async throws -> [T] {
        try modelContext.fetch(descriptor)
    }

    func save(_ item: T) async throws {
        modelContext.insert(item)
        try modelContext.save() // Consider saving strategy (immediate vs. batched)
    }

    func delete(_ item: T) async throws {
        modelContext.delete(item)
        try modelContext.save()
    }
}
```

### Concrete Repository Implementation (Example: StoryRepository)
```swift
class StoryRepository: Repository {
    typealias T = Story
    let modelContext: ModelContext

    // Initialized with a ModelContext (likely mainContext or a background context)
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // Can add specific query methods
    func fetchRecentStories(limit: Int = 10) async throws -> [Story] {
        var descriptor = FetchDescriptor<Story>(sortBy: [SortDescriptor(\.creationDate, order: .reverse)])
        descriptor.fetchLimit = limit
        return try await fetch(descriptor)
    }

    // Implement other specific methods...
}
```

## 4. Caching Strategy
Caching can improve performance for frequently accessed data, reducing load on the persistent store.

### Memory Cache (Example using Actor)
Suitable for short-term caching of recently viewed items.
```swift
actor SimpleMemoryCache<T: Identifiable> {
    private var cache: [T.ID: T] = [:]
    private let maxSize: Int

    init(maxSize: Int = 100) { self.maxSize = maxSize }

    func cache(_ item: T) {
        if cache.count >= maxSize, let oldestKey = cache.keys.first {
             cache.removeValue(forKey: oldestKey) // Simple eviction
        }
        cache[item.id] = item
    }
    func getCached(id: T.ID) -> T? { cache[id] }
    func clearCache() { cache.removeAll() }
}
```

### Persistent Cache (Example using File System)
Consider for larger data like images or generated content, though SwiftData handles blob storage. This might be more relevant for non-SwiftData assets.
```swift
// Example for caching non-SwiftData assets if needed
class FileSystemCache { /* ... Implementation ... */ }
```
*Note: SwiftData itself provides persistence. Explicit file system caching is less common for `@Model` data unless dealing with large binary blobs or external resources.*

## 5. State Management Integration
Repositories are typically used by services or view models, which then publish relevant state to the UI.

```swift
@MainActor
class LibraryViewModel: ObservableObject {
    private let storyRepository: StoryRepository // Injected
    @Published private(set) var stories: [Story] = []
    @Published var isLoading = false

    init(storyRepository: StoryRepository) {
        self.storyRepository = storyRepository
    }

    func loadStories() async {
        isLoading = true
        defer { isLoading = false }
        do {
            // Use specific repository method
            self.stories = try await storyRepository.fetchRecentStories()
        } catch {
            print("Error loading stories: \(error)")
            // Handle error state for UI
        }
    }
}
```

## 6. Error Handling
Define specific errors for persistence operations.

```swift
enum PersistenceError: LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case migrationFailed(String, Error?)
    // Add other specific errors

    var errorDescription: String? { /* ... Implementation ... */ }
}
```
Implement retry logic within repositories or services for transient errors.

## 7. Data Migration (UserDefaults -> SwiftData)

This section outlines the strategy for migrating existing story data stored in `UserDefaults` (by the legacy `PersistenceService`) to the new SwiftData store.

### 7.1. Strategy Overview
-   **Trigger:** Perform a one-time migration check when the app launches for the first time after updating to the version containing the SwiftData implementation.
-   **Mechanism:**
    1.  Check a flag in `UserDefaults` (e.g., `hasMigratedToSwiftData`). If `true`, skip migration.
    2.  If `false` or not present, initiate migration.
    3.  Instantiate the legacy `PersistenceService` to access `UserDefaults` data.
    4.  Fetch all existing stories from `UserDefaults`.
    5.  Instantiate the SwiftData `StoryRepository`.
    6.  Iterate through the fetched stories:
        *   Transform each story from the old format (likely `Codable` struct used by `UserDefaults`) into the new SwiftData `@Model` class (`Story`). Handle any schema differences (e.g., new fields, changed types).
        *   Save the transformed `@Model` object using `StoryRepository.save()`. Consider batching saves for performance if there are many stories.
    7.  Handle potential errors during fetching, transformation, or saving. Log errors extensively. Decide on error strategy (e.g., skip problematic stories, halt migration, inform user).
    8.  Upon successful completion of the loop, set the `hasMigratedToSwiftData` flag to `true` in `UserDefaults`.
    9.  Consider removing the old `UserDefaults` data after successful migration (optional, provides fallback if needed initially).
-   **User Experience:** Perform migration asynchronously in the background, possibly showing an indicator to the user if it takes significant time.

### 7.2. Implementation Sketch (`MigrationManager`)
```swift
class MigrationManager {
    private let legacyPersistence = PersistenceService() // Access UserDefaults
    private let storyRepository: StoryRepository       // Access SwiftData
    private let migrationKey = "hasMigratedToSwiftData"

    init(storyRepository: StoryRepository) {
        self.storyRepository = storyRepository
    }

    func migrateIfNeeded() async {
        guard !UserDefaults.standard.bool(forKey: migrationKey) else {
            print("Migration already completed.")
            return
        }

        print("Starting migration from UserDefaults to SwiftData...")
        do {
            let legacyStories = legacyPersistence.fetchAllStories() // Fetch from UserDefaults
            print("Found \(legacyStories.count) stories in UserDefaults.")

            for legacyStory in legacyStories {
                // --- Transformation Logic ---
                // Create a new SwiftData Story @Model instance
                // Map properties from legacyStory to the new Story model
                // Handle potential data inconsistencies or missing fields
                let newStory = Story(/* map properties from legacyStory */)
                // --- End Transformation ---

                try await storyRepository.save(newStory) // Save to SwiftData
            }

            UserDefaults.standard.set(true, forKey: migrationKey)
            print("Migration completed successfully.")
            // Optionally: legacyPersistence.deleteAllStories() // Clean up UserDefaults
        } catch {
            print("Migration failed: \(error)")
            // Log error, potentially notify user or retry later
            // Do NOT set the migrationKey flag if migration fails
        }
    }
}

// Call this early in the app lifecycle, e.g., in App init or RootView .task
// let migrationManager = MigrationManager(storyRepository: /* injected repo */)
// Task { await migrationManager.migrateIfNeeded() }
```

## 8. Performance Optimization
-   **Batch Operations:** Use `modelContext.save()` strategically, potentially after multiple insertions/deletions, rather than after every single operation.
-   **Query Optimization:** Use specific `FetchDescriptor` predicates and sort orders. Fetch only necessary properties if applicable (`FetchDescriptor.propertiesToFetch`). Set `includePendingChanges = false` for read-only fetches.
-   **Background Threads:** Perform lengthy fetches or migrations on background threads using `modelContext.perform`. Ensure UI updates happen on the main actor.

## 9. Testing
-   **Mock Repositories:** Use mock implementations of `Repository` protocols for testing services and view models without hitting the actual database.
-   **In-Memory Store:** Configure the `ModelContainer` with `isStoredInMemoryOnly: true` for integration tests that require a real SwiftData context but should not persist data between test runs.
-   **Migration Testing:** Create specific test scenarios with pre-populated `UserDefaults` data and verify the outcome after running the migration logic against an in-memory SwiftData store.

## 10. Best Practices
-   Use the Repository pattern for data access abstraction.
-   Implement appropriate caching.
-   Handle persistence errors gracefully.
-   Optimize queries and batch operations.
-   Test persistence logic thoroughly, including migrations.
-   Manage `ModelContext` lifecycle and threading carefully.

## [2025-04-20] Illustration Generation Persistence Update

- **Previous Image Context:**
  - When generating a new illustration, the service loads the previous page's image from `Application Support/Illustrations/` using the tracked relative path.
  - The image is base64-encoded and sent as `inline_data` in the Gemini 2.0 API request for visual consistency.
- **First Page or Missing Image:**
  - If no previous image is available, only the text prompt is sent.
- **Image Storage:**
  - Generated images are saved in `Application Support/Illustrations/` with a unique filename.
  - The relative path is returned and tracked for each page.
- **Fallback:**
  - Legacy Imagen API is used for single-image mode or as a fallback.

See `IllustrationService.swift` for implementation details.

---
This guide should be updated when the SwiftData schema changes, migration strategies evolve, or new persistence requirements emerge.
