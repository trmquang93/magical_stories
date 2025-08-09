import Foundation
import SwiftData

/// Loads pre-made stories and collections from bundled JSON files
/// This replaces the PreMadeContentProvider for production use
@MainActor
class PreMadeContentLoader: ObservableObject {
    
    private let persistenceService: any PersistenceServiceProtocol
    private let collectionService: CollectionService?
    
    @Published var isLoading = false
    @Published var loadProgress: String = ""
    @Published var progressPercentage: Double = 0.0
    
    init(
        persistenceService: any PersistenceServiceProtocol,
        collectionService: CollectionService? = nil
    ) {
        self.persistenceService = persistenceService
        self.collectionService = collectionService
    }
    
    // MARK: - Main Loading Method
    
    /// Loads pre-made content from JSON files if it doesn't already exist
    /// Now fast since images are in bundle resources, not JSON
    func loadPreMadeContentIfNeeded() async {
        print("[PreMadeContentLoader] ===== Starting loadPreMadeContentIfNeeded =====")
        
        // Check if content already exists
        let contentExists = await premadeContentExists()
        print("[PreMadeContentLoader] Content exists check: \(contentExists)")
        
        if contentExists {
            print("[PreMadeContentLoader] Pre-made content already exists, skipping load")
            return
        }
        
        print("[PreMadeContentLoader] No existing content found, proceeding with JSON load")
        isLoading = true
        loadProgress = "Loading pre-made content..."
        
        do {
            progressPercentage = 0.1
            print("[PreMadeContentLoader] Attempting to load stories from JSON...")
            // Load stories from JSON (now async)
            let stories = try await loadStoriesFromJSON()
            progressPercentage = 0.4
            loadProgress = "Loaded \(stories.count) stories from JSON"
            print("[PreMadeContentLoader] Successfully loaded \(stories.count) stories from JSON")
            
            print("[PreMadeContentLoader] Attempting to load collections from JSON...")
            // Load collections from JSON (now async)
            let collections = try await loadCollectionsFromJSON()
            progressPercentage = 0.6
            loadProgress = "Loaded \(collections.count) collections from JSON"
            print("[PreMadeContentLoader] Successfully loaded \(collections.count) collections from JSON")
            
            // Save to database
            print("[PreMadeContentLoader] Attempting to save to database...")
            loadProgress = "Saving to database..."
            progressPercentage = 0.7
            try await saveToDatabase(stories: stories, collections: collections)
            
            progressPercentage = 1.0
            loadProgress = "✅ Pre-made content loaded successfully"
            print("[PreMadeContentLoader] ===== Successfully completed loading \(stories.count) stories and \(collections.count) collections ====")
            
        } catch {
            progressPercentage = 0.0
            loadProgress = "❌ Failed to load pre-made content: \(error.localizedDescription)"
            print("[PreMadeContentLoader] ===== FAILED to load pre-made content: \(error) =====")
        }
        
        isLoading = false
    }
    
    // MARK: - JSON Loading
    
    private func loadStoriesFromJSON() async throws -> [Story] {
        print("[PreMadeContentLoader] Looking for premade_stories.json in bundle...")
        guard let url = Bundle.main.url(forResource: "premade_stories", withExtension: "json") else {
            print("[PreMadeContentLoader] ERROR: premade_stories.json not found in bundle")
            throw PreMadeContentError.fileNotFound("premade_stories.json")
        }
        
        print("[PreMadeContentLoader] Found premade_stories.json at: \(url.path)")
        
        // Move heavy operations off main thread
        // JSON is now lightweight (text-only), can load on main thread
        let data = try Data(contentsOf: url)
        print("[PreMadeContentLoader] Loaded \(data.count) bytes from lightweight JSON file")
        
        let stories = try JSONDecoder().decode([Story].self, from: data)
        print("[PreMadeContentLoader] Successfully decoded \(stories.count) stories from JSON")
        
        for story in stories {
            let imageCount = story.pages.filter { $0.illustrationFileName != nil }.count
            print("[PreMadeContentLoader] Story: '\(story.title)' with \(story.pages.count) pages (\(imageCount) with bundle images)")
        }
        
        return stories
    }
    
    private func loadCollectionsFromJSON() async throws -> [StoryCollection] {
        guard let url = Bundle.main.url(forResource: "premade_collections", withExtension: "json") else {
            throw PreMadeContentError.fileNotFound("premade_collections.json")
        }
        
        // Collections JSON is also lightweight
        let data = try Data(contentsOf: url)
        let collections = try JSONDecoder().decode([StoryCollection].self, from: data)
        
        print("[PreMadeContentLoader] Loaded \(collections.count) collections from JSON")
        return collections
    }
    
    // MARK: - Content Summary Loading
    
    /// Loads the content summary for debugging/verification
    func loadContentSummary() throws -> PreMadeContentSummary? {
        guard let url = Bundle.main.url(forResource: "premade_content_summary", withExtension: "json") else {
            return nil
        }
        
        let data = try Data(contentsOf: url)
        let summary = try JSONDecoder().decode(PreMadeContentSummary.self, from: data)
        
        print("[PreMadeContentLoader] Content summary: \(summary.stories.count) stories, \(summary.totalIllustrations) illustrations")
        return summary
    }
    
    // MARK: - Database Saving
    
