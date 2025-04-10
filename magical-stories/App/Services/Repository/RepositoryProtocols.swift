import Foundation

/// Protocol defining the requirements for managing Growth Collection data.
protocol CollectionRepositoryProtocol {
    /// Saves a new Growth Collection or updates an existing one.
    /// - Parameter collection: The `GrowthCollection` object to save.
    /// - Throws: An error if saving fails (e.g., `PersistenceError.encodingFailed`).
    func saveCollection(_ collection: GrowthCollection) throws

    /// Fetches a specific Growth Collection by its ID.
    /// - Parameter id: The `UUID` of the collection to fetch.
    /// - Returns: The `GrowthCollection` if found, otherwise `nil`.
    /// - Throws: An error if fetching fails (e.g., `PersistenceError.decodingFailed`).
    func fetchCollection(id: UUID) throws -> GrowthCollection?

    /// Fetches all saved Growth Collections.
    /// - Returns: An array of `GrowthCollection` objects. Returns an empty array if none are found.
    /// - Throws: An error if fetching fails (e.g., `PersistenceError.decodingFailed`).
    func fetchAllCollections() throws -> [GrowthCollection]

    /// Updates the progress of a specific Growth Collection.
    /// - Parameters:
    ///   - id: The `UUID` of the collection to update.
    ///   - progress: The new progress value (0.0 to 1.0).
    /// - Throws: An error if the collection is not found or updating fails.
    func updateCollectionProgress(id: UUID, progress: Float) throws

    /// Deletes a specific Growth Collection.
    /// - Parameter id: The `UUID` of the collection to delete.
    /// - Throws: An error if deletion fails.
    func deleteCollection(id: UUID) throws
}

/// Protocol defining the requirements for managing Achievement data.
protocol AchievementRepositoryProtocol {
    /// Saves a new Achievement or updates an existing one.
    /// - Parameter achievement: The `Achievement` object to save.
    /// - Throws: An error if saving fails (e.g., `PersistenceError.encodingFailed`).
    func saveAchievement(_ achievement: Achievement) throws

    /// Fetches a specific Achievement by its ID.
    /// - Parameter id: The `UUID` of the achievement to fetch.
    /// - Returns: The `Achievement` if found, otherwise `nil`.
    /// - Throws: An error if fetching fails (e.g., `PersistenceError.decodingFailed`).
    func fetchAchievement(id: UUID) throws -> Achievement?

    /// Fetches all saved Achievements.
    /// - Returns: An array of `Achievement` objects. Returns an empty array if none are found.
    /// - Throws: An error if fetching fails (e.g., `PersistenceError.decodingFailed`).
    func fetchAllAchievements() throws -> [Achievement]

    /// Fetches all earned Achievements.
    /// - Returns: An array of earned `Achievement` objects. Returns an empty array if none are found.
    /// - Throws: An error if fetching fails (e.g., `PersistenceError.decodingFailed`).
    func fetchEarnedAchievements() throws -> [Achievement]

    /// Fetches all Achievements associated with a specific collection.
    /// - Parameter collectionId: The `UUID` of the collection.
    /// - Returns: An array of `Achievement` objects. Returns an empty array if none are found.
    /// - Throws: An error if fetching fails (e.g., `PersistenceError.decodingFailed`).
    func fetchAchievements(forCollection collectionId: UUID) throws -> [Achievement]

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
}

// Add other repository protocols as needed (e.g., SettingsRepositoryProtocol)

/// Defines potential errors during persistence operations.