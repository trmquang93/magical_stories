// magical-stories/App/Models/AchievementModel.swift

import Foundation
import SwiftData

@Model
final class AchievementModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var achievementDescription: String
    var earnedAt: Date?
    var typeRawValue: String
    var iconName: String?
    var progress: Double?

    @Relationship(inverse: \StoryModel.achievements) var story: StoryModel?

    init(
        id: UUID = UUID(),
        name: String,
        achievementDescription: String? = nil,
        type: AchievementType,
        earnedAt: Date? = nil,
        iconName: String? = nil,
        progress: Double? = nil,
        story: StoryModel? = nil
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
}
