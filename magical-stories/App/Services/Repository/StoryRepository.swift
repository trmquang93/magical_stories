import Foundation
import SwiftData

/// Repository for Story-specific operations, handling StoryModel persistence and relationships.
class StoryRepository: BaseRepository<StoryModel> {
    
    /// Initialize with a ModelContext
    /// - Parameter modelContext: The SwiftData model context to use for persistence operations
    override init(modelContext: ModelContext) {
        super.init(modelContext: modelContext)
    }
    
    /// Fetch all stories, sorted by timestamp (newest first)
    /// - Returns: An array of StoryModel objects
    func fetchAllStories() async throws -> [StoryModel] {
        let descriptor = FetchDescriptor<StoryModel>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        return try await fetch(descriptor)
    }
    
    /// Fetch a specific story by its ID
    /// - Parameter id: The unique identifier of the story to fetch
    /// - Returns: The story if found, otherwise nil
    func fetchStory(withId id: UUID) async throws -> StoryModel? {
        let descriptor = FetchDescriptor<StoryModel>(predicate: #Predicate { $0.id == id })
        let results = try await fetch(descriptor)
        return results.first
    }
    
    /// Save or update a story from a domain model
    /// - Parameter story: The Story domain model to save
    /// - Returns: The saved StoryModel
    @discardableResult
    func saveStory(_ story: Story) async throws -> StoryModel {
        // First check if the story already exists
        let existing = try? await fetchStory(withId: story.id)
        
        let storyModel: StoryModel
        if let existing = existing {
            // Update existing story
            storyModel = existing
            storyModel.title = story.title
            storyModel.timestamp = story.timestamp
            storyModel.childName = story.parameters.childName
            storyModel.childAge = story.parameters.childAge
            storyModel.theme = story.parameters.theme
            storyModel.favoriteCharacter = story.parameters.favoriteCharacter
            // NOTE: readCount, isFavorite, lastReadAt are NOT updated here.
            // They should be managed by specific methods like incrementReadCount, toggleFavorite etc.
            // This prevents overwriting existing state when saving core story updates.
            
            // Remove old pages before adding new ones
            // Consider if a more sophisticated diffing approach is needed later
            storyModel.pages.forEach { modelContext.delete($0) } // Ensure old pages are deleted from context
            storyModel.pages.removeAll()
            
        } else {
            // Create new story
            storyModel = StoryModel(
                id: story.id,
                title: story.title,
                timestamp: story.timestamp,
                childName: story.parameters.childName,
                childAge: story.parameters.childAge,
                theme: story.parameters.theme,
                favoriteCharacter: story.parameters.favoriteCharacter
            )
            try await save(storyModel)
        }
        
        // Add pages
        for page in story.pages {
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
        
        // Save changes (insert for new, update for existing)
        // BaseRepository's update/save handles the context save.
        // If it was a new story, it was already saved once. If existing, update persists changes.
        try await update(storyModel) // Ensures changes like page additions/removals are saved
        
        return storyModel
    }
    
    /// Save multiple stories
    /// - Parameter stories: Array of Story domain models to save
    /// - Returns: Array of saved StoryModel objects
    @discardableResult
    func saveStories(_ stories: [Story]) async throws -> [StoryModel] {
        var savedModels = [StoryModel]()
        for story in stories {
            let model = try await saveStory(story)
            savedModels.append(model)
        }
        return savedModels
    }
    
    /// Convert a collection of StoryModel objects to domain Story objects
    /// - Parameter storyModels: The StoryModel objects to convert
    /// - Returns: An array of Story domain objects
    func toDomainModels(_ storyModels: [StoryModel]) -> [Story] {
        return storyModels.map { $0.toStory() } // Assumes toStory() exists and handles new fields if needed
    }
    
    // MARK: - Specific Field Updates -
    
    /// Increments the read count for a specific story.
    /// - Parameter storyId: The ID of the story to update.
    func incrementReadCount(for storyId: UUID) async throws {
        guard let storyModel = try await fetchStory(withId: storyId) else {
            // Handle error: Story not found
            // Consider throwing a specific error type
            print("Error: Story with ID \(storyId) not found for incrementing read count.")
            return
        }
        storyModel.readCount += 1
        storyModel.lastReadAt = Date() // Also update last read time
        try await update(storyModel)
    }
    
    /// Toggles the favorite status for a specific story.
    /// - Parameter storyId: The ID of the story to update.
    func toggleFavorite(for storyId: UUID) async throws {
        guard let storyModel = try await fetchStory(withId: storyId) else {
            print("Error: Story with ID \(storyId) not found for toggling favorite.")
            return
        }
        storyModel.isFavorite.toggle()
        try await update(storyModel)
    }
    
    /// Updates the last read timestamp for a specific story.
    /// - Parameters:
    ///   - storyId: The ID of the story to update.
    ///   - date: The date to set as the last read date (defaults to now).
    func updateLastReadAt(for storyId: UUID, date: Date = Date()) async throws {
        guard let storyModel = try await fetchStory(withId: storyId) else {
            print("Error: Story with ID \(storyId) not found for updating last read date.")
            return
        }
        storyModel.lastReadAt = date
        try await update(storyModel)
    }
    
    // MARK: - Achievement Relationship Management -
    
    /// Adds an achievement to a specific story.
    /// Note: Assumes the AchievementModel is already saved or will be saved in the same context.
    /// - Parameters:
    ///   - achievement: The AchievementModel to add.
    ///   - storyId: The ID of the story to add the achievement to.
    func addAchievement(_ achievement: AchievementModel, to storyId: UUID) async throws {
        guard let storyModel = try await fetchStory(withId: storyId) else {
            print("Error: Story with ID \(storyId) not found for adding achievement.")
            return
        }
        
        // Ensure the achievement isn't already linked (optional check)
        if !(storyModel.achievements?.contains(where: { $0.id == achievement.id }) ?? false) {
            achievement.story = storyModel // Link achievement back to story
            storyModel.achievements?.append(achievement)
            try await update(storyModel) // Save changes to the story model relationship
            // If the achievement wasn't saved before, ensure it is now (might need separate save in service layer)
            // try? await save(achievement) // Or handle in PersistenceService
        }
    }
    
    /// Removes an achievement from a specific story.
    /// Note: This only removes the relationship link. The achievement itself might persist
    /// unless cascade delete is effective or it's deleted separately.
    /// - Parameters:
    ///   - achievement: The AchievementModel to remove.
    ///   - storyId: The ID of the story to remove the achievement from.
    func removeAchievement(_ achievement: AchievementModel, from storyId: UUID) async throws {
        guard let storyModel = try await fetchStory(withId: storyId) else {
            print("Error: Story with ID \(storyId) not found for removing achievement.")
            return
        }
        
        storyModel.achievements?.removeAll { $0.id == achievement.id }
        achievement.story = nil // Unlink achievement from story
        try await update(storyModel) // Save changes to the story model relationship
        // Consider if the achievement itself should be deleted here or handled elsewhere
    }
}