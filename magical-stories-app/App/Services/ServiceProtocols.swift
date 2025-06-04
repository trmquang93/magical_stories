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

/// Protocol defining the requirements for Illustration services.
protocol IllustrationServiceProtocol {
    /// Generates an illustration using a context-rich description and optionally the previous page's illustration.
    /// - Parameters:
    ///   - illustrationDescription: The detailed, preprocessed description for the illustration.
    ///   - pageNumber: The current page number.
    ///   - totalPages: The total number of pages in the story.
    ///   - previousIllustrationPath: The relative path to the previous page's illustration, if available. Defaults to nil.
    ///   - visualGuide: The visual guide containing character and setting definitions, if available. Defaults to nil.
    ///   - globalReferenceImagePath: The relative path to the global reference image containing all characters and key elements. Defaults to nil.
    ///   - collectionContext: The collection visual context for unified art style and consistency across collection stories. Defaults to nil.
    /// - Returns: A relative path string pointing to the generated illustration, or `nil` if generation fails gracefully.
    /// - Throws: `IllustrationError` for configuration, network, or API issues.
    func generateIllustration(
        for illustrationDescription: String,
        pageNumber: Int,
        totalPages: Int,
        previousIllustrationPath: String?,
        visualGuide: VisualGuide?,
        globalReferenceImagePath: String?,
        collectionContext: CollectionVisualContext?
    ) async throws -> String?
}

// Removed duplicate AchievementRepositoryProtocol, SettingsRepositoryProtocol, and PersistenceError definitions
