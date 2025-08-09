import Combine
import Foundation
import SwiftData

// MARK: - Illustration Status Enum
enum IllustrationStatus: String, Codable, CaseIterable, Equatable, Sendable {
    case pending  // Not yet processed
    case scheduled  // In queue, awaiting generation
    case generating  // API call in progress
    case ready  // Successfully generated
    case failed  // Failed to generate

    // Custom initializer to handle legacy "success" value that might be in the database
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        // Handle legacy "success" value by mapping it to .ready
        if rawValue == "success" {
            self = .ready
        } else if let value = IllustrationStatus(rawValue: rawValue) {
            self = value
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription:
                        "Cannot initialize IllustrationStatus from invalid String value \(rawValue)",
                    underlyingError: nil
                )
            )
        }
    }
}

/// Represents the educational focus of a story lesson
public enum LessonType: String, CaseIterable, Codable, Identifiable, Sendable {
    case creativity = "Creativity"
    case problemSolving = "Problem Solving"
    case emotionalIntelligence = "Emotional Intelligence"
    case socialSkills = "Social Skills"
    case resilience = "Resilience"
    case curiosity = "Curiosity"
    case kindness = "Kindness"
    case empathy = "Empathy"
    
    public var id: String { self.rawValue }
}

/// Represents the input parameters provided by the user to generate a story.
public struct StoryParameters: Codable, Hashable, Sendable {
    public var childName: String?
    public var childAge: Int
    public var theme: String
    public var favoriteCharacter: String?
    public var storyLength: String?
    public var developmentalFocus: [GrowthCategory]?  // Optional array for developmental themes
    public var interactiveElements: Bool?  // Optional flag for interactive prompts
    public var emotionalThemes: [String]?  // Optional array for specific emotions
    public var languageCode: String?  // Make language code optional
    public var lessonType: LessonType?  // Optional lesson type for educational focus
    public var customization: StoryCustomization?  // Optional customization settings
    
    public init(theme: String, childAge: Int, childName: String? = nil, favoriteCharacter: String? = nil, storyLength: String? = nil, developmentalFocus: [GrowthCategory]? = nil, interactiveElements: Bool? = nil, emotionalThemes: [String]? = nil, languageCode: String? = nil, lessonType: LessonType? = nil, customization: StoryCustomization? = nil) {
        self.theme = theme
        self.childAge = childAge
        self.childName = childName
        self.favoriteCharacter = favoriteCharacter
        self.storyLength = storyLength
        self.developmentalFocus = developmentalFocus
        self.interactiveElements = interactiveElements
        self.emotionalThemes = emotionalThemes
        self.languageCode = languageCode
        self.lessonType = lessonType
        self.customization = customization
    }
}

/// Represents customization options for story generation
public struct StoryCustomization: Codable, Hashable, Sendable {
    public var additionalInstructions: String?
    public var visualStyle: String?
    public var narrativeStyle: String?
    
    public init(additionalInstructions: String? = nil, visualStyle: String? = nil, narrativeStyle: String? = nil) {
        self.additionalInstructions = additionalInstructions
        self.visualStyle = visualStyle
        self.narrativeStyle = narrativeStyle
    }
}

/// Represents a page in a story.
@Model
final class Page: Identifiable, Codable, ObservableObject, @unchecked Sendable {
    @Attribute(.unique) var id: UUID
    var content: String
    var pageNumber: Int
    var illustrationStatus: IllustrationStatus
    var imagePrompt: String?
    var firstViewedAt: Date?
    
    // MARK: - Illustration Reference Storage
    /// Filename for illustration stored in app bundle resources (PreMadeImages folder)
    /// For pre-made stories, images are loaded directly from bundle resources
    /// For user-generated stories, cache key is used for persistent storage
    var illustrationFileName: String?
    var illustrationCacheKey: String?
    var illustrationMimeType: String?
    var illustrationGeneratedAt: Date?

    @Relationship(inverse: \Story.pages) var story: Story?

