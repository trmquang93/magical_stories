import Foundation
import SwiftData

/// Represents a collection of stories, often themed around a specific growth category.
@Model
final class StoryCollection: Codable {
    @Attribute(.unique) var id: UUID
    var title: String
    var descriptionText: String  // Renamed from description to avoid conflict
    var category: String
    var ageGroup: String
    var completionProgress: Double = 0.0  // Default progress
    @Relationship(deleteRule: .cascade, inverse: \Story.collections) var stories: [Story]? = []  // Optional to handle potential empty collections initially
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
        case id, title, descriptionText, category, ageGroup, completionProgress, stories, createdAt,
            updatedAt
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let title = try container.decode(String.self, forKey: .title)
        let descriptionText = try container.decode(String.self, forKey: .descriptionText)
        let category = try container.decode(String.self, forKey: .category)
        let ageGroup = try container.decode(String.self, forKey: .ageGroup)
        let completionProgress = try container.decode(Double.self, forKey: .completionProgress)

        let stories = try container.decode([Story].self, forKey: .stories)
        let createdAt = try container.decode(Date.self, forKey: .createdAt)
        let updatedAt = try container.decode(Date.self, forKey: .updatedAt)

        self.init(
            id: id, title: title, descriptionText: descriptionText, category: category,
            ageGroup: ageGroup, stories: stories, createdAt: createdAt, updatedAt: updatedAt)

        self.completionProgress = completionProgress
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(descriptionText, forKey: .descriptionText)
        try container.encode(category, forKey: .category)
        try container.encode(ageGroup, forKey: .ageGroup)
        try container.encode(completionProgress, forKey: .completionProgress)
        try container.encode(stories, forKey: .stories)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    // Add convenience methods or computed properties if required by tests later
}
