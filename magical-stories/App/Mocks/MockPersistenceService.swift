import Foundation
import SwiftData

// MARK: - MockPersistenceService

/// In-memory mock for PersistenceServiceProtocol.
class MockPersistenceService: PersistenceServiceProtocol {
    var storiesToLoad: [Story] = []
    var savedStories: [Story] = []
    var deletedStoryIds: [UUID] = []

    // Properties for test tracking
    var saveStoryCalled: Bool = false
    var storyToSave: Story?
    var loadStoriesCalled: Bool = false
    var saveStoryError: Error?

    func saveStories(_ stories: [Story]) async throws {
        savedStories = stories
    }

    func loadStories() async throws -> [Story] {
        loadStoriesCalled = true
        return storiesToLoad
    }

    func saveStory(_ story: Story) async throws {
        saveStoryCalled = true
        storyToSave = story
        if let error = saveStoryError {
            throw error
        }
        savedStories.append(story)
    }

    func deleteStory(withId id: UUID) async throws {
        deletedStoryIds.append(id)
        savedStories.removeAll { $0.id == id }
    }

    // Implementing the required methods from PersistenceServiceProtocol
    func incrementReadCount(for storyId: UUID) async throws {
        // Implementation for testing - since Story doesn't have readCount, we'll just mark this as a no-op
        print("Mock: incrementReadCount for \(storyId)")
    }

    func toggleFavorite(for storyId: UUID) async throws {
        // Implementation for testing - since Story doesn't have isFavorite, we'll just mark this as a no-op
        print("Mock: toggleFavorite for \(storyId)")
    }

    func updateLastReadAt(for storyId: UUID, date: Date) async throws {
        // Implementation for testing - since Story doesn't have lastReadAt, we'll just mark this as a no-op
        print("Mock: updateLastReadAt for \(storyId) to \(date)")
    }

    // Achievement-related methods
    func saveAchievement(_ achievement: Achievement) async throws {
        // No-op for testing
    }

    func fetchAchievement(id: UUID) async throws -> Achievement? {
        return nil  // For testing
    }

    func fetchAllAchievements() async throws -> [Achievement] {
        return []  // For testing
    }

    func fetchEarnedAchievements() async throws -> [Achievement] {
        return []  // For testing
    }

    func fetchAchievements(forCollection collectionId: UUID) async throws -> [Achievement] {
        return []  // For testing
    }

    func updateAchievementStatus(id: UUID, isEarned: Bool, earnedDate: Date?) async throws {
        // No-op for testing
    }

    func deleteAchievement(withId id: UUID) async throws {
        // No-op for testing
    }

    func associateAchievement(_ achievementId: String, withCollection collectionId: UUID)
        async throws
    {
        // No-op for testing
    }

    func removeAchievementAssociation(_ achievementId: String, fromCollection collectionId: UUID)
        async throws
    {
        // No-op for testing
    }
}
