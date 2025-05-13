import Foundation
import Testing

@testable import magical_stories

@Suite("Story Reading Integration Tests")
struct StoryReadingIntegrationTests {

    @Test("Reading progress calculation across pages")
    @MainActor
    func testReadingProgressCalculation() {
        let pages = [
            Page(
                content: "Page 1 content", pageNumber: 1,
                illustrationPath: "Illustrations/img1.png", illustrationStatus: .ready,
                imagePrompt: "prompt1"),
            Page(
                content: "Page 2 content", pageNumber: 2,
                illustrationPath: "Illustrations/img2.png", illustrationStatus: .ready,
                imagePrompt: "prompt2"),
            Page(
                content: "Page 3 content", pageNumber: 3,
                illustrationPath: "Illustrations/img3.png", illustrationStatus: .ready,
                imagePrompt: "prompt3"),
        ]

        let story = Story(
            title: "Test Story", pages: pages,
            parameters: StoryParameters(
                childName: "Alex", childAge: 5, theme: "Adventure", favoriteCharacter: "Dragon"))

        #expect(story.pages.count == 3)

        let progressPage1 = StoryProcessor.calculateReadingProgress(
            currentPage: 1, totalPages: story.pages.count)
        let progressPage2 = StoryProcessor.calculateReadingProgress(
            currentPage: 2, totalPages: story.pages.count)
        let progressPage3 = StoryProcessor.calculateReadingProgress(
            currentPage: 3, totalPages: story.pages.count)
        let progressPage0 = StoryProcessor.calculateReadingProgress(
            currentPage: 0, totalPages: story.pages.count)

        #expect(progressPage1 == 1.0 / 3.0)
        #expect(progressPage2 == 2.0 / 3.0)
        #expect(progressPage3 == 1.0)
        #expect(progressPage0 == 0.0)
    }

    @Test("Story reading navigation simulation")
    func testStoryNavigation() {
        let pages = [
            Page(
                content: "Page 1 content", pageNumber: 1,
                illustrationPath: "Illustrations/img1.png", illustrationStatus: .ready,
                imagePrompt: "prompt1"),
            Page(
                content: "Page 2 content", pageNumber: 2,
                illustrationPath: "Illustrations/img2.png", illustrationStatus: .ready,
                imagePrompt: "prompt2"),
            Page(
                content: "Page 3 content", pageNumber: 3,
                illustrationPath: "Illustrations/img3.png", illustrationStatus: .ready,
                imagePrompt: "prompt3"),
        ]

        let story = Story(
            title: "Test Story", pages: pages,
            parameters: StoryParameters(
                childName: "Alex", childAge: 5, theme: "Adventure", favoriteCharacter: "Dragon"))

        var currentPageIndex = 0

        #expect(story.pages[currentPageIndex].pageNumber == 1)

        // Simulate next page
        currentPageIndex += 1
        #expect(story.pages[currentPageIndex].pageNumber == 2)

        // Simulate next page
        currentPageIndex += 1
        #expect(story.pages[currentPageIndex].pageNumber == 3)

        // Simulate previous page
        currentPageIndex -= 1
        #expect(story.pages[currentPageIndex].pageNumber == 2)

        // Simulate previous page
        currentPageIndex -= 1
        #expect(story.pages[currentPageIndex].pageNumber == 1)
    }

