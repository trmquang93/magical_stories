import SwiftUI

// MARK: - Service Protocols

// Protocol for StoryService
@MainActor protocol StoryServiceProtocol: ObservableObject {
    var stories: [Story] { get }
    var isGenerating: Bool { get }
    
    func generateStory(parameters: StoryParameters) async throws -> Story
    func loadStories() async
}

// Protocol for PersistenceService
protocol PersistenceServiceProtocol {
    func saveStories(_ stories: [Story]) async throws
    func loadStories() async throws -> [Story]
    func saveStory(_ story: Story) async throws
    func deleteStory(withId id: UUID) async throws
}

// Protocol for SettingsService
@MainActor protocol SettingsServiceProtocol: ObservableObject {
    var parentalControls: ParentalControls { get }
    var appSettings: AppSettings { get }
    
    func updateParentalControls(_ controls: ParentalControls)
    func updateAppSettings(_ settings: AppSettings)
}

// Protocol for IllustrationService
protocol IllustrationServiceProtocol {
    /// Generates an illustration image for the given page text and theme.
    /// - Parameters:
    ///   - pageText: The text content of the story page.
    ///   - theme: The overall theme of the story.
    /// - Returns: An optional relative path string to the saved illustration image, or `nil` if generation fails gracefully.
    /// - Throws: `IllustrationError` for configuration, network, or API issues.
    @MainActor
    func generateIllustration(for pageText: String, theme: String) async throws -> String?
}

// Protocol for CollectionService
@MainActor protocol CollectionServiceProtocol: ObservableObject {
    /// The currently available collections
    var collections: [GrowthCollection] { get }
    
    /// Whether a collection is currently being generated
    var isGenerating: Bool { get }
    
    /// Generates a new growth collection based on the provided parameters
    /// - Parameter parameters: The parameters defining the collection's focus and content
    /// - Returns: The generated collection
    /// - Throws: CollectionError for generation, AI, or persistence issues
    func generateCollection(parameters: CollectionParameters) async throws -> GrowthCollection
    
    /// Loads all available collections from persistence
    func loadCollections() async
    
    /// Updates the progress of a specific collection
    /// - Parameters:
    ///   - collectionId: The ID of the collection to update
    ///   - progress: The new progress value (0.0 to 1.0)
    /// - Throws: CollectionError if the update fails
    func updateProgress(for collectionId: UUID, progress: Float) async throws
    
    /// Deletes a specific collection and its associated stories
    /// - Parameter collectionId: The ID of the collection to delete
    /// - Throws: CollectionError if the deletion fails
    func deleteCollection(_ collectionId: UUID) async throws
    
    /// Checks and awards any achievements associated with collection progress
    /// - Parameter collectionId: The ID of the collection to check
    /// - Returns: Array of newly earned achievements, if any
    /// - Throws: CollectionError if the achievement check fails
    func checkAchievements(for collectionId: UUID) async throws -> [Achievement]
}

// Type extensions to make existing services conform to protocols
extension StoryService: StoryServiceProtocol {}
extension SettingsService: SettingsServiceProtocol {}

// MARK: - Service Errors

/// Errors specific to collection operations
enum CollectionError: LocalizedError {
    case generationFailed(Error?)
    case persistenceFailed(Error?)
    case achievementCheckFailed(Error?)
    case invalidProgress
    case collectionNotFound
    case aiServiceError(Error?)
    
    var errorDescription: String? {
        switch self {
        case .generationFailed:
            return "Failed to generate the collection"
        case .persistenceFailed:
            return "Failed to save or load the collection"
        case .achievementCheckFailed:
            return "Failed to check or award achievements"
        case .invalidProgress:
            return "Invalid progress value provided"
        case .collectionNotFound:
            return "The specified collection was not found"
        case .aiServiceError:
            return "Error communicating with AI service"
        }
    }
}
