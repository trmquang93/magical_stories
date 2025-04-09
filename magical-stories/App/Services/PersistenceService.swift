import Foundation
import SwiftData

/// Errors that can occur during persistence operations
enum PersistenceError: Error {
    case encodingFailed(Error)
    case decodingFailed(Error)
    case dataNotFound
    case migrationFailed(Error)
}

@MainActor
class PersistenceService: PersistenceServiceProtocol {
    private let context: ModelContext // Keep for migration & repository init
    private let storyRepository: StoryRepository
    private let achievementRepository: AchievementRepository // Added
    private let userDefaults: UserDefaults
    private let migrationKey = "storiesMigratedToSwiftData"
    private let legacyStoriesKey = "savedStories"
    private let decoder = JSONDecoder()
    
    init(context: ModelContext, userDefaults: UserDefaults = .standard) {
        self.context = context // Keep for migration & repository init
        self.storyRepository = StoryRepository(modelContext: context)
        self.achievementRepository = AchievementRepository(modelContext: context) // Added
        self.userDefaults = userDefaults
        Task {
            await migrateIfNeeded()
        }
    }
    
    private func migrateIfNeeded() async {
        let migrated = userDefaults.bool(forKey: migrationKey)
        guard !migrated else { return }
        
        guard let data = userDefaults.data(forKey: legacyStoriesKey) else {
            userDefaults.set(true, forKey: migrationKey)
            return
        }
        
        do {
            let legacyStories = try decoder.decode([Story].self, from: data)
            for legacyStory in legacyStories {
                let storyModel = StoryModel(
                    id: legacyStory.id,
                    title: legacyStory.title,
                    timestamp: legacyStory.timestamp,
                    childName: legacyStory.parameters.childName,
                    childAge: legacyStory.parameters.childAge,
                    theme: legacyStory.parameters.theme,
                    favoriteCharacter: legacyStory.parameters.favoriteCharacter
                )
                
                for page in legacyStory.pages {
                    let pageModel = PageModel(
                        id: page.id,
                        content: page.content,
                        pageNumber: page.pageNumber,
                        illustrationRelativePath: page.illustrationRelativePath,
                        illustrationStatus: page.illustrationStatus,
                        imagePrompt: page.imagePrompt,
                        story: storyModel
                    )
                    storyModel.pages.append(pageModel)
                }
                
                context.insert(storyModel)
            }
            try context.save()
            userDefaults.set(true, forKey: migrationKey)
            userDefaults.removeObject(forKey: legacyStoriesKey)
        } catch {
            print("Migration failed: \\(error)")
            // Optionally, set migration flag to avoid retry loop
            userDefaults.set(true, forKey: migrationKey)
        }
    }
    
    func saveStories(_ stories: [Story]) async throws {
        try await storyRepository.saveStories(stories)
    }
    
    func loadStories() async throws -> [Story] {
        let storyModels = try await storyRepository.fetchAllStories()
        return storyRepository.toDomainModels(storyModels)
    }
    
    func saveStory(_ story: Story) async throws {
        print("[PersistenceService] saveStory START (main thread: \(Thread.isMainThread))")
        do {
            try await storyRepository.saveStory(story)
            print("[PersistenceService] saveStory SUCCESS (main thread: \(Thread.isMainThread))")
        } catch {
            print("[PersistenceService] saveStory ERROR: \(error.localizedDescription) (main thread: \(Thread.isMainThread))")
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
    
    /// Saves a standalone achievement or updates an existing one.
    /// - Parameter achievement: The AchievementModel to save.
    func saveAchievement(_ achievement: AchievementModel) async throws {
        // Check if it exists to decide between save (insert) and update
        if let _ = try? await achievementRepository.fetchAchievement(withId: achievement.id) {
            try await achievementRepository.update(achievement)
        } else {
            try await achievementRepository.save(achievement)
        }
    }
    
    /// Fetches all achievements associated with a specific story.
    /// - Parameter storyId: The ID of the story.
    /// - Returns: An array of AchievementModel objects.
    func getAchievements(for storyId: UUID) async throws -> [AchievementModel] {
        try await achievementRepository.fetchAchievements(for: storyId)
    }
    
    /// Fetches all achievements of a specific type.
    /// - Parameter type: The AchievementType to fetch.
    /// - Returns: An array of AchievementModel objects.
    func getAchievements(ofType type: AchievementType) async throws -> [AchievementModel] {
        try await achievementRepository.fetchAchievements(ofType: type)
    }
    
    /// Adds an achievement to a story, ensuring the achievement is saved first.
    /// - Parameters:
    ///   - achievement: The AchievementModel to add.
    ///   - storyId: The ID of the story to link the achievement to.
    func addAchievement(_ achievement: AchievementModel, to storyId: UUID) async throws {
        // 1. Ensure the achievement itself is saved/updated in the context
        try await saveAchievement(achievement)
        
        // 2. Link it to the story via the StoryRepository
        try await storyRepository.addAchievement(achievement, to: storyId)
    }
    
    /// Removes the link between an achievement and a story.
    /// Does not delete the achievement itself.
    /// - Parameters:
    ///   - achievement: The AchievementModel to unlink.
    ///   - storyId: The ID of the story to unlink from.
    func removeAchievement(_ achievement: AchievementModel, from storyId: UUID) async throws {
        try await storyRepository.removeAchievement(achievement, from: storyId)
        // If the achievement should also be deleted, call deleteAchievement here
    }
    
    /// Deletes an achievement permanently.
    /// - Parameter achievement: The AchievementModel to delete.
    func deleteAchievement(_ achievement: AchievementModel) async throws {
        try await achievementRepository.delete(achievement)
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