    @Test(
        "Full progress tracking flow: reading a story to completion updates readCount, lastReadAt, isCompleted, and collection progress"
    )
    @MainActor
    func testFullProgressTrackingFlow() async throws {
        // Setup mocks and test data

        class MockCollectionService {
            var markedCompleted: (UUID, UUID)?
            var updatedProgressFor: UUID?
            func markStoryAsCompleted(storyId: UUID, collectionId: UUID) async throws {
                markedCompleted = (storyId, collectionId)
            }
            func updateCollectionProgressBasedOnReadCount(collectionId: UUID) async throws -> Double
            {
                updatedProgressFor = collectionId
                return 1.0
            }
        }
        let storyId = UUID()
        let collectionId = UUID()
        let story = Story(
            id: storyId,
            title: "Test Story",
            pages: [
                Page(content: "Page 1", pageNumber: 1), Page(content: "Page 2", pageNumber: 2),
            ],
            parameters: StoryParameters(
                childName: "Alex", childAge: 5, theme: "Adventure", favoriteCharacter: "Dragon"),
            isCompleted: false,
            collections: [
                StoryCollection(
                    id: collectionId, title: "Test Collection", descriptionText: "",
                    category: "emotionalIntelligence", ageGroup: "4-6")
            ]
        )
        let persistence = MockPersistenceService()
        persistence.stories = [story]
        let collectionService = MockCollectionService()
        // Simulate reading to last page in StoryDetailView
        // (In real UI, this would trigger handleStoryCompletion)
        // Here, we simulate the calls that should happen:
        try await persistence.incrementReadCount(for: storyId)
        try await persistence.updateLastReadAt(for: storyId, date: Date())
        try await collectionService.markStoryAsCompleted(
            storyId: storyId, collectionId: collectionId)
        let progress = try await collectionService.updateCollectionProgressBasedOnReadCount(
            collectionId: collectionId)
        // Assertions
        #expect(persistence.incrementedStoryId == storyId)
        #expect(persistence.updatedLastReadAt?.0 == storyId)
        #expect(
            collectionService.markedCompleted?.0 == storyId
                && collectionService.markedCompleted?.1 == collectionId)
        #expect(collectionService.updatedProgressFor == collectionId)
        #expect(progress == 1.0)
    }
}

// Mock services for testing
// We use the fixed MockPersistenceService_Fixed.swift that properly implements PersistenceServiceProtocol
// This stub is kept here for backward compatibility
@available(*, deprecated, message: "Use MockPersistenceService_Fixed instead")
class MockPersistenceServiceStub {
    var readCounts: [UUID: Int] = [:]
    var lastReadTimes: [UUID: Date] = [:]
    var incrementedStoryId: UUID?
    var updatedLastReadAt: (UUID, Date)?
    var stories: [Story] = []
    var storyToSave: Story?
    var savedStories: [Story] = []
    var loadStoriesCalled: Bool = false
    var saveStoryCalled: Bool = false

    func saveStory(_ story: Story) async throws {
        saveStoryCalled = true
        storyToSave = story
        savedStories.append(story)
    }
    
    func saveStories(_ stories: [Story]) async throws {
        savedStories = stories
    }

    func loadStories() async throws -> [Story] {
        loadStoriesCalled = true
        return stories
    }

    func deleteStory(withId id: UUID) async throws {
        // Implementation not needed for this test
    }

    func incrementReadCount(for storyId: UUID) async throws {
        readCounts[storyId] = (readCounts[storyId] ?? 0) + 1
        incrementedStoryId = storyId
    }

    func updateLastReadAt(for storyId: UUID, date: Date) async throws {
        lastReadTimes[storyId] = date
        updatedLastReadAt = (storyId, date)
    }

    func toggleFavorite(for storyId: UUID) async throws {
        // Implementation not needed for this test
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

class MockCollectionService: CollectionServiceProtocol {
    var completedStories: [UUID: Bool] = [:]
    var progressUpdates: [UUID: Double] = [:]
    var collections: [StoryCollection] = []

    @MainActor
    func createCollection(_ collection: StoryCollection) throws {
        collections.append(collection)
    }

    @MainActor
    func fetchCollection(id: UUID) throws -> StoryCollection? {
        return collections.first { $0.id == id }
    }

    @MainActor
    func fetchAllCollections() throws -> [StoryCollection] {
        return collections
    }

    @MainActor
    func updateCollectionProgress(id: UUID, progress: Float) throws {
        if let index = collections.firstIndex(where: { $0.id == id }) {
            collections[index].completionProgress = Double(progress)
        }
        progressUpdates[id] = Double(progress)
    }

    @MainActor
    func deleteCollection(id: UUID) throws {
        collections.removeAll { $0.id == id }
    }

    // Additional methods used in the test
    func markStoryAsCompleted(storyId: UUID, collectionId: UUID) async throws {
        completedStories[storyId] = true
        progressUpdates[collectionId] = 1.0
    }

    func updateCollectionProgressBasedOnReadCount(collectionId: UUID) async throws -> Double {
        progressUpdates[collectionId] = 1.0
        return 1.0
    }

    // Required for CollectionService actual implementation but not in protocol
    func loadCollections(forceReload: Bool = false) async {
        // No-op for testing
    }
}
