// magical-stories/App/Services/Repository/AchievementRepository.swift
import Foundation
import SwiftData

/// Repository for Achievement-specific operations
class AchievementRepository: BaseRepository<AchievementModel> {

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
            sortBy: [SortDescriptor(\.earnedAt, order: .reverse)] // Sort by most recent first
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