    init(
        id: UUID = UUID(),
        content: String,
        pageNumber: Int,
        illustrationStatus: IllustrationStatus = .pending,
        imagePrompt: String? = nil,
        firstViewedAt: Date? = nil,
        illustrationFileName: String? = nil,
        illustrationCacheKey: String? = nil,
        illustrationMimeType: String? = nil,
        illustrationGeneratedAt: Date? = nil,
        story: Story? = nil
    ) {
        self.id = id
        self.content = content
        self.pageNumber = pageNumber
        self.illustrationStatus = illustrationStatus
        self.imagePrompt = imagePrompt
        self.firstViewedAt = firstViewedAt
        self.illustrationFileName = illustrationFileName
        self.illustrationCacheKey = illustrationCacheKey
        self.illustrationMimeType = illustrationMimeType
        self.illustrationGeneratedAt = illustrationGeneratedAt
        self.story = story
    }

    enum CodingKeys: String, CodingKey {
        case id, content, pageNumber, illustrationStatus, imagePrompt,
            firstViewedAt, illustrationData, illustrationFileName, illustrationCacheKey, illustrationMimeType, illustrationGeneratedAt
    }

    convenience init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let content = try container.decode(String.self, forKey: .content)
        let pageNumber = try container.decode(Int.self, forKey: .pageNumber)
        let illustrationStatus = try container.decode(
            IllustrationStatus.self, forKey: .illustrationStatus)
        let imagePrompt = try container.decodeIfPresent(String.self, forKey: .imagePrompt)
        let firstViewedAt = try container.decodeIfPresent(Date.self, forKey: .firstViewedAt)
        
        // Handle illustration references - prefer bundle resources over persistent storage
        var illustrationFileName: String?
        var illustrationCacheKey: String?
        
        // First, check for bundle resource filename (pre-made stories)
        if let fileName = try? container.decodeIfPresent(String.self, forKey: .illustrationFileName) {
            illustrationFileName = fileName
            print("[Page] Found bundle resource illustration: \(fileName)")
        }
        // Legacy: Handle illustrationData by converting to cache key (user-generated stories)
        else if let base64String = try? container.decodeIfPresent(String.self, forKey: .illustrationData) {
            // Generate cache key immediately but defer heavy processing
            let cacheKey = "\(id.uuidString)_\(pageNumber)"
            illustrationCacheKey = cacheKey
            
            // Schedule heavy base64 decoding and file I/O on background queue
            Task.detached {
                if let data = Data(base64Encoded: base64String) {
                    PersistentIllustrationStore.shared.storeImage(data, forKey: cacheKey)
                    print("[Page] Stored illustration for cache key: \(cacheKey) (\(data.count) bytes)")
                } else {
                    print("[Page] Failed to decode base64 illustration data for key: \(cacheKey)")
                }
            }
        } else if let data = try? container.decodeIfPresent(Data.self, forKey: .illustrationData) {
            // Handle direct Data format (less common) - also defer heavy I/O
            let cacheKey = "\(id.uuidString)_\(pageNumber)"
            illustrationCacheKey = cacheKey
            
            Task.detached {
                PersistentIllustrationStore.shared.storeImage(data, forKey: cacheKey)
                print("[Page] Stored direct illustration data for cache key: \(cacheKey) (\(data.count) bytes)")
            }
        } else if let existingCacheKey = try? container.decodeIfPresent(String.self, forKey: .illustrationCacheKey) {
            // Handle existing cache key format
            illustrationCacheKey = existingCacheKey
        }
        
        let illustrationMimeType = try container.decodeIfPresent(String.self, forKey: .illustrationMimeType)
        
        // Handle illustrationGeneratedAt - try both Date and timestamp formats
        var illustrationGeneratedAt: Date?
        if let date = try? container.decodeIfPresent(Date.self, forKey: .illustrationGeneratedAt) {
            illustrationGeneratedAt = date
        } else if let timestamp = try? container.decodeIfPresent(Double.self, forKey: .illustrationGeneratedAt) {
            illustrationGeneratedAt = Date(timeIntervalSinceReferenceDate: timestamp)
        }

