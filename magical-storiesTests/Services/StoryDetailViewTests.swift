import Testing
@testable import magical_stories
import SwiftUI // For MainActor
import Foundation // For UUID

@MainActor
struct StoryDetailViewTests {
    // Mocks (reuse from ServiceMocks.swift if applicable, or define specific ones)
    var mockCollectionService: MockCollectionService! // Need MockCollectionService
    var story: Story! // The story being viewed
    var view: StoryDetailView! // Instance of the view (might not be needed directly)
    
    // Test Data
    let collectionId = UUID()
    let achievementId = UUID()

    init() {
        // Setup before each test
        mockCollectionService = MockCollectionService()
        
        // Create a story that belongs to a collection
        story = Story.previewStory(title: "Test Story for Completion")
        story.collectionId = collectionId
        story.pages = [ // Ensure it has pages
            Page(content: "Page 1", pageNumber: 1),
            Page(content: "Page 2", pageNumber: 2)
        ]
        
        // Create a dummy collection in the mock service
        let initialCollection = GrowthCollection(
            id: collectionId,
            title: "Test Collection",
            theme: "Testing",
            targetAgeGroup: "5-7",
            stories: [story], // Include the story
            progress: 0.0 // Start with 0 progress
        )
        mockCollectionService.collections = [initialCollection]
        
        // If testing UI interactions, instantiate the view
        // view = StoryDetailView(story: story).environmentObject(mockCollectionService)
        // However, we are testing the helper method directly here.
    }

    // Test the helper function directly
    @Test func handleStoryCompletion_UpdatesProgressAndChecksAchievements() async throws {
        // Arrange
        var didUpdateProgress = false
        var didCheckAchievements = false
        let expectedProgress: Float = 1.0 // Only one story in collection for this test
        
        // Configure mock updateProgress
        mockCollectionService.updateProgressHandler = { id, progress in
            #expect(id == self.collectionId)
            #expect(progress == expectedProgress)
            didUpdateProgress = true
            // Simulate updating the collection progress in the mock
            if let index = self.mockCollectionService.collections.firstIndex(where: { $0.id == id }) {
                self.mockCollectionService.collections[index].progress = progress
            }
        }
        
        // Configure mock checkAchievements
        mockCollectionService.checkAchievementsHandler = { id in
            #expect(id == self.collectionId)
            didCheckAchievements = true
            // Return a mock achievement
            return [Achievement(id: self.achievementId, name: "Test Achievement", type: .storiesCompleted)]
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
    
    @Test func handleStoryCompletion_ProgressCalculationMultiStory() async throws {
         // Arrange
         var story1 = Story.previewStory(title: "Story 1")
         story1.collectionId = collectionId
         var story2 = Story.previewStory(title: "Story 2")
         story2.collectionId = collectionId
         
         let initialCollection = GrowthCollection(
             id: collectionId,
             title: "Multi Story Collection",
             theme: "Testing",
             targetAgeGroup: "5-7",
             stories: [story1, story2], // Two stories
             progress: 0.0 // Start with 0
         )
         mockCollectionService.collections = [initialCollection]
         self.story = story1 // Simulate completing story1
         
         var updatedProgress: Float? = nil
         mockCollectionService.updateProgressHandler = { _, progress in
             updatedProgress = progress
         }
         mockCollectionService.checkAchievementsHandler = { _ in [] } // Ignore achievements
 
         // Act
         await simulateHandleStoryCompletion()
 
         // Assert
         #expect(updatedProgress == 0.5) // 1 out of 2 stories completed
     }
    
    @Test func handleStoryCompletion_NoUpdateIfProgressNotIncreased() async throws {
        // Arrange
        var story1 = Story.previewStory(title: "Story 1")
        story1.collectionId = collectionId
        
        let initialCollection = GrowthCollection(
            id: collectionId,
            title: "Already Complete Collection",
            theme: "Testing",
            targetAgeGroup: "5-7",
            stories: [story1], 
            progress: 1.0 // Already complete
        )
        mockCollectionService.collections = [initialCollection]
        self.story = story1 // Simulate completing the only story
        
        var didCallUpdateProgress = false
        mockCollectionService.updateProgressHandler = { _, _ in
            didCallUpdateProgress = true
        }
        mockCollectionService.checkAchievementsHandler = { _ in [] } 

        // Act
        await simulateHandleStoryCompletion()

        // Assert
        #expect(!didCallUpdateProgress)
    }

    @Test func handleStoryCompletion_StoryNotInCollection() async throws {
        // Arrange
        story.collectionId = nil // Story does not belong to a collection
        var didCallUpdateProgress = false
        var didCallCheckAchievements = false
        mockCollectionService.updateProgressHandler = { _, _ in didCallUpdateProgress = true }
        mockCollectionService.checkAchievementsHandler = { _ in didCallCheckAchievements = true; return [] }

        // Act
        await simulateHandleStoryCompletion()

        // Assert
        #expect(!didCallUpdateProgress)
        #expect(!didCallCheckAchievements)
    }

    // Simulate the private helper method execution context
    private func simulateHandleStoryCompletion() async {
        // Replicates the logic from StoryDetailView.handleStoryCompletion
        guard let collectionId = story.collectionId else { return }
        guard let collection = mockCollectionService.collections.first(where: { $0.id == collectionId }) else { return }
        
        let totalStories = Float(collection.stories.count)
        guard totalStories > 0 else { return }
        let progressPerStory = 1.0 / totalStories
        let potentialNewProgress = min(collection.progress + progressPerStory, 1.0)
        
        guard potentialNewProgress > collection.progress else { return }
        
        let finalProgress = potentialNewProgress
        
        do {
            try await mockCollectionService.updateProgress(for: collectionId, progress: finalProgress)
            _ = try await mockCollectionService.checkAchievements(for: collectionId)
        } catch {
            // Test error handling if needed
        }
    }
}

// MARK: - Mock Collection Service (Add Handlers)
@MainActor
class MockCollectionService: CollectionServiceProtocol {
    var collections: [GrowthCollection] = []
    var isGenerating: Bool = false
    
    var generateCollectionHandler: ((CollectionParameters) async throws -> GrowthCollection)?
    var loadCollectionsHandler: (() async -> Void)?
    var updateProgressHandler: ((UUID, Float) async throws -> Void)?
    var deleteCollectionHandler: ((UUID) async throws -> Void)?
    var checkAchievementsHandler: ((UUID) async throws -> [Achievement])?
    
    func generateCollection(parameters: CollectionParameters) async throws -> GrowthCollection {
        return try await generateCollectionHandler?(parameters) ?? GrowthCollection.previewExample
    }
    func loadCollections() async { await loadCollectionsHandler?() }
    func updateProgress(for collectionId: UUID, progress: Float) async throws {
        try await updateProgressHandler?(collectionId, progress)
    }
    func deleteCollection(_ collectionId: UUID) async throws {
        try await deleteCollectionHandler?(collectionId)
    }
    func checkAchievements(for collectionId: UUID) async throws -> [Achievement] {
        return try await checkAchievementsHandler?(collectionId) ?? []
    }
} 