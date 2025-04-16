import Combine
import Foundation
import SwiftData

/// Concrete implementation of `CollectionServiceProtocol` using SwiftData.
@MainActor
final class CollectionService: ObservableObject, CollectionServiceProtocol {
    private let repository: CollectionRepositoryProtocol
    private let storyService: StoryService
    private let achievementRepository: AchievementRepository
    // TODO: Add AchievementRepository when implemented

    @Published var collections: [StoryCollection] = []
    @Published var isGenerating: Bool = false
    @Published var generationError: Error?
    private var isLoaded = false

    init(repository: CollectionRepositoryProtocol, storyService: StoryService, achievementRepository: AchievementRepository) {
        self.repository = repository
        self.storyService = storyService
        self.achievementRepository = achievementRepository
        // Load collections immediately on initialization
        loadCollections()
    }

    func createCollection(_ collection: StoryCollection) throws {
        print("[CollectionService] Creating collection: \(collection.title)")
        try repository.saveCollection(collection)
        print("[CollectionService] Collection saved successfully, reloading collections")
        // Reload collections after creation
        loadCollections(forceReload: true)
    }

    func fetchCollection(id: UUID) throws -> StoryCollection? {
        try repository.fetchCollection(id: id)
    }

    func fetchAllCollections() throws -> [StoryCollection] {
        try repository.fetchAllCollections()
    }

    func updateCollectionProgress(id: UUID, progress: Float) throws {
        try repository.updateCollectionProgress(id: id, progress: Float(progress))
    }

    func deleteCollection(id: UUID) throws {
        try repository.deleteCollection(id: id)
    }

    func loadCollections(forceReload: Bool = false) {
        guard !isLoaded || forceReload else { return }
        isLoaded = true
        do {
            let all = try repository.fetchAllCollections()
            print("[CollectionService] Loaded \(all.count) collections from repository")
            for (index, collection) in all.enumerated() {
                print(
                    "[CollectionService] Collection \(index + 1): \(collection.title), id: \(collection.id)"
                )
            }
            DispatchQueue.main.async {
                self.collections = all
                print(
                    "[CollectionService] Published collections updated: \(self.collections.count) items"
                )
            }
        } catch {
            print("[CollectionService] Failed to load collections: \(error)")
        }
    }

    /// Generate multiple stories for a given collection based on its parameters.
    /// This method asynchronously generates a fixed number of stories (e.g., 3) and adds them to the collection.
    ///
    /// - Parameters:
    ///   - collection: The `StoryCollection` to generate stories for
    ///   - parameters: The `CollectionParameters` used to customize story generation
    /// - Throws: StoryServiceError or other errors if story generation or persistence fails
    func generateStoriesForCollection(
        _ collection: StoryCollection, parameters: CollectionParameters
    ) async throws {
        // Set generating state
        DispatchQueue.main.async {
            self.isGenerating = true
            self.generationError = nil
        }
        
        defer {
            DispatchQueue.main.async {
                self.isGenerating = false
            }
        }
        
        do {
            // Number of stories to generate per collection - can be adjusted
            let numberOfStories = 3
            
            // Create dynamic story themes based on developmental focus and interests
            let storyThemes = createStoryThemes(
                developmentalFocus: parameters.developmentalFocus,
                interests: parameters.interests, 
                count: numberOfStories
            )

            var generatedStories: [Story] = []

            for (index, theme) in storyThemes.enumerated() {
                // Extract age from age group (e.g., "4-6" -> 5)
                let ageRange = parameters.childAgeGroup.components(
                    separatedBy: CharacterSet.decimalDigits.inverted
                ).compactMap { Int($0) }
                
                let childAge = ageRange.count >= 2 
                    ? (ageRange[0] + ageRange[1]) / 2  // Average of age range
                    : (ageRange.first ?? 5)  // Default to first number or 5
                
                // Prepare story parameters for each story with unique theme
                let storyParams = StoryParameters(
                    childName: parameters.childName ?? "Child",
                    childAge: childAge,
                    theme: theme,
                    favoriteCharacter: parameters.characters?.first ?? "Friend"
                )

                print(
                    "[CollectionService] Generating story \(index + 1)/\(numberOfStories) for collection \(collection.title) with theme: \(theme)"
                )

                // Generate story using StoryService
                let story = try await storyService.generateStory(parameters: storyParams)
                
                // Add story to collection relationship (bidirectional)
                if !story.collections.contains(where: { $0.id == collection.id }) {
                    story.collections.append(collection)
                }

                generatedStories.append(story)
                
                // Update collection immediately after each story generation for progress feedback
                if index < numberOfStories - 1 {
                    try repository.saveCollection(collection)
                }
            }

            // Add generated stories to the collection if not already added via relationship
            if collection.stories == nil {
                collection.stories = []
            }
            
            for story in generatedStories {
                if !(collection.stories?.contains(where: { $0.id == story.id }) ?? false) {
                    collection.stories?.append(story)
                }
            }

            // Save updated collection with stories
            try repository.saveCollection(collection)

            // Reload collections to update UI
            loadCollections()
            
        } catch {
            print("[CollectionService] Failed to generate stories: \(error)")
            DispatchQueue.main.async {
                self.generationError = error
            }
            throw error
        }
    }
    
