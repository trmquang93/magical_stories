// magical-stories/App/Services/Repository/AchievementRepository.swift
import Foundation
import SwiftData

/// Repository for Achievement-specific operations
class AchievementRepository: BaseRepository<AchievementModel>, AchievementRepositoryProtocol {

    /// Initialize with a ModelContext
    /// - Parameter modelContext: The SwiftData model context to use for persistence operations
    override init(modelContext: ModelContext) {
        super.init(modelContext: modelContext)
    }

    /// Fetch all achievements linked to a specific story ID
    /// - Parameter storyId: The unique identifier of the story
    /// - Returns: An array of AchievementModel objects linked to the story
    func fetchAchievements(for storyId: UUID) async throws -> [AchievementModel] {
        let descriptor = FetchDescriptor<AchievementModel>(
            predicate: #Predicate { $0.story?.id == storyId },
            sortBy: [SortDescriptor(\.earnedAt, order: .reverse)]  // Sort by most recent first
        )
        return try await fetch(descriptor)
    }

    /// Fetch all achievements of a specific type
    /// - Parameter type: The type of achievement to fetch
    /// - Returns: An array of AchievementModel objects of the specified type
    func fetchAchievements(ofType type: AchievementType) async throws -> [AchievementModel] {
        let typeRawValue = type.rawValue
        let descriptor = FetchDescriptor<AchievementModel>(
            predicate: #Predicate { $0.typeRawValue == typeRawValue },
            sortBy: [SortDescriptor(\.earnedAt, order: .reverse)]
        )
        return try await fetch(descriptor)
    }

    /// Fetch a specific achievement by its ID
    /// - Parameter id: The unique identifier of the achievement
    /// - Returns: The achievement if found, otherwise nil
    func fetchAchievement(withId id: UUID) async throws -> AchievementModel? {
        let descriptor = FetchDescriptor<AchievementModel>(predicate: #Predicate { $0.id == id })
        let results = try await fetch(descriptor)
        return results.first
    }

    // Add other specific fetch/query methods as needed, e.g.,
    // - fetchRecentAchievements(limit: Int)
    // - fetchAchievements(earnedAfter: Date)
}

// MARK: - Protocol Conformance (Implied)

extension AchievementRepository {  // Using extension for clarity

    /// Fetches all achievements sorted by earned date (most recent first).
    /// - Returns: An array of all AchievementModel objects.
    func fetchAllAchievements() async throws -> [AchievementModel] {
        let descriptor = FetchDescriptor<AchievementModel>(sortBy: [
            SortDescriptor(\.earnedAt, order: .reverse)
        ])
        return try await fetch(descriptor)
    }

    /// Fetches all achievements that have been earned (earnedAt is not nil).
    /// - Returns: An array of earned AchievementModel objects.
    func fetchEarnedAchievements() async throws -> [AchievementModel] {
        let descriptor = FetchDescriptor<AchievementModel>(
            predicate: #Predicate { $0.earnedAt != nil },
            sortBy: [SortDescriptor(\.earnedAt, order: .reverse)]
        )
        return try await fetch(descriptor)
    }

    /// Updates the earned status and date of a specific achievement.
    /// - Parameters:
    ///   - id: The UUID of the achievement to update.
    ///   - isEarned: Boolean indicating if the achievement is now earned.
    ///   - earnedDate: The date the achievement was earned (defaults to now if isEarned is true and date is nil).
    func updateAchievementStatus(id: UUID, isEarned: Bool, earnedDate: Date?) async throws {
        guard let achievement = try await fetchAchievement(withId: id) else {
            throw PersistenceError.dataNotFound  // Or handle appropriately
        }
        achievement.earnedAt = isEarned ? (earnedDate ?? Date()) : nil
        // SwiftData tracks changes, saving happens at a higher level or explicitly if needed
        // No explicit save call here, assuming context saves changes.
        // If BaseRepository doesn't handle auto-save on modification, add `try await save(achievement)`
    }

    /// Fetches achievements associated with a specific collection ID.
    /// **Note:** Requires `AchievementModel` to have a relationship (direct or indirect) with `StoryCollectionModel`.
    /// - Parameter collectionId: The UUID of the collection.
    /// - Returns: An array of AchievementModel objects associated with the collection.
    func fetchAchievements(forCollection collectionId: UUID) async throws -> [AchievementModel] {
        // Placeholder: This requires knowing how achievements relate to collections.
        // Example if Achievement links to Story, and Story links to Collection:
        // let storyPredicate = #Predicate<Story> { story in
        //     story.collections.contains { $0.id == collectionId }
        // }
        // let achievementPredicate = #Predicate<AchievementModel> { achievement in
        //     achievement.story != nil && storyPredicate.evaluate(achievement.story!)
        // }
        // let descriptor = FetchDescriptor<AchievementModel>(predicate: achievementPredicate)
        // return try await fetch(descriptor)

        print(
            "Warning: fetchAchievements(forCollection:) needs implementation based on actual data model relationships."
        )
        return []  // Return empty until implemented correctly
    }

