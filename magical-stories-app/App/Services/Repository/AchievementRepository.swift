// magical-stories/App/Services/Repository/AchievementRepository.swift
import Foundation
import SwiftData

/// Repository for Achievement-specific operations
@MainActor
class AchievementRepository: BaseRepository<AchievementModel>, @preconcurrency AchievementRepositoryProtocol {

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

        // PERFORMANCE FIX: Remove blocking story fetch that was causing UI freeze
        // Story relationship can be established later if needed via async methods
        // The blocking fetchStory(withId:) method was using DispatchSemaphore.wait()
        // which froze the main thread when achievements were created on story completion
        
        try saveAchievement(achievement)
        return achievement
    }

    /// Fetches a story by its ID (synchronous version).
    /// **WARNING: This method uses DispatchSemaphore.wait() which BLOCKS THE MAIN THREAD**
    /// **DO NOT USE - kept for reference only. Use async story fetching instead.**
    /// This method was causing UI freezes when called during story completion.
    @available(*, deprecated, message: "This method blocks the main thread with DispatchSemaphore. Use async alternatives.")
    private func fetchStory(withId id: UUID) throws -> Story? {
        var result: Story?
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            let descriptor = FetchDescriptor<Story>(predicate: #Predicate { $0.id == id })
            let stories = try await modelContext.fetch(descriptor)
            result = stories.first
            semaphore.signal()
        }
        semaphore.wait() // ⚠️ THIS BLOCKS THE MAIN THREAD - DO NOT USE
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
        // Use blocking call temporarily for protocol conformance
        // This should eventually be replaced when protocol is made async
        return try MainActor.assumeIsolated {
            var result: AchievementModel?
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                result = try? await self.fetchAchievement(withId: id)
                semaphore.signal()
            }
            semaphore.wait()
            return result
        }
    }
    /// Fetch all achievements (synchronous protocol requirement)
    /// - Returns: Array of all achievement models
    func fetchAllAchievements() throws -> [AchievementModel] {
        // Use blocking call temporarily for protocol conformance
        // This should eventually be replaced when protocol is made async
        return try MainActor.assumeIsolated {
            var result: [AchievementModel] = []
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                result = (try? await self.fetchAllAchievementsAsync()) ?? []
                semaphore.signal()
            }
            semaphore.wait()
            return result
        }
    }
    
    /// Fetch all achievements asynchronously without blocking
    /// - Returns: Array of all achievement models
    func fetchAllAchievementsAsync() async throws -> [AchievementModel] {
        let descriptor = FetchDescriptor<AchievementModel>(
            sortBy: [SortDescriptor(\.earnedAt, order: .reverse)]
        )
        return try await fetch(descriptor)
    }
    /// Fetch all earned achievements (synchronous protocol requirement)
    /// - Returns: Array of earned achievement models
    func fetchEarnedAchievements() throws -> [AchievementModel] {
        // Use blocking call temporarily for protocol conformance
        // This should eventually be replaced when protocol is made async
        return try MainActor.assumeIsolated {
            var result: [AchievementModel] = []
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                result = (try? await self.fetchEarnedAchievementsAsync()) ?? []
                semaphore.signal()
            }
            semaphore.wait()
            return result
        }
    }
    
    /// Fetch all earned achievements asynchronously without blocking
    /// - Returns: Array of earned achievement models
    func fetchEarnedAchievementsAsync() async throws -> [AchievementModel] {
        let descriptor = FetchDescriptor<AchievementModel>(
            predicate: #Predicate { $0.earnedAt != nil },
            sortBy: [SortDescriptor(\.earnedAt, order: .reverse)]
        )
        return try await fetch(descriptor)
    }
    /// Fetch achievements for a specific collection (synchronous protocol requirement)
    /// - Parameter collectionId: The UUID of the collection
    /// - Returns: Array of achievement models for the collection
    func fetchAchievements(forCollection collectionId: UUID) throws -> [AchievementModel] {
        // Use blocking call temporarily for protocol conformance
        // This should eventually be replaced when protocol is made async
        return try MainActor.assumeIsolated {
            var result: [AchievementModel] = []
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                result = (try? await self.fetchAchievementsAsync(forCollection: collectionId)) ?? []
                semaphore.signal()
            }
            semaphore.wait()
            return result
        }
    }
    
    /// Fetch achievements for a specific collection asynchronously without blocking
    /// - Parameter collectionId: The UUID of the collection
    /// - Returns: Array of achievement models for the collection
    func fetchAchievementsAsync(forCollection collectionId: UUID) async throws -> [AchievementModel] {
        // Note: This implementation assumes achievements are linked to collections via related stories
        // In practice, this might need adjustment based on actual data model relationships
        let descriptor = FetchDescriptor<AchievementModel>(
            sortBy: [SortDescriptor(\.earnedAt, order: .reverse)]
        )
        let allAchievements = try await fetch(descriptor)
        
        // Filter achievements related to the collection
        // This is a simple implementation - might need refinement based on actual requirements
        return allAchievements.filter { achievement in
            // Filter logic would depend on how achievements are linked to collections
            // For now, return empty array as placeholder
            false
        }
    }

    /// Update achievement status (synchronous protocol requirement)
    /// - Parameters:
    ///   - id: The UUID of the achievement to update
    ///   - isEarned: Whether the achievement is earned
    ///   - earnedDate: The date when achievement was earned (nil if not earned)
    func updateAchievementStatus(id: UUID, isEarned: Bool, earnedDate: Date?) throws {
        // Use blocking call temporarily for protocol conformance
        // This should eventually be replaced when protocol is made async
        try MainActor.assumeIsolated {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                try? await self.updateAchievementStatusAsync(id: id, isEarned: isEarned, earnedDate: earnedDate)
                semaphore.signal()
            }
            semaphore.wait()
        }
    }
    
    /// Update achievement status asynchronously without blocking
    /// - Parameters:
    ///   - id: The UUID of the achievement to update
    ///   - isEarned: Whether the achievement is earned
    ///   - earnedDate: The date when achievement was earned (nil if not earned)
    func updateAchievementStatusAsync(id: UUID, isEarned: Bool, earnedDate: Date?) async throws {
        guard let achievement = try await fetchAchievement(withId: id) else {
            print("[AchievementRepository] Achievement with id \(id) not found")
            return
        }
        
        achievement.earnedAt = isEarned ? (earnedDate ?? Date()) : nil
        try await update(achievement)
    }

    /// Delete achievement (synchronous protocol requirement)
    /// - Parameter id: The UUID of the achievement to delete
    func deleteAchievement(id: UUID) throws {
        // Use blocking call temporarily for protocol conformance
        // This should eventually be replaced when protocol is made async
        try MainActor.assumeIsolated {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                try? await self.deleteAchievementAsync(id: id)
                semaphore.signal()
            }
            semaphore.wait()
        }
    }
    
    /// Delete achievement asynchronously without blocking
    /// - Parameter id: The UUID of the achievement to delete
    func deleteAchievementAsync(id: UUID) async throws {
        guard let achievement = try await fetchAchievement(withId: id) else {
            print("[AchievementRepository] Achievement with id \(id) not found for deletion")
            return
        }
        
        try await delete(achievement)
    }
}
