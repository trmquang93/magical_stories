import Foundation
import SwiftData

/// Generates pre-made stories using actual AI API calls, then exports to JSON for bundling with the app
/// This service is intended for one-time use to create the initial pre-made content
@MainActor
class PreMadeContentGenerator: ObservableObject {
    
    private let storyService: StoryService
    private let collectionService: CollectionService
    private let illustrationService: SimpleIllustrationService
    private let persistenceService: PersistenceService
    
    @Published var isGenerating = false
    @Published var progress: String = ""
    @Published var generatedStories: [Story] = []
    @Published var generatedCollections: [StoryCollection] = []
    
    init(
        storyService: StoryService,
        collectionService: CollectionService,
        illustrationService: SimpleIllustrationService,
        persistenceService: PersistenceService
    ) {
        self.storyService = storyService
        self.collectionService = collectionService
        self.illustrationService = illustrationService
        self.persistenceService = persistenceService
    }
    
    // MARK: - Predefined Story Parameters
    
    private func getStoryParameters() -> [StoryParameters] {
        return [
            // Story 1: Luna's Moonbeam Adventure
            StoryParameters(
                theme: "Magical Adventure",
                childAge: 5,
                childName: "Luna",
                favoriteCharacter: "Moonbeam Cat",
                storyLength: "medium",
                developmentalFocus: [.emotionalIntelligence, .problemSolving],
                interactiveElements: true,
                emotionalThemes: ["courage", "empathy"],
                languageCode: "en"
            ),
            
            // Story 2: Max's Robot Friend
            StoryParameters(
                theme: "Science & Technology",
                childAge: 6,
                childName: "Max",
                favoriteCharacter: "Helper Robot",
                storyLength: "medium",
                developmentalFocus: [.creativityImagination, .problemSolving],
                interactiveElements: true,
                emotionalThemes: ["curiosity", "friendship"],
                languageCode: "en"
            ),
            
            // Story 3: Zoe's Ocean Discovery
            StoryParameters(
                theme: "Ocean Adventure",
                childAge: 4,
                childName: "Zoe",
                favoriteCharacter: "Friendly Dolphin",
                storyLength: "medium",
                developmentalFocus: [.socialSkills, .kindnessEmpathy],
                interactiveElements: true,
                emotionalThemes: ["wonder", "responsibility"],
                languageCode: "en"
            ),
            
            // Story 4: Kai's Garden Kingdom
            StoryParameters(
                theme: "Nature & Growth",
                childAge: 7,
                childName: "Kai",
                favoriteCharacter: "Wise Tree",
                storyLength: "medium",
                developmentalFocus: [.resilienceGrit, .kindnessEmpathy],
                interactiveElements: true,
                emotionalThemes: ["patience", "nurturing"],
                languageCode: "en"
            ),
            
            // Story 5: Mia's Musical Journey
            StoryParameters(
                theme: "Music & Arts",
                childAge: 5,
                childName: "Mia",
                favoriteCharacter: "Singing Bird",
                storyLength: "medium",
                developmentalFocus: [.creativityImagination, .socialSkills],
                interactiveElements: true,
                emotionalThemes: ["confidence", "self-expression"],
                languageCode: "en"
            )
        ]
    }
    
    // MARK: - Main Generation Method
    
    /// Generates all pre-made content using AI APIs
    func generateAllPreMadeContent() async {
        guard !isGenerating else { return }
        
        isGenerating = true
        progress = "Starting generation..."
        generatedStories = []
        generatedCollections = []
        
        do {
            // Step 1: Generate stories using AI
            progress = "Generating stories with AI..."
            let stories = try await generateStoriesWithAI()
            
            // Step 2: Generate illustrations for all pages
            progress = "Generating illustrations..."
            try await generateIllustrationsForStories(stories)
            
            // Step 3: Generate collections
            progress = "Generating collections..."
            let collections = try await generateCollections(with: stories)
            
            // Step 4: Save to database
            progress = "Saving to database..."
            try await saveGeneratedContent(stories: stories, collections: collections)
            
            generatedStories = stories
            generatedCollections = collections
            
            progress = "✅ Generation complete! Ready to export JSON."
            
        } catch {
            progress = "❌ Generation failed: \(error.localizedDescription)"
            print("[PreMadeContentGenerator] Generation failed: \(error)")
        }
        
        isGenerating = false
    }
    