    /// Associates an achievement with a collection.
    /// **Note:** Requires relationship modification capabilities.
    /// - Parameters:
    ///   - achievementId: The ID of the achievement (assuming String for consistency with UserDefaults version, adjust if needed).
    ///   - collectionId: The UUID of the collection.
    func associateAchievement(_ achievementId: String, withCollection collectionId: UUID)
        async throws
    {
        // Placeholder: Implementation depends on how the relationship is modeled.
        // Might involve fetching the achievement and collection models and updating their relationship properties.
        guard let achievementUUID = UUID(uuidString: achievementId),
            (try await fetchAchievement(withId: achievementUUID)) != nil
        else {
            throw PersistenceError.dataNotFound
        }
        // Fetch the CollectionModel (requires CollectionRepository)
        // Update the relationship (e.g., achievement.collections.append(collection) or collection.achievements.append(achievement))
        // Save changes if needed.
        print(
            "Warning: associateAchievement(_:withCollection:) needs implementation based on actual data model relationships."
        )
        // throw PersistenceError.repositoryError(NSError(domain: "Not implemented", code: -1))
    }

    /// Removes an achievement's association with a collection.
    /// **Note:** Requires relationship modification capabilities.
    /// - Parameters:
    ///   - achievementId: The ID of the achievement (assuming String).
    ///   - collectionId: The UUID of the collection.
    func removeAchievementAssociation(_ achievementId: String, fromCollection collectionId: UUID)
        async throws
    {
        // Placeholder: Implementation depends on how the relationship is modeled.
        // Might involve fetching models and removing links from their relationship properties.
        guard let achievementUUID = UUID(uuidString: achievementId),
            (try await fetchAchievement(withId: achievementUUID)) != nil
        else {
            throw PersistenceError.dataNotFound
        }
        // Fetch the CollectionModel
        // Remove the relationship link
        // Save changes if needed.
        print(
            "Warning: removeAchievementAssociation(_:fromCollection:) needs implementation based on actual data model relationships."
        )
        // throw PersistenceError.repositoryError(NSError(domain: "Not implemented", code: -1))
    }
}

// MARK: - AchievementRepositoryProtocol Synchronous Conformance (Temporary Workaround)
// TODO: This is a temporary workaround to satisfy AchievementRepositoryProtocol, which requires synchronous methods.
// In the future, refactor the protocol and all usages to be async/await throughout.
extension AchievementRepository {

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
    ) throws -> AchievementModel {
        let achievement = AchievementModel(
            id: UUID(),
            name: title,
            achievementDescription: description,
            type: type,
            earnedAt: earnedAt
        )

        // If there's a related story, fetch and link it
        if let storyId = relatedStoryId, let story = try fetchStory(withId: storyId) {
            achievement.story = story
        }

        try saveAchievement(achievement)
        return achievement
    }

    /// Fetches a story by its ID (synchronous version).
    /// This is a helper method for the createAchievement method.
    private func fetchStory(withId id: UUID) throws -> Story? {
        var result: Story?
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            let descriptor = FetchDescriptor<Story>(predicate: #Predicate { $0.id == id })
            let stories = try await modelContext.fetch(descriptor)
            result = stories.first
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }

    /// Checks if an achievement with the given title and type exists.
    /// - Parameters:
    ///   - title: The title of the achievement.
    ///   - type: The type of the achievement.
    /// - Returns: `true` if an achievement exists, `false` otherwise.
    func achievementExists(withTitle title: String, ofType type: AchievementType) -> Bool {
        var exists = false
        let semaphore = DispatchSemaphore(value: 0)

        Task {
            do {
                let typeRawValue = type.rawValue
                let descriptor = FetchDescriptor<AchievementModel>(
                    predicate: #Predicate { $0.name == title && $0.typeRawValue == typeRawValue }
                )
                let results = try await fetch(descriptor)
                exists = !results.isEmpty
            } catch {
                exists = false
            }
            semaphore.signal()
        }

        semaphore.wait()
        return exists
    }

    func saveAchievement(_ achievement: AchievementModel) throws {
        // If async save is needed, implement here. For now, assume context auto-saves.
        // If explicit save is needed, add: try await save(achievement)
    }
    func fetchAchievement(id: UUID) throws -> AchievementModel? {
        var result: AchievementModel?
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            result = try? await fetchAchievement(withId: id)
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }
    func fetchAllAchievements() throws -> [AchievementModel] {
        var result: [AchievementModel] = []
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            result = (try? await fetchAllAchievements()) ?? []
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }
    func fetchEarnedAchievements() throws -> [AchievementModel] {
        var result: [AchievementModel] = []
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            result = (try? await fetchEarnedAchievements()) ?? []
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }
    func fetchAchievements(forCollection collectionId: UUID) throws -> [AchievementModel] {
        var result: [AchievementModel] = []
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            result = (try? await fetchAchievements(forCollection: collectionId)) ?? []
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }

    func updateAchievementStatus(id: UUID, isEarned: Bool, earnedDate: Date?) throws {
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            do {
                try await updateAchievementStatus(
                    id: id, isEarned: isEarned, earnedDate: earnedDate)
            } catch {
                print("Error updating achievement status: \(error)")
            }
            semaphore.signal()
        }
        semaphore.wait()
    }

    func deleteAchievement(id: UUID) throws {
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            do {
                if let achievement = try await fetchAchievement(withId: id) {
                    try await delete(achievement)
                }
            } catch {
                print("Error deleting achievement: \(error)")
            }
            semaphore.signal()
        }
        semaphore.wait()
    }
}
