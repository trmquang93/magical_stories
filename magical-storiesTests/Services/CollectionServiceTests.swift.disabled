import Foundation
import SwiftData
import SwiftUI
import Testing
import XCTest

@testable import magical_stories

// MARK: - Collection Service Errors

enum CollectionError: LocalizedError, Equatable {
    case collectionNotFound
    case storyNotFound
    case generationFailed(String)
    case persistenceFailed

    var errorDescription: String? {
        switch self {
        case .collectionNotFound:
            return "Collection not found"
        case .storyNotFound:
            return "Story not found in collection"
        case .generationFailed(let message):
            return "Failed to generate stories: \(message)"
        case .persistenceFailed:
            return "Failed to save or load collection"
        }
    }

    static func == (lhs: CollectionError, rhs: CollectionError) -> Bool {
        switch (lhs, rhs) {
        case (.collectionNotFound, .collectionNotFound),
            (.storyNotFound, .storyNotFound),
            (.persistenceFailed, .persistenceFailed):
            return true
        case (.generationFailed(let lhsMessage), .generationFailed(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

/// Mock for CollectionRepositoryProtocol to use in tests
class MockCollectionRepository: CollectionRepositoryProtocol {
    var collections: [UUID: StoryCollection] = [:]
    var saveCollectionCalled = false
    var updateProgressCalled = false

    func saveCollection(_ collection: StoryCollection) throws {
        saveCollectionCalled = true
        collections[collection.id] = collection
    }

    func fetchCollection(id: UUID) throws -> StoryCollection? {
        return collections[id]
    }

    func getCollection(id: UUID) throws -> StoryCollection {
        guard let collection = collections[id] else {
            throw CollectionError.collectionNotFound
        }
        return collection
    }

    func fetchAllCollections() throws -> [StoryCollection] {
        return Array(collections.values)
    }

    func updateCollectionProgress(id: UUID, progress: Float) throws {
        updateProgressCalled = true
        if let collection = collections[id] {
            collection.completionProgress = Double(progress)
            collection.updatedAt = Date()
        }
    }

    func deleteCollection(id: UUID) throws {
        collections.removeValue(forKey: id)
    }
}

/// Mock for AchievementRepositoryProtocol to use in tests
class MockAchievementRepository: AchievementRepositoryProtocol {
    var achievements: [UUID: AchievementModel] = [:]
    var saveCalled = false
    var achievementCreationCount = 0  // Added counter
    var lastCreatedAchievement: AchievementModel?  // Added property to capture last created achievement

    // Handlers for mocking behavior
    var createAchievementHandler: ((AchievementModel) throws -> AchievementModel)? = nil
    var achievementExistsHandler: ((String, AchievementType) -> Bool)? = nil

    func saveAchievement(_ achievement: AchievementModel) throws {
        saveCalled = true
        achievements[achievement.id] = achievement
    }

    func fetchAchievement(id: UUID) throws -> AchievementModel? {
        return achievements[id]
    }

    func fetchAllAchievements() throws -> [AchievementModel] {
        return Array(achievements.values)
    }

    func fetchEarnedAchievements() throws -> [AchievementModel] {
        return achievements.values.filter { $0.earnedAt != nil }
    }

    func fetchAchievements(forCollection collectionId: UUID) throws -> [AchievementModel] {
        return []
    }

    func updateAchievementStatus(id: UUID, isEarned: Bool, earnedDate: Date?) throws {
        if let achievement = achievements[id] {
            achievement.earnedAt = isEarned ? (earnedDate ?? Date()) : nil
            achievements[id] = achievement
        }
    }

    func deleteAchievement(id: UUID) throws {
        achievements.removeValue(forKey: id)
    }

    // Add methods needed for Achievement tests
    func createAchievement(
        title: String,
        description: String?,
        type: AchievementType,
        relatedStoryId: UUID?,
        earnedAt: Date?
    ) throws -> AchievementModel {
        // In a real repository, we would find the story by ID
        var story: Story? = nil

        // Find or create a story with the specified ID
        if let storyId = relatedStoryId {
            // Create a mock story with the provided ID for testing purpose
            story = Story(
                id: storyId,
                title: "Test Story",
                pages: [],
                parameters: StoryParameters(
                    theme: "Test Theme",
                    childAge: 5,
                    childName: "Test",
                    favoriteCharacter: "Friend"
                ),
                isCompleted: false,
                collections: [],
                categoryName: nil,
                readCount: 0,
                lastReadAt: nil,
                isFavorite: false,
                achievements: []
            )
        }

        let achievement = AchievementModel(
            name: title,
            achievementDescription: description,
            type: type,
            earnedAt: earnedAt,
            story: story
        )

        // Use try with saveAchievement
        try saveAchievement(achievement)

        // Increment counter and capture the achievement
        achievementCreationCount += 1
        lastCreatedAchievement = achievement

        // Call handler if it exists
        if let handler = createAchievementHandler {
            return try handler(achievement)
        }

        // If no handler, throw an error
        throw CollectionError.persistenceFailed
    }

    func achievementExists(withTitle title: String, ofType type: AchievementType) -> Bool {
        // Use handler if provided
        if let handler = achievementExistsHandler {
            return handler(title, type)
        }

        // Default implementation
        return achievements.values.contains {
            $0.name == title && $0.type == type
        }
    }
}

@Suite("CollectionService Tests")
@MainActor
struct CollectionServiceTests {

    func setupTest() -> (
        service: CollectionService, repository: MockCollectionRepository,
        storyService: MockStoryService, achievementRepository: MockAchievementRepository
    ) {
        let repository = MockCollectionRepository()
        // Use an in-memory ModelContext for MockStoryService
        let modelContext: ModelContext = {
            do {
                return try ModelContext(ModelContainer(for: StoryCollection.self))
            } catch {
                fatalError("Failed to create ModelContext/ModelContainer: \(error)")
            }
        }()
        let storyService: MockStoryService
        do {
            storyService = try MockStoryService(context: modelContext)
        } catch {
            fatalError("Failed to initialize MockStoryService: \(error)")
        }
        let achievementRepository = MockAchievementRepository()
        let service = CollectionService(
            repository: repository, storyService: storyService,
            achievementRepository: achievementRepository)
        return (service, repository, storyService, achievementRepository)
    }

    @Test("generateStoriesForCollection creates stories with varied themes")
    func testGenerateStoriesForCollection() async throws {
        let (service, repository, storyService, _) = setupTest()

        let collection = StoryCollection(
            title: "Test Collection",
            descriptionText: "Test Description",
            category: "emotionalIntelligence",
            ageGroup: "4-6"
        )

        let parameters = CollectionParameters(
            childAgeGroup: "4-6",
            developmentalFocus: "Emotional Intelligence",
            interests: "Dinosaurs",
            childName: "Alex"
        )

        // Configure story service to return a specific number of stories
        let storyParameters1 = StoryParameters(
            theme: "Theme1", childAge: 5, childName: "Alex", favoriteCharacter: "Dino")
        let storyParameters2 = StoryParameters(
            theme: "Theme2", childAge: 5, childName: "Alex", favoriteCharacter: "Dino")
        let storyParameters3 = StoryParameters(
            theme: "Theme1", childAge: 5, childName: "Alex", favoriteCharacter: "Dino")

        let stories = [
            Story(
                title: "Story 1", pages: [], parameters: storyParameters1, isCompleted: false,
                categoryName: "Theme1"),
            Story(
                title: "Story 2", pages: [], parameters: storyParameters2, isCompleted: false,
                categoryName: "Theme2"),
            Story(
                title: "Story 3", pages: [], parameters: storyParameters3, isCompleted: false,
                categoryName: "Theme1"),
        ]
        storyService.storiesToReturn = stories

        // Generate stories for the collection
        try await service.generateStoriesForCollection(collection, parameters: parameters)

        // Assert that the stories were saved to the repository
        try #require(
            repository.collections[collection.id] != nil, "Collection should be saved in repository"
        )
        let savedCollection = try #require(
            repository.collections[collection.id]!, "Collection should exist")
        let savedStories = try #require(savedCollection.stories, "Stories should exist")
        #expect(savedStories.count == 3, "Collection should have 3 stories")
        #expect(repository.saveCollectionCalled, "Repository's saveCollection should be called")
    }

    @Test("generateStoriesForCollection handles story generation failure gracefully")
    func testGenerateStoriesForCollectionHandlesFailureGracefully() async throws {
        let (service, _, storyService, _) = setupTest()

        let collection = StoryCollection(
            title: "Test Collection",
            descriptionText: "Test Description",
            category: "emotionalIntelligence",
            ageGroup: "4-6"
        )

        let parameters = CollectionParameters(
            childAgeGroup: "4-6",
            developmentalFocus: "Emotional Intelligence",
            interests: "Dinosaurs",
            childName: "Alex"
        )

        // Configure story service to simulate an error
        storyService.shouldSimulateError = true
        storyService.simulatedError = CollectionError.generationFailed("Simulated error")

        do {
            // Attempt to generate stories for the collection
            try await service.generateStoriesForCollection(collection, parameters: parameters)
            #expect(false, "Expected an error to be thrown")
        } catch {
            // Assert that the error is of the expected type
            #expect(
                error as? CollectionError == CollectionError.generationFailed("Simulated error"),
                "Error should be generationFailed")
        }
    }

    @Test("generateStoriesForCollection handles network error gracefully")
    func testGenerateStoriesForCollectionHandlesNetworkErrorGracefully() async throws {
        let (service, _, storyService, _) = setupTest()

        let collection = StoryCollection(
            title: "Test Collection",
            descriptionText: "Test Description",
            category: "emotionalIntelligence",
            ageGroup: "4-6"
        )

        let parameters = CollectionParameters(
            childAgeGroup: "4-6",
            developmentalFocus: "Emotional Intelligence",
            interests: "Dinosaurs",
            childName: "Alex"
        )

        // Configure story service to simulate a network error
        storyService.simulateNetworkError = true

        do {
            // Attempt to generate stories for the collection
            try await service.generateStoriesForCollection(collection, parameters: parameters)
            #expect(false, "Expected an error to be thrown")
        } catch {
            // Assert that the error is of the expected type
            let nsError = error as NSError
            #expect(
                nsError.code == NSURLErrorNotConnectedToInternet,
                "Error code should be NSURLErrorNotConnectedToInternet")
        }
    }

    @Test("markStoryAsCompleted toggles completion status and updates progress")
    func testMarkStoryAsCompleted() async throws {
        // Arrange
        let (service, repository, _, _) = setupTest()

        // Create a collection with two stories
        let collection = StoryCollection(
            title: "Test Collection",
            descriptionText: "Test Description",
            category: "emotionalIntelligence",
            ageGroup: "4-6"
        )

        let story1 = Story(
            title: "Story 1",
            pages: [],
            parameters: StoryParameters(
                theme: "Theme1", childAge: 5, childName: "Alex", favoriteCharacter: "Dino"),
            isCompleted: false
        )

        let story2 = Story(
            title: "Story 2",
            pages: [],
            parameters: StoryParameters(
                theme: "Theme2", childAge: 5, childName: "Alex", favoriteCharacter: "Dino"),
            isCompleted: false
        )

        // Setup bidirectional relationships
        story1.collections = [collection]
        story2.collections = [collection]
        collection.stories = [story1, story2]

        try repository.saveCollection(collection)

        // Act & Assert - Initial state
        let initialProgress = try await service.updateCollectionProgressBasedOnReadCount(
            collectionId: collection.id)
        #expect(initialProgress == 0.0, "Initial progress should be 0.0")
        #expect(story1.isCompleted == false, "Story1 should not be completed initially")

        // Mark story1 as completed
        try await service.markStoryAsCompleted(storyId: story1.id, collectionId: collection.id)

        // Verify story1 is now completed
        let collectionAfterFirstMark = try #require(
            repository.collections[collection.id], "Collection should exist")

        // Fix the casting/unwrapping issue - use a valid reference to the story
        let story1AfterToggle = collectionAfterFirstMark.stories?.first(where: {
            $0.id == story1.id
        })
        try #require(story1AfterToggle != nil, "Story1 should exist")
        #expect(story1AfterToggle?.isCompleted == true, "Story1 should be marked as completed")

        // Verify progress updated correctly
        #expect(
            collectionAfterFirstMark.completionProgress == 0.5,
            "Progress should be 0.5 after marking 1 of 2 stories complete")

