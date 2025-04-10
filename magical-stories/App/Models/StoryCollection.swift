import Foundation
import SwiftData

@Model
class StoryCollection: Identifiable {
    @Attribute(.unique) var id: String
    var title: String
    var theme: String
    var ageGroup: String
    var focusArea: String
    var createdDate: Date
    var progress: Double

    @Relationship(deleteRule: .cascade)
    var stories: [StoryModel]

    @Relationship(deleteRule: .cascade)
    var achievements: [AchievementModel]

    init(
        id: String,
        title: String,
        theme: String,
        ageGroup: String,
        focusArea: String,
        createdDate: Date,
        stories: [StoryModel] = [],
        progress: Double = 0.0,
        achievements: [AchievementModel] = []
    ) {
        self.id = id
        self.title = title
        self.theme = theme
        self.ageGroup = ageGroup
        self.focusArea = focusArea
        self.createdDate = createdDate
        self.stories = stories
        self.progress = progress
        self.achievements = achievements
    }
}