import Testing
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
}