import Foundation
import SwiftData
import SwiftUI
import Combine

/// Protocol defining the requirements for managing Story Collection data.
protocol CollectionRepositoryProtocol {
    /// Saves a new Story Collection or updates an existing one.
    /// - Parameter collection: The `StoryCollection` object to save.
    /// - Throws: An error if saving fails (e.g., `PersistenceError.encodingFailed`).
    func saveCollection(_ collection: StoryCollection) throws

    /// Fetches a specific Story Collection by its ID.
    /// - Parameter id: The `UUID` of the collection to fetch.
    /// - Returns: The `StoryCollection` if found, otherwise `nil`.
    /// - Throws: An error if fetching fails (e.g., `PersistenceError.decodingFailed`).
    func fetchCollection(id: UUID) throws -> StoryCollection?

    /// Fetches all saved Story Collections.
    /// - Returns: An array of `StoryCollection` objects. Returns an empty array if none are found.
    /// - Throws: An error if fetching fails (e.g., `PersistenceError.decodingFailed`).
    func fetchAllCollections() throws -> [StoryCollection]

    /// Updates the progress of a specific Story Collection.
    /// - Parameters:
    ///   - id: The `UUID` of the collection to update.
    ///   - progress: The new progress value (0.0 to 1.0).
    ///   - Throws: An error if the collection is not found or updating fails.
    func updateCollectionProgress(id: UUID, progress: Float) throws

    /// Deletes a specific Story Collection.
    /// - Parameter id: The `UUID` of the collection to delete.
    /// - Throws: An error if deletion fails.
    func deleteCollection(id: UUID) throws
}

/// Protocol defining the requirements for managing Achievement data.
protocol AchievementRepositoryProtocol {
    // TODO: This protocol is now tightly coupled to AchievementModel (the persistence model). Consider adding a conversion layer if a public struct is needed in the future.
    /// Creates a new Achievement.
    /// - Parameters:
    ///   - title: The title of the achievement.
    ///   - description: The description of the achievement.
    ///   - type: The type of achievement.
    ///   - relatedStoryId: The ID of the related story, if any.
    ///   - earnedAt: The date the achievement was earned, if already earned.
    /// - Returns: The created `AchievementModel`.
    /// - Throws: An error if creation fails.
    func createAchievement(
        title: String,
        description: String?,
        type: AchievementType,
        relatedStoryId: UUID?,
        earnedAt: Date?
    ) throws -> AchievementModel

    /// Saves a new Achievement or updates an existing one.
    /// - Parameter achievement: The `AchievementModel` object to save.
    /// - Throws: An error if saving fails (e.g., `PersistenceError.encodingFailed`).
    func saveAchievement(_ achievement: AchievementModel) throws

    /// Fetches a specific Achievement by its ID.
    /// - Parameter id: The `UUID` of the achievement to fetch.
    /// - Returns: The `AchievementModel` if found, otherwise `nil`.
    /// - Throws: An error if fetching fails (e.g., `PersistenceError.decodingFailed`).
    func fetchAchievement(id: UUID) throws -> AchievementModel?

    /// Fetches all saved Achievements.
    /// - Returns: An array of `AchievementModel` objects. Returns an empty array if none are found.
    /// - Throws: An error if fetching fails (e.g., `PersistenceError.decodingFailed`).
    func fetchAllAchievements() throws -> [AchievementModel]

    /// Fetches all earned Achievements.
    /// - Returns: An array of earned `AchievementModel` objects. Returns an empty array if none are found.
    /// - Throws: An error if fetching fails (e.g., `PersistenceError.decodingFailed`).
    func fetchEarnedAchievements() throws -> [AchievementModel]

    /// Fetches all Achievements associated with a specific collection.
    /// - Parameter collectionId: The `UUID` of the collection.
    /// - Returns: An array of `AchievementModel` objects. Returns an empty array if none are found.
    /// - Throws: An error if fetching fails (e.g., `PersistenceError.decodingFailed`).
    func fetchAchievements(forCollection collectionId: UUID) throws -> [AchievementModel]

    /// Updates the earned status of a specific Achievement.
    /// - Parameters:
    ///   - id: The `UUID` of the achievement to update.
    ///   - isEarned: The new earned status.
    ///   - earnedDate: The date when the achievement was earned (if applicable).
    /// - Throws: An error if the achievement is not found or updating fails.
    func updateAchievementStatus(id: UUID, isEarned: Bool, earnedDate: Date?) throws

    /// Deletes a specific Achievement.
    /// - Parameter id: The `UUID` of the achievement to delete.
    /// - Throws: An error if deletion fails.
    func deleteAchievement(id: UUID) throws

    /// Checks if an achievement with the given title and type exists.
    /// - Parameters:
    ///   - title: The title of the achievement.
    ///   - type: The type of the achievement.
    /// - Returns: `true` if an achievement exists, `false` otherwise.
    func achievementExists(withTitle title: String, ofType type: AchievementType) -> Bool
}

/// Protocol defining the requirements for managing Story data.
protocol StoryRepositoryProtocol {
    /// Saves a new Story or updates an existing one.
    /// - Parameter story: The `StoryModel` object to save.
    /// - Throws: An error if saving fails (e.g., `PersistenceError.encodingFailed`).
    func saveStory(_ story: StoryModel) throws

    /// Fetches a specific Story by its ID.
    /// - Parameter id: The `UUID` of the story to fetch.
    /// - Returns: The `StoryModel` if found, otherwise `nil`.
    /// - Throws: An error if fetching fails (e.g., `PersistenceError.decodingFailed`).
    func fetchStory(id: UUID) throws -> StoryModel?

    /// Fetches all saved Stories.
    /// - Returns: An array of `StoryModel` objects. Returns an empty array if none are found.
    /// - Throws: An error if fetching fails (e.g., `PersistenceError.decodingFailed`).
    func fetchAllStories() throws -> [StoryModel]

    /// Deletes a specific Story.
    /// - Parameter id: The `UUID` of the story to delete.
    /// - Throws: An error if deletion fails.
    func deleteStory(id: UUID) throws

    /// Increments the read count for a specific story.
    /// - Parameter id: The `UUID` of the story to update.
    /// - Throws: An error if the story is not found or updating fails.
    func incrementReadCount(id: UUID) throws

    /// Updates the last read date for a specific story.
    /// - Parameter id: The `UUID` of the story to update.
    /// - Throws: An error if the story is not found or updating fails.
    func updateLastReadAt(id: UUID) throws

    /// Toggles the favorite status for a specific story.
    /// - Parameter id: The `UUID` of the story to update.
    /// - Throws: An error if the story is not found or updating fails.
    func toggleFavorite(id: UUID) throws
}

// Removed duplicate SettingsRepositoryProtocol, UserProfileRepositoryProtocol, and PersistenceError definitions
