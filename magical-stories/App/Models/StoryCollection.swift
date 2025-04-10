import Foundation
import SwiftData

/// A collection of stories focused on child development areas like emotional intelligence, confidence, etc.
/// Combines functionality from both StoryCollection and GrowthCollection concepts.
@Model
final class StoryCollection: Identifiable, Codable {
    @Attribute(.unique) var id: UUID
    var title: String
    var descriptionText: String?
    var growthCategory: String? // e.g., emotionalIntelligence, confidenceLeadership
    var targetAgeGroup: String? // e.g., preschool, elementary, preteen
    var completionProgress: Double // 0.0 to 1.0
    var stories: [Story] // many-to-many relationship
    var achievements: [Achievement]?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        descriptionText: String? = nil,
        growthCategory: String? = nil,
        targetAgeGroup: String? = nil,
        stories: [Story] = [],
        achievements: [Achievement]? = nil,
        completionProgress: Double = 0.0
    ) {
        self.id = id
        self.title = title
        self.descriptionText = descriptionText
        self.growthCategory = growthCategory
        self.targetAgeGroup = targetAgeGroup
        self.stories = stories
        self.achievements = achievements
        self.completionProgress = completionProgress
        self.createdAt = Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, descriptionText, growthCategory, targetAgeGroup, completionProgress, stories, achievements, createdAt
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let title = try container.decode(String.self, forKey: .title)
        let descriptionText = try container.decodeIfPresent(String.self, forKey: .descriptionText)
        let growthCategory = try container.decodeIfPresent(String.self, forKey: .growthCategory)
        let targetAgeGroup = try container.decodeIfPresent(String.self, forKey: .targetAgeGroup)
        let completionProgress = try container.decode(Double.self, forKey: .completionProgress)
        let stories = try container.decode([Story].self, forKey: .stories)
        let achievements = try container.decodeIfPresent([Achievement].self, forKey: .achievements)
        let createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.init(
            id: id,
            title: title,
            descriptionText: descriptionText,
            growthCategory: growthCategory,
            targetAgeGroup: targetAgeGroup,
            stories: stories,
            achievements: achievements,
            completionProgress: completionProgress
        )
        self.createdAt = createdAt
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(descriptionText, forKey: .descriptionText)
        try container.encodeIfPresent(growthCategory, forKey: .growthCategory)
        try container.encodeIfPresent(targetAgeGroup, forKey: .targetAgeGroup)
        try container.encode(completionProgress, forKey: .completionProgress)
        try container.encode(stories, forKey: .stories)
        try container.encodeIfPresent(achievements, forKey: .achievements)
        try container.encode(createdAt, forKey: .createdAt)
    }
    
    /// Calculates completion progress based on completed stories
    func calculateProgress() -> Double {
        guard !stories.isEmpty else { return 0.0 }
        let completedCount = stories.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(stories.count)
    }
    
    // Example for previews
    static var previewExample: StoryCollection {
        StoryCollection(
            title: "The Little Explorer's Guide to Courage",
            descriptionText: "A collection of stories helping young adventurers find their inner bravery.",
            growthCategory: "confidenceLeadership",
            targetAgeGroup: "preschool",
            stories: [
                Story.previewStory(title: "Finley Fox Faces the Dark"),
                Story.previewStory(title: "Lily Lamb Tries Something New"),
                Story.previewStory(title: "Sammy Squirrel Climbs High")
            ],
            completionProgress: 0.66
        )
    }
}