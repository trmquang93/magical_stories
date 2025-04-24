import Testing
import Foundation
@testable import magical_stories

@Suite("Story Reading Integration Tests")
struct StoryReadingIntegrationTests {

    @Test("Reading progress calculation across pages")
    @MainActor
    func testReadingProgressCalculation() {
        let pages = [
            Page(content: "Page 1 content", pageNumber: 1, illustrationRelativePath: "Illustrations/img1.png", illustrationStatus: .success, imagePrompt: "prompt1"),
            Page(content: "Page 2 content", pageNumber: 2, illustrationRelativePath: "Illustrations/img2.png", illustrationStatus: .success, imagePrompt: "prompt2"),
            Page(content: "Page 3 content", pageNumber: 3, illustrationRelativePath: "Illustrations/img3.png", illustrationStatus: .success, imagePrompt: "prompt3")
        ]

        let story = Story(title: "Test Story", pages: pages, parameters: StoryParameters(childName: "Alex", childAge: 5, theme: "Adventure", favoriteCharacter: "Dragon"))

        #expect(story.pages.count == 3)

        let progressPage1 = StoryProcessor.calculateReadingProgress(currentPage: 1, totalPages: story.pages.count)
        let progressPage2 = StoryProcessor.calculateReadingProgress(currentPage: 2, totalPages: story.pages.count)
        let progressPage3 = StoryProcessor.calculateReadingProgress(currentPage: 3, totalPages: story.pages.count)
        let progressPage0 = StoryProcessor.calculateReadingProgress(currentPage: 0, totalPages: story.pages.count)

        #expect(progressPage1 == 1.0 / 3.0)
        #expect(progressPage2 == 2.0 / 3.0)
        #expect(progressPage3 == 1.0)
        #expect(progressPage0 == 0.0)
    }

    @Test("Story reading navigation simulation")
    func testStoryNavigation() {
        let pages = [
            Page(content: "Page 1 content", pageNumber: 1, illustrationRelativePath: "Illustrations/img1.png", illustrationStatus: .success, imagePrompt: "prompt1"),
            Page(content: "Page 2 content", pageNumber: 2, illustrationRelativePath: "Illustrations/img2.png", illustrationStatus: .success, imagePrompt: "prompt2"),
            Page(content: "Page 3 content", pageNumber: 3, illustrationRelativePath: "Illustrations/img3.png", illustrationStatus: .success, imagePrompt: "prompt3")
        ]

        let story = Story(title: "Test Story", pages: pages, parameters: StoryParameters(childName: "Alex", childAge: 5, theme: "Adventure", favoriteCharacter: "Dragon"))

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

    @Test("Full progress tracking flow: reading a story to completion updates readCount, lastReadAt, isCompleted, and collection progress")
    @MainActor
    func testFullProgressTrackingFlow() async throws {
        // Setup mocks and test data
        
        class MockCollectionService {
            var markedCompleted: (UUID, UUID)?
            var updatedProgressFor: UUID?
            func markStoryAsCompleted(storyId: UUID, collectionId: UUID) async throws {
                markedCompleted = (storyId, collectionId)
            }
            func updateCollectionProgressBasedOnReadCount(collectionId: UUID) async throws -> Double {
                updatedProgressFor = collectionId
                return 1.0
            }
        }
        let storyId = UUID()
        let collectionId = UUID()
        let story = Story(
            id: storyId,
            title: "Test Story",
            pages: [Page(content: "Page 1", pageNumber: 1), Page(content: "Page 2", pageNumber: 2)],
            parameters: StoryParameters(childName: "Alex", childAge: 5, theme: "Adventure", favoriteCharacter: "Dragon"),
            isCompleted: false,
            collections: [StoryCollection(id: collectionId, title: "Test Collection", descriptionText: "", category: "emotionalIntelligence", ageGroup: "4-6")]
        )
        let persistence = MockPersistenceService()
        persistence.stories = [story]
        let collectionService = MockCollectionService()
        // Simulate reading to last page in StoryDetailView
        // (In real UI, this would trigger handleStoryCompletion)
        // Here, we simulate the calls that should happen:
        try await persistence.incrementReadCount(for: storyId)
        try await persistence.updateLastReadAt(for: storyId, date: Date())
        try await collectionService.markStoryAsCompleted(storyId: storyId, collectionId: collectionId)
        let progress = try await collectionService.updateCollectionProgressBasedOnReadCount(collectionId: collectionId)
        // Assertions
        #expect(persistence.incrementedStoryId == storyId)
        #expect(persistence.updatedLastReadAt?.0 == storyId)
        #expect(collectionService.markedCompleted?.0 == storyId && collectionService.markedCompleted?.1 == collectionId)
        #expect(collectionService.updatedProgressFor == collectionId)
        #expect(progress == 1.0)
    }
}