    /// Creates varied story themes based on developmental focus and interests
    /// - Parameters:
    ///   - developmentalFocus: The primary developmental area to focus on
    ///   - interests: The child's interests to incorporate
    ///   - count: Number of themes to generate
    /// - Returns: Array of theme strings
    private func createStoryThemes(developmentalFocus: String, interests: String, count: Int) -> [String] {
        let interestsList = interests.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // Base themes combining developmental focus with different aspects
        var baseThemes = [
            "\(developmentalFocus) through Cooperation",
            "\(developmentalFocus) through Problem Solving",
            "\(developmentalFocus) through Friendship",
            "\(developmentalFocus) in Challenging Situations",
            "\(developmentalFocus) with Family"
        ]
        
        // Add interest-specific themes
        for interest in interestsList {
            if !interest.isEmpty {
                baseThemes.append("\(developmentalFocus) with \(interest)")
            }
        }
        
        // Shuffle and take required number, or repeat if not enough themes
        baseThemes.shuffle()
        var result: [String] = []
        
        for i in 0..<count {
            result.append(baseThemes[i % baseThemes.count])
        }
        
        return result
    }
    
    /// Updates the collection progress based on stories' readCount
    /// A story is considered "completed" if it has been read at least once (readCount > 0)
    /// Collection progress is calculated as the ratio of completed stories to total stories
    ///
    /// - Parameter collectionId: The ID of the collection to update
    /// - Returns: The updated progress value (0.0 to 1.0)
    /// - Throws: Error if collection not found or update fails
    @discardableResult
    func updateCollectionProgressBasedOnReadCount(collectionId: UUID) async throws -> Double {
        guard let collection = try repository.fetchCollection(id: collectionId) else {
            throw NSError(domain: "CollectionService", code: 404, 
                          userInfo: [NSLocalizedDescriptionKey: "Collection not found"])
        }
        
        // Ensure we have stories to calculate progress
        guard let stories = collection.stories, !stories.isEmpty else {
            // If no stories, progress is 0
            collection.completionProgress = 0.0
            try repository.saveCollection(collection)
            return 0.0
        }
        
        // Count stories that have isCompleted=true or readCount > 0
        var completedCount = 0
        
        for story in stories {
            if story.isCompleted {
                completedCount += 1
            }
        }
        
        // Calculate progress as ratio of completed to total
        let progress = Double(completedCount) / Double(stories.count)
        
        // Update collection progress
        collection.completionProgress = progress
        collection.updatedAt = Date()
        
        // Save changes
        try repository.saveCollection(collection)
        
        // Check if collection is completed and track achievement if needed
        if progress >= 1.0 {
            try await trackCollectionCompletionAchievement(collection: collection)
        }
        
        return progress
    }
    
    /// Marks a story as completed and updates collection progress
    /// This method should be called when a story is finished being read
    ///
    /// - Parameters:
    ///   - storyId: ID of the completed story
    ///   - collectionId: ID of the collection containing the story
    /// - Throws: Error if story or collection not found or update fails
    func markStoryAsCompleted(storyId: UUID, collectionId: UUID) async throws {
        guard let collection = try repository.fetchCollection(id: collectionId) else {
            throw NSError(domain: "CollectionService", code: 404,
                         userInfo: [NSLocalizedDescriptionKey: "Collection not found"])
        }
        
        guard let story = collection.stories?.first(where: { $0.id == storyId }) else {
            throw NSError(domain: "CollectionService", code: 404,
                         userInfo: [NSLocalizedDescriptionKey: "Story not found in collection"])
        }
        
        // Update story completion status
        story.isCompleted = true
        
        // Save collection which also saves the story due to relationship
        try repository.saveCollection(collection)
        
        // Update collection progress
        try await updateCollectionProgressBasedOnReadCount(collectionId: collectionId)
    }
    
    /// Tracks an achievement for completing a collection
    /// This is a placeholder for the achievement system integration
    ///
    /// - Parameter collection: The completed collection
    /// - Throws: Error if achievement tracking fails
    private func trackCollectionCompletionAchievement(collection: StoryCollection) async throws {
        // Check if an achievement for this collection already exists (by name/type)
        let achievementName = "Completed \(collection.title)"
        let achievementType = AchievementType.growthPathProgress
        let allAchievements = try await achievementRepository.fetchAllAchievements()
        if allAchievements.contains(where: { $0.name == achievementName && $0.typeRawValue == achievementType.rawValue }) {
            print("[CollectionService] Achievement for collection \(collection.title) already exists.")
            return
        }
        // Associate with the first story in the collection if possible
        let associatedStory = collection.stories?.first
        let achievementModel = AchievementModel(
            name: achievementName,
            achievementDescription: "Completed all stories in the \(collection.title) collection.",
            type: achievementType,
            earnedAt: Date(),
            iconName: achievementType.defaultIconName,
            progress: 1.0,
            story: associatedStory as? StoryModel // Only if using StoryModel, otherwise nil
        )
        try await achievementRepository.save(achievementModel)
        print("[CollectionService] Achievement for collection \(collection.title) created and saved.")
        // TODO: Trigger UI update/notification for achievement unlock (to be handled in UI layer)
    }
}
