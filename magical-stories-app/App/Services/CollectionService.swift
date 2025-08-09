import Combine
import Foundation
import SwiftData


/// Concrete implementation of `CollectionServiceProtocol` using SwiftData.
@MainActor
final class CollectionService: ObservableObject, CollectionServiceProtocol {
    private let repository: any CollectionRepositoryProtocol
    private let storyService: StoryService
    private let achievementRepository: any AchievementRepositoryProtocol
    private weak var ratingService: RatingService?
    // TODO: Add AchievementRepository when implemented

    @Published var collections: [StoryCollection] = []
    @Published var isGenerating: Bool = false
    @Published var generationError: (any Error)?
    private var isLoaded = false

    init(repository: any CollectionRepositoryProtocol, storyService: StoryService, achievementRepository: any AchievementRepositoryProtocol) {
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
        
        // Record collection creation for rating system (non-blocking)
        Task { @MainActor [weak self] in
            await self?.ratingService?.recordEngagementEvent(.storyCompleted)
        }
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
    
    /// Sets the rating service dependency
    /// - Parameter ratingService: The rating service for tracking user engagement
    func setRatingService(_ ratingService: RatingService) {
        self.ratingService = ratingService
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
            let numberOfStories = 3 // Changed from 5 back to 3 to match test expectations

            // NEW: Create unified visual context for entire collection
            let visualContext = createCollectionVisualContext(
                collection: collection,
                parameters: parameters
            )
            
            print("[CollectionService] Created visual context: \(visualContext.collectionTheme)")
            print("[CollectionService] Shared characters: \(visualContext.sharedCharacters)")

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
                
                // Remove the older implementation and keep only the new one
                // Prepare story parameters for each story with unique theme
                
                // Get character name for this story, cycling through available characters if provided
                let characterName: String? = {
                    if let availableCharacters = parameters.characters, !availableCharacters.isEmpty {
                    // Cycle through characters if multiple are provided
                    let characterIndex = index % availableCharacters.count
                    return availableCharacters[characterIndex]
                } else {
                    return nil // Don't provide any character name if none are available
                }
                }()
                
                let storyParams = StoryParameters(
                    theme: theme,
                    childAge: childAge,
                    childName: parameters.childName,
                    favoriteCharacter: characterName,
                    languageCode: parameters.languageCode // Pass the language code from collection parameters
                )

                print(
                    "[CollectionService] Generating story \(index + 1)/\(numberOfStories) for collection \(collection.title) with collection context"
                )

                // Use enhanced story generation with collection context
                let story = try await storyService.generateStory(
                    parameters: storyParams,
                    collectionContext: visualContext
                )

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
            // Track achievement asynchronously without blocking story completion
            Task {
                do {
                    try await trackCollectionCompletionAchievement(collection: collection)
                } catch {
                    print("[CollectionService] Achievement tracking failed: \(error)")
                    // Continue execution - achievement tracking failure shouldn't block story completion
                }
            }
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

        guard let stories = collection.stories else {
            throw NSError(domain: "CollectionService", code: 404,
                         userInfo: [NSLocalizedDescriptionKey: "No stories in collection"])
        }

        guard let storyIndex = stories.firstIndex(where: { $0.id == storyId }) else {
            throw NSError(domain: "CollectionService", code: 404,
                         userInfo: [NSLocalizedDescriptionKey: "Story not found in collection"])
        }

        // Update story completion status - always set to true when marking as completed
        // Check if already completed to avoid redundant operations
        if !stories[storyIndex].isCompleted {
            stories[storyIndex].isCompleted = true
            // REMOVED: collection.stories = stories  // This was causing SwiftData sync issues!
            // The story is already part of the collection's stories array, so modifying it in-place
            // is sufficient and avoids triggering unnecessary SwiftData relationship synchronization

            // Save the updated collection
            try repository.saveCollection(collection)

            // Update collection progress
            try await updateCollectionProgressBasedOnReadCount(collectionId: collectionId)
        } else {
            print("[CollectionService] Story \(storyId) is already marked as completed")
        }
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
        
        // PERFORMANCE FIX: Don't fetch ALL achievements - this was causing the hang!
        // Instead, just try to create the achievement and handle the duplicate case
        do {
            // Associate with the first story in the collection if possible
            let associatedStory = collection.stories?.first
            let achievement = try achievementRepository.createAchievement(
                title: achievementName,
                description: "Completed all stories in the \(collection.title) collection.",
                type: achievementType,
                relatedStoryId: associatedStory?.id,
                earnedAt: Date()
            )
            print("[CollectionService] Achievement for collection \(collection.title) created and saved: \(achievement.id)")
        } catch {
            // If achievement creation fails (likely due to duplicate), just log and continue
            // This prevents the app from hanging when checking for existing achievements
            print("[CollectionService] Could not create achievement for collection \(collection.title): \(error)")
            print("[CollectionService] Achievement may already exist, continuing...")
        }
        
        // TODO: Trigger UI update/notification for achievement unlock (to be handled in UI layer)
    }
    
    // MARK: - Visual Context Creation Methods
    
    /// Create unified visual context for collection
    /// This creates a shared visual framework that ensures consistency across all stories in the collection
    ///
    /// - Parameters:
    ///   - collection: The collection being generated
    ///   - parameters: Collection parameters containing developmental focus, interests, etc.
    /// - Returns: CollectionVisualContext for story generation
    private func createCollectionVisualContext(
        collection: StoryCollection,
        parameters: CollectionParameters
    ) -> CollectionVisualContext {
        
        // Extract shared characters from parameters
        let sharedCharacters = parameters.characters ?? []
        
        // Create unified art style based on age group and developmental focus
        let unifiedArtStyle = createUnifiedArtStyle(
            ageGroup: parameters.childAgeGroup,
            developmentalFocus: parameters.developmentalFocus
        )
        
        // Determine shared props based on interests and developmental focus
        let sharedProps = extractSharedProps(
            interests: parameters.interests,
            developmentalFocus: parameters.developmentalFocus
        )
        
        return CollectionVisualContext(
            collectionId: collection.id,
            collectionTheme: "\(parameters.developmentalFocus) through \(parameters.interests)",
            sharedCharacters: sharedCharacters,
            unifiedArtStyle: unifiedArtStyle,
            developmentalFocus: parameters.developmentalFocus,
            ageGroup: parameters.childAgeGroup,
            requiresCharacterConsistency: true,
            allowsStyleVariation: false,
            sharedProps: sharedProps
        )
    }
    
    /// Create unified art style description based on age group and developmental focus
    ///
    /// - Parameters:
    ///   - ageGroup: Target age group (e.g., "4-6", "5-7")
    ///   - developmentalFocus: Developmental area being targeted
    /// - Returns: Detailed art style description for consistent visuals
    private func createUnifiedArtStyle(ageGroup: String, developmentalFocus: String) -> String {
        let baseStyle = "Warm, engaging children's book illustration style with soft edges and vibrant colors"
        let ageSpecific = ageGroup.contains("3") || ageGroup.contains("4") ? 
            "Simple shapes and bold colors suitable for preschoolers" :
            "Detailed illustrations with rich visual storytelling"
        let focusSpecific = "Visual elements that support \(developmentalFocus) development"
        
        return "\(baseStyle). \(ageSpecific). \(focusSpecific)."
    }
    
    /// Extract shared props from interests and developmental focus
    /// These props will appear consistently across stories in the collection
    ///
    /// - Parameters:
    ///   - interests: Child's interests (comma-separated string)
    ///   - developmentalFocus: Developmental focus area
    /// - Returns: Array of prop descriptions for visual consistency
    private func extractSharedProps(interests: String, developmentalFocus: String) -> [String] {
        var props: [String] = []
        
        // Extract props from interests
        let interestsList = interests.lowercased().components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        for interest in interestsList {
            switch interest {
            case let i where i.contains("animal"):
                props.append("friendly animals")
            case let i where i.contains("space"):
                props.append("stars and planets")
            case let i where i.contains("ocean"):
                props.append("seashells and waves")
            case let i where i.contains("forest"):
                props.append("trees and flowers")
            default:
                props.append(interest)
            }
        }
        
        // Add developmental focus props
        switch developmentalFocus.lowercased() {
        case let f where f.contains("emotional"):
            props.append("expressive faces")
        case let f where f.contains("problem"):
            props.append("puzzle elements")
        case let f where f.contains("social"):
            props.append("group activities")
        default:
            break
        }
        
        return props
    }
}
