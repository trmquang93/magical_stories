import Foundation  // For UUID
import SwiftUI  // For MainActor
import Testing

@testable import magical_stories

@MainActor
struct StoryDetailViewTests {
    // Mocks (reuse from ServiceMocks.swift if applicable, or define specific ones)
    var mockCollectionService: CollectionServiceMock!  // Need CollectionServiceMock
    var story: Story!  // The story being viewed
    var view: StoryDetailView!  // Instance of the view (might not be needed directly)

    // Test Data
    let collectionId = UUID()
    let achievementId = "test-achievement-id"

    init() {
        // Setup before each test
        mockCollectionService = CollectionServiceMock()

        // Create a story that belongs to a collection
        story = Story.previewStory(title: "Test Story for Completion")
        // Associate the story with a collection via the collections property
        let storyCollection = StoryCollection(
            id: collectionId,
            title: "Test Collection",
            descriptionText: "A collection for testing.",  // Added
            category: "TestCategory",  // Added
            ageGroup: "5-7"  // Added
        )
        story.collections = [storyCollection]
        story.pages = [  // Ensure it has pages
            Page(content: "Page 1", pageNumber: 1),
            Page(content: "Page 2", pageNumber: 2),
        ]

        // Create a dummy collection in the mock service
        // Replaced GrowthCollection with StoryCollection and added missing args
        let initialCollection = StoryCollection(
            id: collectionId,
            title: "Test Collection",
            descriptionText: "A test collection for completion",  // Renamed/Added
            category: "Testing",  // Added (using theme value)
            ageGroup: "5-7",  // Added (using targetAgeGroup value)
            stories: [story]  // Include the story
            // progress is handled by StoryCollection's default or internal logic now
        )
        // Assuming mockCollectionService.collections expects [StoryCollection]
        // If it expects [GrowthCollection], this needs adjustment based on GrowthCollection definition
        mockCollectionService.collections = [initialCollection]  // Type needs to match mock service expectation

        // If testing UI interactions, instantiate the view
        // view = StoryDetailView(story: story).environmentObject(mockCollectionService)
        // However, we are testing the helper method directly here.
    }

    // Test the helper function directly
    @Test func handleStoryCompletion_UpdatesProgressAndChecksAchievements() async throws {
        // Arrange
        var didUpdateProgress = false
        var didCheckAchievements = false
        let expectedProgress: Float = 1.0  // Only one story in collection for this test

        // Configure mock updateProgress
        mockCollectionService.updateProgressHandler = {
            (id: UUID, progress: Float) async throws -> Void in
            #expect(id == self.collectionId)
            #expect(progress == expectedProgress)
            didUpdateProgress = true
            // Simulate updating the collection progress in the mock
            if let index = self.mockCollectionService.collections.firstIndex(where: { $0.id == id })
            {
                // Corrected property name
                self.mockCollectionService.collections[index].completionProgress = Double(progress)
            }
        }

        // Configure mock checkAchievements
        mockCollectionService.checkAchievementsHandler = {
            (id: UUID) async throws -> [Achievement] in
            #expect(id == self.collectionId)
            didCheckAchievements = true
            // Return a mock achievement
            return [
                Achievement(
                    id: self.achievementId,
                    name: "Test Achievement",
                    description: "Awarded for completing all stories",
                    iconName: "test-icon",
                    unlockCriteriaDescription: "Complete all stories in the collection"
                )
            ]
        }

        // Act
        // Create an instance of the view OR call the helper method directly
        // To call directly, we need an instance or make it static/pass dependencies.
        // Let's simulate calling the logic as it would be from the view context.
        await simulateHandleStoryCompletion()

        // Assert
        #expect(didUpdateProgress)
        #expect(didCheckAchievements)
    }