    // MARK: - Story Generation
    
    private func generateStoriesWithAI() async throws -> [Story] {
        let storyParameters = getStoryParameters()
        var stories: [Story] = []
        
        for (index, parameters) in storyParameters.enumerated() {
            progress = "Generating story \(index + 1)/\(storyParameters.count): \(parameters.childName ?? "Unknown")'s story..."
            
            let story = try await storyService.generateStory(parameters: parameters)
            stories.append(story)
            
            // Small delay between generations to avoid overwhelming the API
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        }
        
        return stories
    }
    
    // MARK: - Illustration Generation
    
    private func generateIllustrationsForStories(_ stories: [Story]) async throws {
        var totalPages = 0
        var completedPages = 0
        
        // Count total pages
        for story in stories {
            totalPages += story.pages.count
        }
        
        for story in stories {
            // Generate character references first for consistency
            if let characterNames = story.characterNames, !characterNames.isEmpty {
                progress = "Generating character references for \(story.title)..."
                try await generateCharacterReferences(for: story)
            }
            
            // Generate illustrations for each page
            for page in story.pages {
                completedPages += 1
                progress = "Generating illustration \(completedPages)/\(totalPages) - \(story.title) page \(page.pageNumber)..."
                
                try await generateIllustrationForPage(page, in: story)
                
                // Small delay between illustrations
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
        }
    }
    
    private func generateCharacterReferences(for story: Story) async throws {
        // Generate character references using the existing service
        do {
            try await storyService.generateCharacterReferences(for: story)
        } catch {
            print("[PreMadeContentGenerator] Failed to generate character references for \(story.title): \(error)")
            // Continue even if character references fail
        }
    }
    
    private func generateIllustrationForPage(_ page: Page, in story: Story) async throws {
        // Skip if illustration already exists
        guard page.illustrationStatus != .ready else { return }
        
        // Set status to generating
        page.illustrationStatus = .generating
        
        do {
            // Generate illustration using the existing service and get the data
            let illustrationData = try await illustrationService.generateIllustration(
                for: page,
                in: story
            )
            
            // Save the illustration data to the page
            page.setEmbeddedIllustration(data: illustrationData, mimeType: "image/png")
            
            print("[PreMadeContentGenerator] Successfully generated and saved illustration for page \(page.pageNumber) in \(story.title) (\(illustrationData.count) bytes)")
            
        } catch {
            page.illustrationStatus = .failed
            print("[PreMadeContentGenerator] Error generating illustration for page \(page.pageNumber) in \(story.title): \(error)")
            // Continue with other pages even if one fails
        }
    }
    
    // MARK: - Collection Generation
    
    private func generateCollections(with stories: [Story]) async throws -> [StoryCollection] {
        var collections: [StoryCollection] = []
        
        // Collection 1: Emotional Heroes Journey
        let emotionalStories = stories.filter { story in
            guard let developmentalFocus = story.parameters.developmentalFocus else { return false }
            return developmentalFocus.contains(.emotionalIntelligence) || 
                   developmentalFocus.contains(.socialSkills)
        }
        
        let emotionalCollection = StoryCollection(
            title: "Emotional Heroes Journey",
            descriptionText: "Stories that help children understand feelings, show empathy, and build strong friendships. These adventures teach emotional intelligence through caring characters and meaningful connections.",
            category: "Emotional Intelligence",
            ageGroup: "Ages 4-7",
            stories: emotionalStories
        )
        
        collections.append(emotionalCollection)
        
        // Collection 2: Creative Adventures
        let creativeStories = stories.filter { story in
            guard let developmentalFocus = story.parameters.developmentalFocus else { return false }
            return developmentalFocus.contains(.creativityImagination) || 
                   developmentalFocus.contains(.problemSolving)
        }
        
        let creativeCollection = StoryCollection(
            title: "Creative Adventures",
            descriptionText: "Adventures that inspire creativity, innovation, and clever problem-solving. These stories show children how to think outside the box and find unique solutions.",
            category: "Creativity & Problem Solving",
            ageGroup: "Ages 5-7",
            stories: creativeStories
        )
        
        collections.append(creativeCollection)
        
        // Collection 3: Nature Explorers
        let natureStories = stories.filter { story in
            guard let developmentalFocus = story.parameters.developmentalFocus else { return false }
            return developmentalFocus.contains(.kindnessEmpathy) || 
                   story.parameters.theme.contains("Nature") ||
                   story.parameters.theme.contains("Ocean")
        }
        
        let natureCollection = StoryCollection(
            title: "Nature Explorers",
            descriptionText: "Discover the wonders of nature through exciting adventures. These stories foster environmental awareness, patience, and respect for the natural world around us.",
            category: "Nature & Environment",
            ageGroup: "Ages 4-8",
            stories: natureStories
        )
        
        collections.append(natureCollection)
        
        return collections
    }
    
    // MARK: - Save Generated Content
    
    private func saveGeneratedContent(stories: [Story], collections: [StoryCollection]) async throws {
        // Save stories
        for story in stories {
            try await persistenceService.saveStory(story)
        }
        
        // Save collections
        for collection in collections {
            try collectionService.createCollection(collection)
        }
    }
    
    // MARK: - JSON Export
    
    /// Exports generated content to JSON files
    func exportToJSON() async throws -> [String: Data] {
        guard !generatedStories.isEmpty else {
            throw NSError(domain: "PreMadeContentGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "No generated content to export"])
        }
        
        progress = "Exporting to JSON..."
        
        var jsonFiles: [String: Data] = [:]
        
        // Create JSON-safe copies that break circular references
        let jsonSafeStories = generatedStories.map { createJSONSafeStory(from: $0) }
        let jsonSafeCollections = generatedCollections.map { createJSONSafeCollection(from: $0) }
        
        // Export stories
        let storiesData = try JSONEncoder().encode(jsonSafeStories)
        jsonFiles["premade_stories.json"] = storiesData
        
        // Export collections  
        let collectionsData = try JSONEncoder().encode(jsonSafeCollections)
        jsonFiles["premade_collections.json"] = collectionsData
        
        // Create summary file
        let summary = PreMadeContentSummary(
            stories: generatedStories.map { story in
                StorySummary(
                    id: story.id,
                    title: story.title,
                    pageCount: story.pages.count,
                    illustrationsGenerated: story.pages.filter { $0.illustrationStatus == .ready }.count,
                    developmentalFocus: story.parameters.developmentalFocus?.map { $0.rawValue } ?? [],
                    generatedAt: Date()
                )
            },
            collections: generatedCollections.map { collection in
                CollectionSummary(
                    id: collection.id,
                    title: collection.title,
                    storyCount: collection.stories?.count ?? 0,
                    category: collection.category
                )
            },
            exportedAt: Date(),
            totalIllustrations: generatedStories.flatMap { $0.pages }.filter { $0.illustrationStatus == .ready }.count
        )
        
        let summaryData = try JSONEncoder().encode(summary)
        jsonFiles["premade_content_summary.json"] = summaryData
        
        progress = "✅ JSON export complete!"
        
        return jsonFiles
    }
    
    // MARK: - File Writing Helper
    
    /// Writes JSON files to Documents directory for easy access
    func writeJSONFilesToDocuments() async throws {
        print("[PreMadeContentGenerator] 🚀 Starting JSON export process...")
        
        // Check if we have generated content
        guard !generatedStories.isEmpty else {
            print("[PreMadeContentGenerator] ❌ No generated stories to export!")
            progress = "❌ No generated content to export. Generate content first!"
            return
        }
        
        print("[PreMadeContentGenerator] 📊 Content to export:")
        print("[PreMadeContentGenerator]   - Stories: \(generatedStories.count)")
        print("[PreMadeContentGenerator]   - Collections: \(generatedCollections.count)")
        
        do {
            let jsonFiles = try await exportToJSON()
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            
            // Ensure documents directory exists
            try FileManager.default.createDirectory(at: documentsPath, withIntermediateDirectories: true, attributes: nil)
            
            print("\n" + String(repeating: "=", count: 80))
            print("📁 JSON FILES LOCATION")
            print(String(repeating: "=", count: 80))
            print("📂 Documents Directory: \(documentsPath.path)")
            print("📋 Files being exported:")
            
            for (filename, data) in jsonFiles {
                let fileURL = documentsPath.appendingPathComponent(filename)
                print("[PreMadeContentGenerator] 💾 Writing \(filename)...")
                
                try data.write(to: fileURL)
                
                // Verify file was written
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    let fileSizeKB = data.count / 1024
                    print("   ✅ \(filename) (\(fileSizeKB) KB)")
                    print("      📍 Full path: \(fileURL.path)")
                } else {
                    print("   ❌ \(filename) - FAILED TO WRITE!")
                }
            }
            
            print("\n💡 To access files:")
            print("   1. Copy this path: \(documentsPath.path)")
            print("   2. In Finder: Cmd+Shift+G and paste the path")
            print("   3. Or check Xcode console for individual file paths")
            print(String(repeating: "=", count: 80) + "\n")
            
            progress = "✅ JSON files written to Documents directory!"
            
        } catch {
            print("[PreMadeContentGenerator] ❌ JSON export failed: \(error)")
            progress = "❌ JSON export failed: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - JSON-Safe Copy Helpers
    
    /// Creates a JSON-safe copy of a Story without circular references
    private func createJSONSafeStory(from story: Story) -> JSONSafeStory {
        return JSONSafeStory(
            id: story.id,
            title: story.title,
            parameters: story.parameters,
            timestamp: story.timestamp,
            isCompleted: story.isCompleted,
            categoryName: story.categoryName,
            readCount: story.readCount,
            lastReadAt: story.lastReadAt,
            isFavorite: story.isFavorite,
            characterNames: story.characterNames,
            visualGuide: story.visualGuide,
            pages: story.pages.map { createJSONSafePage(from: $0) }
        )
    }
    
    /// Creates a JSON-safe copy of a StoryCollection without circular references
    private func createJSONSafeCollection(from collection: StoryCollection) -> JSONSafeStoryCollection {
        return JSONSafeStoryCollection(
            id: collection.id,
            title: collection.title,
            descriptionText: collection.descriptionText,
            category: collection.category,
            ageGroup: collection.ageGroup,
            completionProgress: collection.completionProgress,
            createdAt: collection.createdAt,
            updatedAt: collection.updatedAt,
            storyIds: collection.stories?.map { $0.id } ?? []
        )
    }
    
    /// Creates a JSON-safe copy of a Page
    private func createJSONSafePage(from page: Page) -> JSONSafePage {
        return JSONSafePage(
            id: page.id,
            pageNumber: page.pageNumber,
            content: page.content,
            imagePrompt: page.imagePrompt,
            illustrationStatus: page.illustrationStatus,
            illustrationData: page.getIllustrationData(),
            illustrationMimeType: page.illustrationMimeType,
            illustrationGeneratedAt: page.illustrationGeneratedAt,
            firstViewedAt: page.firstViewedAt
        )
    }
}

// MARK: - JSON-Safe Data Structures

/// JSON-safe version of Story without circular references
struct JSONSafeStory: Codable {
    let id: UUID
    let title: String
    let parameters: StoryParameters
    let timestamp: Date
    let isCompleted: Bool
    let categoryName: String?
    let readCount: Int
    let lastReadAt: Date?
    let isFavorite: Bool
    let characterNames: [String]?
    let visualGuide: VisualGuide?
    let pages: [JSONSafePage]
}

/// JSON-safe version of StoryCollection without circular references
struct JSONSafeStoryCollection: Codable {
    let id: UUID
    let title: String
    let descriptionText: String
    let category: String
    let ageGroup: String
    let completionProgress: Double
    let createdAt: Date
    let updatedAt: Date
    let storyIds: [UUID] // Reference stories by ID only
}

/// JSON-safe version of Page
struct JSONSafePage: Codable {
    let id: UUID
    let pageNumber: Int
    let content: String
    let imagePrompt: String?
    let illustrationStatus: IllustrationStatus
    let illustrationData: Data?
    let illustrationMimeType: String?
    let illustrationGeneratedAt: Date?
    let firstViewedAt: Date?
}

// MARK: - Summary Data Structures

struct PreMadeContentSummary: Codable {
    let stories: [StorySummary]
    let collections: [CollectionSummary]
    let exportedAt: Date
    let totalIllustrations: Int
}

struct StorySummary: Codable {
    let id: UUID
    let title: String
    let pageCount: Int
    let illustrationsGenerated: Int
    let developmentalFocus: [String]
    let generatedAt: Date
}

struct CollectionSummary: Codable {
    let id: UUID
    let title: String
    let storyCount: Int
    let category: String
}