        self.init(
            id: id,
            content: content,
            pageNumber: pageNumber,
            illustrationStatus: illustrationStatus,
            imagePrompt: imagePrompt,
            firstViewedAt: firstViewedAt,
            illustrationFileName: illustrationFileName,
            illustrationCacheKey: illustrationCacheKey,
            illustrationMimeType: illustrationMimeType,
            illustrationGeneratedAt: illustrationGeneratedAt
        )
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(pageNumber, forKey: .pageNumber)
        try container.encode(illustrationStatus, forKey: .illustrationStatus)
        try container.encodeIfPresent(imagePrompt, forKey: .imagePrompt)
        try container.encodeIfPresent(firstViewedAt, forKey: .firstViewedAt)
        try container.encodeIfPresent(illustrationFileName, forKey: .illustrationFileName)
        try container.encodeIfPresent(illustrationCacheKey, forKey: .illustrationCacheKey)
        try container.encodeIfPresent(illustrationMimeType, forKey: .illustrationMimeType)
        try container.encodeIfPresent(illustrationGeneratedAt, forKey: .illustrationGeneratedAt)
    }
    
    // MARK: - Persistent Illustration Convenience Methods
    
    /// Checks if the page has any illustration (bundle resource or cached)
    var hasEmbeddedIllustration: Bool {
        return illustrationFileName != nil || illustrationCacheKey != nil
    }
    
    /// Checks if the page has any illustration
    var hasIllustration: Bool {
        return hasEmbeddedIllustration
    }
    
    /// Gets the illustration data from bundle resources or persistent storage
    /// - Returns: Image data if available, nil otherwise
    func getIllustrationData() -> Data? {
        // First, try to load from bundle resources (pre-made stories)
        if let fileName = illustrationFileName {
            return loadImageFromBundle(fileName: fileName)
        }
        
        // Fallback to persistent storage (user-generated stories)
        if let cacheKey = illustrationCacheKey {
            return PersistentIllustrationStore.shared.getImage(forKey: cacheKey)
        }
        
        return nil
    }
    
    /// Loads image data from app bundle resources
    /// - Parameter fileName: The filename in PreMadeImages folder
    /// - Returns: Image data if found, nil otherwise
    private func loadImageFromBundle(fileName: String) -> Data? {
        print("[Page] 🔍 Attempting to load bundle image: \(fileName)")
        print("[Page] Bundle path: \(Bundle.main.bundlePath)")
        
        // Check bundle root directory contents
        if let resourcePath = Bundle.main.resourcePath {
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                let pngFiles = contents.filter { $0.hasSuffix(".png") }
                print("[Page] Bundle root contents: \(contents.count) items, \(pngFiles.count) PNG files")
                print("[Page] PNG files in bundle: \(pngFiles)")
                
                // Check if our specific image exists
                let imageExists = contents.contains(fileName)
                print("[Page] Image \(fileName) exists in bundle root: \(imageExists ? "✅" : "❌")")
            } catch {
                print("[Page] Error reading bundle root directory: \(error)")
            }
        }
        
        // Look for image at root level of bundle (same level as JSON files)
        guard let url = Bundle.main.url(forResource: fileName.replacingOccurrences(of: ".png", with: ""), 
                                       withExtension: "png") else {
            print("[Page] ❌ Bundle image not found: \(fileName)")
            return nil
        }
        
        print("[Page] ✅ Found bundle image URL: \(url.path)")
        
        do {
            let data = try Data(contentsOf: url)
            print("[Page] ✅ Loaded bundle image: \(fileName) (\(data.count) bytes)")
            return data
        } catch {
            print("[Page] ❌ Failed to load bundle image \(fileName): \(error)")
            return nil
        }
    }
    
    /// Sets illustration data in persistent store and updates related fields
    /// Note: This is for user-generated content. Pre-made stories use bundle resources.
    /// - Parameters:
    ///   - data: The image data to store
    ///   - mimeType: The MIME type of the image (e.g., "image/png")
    @MainActor
    func setEmbeddedIllustration(data: Data, mimeType: String = "image/png") {
        let cacheKey = "\(id.uuidString)_\(pageNumber)"
        PersistentIllustrationStore.shared.storeImage(data, forKey: cacheKey)
        self.illustrationCacheKey = cacheKey
        self.illustrationFileName = nil  // Clear bundle reference when setting user content
        self.illustrationMimeType = mimeType
        self.illustrationGeneratedAt = Date()
        self.illustrationStatus = .ready
    }
    
    /// Clears all illustration data
    @MainActor
    func clearIllustration() {
        if let cacheKey = illustrationCacheKey {
            PersistentIllustrationStore.shared.removeImage(forKey: cacheKey)
        }
        self.illustrationFileName = nil
        self.illustrationCacheKey = nil
        self.illustrationMimeType = nil
        self.illustrationGeneratedAt = nil
        self.illustrationStatus = .pending
    }
}