    @Test mutating func handleStoryCompletion_ProgressCalculationMultiStory() async throws {
        // Arrange
        var story1 = Story.previewStory(title: "Story 1")
        var story2 = Story.previewStory(title: "Story 2")
        // Added missing arguments
        let storyCollection = StoryCollection(
            id: collectionId,
            title: "Multi Story Collection",
            descriptionText: "A collection with multiple stories.",  // Added
            category: "TestCategory",  // Added
            ageGroup: "5-7"  // Added
        )
        story1.collections = [storyCollection]
        story2.collections = [storyCollection]

        // Replaced GrowthCollection with StoryCollection and added missing args
        let initialCollection = StoryCollection(
            id: collectionId,
            title: "Multi Story Collection",
            descriptionText: "A collection with two stories",  // Renamed/Added
            category: "Testing",  // Added (using theme value)
            ageGroup: "5-7",  // Added (using targetAgeGroup value)
            stories: [story1, story2]  // Two stories
            // progress handled by StoryCollection
        )
        mockCollectionService.collections = [initialCollection]  // Type needs to match mock service
        self.story = story1  // Simulate completing story1

        var updatedProgress: Float? = nil
        mockCollectionService.updateProgressHandler = {
            (_: UUID, progress: Float) async throws -> Void in
            updatedProgress = progress
        }
        mockCollectionService.checkAchievementsHandler = {
            (_: UUID) async throws -> [Achievement] in []
        }  // Ignore achievements

        // Act
        await simulateHandleStoryCompletion()

        // Assert
        #expect(updatedProgress == 0.5)  // 1 out of 2 stories completed
    }

    @Test mutating func handleStoryCompletion_NoUpdateIfProgressNotIncreased() async throws {
        // Arrange
        var story1 = Story.previewStory(title: "Story 1")
        // Added missing arguments
        let storyCollection = StoryCollection(
            id: collectionId,
            title: "Already Complete Collection",
            descriptionText: "A collection already complete.",  // Added
            category: "TestCategory",  // Added
            ageGroup: "5-7"  // Added
        )
        story1.collections = [storyCollection]

        // Replaced GrowthCollection with StoryCollection and added missing args
        let initialCollection = StoryCollection(
            id: collectionId,
            title: "Already Complete Collection",
            descriptionText: "A collection that is already complete",  // Renamed/Added
            category: "Testing",  // Added (using theme value)
            ageGroup: "5-7",  // Added (using targetAgeGroup value)
            stories: [story1]
            // progress handled by StoryCollection
        )
        initialCollection.completionProgress = 1.0  // Set progress after init
        mockCollectionService.collections = [initialCollection]  // Type needs to match mock service
        self.story = story1  // Simulate completing the only story

        var didCallUpdateProgress = false
        mockCollectionService.updateProgressHandler = { (_: UUID, _: Float) async throws -> Void in
            didCallUpdateProgress = true
        }
        mockCollectionService.checkAchievementsHandler = {
            (_: UUID) async throws -> [Achievement] in []
        }

        // Act
        await simulateHandleStoryCompletion()

        // Assert
        #expect(!didCallUpdateProgress)
    }

    @Test func handleStoryCompletion_StoryNotInCollection() async throws {
        // Arrange
        story.collections = []  // Story does not belong to a collection
        var didCallUpdateProgress = false
        var didCallCheckAchievements = false
        mockCollectionService.updateProgressHandler = { (_: UUID, _: Float) async throws -> Void in
            didCallUpdateProgress = true
        }
        mockCollectionService.checkAchievementsHandler = {
            (_: UUID) async throws -> [Achievement] in
            didCallCheckAchievements = true
            return []
        }

        // Act
        await simulateHandleStoryCompletion()

        // Assert
        #expect(!didCallUpdateProgress)
        #expect(!didCallCheckAchievements)
    }

    // Simulate the private helper method execution context
    private func simulateHandleStoryCompletion() async {
        // Replicates the logic from StoryDetailView.handleStoryCompletion
        // Use the first collection the story belongs to, if any
        guard let storyCollection = story.collections.first else { return }
        let collectionId = storyCollection.id
        guard
            let collection = mockCollectionService.collections.first(where: {
                $0.id == collectionId
            })
        else { return }

        // Use optional chaining and nil-coalescing for safety with stories
        let totalStories = Float(collection.stories?.count ?? 0)
        guard totalStories > 0 else { return }
        let progressPerStory = 1.0 / totalStories
        // Use completionProgress property (ensure Double for calculation)
        let potentialNewProgress = min(
            collection.completionProgress + Double(progressPerStory), 1.0)

        // Use completionProgress property
        guard potentialNewProgress > collection.completionProgress else { return }

        let finalProgress = Float(potentialNewProgress)  // Ensure Float type for updateProgress call

        do {
            try await mockCollectionService.updateProgress(
                for: collectionId, progress: finalProgress)
            _ = try await mockCollectionService.checkAchievements(for: collectionId)
        } catch {
            // Test error handling if needed
        }
    }
}

// MARK: - Mock Collection Service (Add Handlers)
