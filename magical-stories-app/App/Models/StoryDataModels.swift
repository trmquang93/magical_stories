import Foundation
import SwiftData

// MARK: - Achievement Type Enum
enum AchievementType: String, Codable, CaseIterable, Identifiable {
    case readingStreak = "Reading Streak"
    case storiesCompleted = "Stories Completed"
    case themeMastery = "Theme Mastery"
    case growthPathProgress = "Growth Path Progress"
    case specialMilestone = "Special Milestone"  // Generic milestone

    var id: String { self.rawValue }

    /// Provides a default description for each achievement type.
    var defaultDescription: String {
        switch self {
        case .readingStreak: return "Keep up the great reading habit!"
        case .storiesCompleted: return "Finished another magical adventure!"
        case .themeMastery: return "Mastered a story theme!"
        case .growthPathProgress: return "Making progress on a learning journey!"
        case .specialMilestone: return "Reached a special achievement!"
        }
    }

    /// Provides a default system icon name for each type (optional).
    var defaultIconName: String {
        switch self {
        case .readingStreak: return "flame.fill"
        case .storiesCompleted: return "star.fill"
        case .themeMastery: return "bookmark.fill"
        case .growthPathProgress: return "figure.walk.motion"
        case .specialMilestone: return "sparkles"
        }
    }
}
