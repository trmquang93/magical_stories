import Foundation
import SwiftData
import Combine

@testable import magical_stories

/// A complete mock implementation of PersistenceServiceProtocol for tests
class MockPersistenceService: ObservableObject, PersistenceServiceProtocol {
    // Properties for tracking method calls
    var readCounts: [UUID: Int] = [:]
    var lastReadTimes: [UUID: Date] = [:]
    var incrementedStoryId: UUID?
    var updatedLastReadAt: (UUID, Date)?
    var stories: [Story] = []
    var storyToSave: Story?
    var savedStories: [Story] = []
    var loadStoriesCalled: Bool = false
    var saveStoryCalled: Bool = false
    var deletedStoryIds: [UUID] = []
    var saveStoryError: Error?
    
    // MARK: - Story Management
    
    func saveStories(_ stories: [Story]) async throws {
        savedStories = stories
    }
    
    func loadStories() async throws -> [Story] {
        loadStoriesCalled = true
        return stories
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
    
    func fetchStory(withId id: UUID) async throws -> Story? {
        return savedStories.first { $0.id == id }
    }
    
    // MARK: - Story State Updates
    
    func incrementReadCount(for storyId: UUID) async throws {
        readCounts[storyId] = (readCounts[storyId] ?? 0) + 1
        incrementedStoryId = storyId
    }
    
    func toggleFavorite(for storyId: UUID) async throws {
        // Implementation for testing - since Story doesn't have isFavorite, we'll just mark this as a no-op
        print("Mock: toggleFavorite for \(storyId)")
    }
    
    func updateLastReadAt(for storyId: UUID, date: Date) async throws {
        lastReadTimes[storyId] = date
        updatedLastReadAt = (storyId, date)
    }
    
    // MARK: - Achievement Management
    
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
    
    func associateAchievement(_ achievementId: String, withCollection collectionId: UUID) async throws {
        // No-op for testing
    }
    
    func removeAchievementAssociation(_ achievementId: String, fromCollection collectionId: UUID) async throws {
        // No-op for testing
    }
}