/// Represents a generated story.
@Model
final class Story: Identifiable, Codable, @unchecked Sendable {
    @Attribute(.unique) var id: UUID
    var title: String
    var pages: [Page]
    var parameters: StoryParameters
    var timestamp: Date
    var isCompleted: Bool = false
    var collections: [StoryCollection]
    var categoryName: String?

    // Add missing fields
    var readCount: Int = 0
    var lastReadAt: Date?
    var isFavorite: Bool = false

    // Visual guide for character consistency across illustrations
    var visualGuideData: Data?

    // Collection context for stories that are part of a collection
    var collectionContextData: Data?
    
    // MARK: - Visual Element Reference Storage
    /// Serialized array of visual element names for reference generation (characters, toys, objects, etc.)
    /// Stored as Data to avoid SwiftData Array<String> serialization issues
    var characterNamesData: Data?
    
    /// Master reference image containing all visual elements
    var characterReferenceData: Data?

    // Add relationship for achievements
    @Relationship(deleteRule: .cascade) var achievements: [AchievementModel] = []

    init(
        id: UUID = UUID(),
        title: String,
        pages: [Page],
        parameters: StoryParameters,
        timestamp: Date = Date(),
        isCompleted: Bool = false,
        collections: [StoryCollection] = [],
        categoryName: String? = nil,
        readCount: Int = 0,
        lastReadAt: Date? = nil,
        isFavorite: Bool = false,
        visualGuideData: Data? = nil,
        collectionContextData: Data? = nil,
        characterNames: [String]? = nil,
        characterReferenceData: Data? = nil,
        achievements: [AchievementModel] = []
    ) {
        self.id = id
        self.title = title
        self.pages = pages
        self.parameters = parameters
        self.timestamp = timestamp
        self.isCompleted = isCompleted
        self.collections = collections
        self.categoryName = categoryName
        self.readCount = readCount
        self.lastReadAt = lastReadAt
        self.isFavorite = isFavorite
        self.visualGuideData = visualGuideData
        self.collectionContextData = collectionContextData
        // Convert characterNames to Data for storage
        if let names = characterNames {
            self.characterNamesData = try? JSONEncoder().encode(names)
        } else {
            self.characterNamesData = nil
        }
        self.characterReferenceData = characterReferenceData
        self.achievements = achievements
    }

    enum CodingKeys: String, CodingKey {
        case id, title, pages, parameters, timestamp, isCompleted, collections, categoryName,
            readCount, lastReadAt, isFavorite, visualGuideData, visualGuide, collectionContextData,
            characterNames, characterNamesData, characterReferenceData, achievements
    }

