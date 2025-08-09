import Foundation
import SwiftData

/// Fast startup loader for pre-made content
/// Loads content immediately on app startup since images are now in bundle resources
@MainActor
class StartupContentLoader: ObservableObject {
    
    private let persistenceService: any PersistenceServiceProtocol
    private let collectionService: CollectionService?
    
    @Published var isLoaded = false
    @Published var isLoading = false
    
    init(
        persistenceService: any PersistenceServiceProtocol,
        collectionService: CollectionService? = nil
    ) {
        self.persistenceService = persistenceService
        self.collectionService = collectionService
    }
    
    /// Load pre-made content on app startup
    /// This is now fast since images are in bundle resources
    func loadContentOnStartup(forceReload: Bool = false) async {
        print("[StartupContentLoader] ===== Starting app startup content load =====")
        
        // Debug bundle contents
        debugBundleContents()
        
        // Check if already loaded
        if isLoaded && !forceReload {
            print("[StartupContentLoader] Content already loaded, skipping")
            return
        }
        
        // Check if content exists in database (skip if forceReload is true)
        if !forceReload {
            let contentExists = await checkContentExists()
            if contentExists {
                print("[StartupContentLoader] Pre-made content already exists in database")
                isLoaded = true
                return
            }
        } else {
            print("[StartupContentLoader] Force reload requested, skipping database check")
        }
        
        isLoading = true
        
        do {
            print("[StartupContentLoader] Loading lightweight JSON...")
            
            // Load stories (now fast - text only)
            let stories = try await loadStoriesFromJSON()
            print("[StartupContentLoader] Loaded \(stories.count) stories")
            
            // Load collections
            let collections = try await loadCollectionsFromJSON()  
            print("[StartupContentLoader] Loaded \(collections.count) collections")
            
            // Save to database
            print("[StartupContentLoader] Saving to database...")
            try await saveToDatabase(stories: stories, collections: collections)
            
            isLoaded = true
            print("[StartupContentLoader] ===== Startup content load complete =====")
            
        } catch {
            print("[StartupContentLoader] ===== FAILED startup content load: \(error) =====")
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func debugBundleContents() {
        print("[StartupContentLoader] 🔍 Bundle Debugging:")
        print("[StartupContentLoader] Bundle path: \(Bundle.main.bundlePath)")
        
        if let resourcePath = Bundle.main.resourcePath {
            print("[StartupContentLoader] Resource path: \(resourcePath)")
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                print("[StartupContentLoader] Bundle root contents (\(contents.count) items):")
                for item in contents.sorted() {
                    print("[StartupContentLoader]   - \(item)")
                }
                
                // Check for specific files
                let jsonExists = contents.contains("premade_stories.json")
                let imagesExists = contents.contains("PreMadeImages")
                print("[StartupContentLoader] premade_stories.json in bundle: \(jsonExists ? "✅" : "❌")")
                print("[StartupContentLoader] PreMadeImages folder in bundle: \(imagesExists ? "✅" : "❌")")
                
            } catch {
                print("[StartupContentLoader] ❌ Error reading bundle contents: \(error)")
            }
        } else {
            print("[StartupContentLoader] ❌ No resource path found")
        }
    }
    
    private func checkContentExists() async -> Bool {
        do {
            let stories = try await persistenceService.loadStories()
            return !stories.isEmpty
        } catch {
            print("[StartupContentLoader] Error checking existing content: \(error)")
            return false
        }
    }
    
    private func loadStoriesFromJSON() async throws -> [Story] {
        print("[StartupContentLoader] Looking for premade_stories.json in bundle...")
        guard let url = Bundle.main.url(forResource: "premade_stories", withExtension: "json") else {
            print("[StartupContentLoader] ❌ premade_stories.json not found in bundle!")
            print("[StartupContentLoader] Bundle path: \(Bundle.main.bundlePath)")
            throw StartupContentError.fileNotFound("premade_stories.json")
        }
        
        print("[StartupContentLoader] ✅ Found premade_stories.json at: \(url.path)")
        let data = try Data(contentsOf: url)
        print("[StartupContentLoader] JSON size: \(data.count) bytes (lightweight!)")
        
        let stories = try JSONDecoder().decode([Story].self, from: data)
        print("[StartupContentLoader] ✅ Decoded \(stories.count) stories from JSON")
        
        // Verify bundle images exist (at root level, same as JSON files)
        var imagesFound = 0
        var imagesMissing = 0
        for story in stories {
            for page in story.pages {
                if let fileName = page.illustrationFileName {
                    if Bundle.main.url(forResource: fileName.replacingOccurrences(of: ".png", with: ""), 
                                      withExtension: "png") != nil {
                        imagesFound += 1
                    } else {
                        imagesMissing += 1
                        print("[StartupContentLoader] ⚠️ Bundle image not found: \(fileName)")
                    }
                }
            }
        }
        print("[StartupContentLoader] Bundle images: \(imagesFound) found, \(imagesMissing) missing")
        
        return stories
    }
    
    private func loadCollectionsFromJSON() async throws -> [StoryCollection] {
        guard let url = Bundle.main.url(forResource: "premade_collections", withExtension: "json") else {
            print("[StartupContentLoader] Warning: premade_collections.json not found in bundle")
            return [] // Return empty array instead of throwing
        }
        
        let data = try Data(contentsOf: url)
        print("[StartupContentLoader] Collections JSON size: \(data.count) bytes")
        
        let collections = try JSONDecoder().decode([StoryCollection].self, from: data)
        print("[StartupContentLoader] Decoded \(collections.count) collections from JSON")
        return collections
    }
    
    private func saveToDatabase(stories: [Story], collections: [StoryCollection]) async throws {
        // Save stories first
        for story in stories {
            try await persistenceService.saveStory(story)
        }
        
        // Resolve story IDs to actual Story objects for collections
        let storyMap = Dictionary(uniqueKeysWithValues: stories.map { ($0.id.uuidString, $0) })
        
        // Save collections with resolved story relationships
        if let collectionService = collectionService {
            for collection in collections {
                // Resolve storyIds to actual Story objects
                let resolvedStories = collection.storyIds.compactMap { storyId in
                    storyMap[storyId]
                }
                collection.stories = resolvedStories
                
                print("[StartupContentLoader] Collection '\(collection.title)': resolved \(resolvedStories.count)/\(collection.storyIds.count) stories")
                
                try collectionService.createCollection(collection)
            }
        }
    }
}

// MARK: - Error Types

enum StartupContentError: LocalizedError {
    case fileNotFound(String)
    case bundleImageMissing(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "Required file not found: \(filename)"
        case .bundleImageMissing(let filename):
            return "Bundle image not found: \(filename)"
        }
    }
}