import Foundation
import SwiftData

/// Errors that can occur during persistence operations
enum PersistenceError: Error {
    case encodingFailed(Error)
    case decodingFailed(Error)
    case dataNotFound
    case migrationFailed(Error)
    case repositoryError(Error)
}

@MainActor
class PersistenceService: PersistenceServiceProtocol {
    private let context: ModelContext
    private let storyRepository: StoryRepository
    private let swiftDataAchievementRepository: AchievementRepository
    private let decoder = JSONDecoder()
    
    init(context: ModelContext) {
        self.context = context
        self.storyRepository = StoryRepository(modelContext: context)
        self.swiftDataAchievementRepository = AchievementRepository(modelContext: context)
    }
    
    func saveStories(_ stories: [Story]) async throws {
        try await storyRepository.saveStories(stories)
    }
    
    func loadStories() async throws -> [Story] {
        let storyModels = try await storyRepository.fetchAllStories()
        return storyRepository.toDomainModels(storyModels)
    }
    
    @MainActor
    func saveStory(_ story: Story) async throws {
        print("[PersistenceService] saveStory START")
        do {
            try await storyRepository.saveStory(story)
            print("[PersistenceService] saveStory SUCCESS")
        } catch {
            print("[PersistenceService] saveStory ERROR: \(error.localizedDescription)")
            throw error
        }
    }
    
    func deleteStory(withId id: UUID) async throws {
        guard let storyModel = try await storyRepository.fetchStory(withId: id) else {
            // Optionally throw an error if the story doesn't exist
            print("Story with ID \(id) not found for deletion.")
            return
        }
        try await storyRepository.delete(storyModel)
    }
    
    // MARK: - Story State Updates -
    
    func incrementReadCount(for storyId: UUID) async throws {
        try await storyRepository.incrementReadCount(for: storyId)
    }
    
    func toggleFavorite(for storyId: UUID) async throws {
        try await storyRepository.toggleFavorite(for: storyId)
    }
    
    func updateLastReadAt(for storyId: UUID, date: Date = Date()) async throws {
        try await storyRepository.updateLastReadAt(for: storyId, date: date)
    }
    
    // MARK: - Achievement Management -
    
    /// Saves an achievement using the appropriate repository based on migration status
    /// - Parameter achievement: The Achievement to save
    func saveAchievement(_ achievement: Achievement) async throws {
        // Convert Achievement to AchievementModel and save using SwiftData
        let achievementModel = AchievementModel(from: achievement)
        try await swiftDataAchievementRepository.save(achievementModel)
    }
    
    /// Fetches an achievement by ID using the appropriate repository
    /// - Parameter id: The UUID of the achievement
    /// - Returns: The Achievement if found
    func fetchAchievement(id: UUID) async throws -> Achievement? {
        let model = try await swiftDataAchievementRepository.fetchAchievement(withId: id)
        return model?.toDomainModel()
    }
    
    /// Fetches all achievements using the appropriate repository
    /// - Returns: Array of Achievement objects
    func fetchAllAchievements() async throws -> [Achievement] {
        let models = try await swiftDataAchievementRepository.fetchAllAchievements()
        return models.map { $0.toDomainModel() }
    }
    
    /// Fetches earned achievements using the appropriate repository
    /// - Returns: Array of Achievement objects
    func fetchEarnedAchievements() async throws -> [Achievement] {
        let models = try await swiftDataAchievementRepository.fetchEarnedAchievements()
        return models.map { $0.toDomainModel() }
    }
    
    /// Fetches achievements for a specific collection using the appropriate repository
    /// - Parameter collectionId: The UUID of the collection
    /// - Returns: Array of Achievement objects associated with the collection
    func fetchAchievements(forCollection collectionId: UUID) async throws -> [Achievement] {
        // Note: Uses the placeholder implementation in AchievementRepository
        let models = try await swiftDataAchievementRepository.fetchAchievements(forCollection: collectionId)
        return models.map { $0.toDomainModel() }
    }
    
    /// Updates achievement status using the appropriate repository
    /// - Parameters:
    ///   - id: The UUID of the achievement
    ///   - isEarned: Whether the achievement is earned
    ///   - earnedDate: The date when earned (if applicable)
    func updateAchievementStatus(id: UUID, isEarned: Bool, earnedDate: Date?) async throws {
        try await swiftDataAchievementRepository.updateAchievementStatus(id: id, isEarned: isEarned, earnedDate: earnedDate)
    }
    
    /// Deletes an achievement using the appropriate repository
    /// - Parameter id: The UUID of the achievement to delete
    func deleteAchievement(withId id: UUID) async throws {
        guard let model = try await swiftDataAchievementRepository.fetchAchievement(withId: id) else {
            return // Already deleted or doesn't exist
        }
        try await swiftDataAchievementRepository.delete(model)
    }
    
    /// Associates an achievement with a collection using the appropriate repository
    /// - Parameters:
    ///   - achievementId: The ID of the achievement
    ///   - collectionId: The UUID of the collection
    func associateAchievement(_ achievementId: String, withCollection collectionId: UUID) async throws {
        // Note: Uses the placeholder implementation in AchievementRepository
        try await swiftDataAchievementRepository.associateAchievement(achievementId, withCollection: collectionId)
    }
    
    /// Removes an achievement's association with a collection using the appropriate repository
    /// - Parameters:
    ///   - achievementId: The ID of the achievement
    ///   - collectionId: The UUID of the collection
    func removeAchievementAssociation(_ achievementId: String, fromCollection collectionId: UUID) async throws {
        // Note: Uses the placeholder implementation in AchievementRepository
        try await swiftDataAchievementRepository.removeAchievementAssociation(achievementId, fromCollection: collectionId)
    }
}

// MARK: - Model Conversions

extension AchievementModel {
    convenience init(from achievement: Achievement) {
        self.init(
            id: UUID(uuidString: achievement.id) ?? UUID(),
            name: achievement.name,
            achievementDescription: achievement.description,
            type: .specialMilestone,
            earnedAt: achievement.dateEarned ?? Date(),
            iconName: achievement.iconName
        )
    }
    
    func toDomainModel() -> Achievement {
        Achievement(
            id: id.uuidString,
            name: name,
            description: achievementDescription,
            iconName: iconName ?? "defaultIcon",
            unlockCriteriaDescription: "",
            dateEarned: earnedAt
        )
    }
}

// MARK: - Conversion Helpers

extension StoryModel {
    func toStory() -> Story {
        let parameters = StoryParameters(
            childName: self.childName,
            childAge: self.childAge,
            theme: self.theme,
            favoriteCharacter: self.favoriteCharacter
        )
        let pages = self.pages.sorted { $0.pageNumber < $1.pageNumber }.map { $0.toPage() }
        return Story(
            id: self.id,
            title: self.title,
            pages: pages,
            parameters: parameters,
            timestamp: self.timestamp
        )
    }
}

extension PageModel {
    func toPage() -> Page {
        Page(
            id: self.id,
            content: self.content,
            pageNumber: self.pageNumber,
            illustrationRelativePath: self.illustrationRelativePath,
            illustrationStatus: self.illustrationStatus,
            imagePrompt: self.imagePrompt
        )
    }
}

// MARK: - UserDefaults Keys (Unrelated to stories, keep as is)

// UserDefaults extension for usage analytics removed as data is now managed by UsageAnalyticsService via UserProfile model.