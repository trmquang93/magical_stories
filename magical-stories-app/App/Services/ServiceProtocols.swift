import Foundation

/// Protocol defining the requirements for Story Collection services.
protocol CollectionServiceProtocol {
    /// Creates a new Story Collection.
    /// - Parameter collection: The `StoryCollection` to create.
    /// - Throws: An error if creation fails.
    @MainActor func createCollection(_ collection: StoryCollection) throws

    /// Fetches a specific Story Collection by its ID.
    /// - Parameter id: The `UUID` of the collection to fetch.
    /// - Returns: The `StoryCollection` if found, otherwise `nil`.
    /// - Throws: An error if fetching fails.
    @MainActor func fetchCollection(id: UUID) throws -> StoryCollection?

    /// Fetches all Story Collections.
    /// - Returns: An array of `StoryCollection` objects.
    /// - Throws: An error if fetching fails.
    @MainActor func fetchAllCollections() throws -> [StoryCollection]

    /// Updates the progress of a specific Story Collection.
    /// - Parameters:
    ///   - id: The `UUID` of the collection to update.
    ///   - progress: The new progress value (0.0 to 1.0).
    ///   - Throws: An error if updating fails.
    @MainActor func updateCollectionProgress(id: UUID, progress: Float) throws

    /// Deletes a specific Story Collection.
    /// - Parameter id: The `UUID` of the collection to delete.
    /// - Throws: An error if deletion fails.
    @MainActor func deleteCollection(id: UUID) throws
}

/// Protocol defining the requirements for Story services.
protocol StoryServiceProtocol {
    /// Creates a new Story.
    /// - Parameter story: The `StoryModel` to create.
    /// - Throws: An error if creation fails.
    func createStory(_ story: StoryModel) throws

    /// Fetches a specific Story by its ID.
    /// - Parameter id: The `UUID` of the story to fetch.
    /// - Returns: The `StoryModel` if found, otherwise `nil`.
    /// - Throws: An error if fetching fails.
    func fetchStory(id: UUID) throws -> StoryModel?

    /// Fetches all Stories for a specific collection.
    /// - Parameter collectionId: The `UUID` of the collection.
    /// - Returns: An array of `StoryModel` objects.
    /// - Throws: An error if fetching fails.
    func fetchStories(forCollection collectionId: UUID) throws -> [StoryModel]

    /// Updates a specific Story.
    /// - Parameter story: The `StoryModel` to update.
    /// - Throws: An error if updating fails.
    func updateStory(_ story: StoryModel) throws

    /// Deletes a specific Story.
    /// - Parameter id: The `UUID` of the story to delete.
    /// - Throws: An error if deletion fails.
    func deleteStory(id: UUID) throws
}

/// Protocol defining the requirements for Illustration services.
protocol IllustrationServiceProtocol {
    /// Generates an illustration URL for the given page text and theme.
    /// - Parameters:
    ///   - pageText: The text content of the story page.
    ///   - theme: The overall theme of the story.
    /// - Returns: A relative path string pointing to the generated illustration, or `nil` if generation fails gracefully.
    /// - Throws: `IllustrationError` for configuration, network, or API issues.
    func generateIllustration(for pageText: String, theme: String) async throws -> String?

    /// Generates an illustration using a context-rich description and optionally the previous page's illustration.
    /// - Parameters:
    ///   - illustrationDescription: The detailed, preprocessed description for the illustration.
    ///   - pageNumber: The current page number.
    ///   - totalPages: The total number of pages in the story.
    ///   - previousIllustrationPath: The relative path to the previous page's illustration, if available. Defaults to nil.
    /// - Returns: A relative path string pointing to the generated illustration, or `nil` if generation fails gracefully.
    /// - Throws: `IllustrationError` for configuration, network, or API issues.
    func generateIllustration(
        for illustrationDescription: String,
        pageNumber: Int,
        totalPages: Int,
        previousIllustrationPath: String?
    ) async throws -> String?
}

// Removed duplicate AchievementRepositoryProtocol, SettingsRepositoryProtocol, and PersistenceError definitions
