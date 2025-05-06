import Combine
import Foundation
import SwiftData

// MARK: - Illustration Status Enum
enum IllustrationStatus: String, Codable, CaseIterable, Equatable {
    case pending    // Not yet processed
    case scheduled  // In queue, awaiting generation
    case generating // API call in progress
    case ready      // Successfully generated
    case failed     // Failed to generate
}

/// Represents the input parameters provided by the user to generate a story.
struct StoryParameters: Codable, Hashable {
    var childName: String?
    var childAge: Int
    var theme: String
    var favoriteCharacter: String?
    var storyLength: String?
    var developmentalFocus: [GrowthCategory]?  // Optional array for developmental themes
    var interactiveElements: Bool?  // Optional flag for interactive prompts
    var emotionalThemes: [String]?  // Optional array for specific emotions
    var languageCode: String?  // Make language code optional
}

/// Represents a page in a story.
@Model
final class Page: Identifiable, Codable, ObservableObject {
    @Attribute(.unique) var id: UUID
    var content: String
    var pageNumber: Int
    var illustrationPath: String?
    var illustrationStatus: IllustrationStatus
    var imagePrompt: String?
    var firstViewedAt: Date?  // Added from the deleted Page.swift

    @Relationship(inverse: \Story.pages) var story: Story?

    init(
        id: UUID = UUID(),
        content: String,
        pageNumber: Int,
        illustrationPath: String? = nil,
        illustrationStatus: IllustrationStatus = .pending,
        imagePrompt: String? = nil,
        firstViewedAt: Date? = nil,
        story: Story? = nil
    ) {
        self.id = id
        self.content = content
        self.pageNumber = pageNumber
        self.illustrationPath = illustrationPath
        self.illustrationStatus = illustrationStatus
        self.imagePrompt = imagePrompt
        self.firstViewedAt = firstViewedAt
        self.story = story
    }

    enum CodingKeys: String, CodingKey {
        case id, content, pageNumber, illustrationPath, illustrationStatus, imagePrompt,
            firstViewedAt
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let content = try container.decode(String.self, forKey: .content)
        let pageNumber = try container.decode(Int.self, forKey: .pageNumber)
        let illustrationPath = try container.decodeIfPresent(
            String.self, forKey: .illustrationPath)
        let illustrationStatus = try container.decode(
            IllustrationStatus.self, forKey: .illustrationStatus)
        let imagePrompt = try container.decodeIfPresent(String.self, forKey: .imagePrompt)
        let firstViewedAt = try container.decodeIfPresent(Date.self, forKey: .firstViewedAt)

        self.init(
            id: id,
            content: content,
            pageNumber: pageNumber,
            illustrationPath: illustrationPath,
            illustrationStatus: illustrationStatus,
            imagePrompt: imagePrompt,
            firstViewedAt: firstViewedAt
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(pageNumber, forKey: .pageNumber)
        try container.encodeIfPresent(illustrationPath, forKey: .illustrationPath)
        try container.encode(illustrationStatus, forKey: .illustrationStatus)
        try container.encodeIfPresent(imagePrompt, forKey: .imagePrompt)
        try container.encodeIfPresent(firstViewedAt, forKey: .firstViewedAt)
    }
}

/// Represents a generated story.
@Model
final class Story: Identifiable, Codable {
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
        self.achievements = achievements
    }

    enum CodingKeys: String, CodingKey {
        case id, title, pages, parameters, timestamp, isCompleted, collections, categoryName,
            readCount, lastReadAt, isFavorite, achievements
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let title = try container.decode(String.self, forKey: .title)
        let pages = try container.decode([Page].self, forKey: .pages)
        let parameters = try container.decode(StoryParameters.self, forKey: .parameters)
        let timestamp = try container.decode(Date.self, forKey: .timestamp)
        let isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        let collections = try container.decode([StoryCollection].self, forKey: .collections)
        let categoryName = try container.decodeIfPresent(String.self, forKey: .categoryName)
        let readCount = try container.decodeIfPresent(Int.self, forKey: .readCount) ?? 0
        let lastReadAt = try container.decodeIfPresent(Date.self, forKey: .lastReadAt)
        let isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        let achievements =
            try container.decodeIfPresent([AchievementModel].self, forKey: .achievements) ?? []

        self.init(
            id: id, title: title, pages: pages, parameters: parameters, timestamp: timestamp,
            isCompleted: isCompleted, collections: collections, categoryName: categoryName,
            readCount: readCount, lastReadAt: lastReadAt, isFavorite: isFavorite,
            achievements: achievements)
    }

    func encode(to encoder: Encoder) throws {
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
            illustrationPath: illustrationURL?.path,
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
}

/// Represents user-specific settings for the application.
struct UserSettings: Codable {  // Conform to Codable for saving
    /// Preference for enabling or disabling Text-to-Speech functionality.
    var isTextToSpeechEnabled: Bool = false  // Default value
}

/// Represents errors that can occur during story generation or handling.
enum StoryError: Error, LocalizedError {
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
            childName: "Alex",
            childAge: 5,
            theme: "Friendship",
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