        // Toggle story1 back to not completed
        try await service.markStoryAsCompleted(storyId: story1.id, collectionId: collection.id)

        // Verify story1 is now not completed
        let collectionAfterSecondMark = try #require(
            repository.collections[collection.id], "Collection should exist")

        // Fix the casting/unwrapping issue
        let story1AfterSecondToggle = collectionAfterSecondMark.stories?.first(where: {
            $0.id == story1.id
        })
        try #require(story1AfterSecondToggle != nil, "Story1 should exist")
        #expect(
            story1AfterSecondToggle?.isCompleted == false,
            "Story1 should be unmarked after second toggle")

        // Verify progress updated correctly
        #expect(
            collectionAfterSecondMark.completionProgress == 0.0,
            "Progress should be 0.0 after unmarking the story")
    }

    @Test("trackCollectionCompletionAchievement creates achievement when collection is completed")
    func testTrackCollectionCompletionAchievement() async throws {
        // Arrange
        let (service, repository, _, achievementRepository) = setupTest()

        // Configure achievementRepository to return created achievements
        achievementRepository.createAchievementHandler = { achievement in
            achievementRepository.achievements[achievement.id] = achievement
            return achievement
        }

        // Configure achievementRepository to check for existing achievements
        achievementRepository.achievementExistsHandler = { title, type in
            return achievementRepository.achievements.values.contains {
                $0.name == title && $0.type == type
            }
        }

        // Create a collection with two stories
        let collection = StoryCollection(
            title: "Test Collection",
            descriptionText: "Test Description",
            category: "emotionalIntelligence",
            ageGroup: "4-6"
        )

        let story1 = Story(
            title: "Story 1",
            pages: [],
            parameters: StoryParameters(
                theme: "Theme1", childAge: 5, childName: "Alex", favoriteCharacter: "Dino"),
            isCompleted: false
        )

        let story2 = Story(
            title: "Story 2",
            pages: [],
            parameters: StoryParameters(
                theme: "Theme2", childAge: 5, childName: "Alex", favoriteCharacter: "Dino"),
            isCompleted: false
        )

        // Setup bidirectional relationships
        story1.collections = [collection]
        story2.collections = [collection]
        collection.stories = [story1, story2]

        try repository.saveCollection(collection)

        // Act - Mark both stories as completed and trigger trackCollectionCompletionAchievement
        story1.isCompleted = true
        story2.isCompleted = true
        try repository.saveCollection(collection)
        collection.completionProgress = 1.0
        try await service.updateCollectionProgressBasedOnReadCount(collectionId: collection.id)

        // Assert - Verify an achievement was created
        let achievements = achievementRepository.achievements.values.map { $0 }
        #expect(achievements.count == 1, "One achievement should be created")

        let achievement = achievements.first
        try #require(achievement != nil, "Achievement should exist")
        #expect(
            achievement?.name == "Completed Test Collection", "Achievement should have correct name"
        )
        #expect(achievement?.type == .growthPathProgress, "Achievement should have correct type")
        #expect(achievement?.earnedAt != nil, "Achievement should have earned date")

        // Act - Trigger achievement creation again
        try await service.updateCollectionProgressBasedOnReadCount(collectionId: collection.id)

        // Assert - Verify no duplicate achievement was created
        let achievementsAfterSecondUpdate = achievementRepository.achievements.values.map { $0 }
        #expect(
            achievementsAfterSecondUpdate.count == 1, "No duplicate achievement should be created")
    }

    // MARK: - Error Handling Tests

    @Test("updateCollectionProgressBasedOnReadCount throws error for non-existent collection")
    func testUpdateCollectionProgressWithNonExistentCollection() async throws {
        // Arrange
        let (service, _, _, _) = setupTest()
        let nonExistentCollectionId = UUID()

        // Act & Assert
        do {
            _ = try await service.updateCollectionProgressBasedOnReadCount(
                collectionId: nonExistentCollectionId)
            #expect(false, "Expected an error to be thrown for non-existent collection")
        } catch {
            // Verify the error is of the expected type with a 404 code
            let nsError = error as NSError
            #expect(
                nsError.domain == "CollectionService",
                "Error should be from CollectionService domain")
            #expect(nsError.code == 404, "Error code should be 404 for not found")
            #expect(
                nsError.localizedDescription.contains("Collection not found"),
                "Error message should indicate collection not found")
        }
    }

    @Test("markStoryAsCompleted throws error for non-existent collection")
    func testMarkStoryAsCompletedWithNonExistentCollection() async throws {
        // Arrange
        let (service, _, _, _) = setupTest()
        let storyId = UUID()
        let nonExistentCollectionId = UUID()

        // Act & Assert
        do {
            try await service.markStoryAsCompleted(
                storyId: storyId, collectionId: nonExistentCollectionId)
            #expect(false, "Expected an error to be thrown for non-existent collection")
        } catch {
            // Verify the error is of the expected type with a 404 code
            let nsError = error as NSError
            #expect(
                nsError.domain == "CollectionService",
                "Error should be from CollectionService domain")
            #expect(nsError.code == 404, "Error code should be 404 for not found")
            #expect(
                nsError.localizedDescription.contains("Collection not found"),
                "Error message should indicate collection not found")
        }
    }

    @Test("markStoryAsCompleted throws error for non-existent story in collection")
    func testMarkStoryAsCompletedWithNonExistentStory() async throws {
        // Arrange
        let (service, repository, _, _) = setupTest()

        // Create a collection with no stories
        let collection = StoryCollection(
            title: "Test Collection",
            descriptionText: "Test Description",
            category: "emotionalIntelligence",
            ageGroup: "4-6"
        )

        collection.stories = []
        try repository.saveCollection(collection)

        // Non-existent story ID
        let nonExistentStoryId = UUID()

        // Act & Assert
        do {
            try await service.markStoryAsCompleted(
                storyId: nonExistentStoryId, collectionId: collection.id)
            #expect(false, "Expected an error to be thrown for non-existent story")
        } catch {
            // Verify the error is of the expected type
            let nsError = error as NSError
            #expect(
                nsError.domain == "CollectionService",
                "Error should be from CollectionService domain")
            #expect(nsError.code == 404, "Error code should be 404 for not found")
            #expect(
                nsError.localizedDescription.contains("Story not found"),
                "Error message should indicate story not found")
        }
    }

    @Test("deleteCollection removes collection from repository")
    func testDeleteCollection() throws {
        // Arrange
        let (service, repository, _, _) = setupTest()

        // Create a collection
        let collection = StoryCollection(
            title: "Test Collection",
            descriptionText: "Test Description",
            category: "emotionalIntelligence",
            ageGroup: "4-6"
        )

        // Save it first
        try repository.saveCollection(collection)

        // Test for collection verification
        let existingCollection = try repository.fetchCollection(id: collection.id)
        try #require(
            existingCollection != nil, "Collection should exist in repository before deletion")

        // Act
        try service.deleteCollection(id: collection.id)

        // Assert
        // Verify the collection was removed from the repository
        let deletedCollection = try repository.fetchCollection(id: collection.id)
        #expect(
            deletedCollection == nil, "Collection should not exist in repository after deletion")
    }
}