    private func saveToDatabase(stories: [Story], collections: [StoryCollection]) async throws {
        print("[PreMadeContentLoader] Saving \(stories.count) stories to database...")
        
        // Save stories with progress updates
        let totalItems = stories.count + collections.count
        var completedItems = 0
        
        for (index, story) in stories.enumerated() {
            print("[PreMadeContentLoader] Saving story \(index + 1)/\(stories.count): '\(story.title)'")
            
            // Update progress on main thread
            await MainActor.run {
                loadProgress = "Saving story \(index + 1)/\(stories.count): \(story.title)"
                progressPercentage = 0.7 + (Double(completedItems) / Double(totalItems)) * 0.3
            }
            
            try await persistenceService.saveStory(story)
            completedItems += 1
        }
        print("[PreMadeContentLoader] Successfully saved all stories to database")
        
        // Save collections using CollectionService if available
        if let collectionService = collectionService {
            print("[PreMadeContentLoader] Saving \(collections.count) collections to database...")
            for (index, collection) in collections.enumerated() {
                print("[PreMadeContentLoader] Saving collection \(index + 1)/\(collections.count): '\(collection.title)'")
                
                // Update progress on main thread
                await MainActor.run {
                    loadProgress = "Saving collection \(index + 1)/\(collections.count): \(collection.title)"
                    progressPercentage = 0.7 + (Double(completedItems) / Double(totalItems)) * 0.3
                }
                
                try collectionService.createCollection(collection)
                completedItems += 1
            }
            print("[PreMadeContentLoader] Successfully saved all collections to database")
        } else {
            print("[PreMadeContentLoader] No CollectionService available, skipping collection save")
        }
    }
    
    // MARK: - Content Existence Check
    
    private func premadeContentExists() async -> Bool {
        do {
            let stories = try await persistenceService.loadStories()
            print("[PreMadeContentLoader] Found \(stories.count) existing stories in database")
            // Simply check if we have any stories - if database is empty, load from JSON
            return !stories.isEmpty
        } catch {
            print("[PreMadeContentLoader] Error checking existing content: \(error)")
            return false
        }
    }
    
    // MARK: - Validation Methods
    
    /// Validates that JSON files exist in the bundle
    func validateJSONFiles() -> ValidationResult {
        var results = ValidationResult()
        
        // Check stories file
        if Bundle.main.url(forResource: "premade_stories", withExtension: "json") != nil {
            results.storiesFileExists = true
        }
        
        // Check collections file
        if Bundle.main.url(forResource: "premade_collections", withExtension: "json") != nil {
            results.collectionsFileExists = true
        }
        
        // Check summary file
        if Bundle.main.url(forResource: "premade_content_summary", withExtension: "json") != nil {
            results.summaryFileExists = true
        }
        
        return results
    }
    
    /// Validates JSON file contents can be parsed
    func validateJSONContents() async -> ValidationResult {
        var results = validateJSONFiles()
        
        // Validate stories JSON
        if results.storiesFileExists {
            do {
                let stories = try await loadStoriesFromJSON()
                results.storiesCount = stories.count
                results.storiesValid = true
                
                // Count illustrations
                results.illustrationsCount = stories.flatMap { $0.pages }.filter { $0.hasEmbeddedIllustration }.count
                
            } catch {
                results.storiesError = error.localizedDescription
            }
        }
        
        // Validate collections JSON
        if results.collectionsFileExists {
            do {
                let collections = try await loadCollectionsFromJSON()
                results.collectionsCount = collections.count
                results.collectionsValid = true
            } catch {
                results.collectionsError = error.localizedDescription
            }
        }
        
        // Validate summary JSON
        if results.summaryFileExists {
            do {
                let summary = try loadContentSummary()
                results.summaryValid = (summary != nil)
            } catch {
                results.summaryError = error.localizedDescription
            }
        }
        
        return results
    }
}

// MARK: - Error Types

enum PreMadeContentError: LocalizedError {
    case fileNotFound(String)
    case invalidJSON(String)
    case databaseError(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "JSON file not found: \(filename)"
        case .invalidJSON(let details):
            return "Invalid JSON format: \(details)"
        case .databaseError(let details):
            return "Database error: \(details)"
        }
    }
}

// MARK: - Validation Result

struct ValidationResult {
    var storiesFileExists = false
    var collectionsFileExists = false
    var summaryFileExists = false
    
    var storiesValid = false
    var collectionsValid = false
    var summaryValid = false
    
    var storiesCount = 0
    var collectionsCount = 0
    var illustrationsCount = 0
    
    var storiesError: String?
    var collectionsError: String?
    var summaryError: String?
    
    var isValid: Bool {
        return storiesFileExists && collectionsFileExists && 
               storiesValid && collectionsValid &&
               storiesCount > 0 && collectionsCount > 0
    }
    
    var summary: String {
        if isValid {
            return "✅ All JSON files valid: \(storiesCount) stories, \(collectionsCount) collections, \(illustrationsCount) illustrations"
        } else {
            var issues: [String] = []
            if !storiesFileExists { issues.append("Stories file missing") }
            if !collectionsFileExists { issues.append("Collections file missing") }
            if !storiesValid { issues.append("Stories JSON invalid") }
            if !collectionsValid { issues.append("Collections JSON invalid") }
            if let error = storiesError { issues.append("Stories error: \(error)") }
            if let error = collectionsError { issues.append("Collections error: \(error)") }
            return "❌ Issues found: \(issues.joined(separator: ", "))"
        }
    }
}