    convenience init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let title = try container.decode(String.self, forKey: .title)
        let pages = try container.decode([Page].self, forKey: .pages)
        let parameters = try container.decode(StoryParameters.self, forKey: .parameters)
        let timestamp = try container.decode(Date.self, forKey: .timestamp)
        let isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        let collections = try container.decodeIfPresent([StoryCollection].self, forKey: .collections) ?? []
        let categoryName = try container.decodeIfPresent(String.self, forKey: .categoryName)
        let readCount = try container.decodeIfPresent(Int.self, forKey: .readCount) ?? 0
        let lastReadAt = try container.decodeIfPresent(Date.self, forKey: .lastReadAt)
        let isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        
        // Handle visualGuide - try both the stored data format and the JSON object format
        var visualGuideData: Data?
        if let storedData = try? container.decodeIfPresent(Data.self, forKey: .visualGuideData) {
            visualGuideData = storedData
        } else if container.contains(.visualGuide) {
            // Try to decode the visualGuide object and convert to Data
            if let visualGuide = try? container.decode(VisualGuide.self, forKey: .visualGuide) {
                visualGuideData = try? JSONEncoder().encode(visualGuide)
            }
        }
        
        let collectionContextData = try container.decodeIfPresent(Data.self, forKey: .collectionContextData)
        // Handle both legacy characterNames and new characterNamesData
        var characterNames: [String]?
        if let namesData = try? container.decodeIfPresent(Data.self, forKey: .characterNamesData) {
            characterNames = try? JSONDecoder().decode([String].self, from: namesData)
        } else {
            characterNames = try? container.decodeIfPresent([String].self, forKey: .characterNames)
        }
        let characterReferenceData = try container.decodeIfPresent(Data.self, forKey: .characterReferenceData)
        let achievements =
            try container.decodeIfPresent([AchievementModel].self, forKey: .achievements) ?? []

        self.init(
            id: id, title: title, pages: pages, parameters: parameters, timestamp: timestamp,
            isCompleted: isCompleted, collections: collections, categoryName: categoryName,
            readCount: readCount, lastReadAt: lastReadAt, isFavorite: isFavorite,
            visualGuideData: visualGuideData, collectionContextData: collectionContextData, 
            characterNames: characterNames, characterReferenceData: characterReferenceData, 
            achievements: achievements)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(pages, forKey: .pages)
        try container.encode(parameters, forKey: .parameters)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(collections, forKey: .collections)
        try container.encodeIfPresent(categoryName, forKey: .categoryName)
        try container.encode(readCount, forKey: .readCount)
        try container.encodeIfPresent(lastReadAt, forKey: .lastReadAt)
        try container.encode(isFavorite, forKey: .isFavorite)
        try container.encodeIfPresent(visualGuideData, forKey: .visualGuideData)
        try container.encodeIfPresent(collectionContextData, forKey: .collectionContextData)
        // Encode characterNames as Data
        if let names = characterNames {
            let namesData = try? JSONEncoder().encode(names)
            try container.encodeIfPresent(namesData, forKey: .characterNamesData)
        }
        try container.encodeIfPresent(characterReferenceData, forKey: .characterReferenceData)
        try container.encode(achievements, forKey: .achievements)
    }

    // Compatibility initializer
    convenience init(
        id: UUID = UUID(),
        title: String,
        content: String,
        parameters: StoryParameters,
        timestamp: Date = Date(),
        illustrationURL: URL? = nil,
        imagePrompt: String? = nil,
        categoryName: String? = nil
    ) {
        let singlePage = Page(
            content: content,
            pageNumber: 1,
            imagePrompt: imagePrompt
        )
        self.init(
            id: id,
            title: title,
            pages: [singlePage],
            parameters: parameters,
            timestamp: timestamp,
            categoryName: categoryName
        )
    }
    
    // MARK: - Visual Guide Convenience Methods
    
    /// Get the visual guide for this story, if available
    var visualGuide: VisualGuide? {
        get {
            guard let data = visualGuideData else { 
                print("[Story] No visual guide data found for story: \(title)")
                return nil 
            }
            do {
                let guide = try JSONDecoder().decode(VisualGuide.self, from: data)
                print("[Story] Successfully decoded visual guide for story: \(title)")
                return guide
            } catch {
                print("[Story] Failed to decode visual guide for story \(title): \(error)")
                return nil
            }
        }
        set {
            if let guide = newValue {
                do {
                    visualGuideData = try JSONEncoder().encode(guide)
                    print("[Story] Visual guide encoded and saved for story: \(title)")
                } catch {
                    print("[Story] Failed to encode visual guide for story \(title): \(error)")
                    visualGuideData = nil
                }
            } else {
                visualGuideData = nil
                print("[Story] Visual guide cleared for story: \(title)")
            }
        }
    }
    
    /// Set the visual guide for this story
    func setVisualGuide(_ guide: VisualGuide) {
        self.visualGuide = guide
    }
    
    // MARK: - Collection Context Convenience Methods
    
    /// Get the collection context for this story, if available
    var collectionContext: CollectionVisualContext? {
        get {
            guard let data = collectionContextData else { return nil }
            return try? JSONDecoder().decode(CollectionVisualContext.self, from: data)
        }
        set {
            if let context = newValue {
                collectionContextData = try? JSONEncoder().encode(context)
            } else {
                collectionContextData = nil
            }
        }
    }
    
    /// Set the collection context for this story
    func setCollectionContext(_ context: CollectionVisualContext) {
        self.collectionContext = context
    }
    
    // MARK: - Visual Element Reference Management
    
    /// Set the visual element names for this story (characters, toys, objects, etc.)
    /// - Parameter names: Array of visual element names to be used for reference generation
    func setCharacterNames(_ names: [String]) {
        self.characterNamesData = try? JSONEncoder().encode(names)
    }
    
    /// Get the character names for this story
    var characterNames: [String]? {
        get {
            guard let data = characterNamesData else { return nil }
            return try? JSONDecoder().decode([String].self, from: data)
        }
        set {
            if let names = newValue {
                characterNamesData = try? JSONEncoder().encode(names)
            } else {
                characterNamesData = nil
            }
        }
    }
    
    /// Computed property to check if the story has master reference data
    var hasCharacterReference: Bool {
        return characterReferenceData != nil
    }
    
    /// Clear all visual element reference data
    func clearCharacterReferences() {
        self.characterNamesData = nil
        self.characterReferenceData = nil
    }
}

