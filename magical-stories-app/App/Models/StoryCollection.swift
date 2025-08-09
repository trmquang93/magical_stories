import Foundation
import SwiftData

/// Represents a collection of stories, often themed around a specific growth category.
@Model
final class StoryCollection: Codable, @unchecked Sendable {
    @Attribute(.unique) var id: UUID
    var title: String
    var descriptionText: String  // Renamed from description to avoid conflict
    var category: String
    var ageGroup: String
    var completionProgress: Double = 0.0  // Default progress
    @Relationship(deleteRule: .cascade, inverse: \Story.collections) var stories: [Story]? = []  // Optional to handle potential empty collections initially
    /// Serialized array of story IDs for JSON loading
    /// Stored as Data to avoid SwiftData Array<String> serialization issues
    var storyIdsData: Data?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        descriptionText: String,
        category: String,
        ageGroup: String,
        stories: [Story]? = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.descriptionText = descriptionText
        self.category = category
        self.ageGroup = ageGroup
        self.stories = stories
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, title, descriptionText, category, ageGroup, completionProgress, storyIds, storyIdsData, createdAt,
            updatedAt
    }

    convenience init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let title = try container.decode(String.self, forKey: .title)
        let descriptionText = try container.decode(String.self, forKey: .descriptionText)
        let category = try container.decode(String.self, forKey: .category)
        let ageGroup = try container.decode(String.self, forKey: .ageGroup)
        let completionProgress = try container.decode(Double.self, forKey: .completionProgress)

        // Handle both legacy storyIds and new storyIdsData
        var storyIds: [String] = []
        if let idsData = try? container.decodeIfPresent(Data.self, forKey: .storyIdsData) {
            storyIds = (try? JSONDecoder().decode([String].self, from: idsData)) ?? []
        } else {
            storyIds = (try? container.decode([String].self, forKey: .storyIds)) ?? []
        }
        let createdAt = try container.decode(Date.self, forKey: .createdAt)
        let updatedAt = try container.decode(Date.self, forKey: .updatedAt)

        // Initialize with empty stories array - will be populated after Story objects are loaded
        self.init(
            id: id, title: title, descriptionText: descriptionText, category: category,
            ageGroup: ageGroup, stories: [], createdAt: createdAt, updatedAt: updatedAt)

        self.completionProgress = completionProgress
        // Convert storyIds to Data for storage
        if !storyIds.isEmpty {
            self.storyIdsData = try? JSONEncoder().encode(storyIds)
        } else {
            self.storyIdsData = nil
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(descriptionText, forKey: .descriptionText)
        try container.encode(category, forKey: .category)
        try container.encode(ageGroup, forKey: .ageGroup)
        try container.encode(completionProgress, forKey: .completionProgress)
        // Encode storyIds as Data
        let ids = storyIds
        if !ids.isEmpty {
            let idsData = try? JSONEncoder().encode(ids)
            try container.encodeIfPresent(idsData, forKey: .storyIdsData)
        }
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    /// Get the story IDs for this collection
    var storyIds: [String] {
        get {
            guard let data = storyIdsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            if !newValue.isEmpty {
                storyIdsData = try? JSONEncoder().encode(newValue)
            } else {
                storyIdsData = nil
            }
        }
    }
    
    // Add convenience methods or computed properties if required by tests later
}
