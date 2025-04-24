import Foundation
import SwiftData
  // MARK: - Illustration Status Enum
 enum IllustrationStatus: String, Codable {
     case pending
     case success
     case failed
     case placeholder
 }
 
 // MARK: - Achievement Type Enum
 enum AchievementType: String, Codable, CaseIterable, Identifiable {
     case readingStreak = "Reading Streak"
     case storiesCompleted = "Stories Completed"
     case themeMastery = "Theme Mastery"
     case growthPathProgress = "Growth Path Progress"
     case specialMilestone = "Special Milestone" // Generic milestone
 
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
 

// MARK: - Illustration Status Enum

@Model
final class PageModel {
    @Attribute(.unique) var id: UUID
    var content: String
    var pageNumber: Int
    var illustrationRelativePath: String?
    var illustrationStatusRaw: String
    var imagePrompt: String?
    
    @Relationship(inverse: \StoryModel.pages) var story: StoryModel?

    init(
        id: UUID = UUID(),
        content: String,
        pageNumber: Int,
        illustrationRelativePath: String? = nil,
        illustrationStatus: IllustrationStatus = .pending,
        imagePrompt: String? = nil,
        story: StoryModel? = nil
    ) {
        self.id = id
        self.content = content
        self.pageNumber = pageNumber
        self.illustrationRelativePath = illustrationRelativePath
        self.illustrationStatusRaw = illustrationStatus.rawValue
        self.imagePrompt = imagePrompt
        self.story = story
    }
    
    var illustrationStatus: IllustrationStatus {
        get { IllustrationStatus(rawValue: illustrationStatusRaw) ?? .pending }
        set { illustrationStatusRaw = newValue.rawValue }
    }
}

@Model
final class StoryModel {
    @Attribute(.unique) var id: UUID
    var title: String
    var timestamp: Date
    
    // Flattened StoryParameters
    var childName: String
    var childAge: Int
    var theme: String
    var favoriteCharacter: String
    
    @Relationship(deleteRule: .cascade) var pages: [PageModel] = []
    
    // Phase 4 Additions
    var readCount: Int
    var isFavorite: Bool
    var lastReadAt: Date?
    
    // Relationship to Achievements
    @Relationship(deleteRule: .cascade) var achievements: [AchievementModel]? = []

    init(
        id: UUID = UUID(),
        title: String,
        timestamp: Date = Date(),
        childName: String,
        childAge: Int,
        theme: String,
        favoriteCharacter: String,
        pages: [PageModel] = [],
        readCount: Int = 0,
        isFavorite: Bool = false,
        lastReadAt: Date? = nil,
        achievements: [AchievementModel]? = []
    ) {
        self.id = id
        self.title = title
        self.timestamp = timestamp
        self.childName = childName
        self.childAge = childAge
        self.theme = theme
        self.favoriteCharacter = favoriteCharacter
        self.pages = pages
        self.readCount = readCount
        self.isFavorite = isFavorite
        self.lastReadAt = lastReadAt
        self.achievements = achievements
    }
}
