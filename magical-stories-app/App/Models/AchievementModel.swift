// magical-stories/App/Models/AchievementModel.swift

import Foundation
import SwiftData

@Model
final class AchievementModel: Codable {
    @Attribute(.unique) var id: UUID
    var name: String
    var achievementDescription: String
    var earnedAt: Date?
    var typeRawValue: String
    var iconName: String?
    var progress: Double?

    @Relationship var story: Story?

    init(
        id: UUID = UUID(),
        name: String,
        achievementDescription: String? = nil,
        type: AchievementType,
        earnedAt: Date? = nil,
        iconName: String? = nil,
        progress: Double? = nil,
        story: Story? = nil
    ) {
        self.id = id
        self.name = name
        self.achievementDescription = achievementDescription ?? type.defaultDescription
        self.typeRawValue = type.rawValue
        self.earnedAt = earnedAt
        self.iconName = iconName ?? type.defaultIconName
        self.progress = progress
        self.story = story
    }

    var type: AchievementType {
        get { AchievementType(rawValue: typeRawValue) ?? .specialMilestone }
        set { typeRawValue = newValue.rawValue }
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, name, achievementDescription, earnedAt, typeRawValue, iconName, progress
        // Note: story is intentionally excluded from CodingKeys to avoid circular references
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.achievementDescription = try container.decode(
            String.self, forKey: .achievementDescription)
        self.earnedAt = try container.decodeIfPresent(Date.self, forKey: .earnedAt)
        self.typeRawValue = try container.decode(String.self, forKey: .typeRawValue)
        self.iconName = try container.decodeIfPresent(String.self, forKey: .iconName)
        self.progress = try container.decodeIfPresent(Double.self, forKey: .progress)
        // story is intentionally not decoded to avoid circular references
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(achievementDescription, forKey: .achievementDescription)
        try container.encodeIfPresent(earnedAt, forKey: .earnedAt)
        try container.encode(typeRawValue, forKey: .typeRawValue)
        try container.encodeIfPresent(iconName, forKey: .iconName)
        try container.encodeIfPresent(progress, forKey: .progress)
        // story is intentionally not encoded to avoid circular references
    }
}