/// Represents user-specific settings for the application.
struct UserSettings: Codable, Sendable {  // Conform to Codable for saving
    /// Preference for enabling or disabling Text-to-Speech functionality.
    var isTextToSpeechEnabled: Bool = false  // Default value
}

/// Represents errors that can occur during story generation or handling.
enum StoryError: Error, LocalizedError, Sendable {
    case generationFailed
    case invalidParameters
    case persistenceFailed  // Although persistence isn't implemented yet, keep the error case as defined.

    var errorDescription: String? {
        switch self {
        case .generationFailed:
            return NSLocalizedString(
                "Failed to generate the story. Please try again.", comment: "Story Generation Error"
            )
        case .invalidParameters:
            return NSLocalizedString(
                "The provided parameters were invalid.", comment: "Invalid Story Parameters Error")
        case .persistenceFailed:
            return NSLocalizedString(
                "Failed to save or load the story.", comment: "Story Persistence Error")
        }
    }
}

// MARK: - Preview Helpers

extension Story {
    static func previewStory(
        title: String = "The Magical Forest Adventure", categoryName: String? = "Fantasy"
    ) -> Story {
        let params = StoryParameters(
            theme: "Friendship",
            childAge: 5,
            childName: "Alex",
            favoriteCharacter: "Brave Bear"
                // languageCode is optional, no need to set in basic preview
        )
        return Story(
            title: title,
            pages: [
                Page(
                    content: "Once upon a time, Alex and Brave Bear went into the forest.",
                    pageNumber: 1, imagePrompt: "A child and a bear entering a forest"),
                Page(
                    content: "They met a lost squirrel and helped it find its way home.",
                    pageNumber: 2, imagePrompt: "Bear and child helping a squirrel"),
                Page(
                    content: "They learned that helping friends is important. The end.",
                    pageNumber: 3, imagePrompt: "Bear, child, and squirrel waving goodbye"),
            ],
            parameters: params,
            categoryName: categoryName
        )
    }

    static var preview: Story { previewStory() }
}
