import Foundation

/// Protocol defining the requirements for Story Collection services.
@MainActor 
protocol CollectionServiceProtocol {
    /// Creates a new Story Collection.
    /// - Parameter collection: The `StoryCollection` to create.
    /// - Throws: An error if creation fails.
    func createCollection(_ collection: StoryCollection) throws

    /// Fetches a specific Story Collection by its ID.
    /// - Parameter id: The `UUID` of the collection to fetch.
    /// - Returns: The `StoryCollection` if found, otherwise `nil`.
    /// - Throws: An error if fetching fails.
    func fetchCollection(id: UUID) throws -> StoryCollection?

    /// Fetches all Story Collections.
    /// - Returns: An array of `StoryCollection` objects.
    /// - Throws: An error if fetching fails.
    func fetchAllCollections() throws -> [StoryCollection]

    /// Updates the progress of a specific Story Collection.
    /// - Parameters:
    ///   - id: The `UUID` of the collection to update.
    ///   - progress: The new progress value (0.0 to 1.0).
    ///   - Throws: An error if updating fails.
    func updateCollectionProgress(id: UUID, progress: Float) throws

    /// Deletes a specific Story Collection.
    /// - Parameter id: The `UUID` of the collection to delete.
    /// - Throws: An error if deletion fails.
    func deleteCollection(id: UUID) throws
    
    /// Loads collections with optional force reload
    /// - Parameter forceReload: Whether to force reload collections
    func loadCollections(forceReload: Bool)
    
    /// Generates stories for a collection
    /// - Parameters:
    ///   - collection: The collection to generate stories for
    ///   - parameters: The parameters for story generation
    /// - Throws: An error if generation fails
    func generateStoriesForCollection(_ collection: StoryCollection, parameters: CollectionParameters) async throws
    
    /// Updates collection progress based on read count
    /// - Parameter collectionId: The collection ID to update
    /// - Returns: The updated progress value
    /// - Throws: An error if update fails
    func updateCollectionProgressBasedOnReadCount(collectionId: UUID) async throws -> Double
    
    /// Marks a story as completed in a collection
    /// - Parameters:
    ///   - storyId: The story ID to mark as completed
    ///   - collectionId: The collection ID containing the story
    /// - Throws: An error if marking fails
    func markStoryAsCompleted(storyId: UUID, collectionId: UUID) async throws
}

/// Protocol defining the requirements for Illustration services.
/// 
/// **DEPRECATED**: This complex protocol is being replaced by SimpleIllustrationServiceProtocol and EmbeddedIllustrationServiceProtocol.
/// Use those protocols for new development.
@available(*, deprecated, message: "Use SimpleIllustrationServiceProtocol or EmbeddedIllustrationServiceProtocol instead. This legacy protocol will be removed.")
protocol IllustrationServiceProtocol: Sendable {
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

/// Protocol for simple illustration service with caching support
protocol SimpleIllustrationServiceProtocol: Sendable {
    /// Generates an illustration for a page
    /// - Parameter page: The page to generate illustration for
    /// - Returns: Image data for the generated illustration
    /// - Throws: Error if generation fails
    func generateIllustration(for page: Page) async throws -> Data
    
    /// Generates an illustration for a page with explicit story context
    /// - Parameters:
    ///   - page: The page to generate illustration for
    ///   - story: The story context for character reference integration
    /// - Returns: Image data for the generated illustration
    /// - Throws: Error if generation fails
    func generateIllustration(for page: Page, in story: Story?) async throws -> Data
    
    /// Gets cached illustration data for a given page ID
    /// - Parameter pageId: The page identifier
    /// - Returns: Cached image data if available
    func getCachedIllustration(for pageId: String) -> Data?
    
    /// Clears all cached illustrations
    func clearCache()
    
    /// Generates an illustration using a raw prompt, bypassing story context
    /// - Parameters:
    ///   - prompt: The raw prompt for illustration generation
    ///   - masterReferenceData: Optional master reference image data
    /// - Returns: Generated image data
    /// - Throws: Error if generation fails
    func generateRawIllustration(prompt: String, masterReferenceData: Data?) async throws -> Data
}

/// Protocol for illustration service with embedded storage support
protocol EmbeddedIllustrationServiceProtocol: Sendable {
    /// Generates and stores illustration directly in the page model
    /// - Parameter page: The page to generate illustration for
    /// - Throws: Error if generation or storage fails
    func generateAndStoreIllustration(for page: Page) async throws
    
    /// Generates and stores illustration directly in the page model with explicit story context
    /// - Parameters:
    ///   - page: The page to generate illustration for
    ///   - story: The story context for character reference integration
    /// - Throws: Error if generation or storage fails
    func generateAndStoreIllustration(for page: Page, in story: Story?) async throws
    
    /// Gets illustration data from embedded storage or cache
    /// - Parameter page: The page to get illustration for
    /// - Returns: Image data if available
    func getIllustration(for page: Page) -> Data?
}

// Removed duplicate AchievementRepositoryProtocol, SettingsRepositoryProtocol, and PersistenceError definitions
