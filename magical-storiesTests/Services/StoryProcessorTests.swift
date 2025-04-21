import Foundation
// magical-storiesTests/Services/StoryProcessorTests.swift
// MARK: - Story Processor Tests
import Testing

@testable import magical_stories

// MARK: - Mock Illustration Service
@MainActor
class MockIllustrationService: IllustrationServiceProtocol {
    var generateIllustrationCallCount = 0
    // Store the parameters received by the last call
    var lastCallParameters: (pageText: String, theme: String)?
    var generateIllustrationPrompts: [(pageText: String, theme: String)] = []  // Store all parameters received
    var generateIllustrationShouldReturnURL: URL? = URL(string: "https://mock.url/image.png")  // Default success URL
    var generateIllustrationShouldThrowError: Error? = nil  // Default no error
    var urlToReturn: URL? = URL(string: "https://mock.url/image.png")  // Control return value

    // Update signature to match protocol
    @MainActor
    func generateIllustration(for pageText: String, theme: String) async throws -> String? {
        generateIllustrationCallCount += 1
        lastCallParameters = (pageText, theme)
        generateIllustrationPrompts.append((pageText, theme))

        if let error = generateIllustrationShouldThrowError {
            print(
                "--- MockIllustrationService: Throwing error for pageText: \(pageText.prefix(50))..., theme: \(theme) ---"
            )
            throw error
        }
        let relativePath = urlToReturn?.path.replacingOccurrences(
            of: "/private/var/mobile/Containers/Data/Application/UUID/Application Support/",
            with: "")
        print(
            "--- MockIllustrationService: Returning relative path \(relativePath ?? "nil") for pageText: \(pageText.prefix(50))..., theme: \(theme) ---"
        )
        return relativePath
    }

    func reset() {
        generateIllustrationCallCount = 0
        lastCallParameters = nil
        generateIllustrationPrompts = []
        generateIllustrationShouldThrowError = nil
        urlToReturn = URL(string: "https://mock.url/image.png")
    }
}

@Suite("StoryProcessor Tests")
struct StoryProcessorTests {

    @Test("Short story segmentation")
    @MainActor
    func testShortStorySegmentation() async throws {
        let mockIllustrationService = MockIllustrationService()
        let storyProcessor = StoryProcessor(illustrationService: mockIllustrationService)

        let shortContent = "Once upon a time, there was a brave lion."
        let theme = "Bravery"

        let pages = try await storyProcessor.processIntoPages(shortContent, theme: theme)

        #expect(!pages.isEmpty)
        #expect(pages.count == 1)
        #expect(pages[0].content == shortContent)
        #expect(pages[0].pageNumber == 1)
    }

    @Test("Medium story segmentation")
    @MainActor
    func testMediumStorySegmentation() async throws {
        let mockIllustrationService = MockIllustrationService()
        let storyProcessor = StoryProcessor(illustrationService: mockIllustrationService)

        let mediumContent = """
            Once upon a time, there was a brave lion who lived in the forest.

            The lion was very kind and helped all the animals in need.

            One day, the lion found a lost rabbit and helped it find its way home.

            The rabbit was very grateful and they became good friends.
            """
        let theme = "Kindness"

        let pages = try await storyProcessor.processIntoPages(mediumContent, theme: theme)

        #expect(pages.count > 1)
        #expect(pages[0].pageNumber == 1)
        #expect(pages[1].pageNumber == 2)
        #expect(pages[0].content.contains("Once upon a time"))
        #expect(pages[0].content.contains("lion was very kind"))
        #expect(pages[1].content.contains("found a lost rabbit"))
    }
    
    @Test("Delimiter-based story segmentation")
    @MainActor
    func testDelimiterBasedSegmentation() async throws {
        let mockIllustrationService = MockIllustrationService()
        let storyProcessor = StoryProcessor(illustrationService: mockIllustrationService)

        let contentWithDelimiters = """
            Once upon a time, there was a brave lion who lived in the forest.
            The lion was very kind and helped all the animals in need.
            ---
            One day, the lion found a lost rabbit and helped it find its way home.
            The rabbit was very grateful and they became good friends.
            ---
            From that day forward, the lion and the rabbit went on many adventures together.
            They taught everyone in the forest about the importance of friendship.
            """
        let theme = "Friendship"

        let pages = try await storyProcessor.processIntoPages(contentWithDelimiters, theme: theme)

        #expect(pages.count == 3)
        
        #expect(pages[0].pageNumber == 1)
        #expect(pages[1].pageNumber == 2)
        #expect(pages[2].pageNumber == 3)
        
        #expect(pages[0].content.contains("Once upon a time"))
        #expect(pages[1].content.contains("One day, the lion found"))
        #expect(pages[2].content.contains("From that day forward"))
        
        // Verify the delimiters are removed from the content
        for page in pages {
            #expect(!page.content.contains("---"))
        }
    }
    
    @Test("Delimiter-based segmentation with empty segments")
    @MainActor
    func testDelimiterBasedSegmentationWithEmptySegments() async throws {
        let mockIllustrationService = MockIllustrationService()
        let storyProcessor = StoryProcessor(illustrationService: mockIllustrationService)

        let contentWithEmptySegments = """
            First page content.
            ---
            
            ---
            Third page content.
            ---
            
            ---
            Fifth page content.
            """
        let theme = "Testing"

        let pages = try await storyProcessor.processIntoPages(contentWithEmptySegments, theme: theme)

        // Empty segments should be skipped
        #expect(pages.count == 3)
        
        #expect(pages[0].pageNumber == 1)
        #expect(pages[1].pageNumber == 2)
        #expect(pages[2].pageNumber == 3)
        
        #expect(pages[0].content.contains("First page content"))
        #expect(pages[1].content.contains("Third page content"))
        #expect(pages[2].content.contains("Fifth page content"))
    }
    
    @Test("Custom delimiter segmentation")
    @MainActor
    func testCustomDelimiterSegmentation() async throws {
        let mockIllustrationService = MockIllustrationService()
        let storyProcessor = StoryProcessor(illustrationService: mockIllustrationService)

        let contentWithCustomDelimiter = """
            First page content.
            ===PAGE BREAK===
            Second page content.
            ===PAGE BREAK===
            Third page content.
            """
        
        // Call paginateStory directly to test the custom delimiter
        let pages = storyProcessor.paginateStory(contentWithCustomDelimiter, delimiter: "===PAGE BREAK===")

        #expect(pages.count == 3)
        
        #expect(pages[0].pageNumber == 1)
        #expect(pages[1].pageNumber == 2)
        #expect(pages[2].pageNumber == 3)
        
        #expect(pages[0].content.contains("First page content"))
        #expect(pages[1].content.contains("Second page content"))
        #expect(pages[2].content.contains("Third page content"))
        
        // Verify the custom delimiters are removed from the content
        for page in pages {
            #expect(!page.content.contains("===PAGE BREAK==="))
        }
    }
    
    @Test("Fallback to paragraph-based segmentation when no delimiter")
    @MainActor
    func testFallbackWhenNoDelimiter() async throws {
        let mockIllustrationService = MockIllustrationService()
        let storyProcessor = StoryProcessor(illustrationService: mockIllustrationService)

        let contentWithoutDelimiters = """
            First paragraph of content with no delimiters.

            Second paragraph of content.

            Third paragraph of content.

            Fourth paragraph which should be on a different page.
            """
        let theme = "Testing"

        let pages = try await storyProcessor.processIntoPages(contentWithoutDelimiters, theme: theme)

        // Should fall back to paragraph-based segmentation
        #expect(pages.count > 1)
        #expect(pages[0].content.contains("First paragraph"))
        #expect(pages[0].content.contains("Second paragraph"))
    }

    @Test("Long story segmentation")
    @MainActor
    func testLongStorySegmentation() async throws {
        let mockIllustrationService = MockIllustrationService()
        let storyProcessor = StoryProcessor(illustrationService: mockIllustrationService)

        let longContent = """
            Once upon a time, there was a brave lion who lived in the forest.

            The lion was very kind and helped all the animals in need. The other animals respected him greatly.

            One day, the lion found a lost rabbit who had wandered too far from home.

            The lion decided to help the little rabbit find its way back to its family.

            They traveled through the forest, meeting many other animals along the way.

            The journey was long, but the lion was patient and guided the rabbit carefully.

            Finally, they reached the rabbit's home, and the rabbit's family was overjoyed.

            They thanked the lion for his kindness and invited him to visit anytime.

            The lion and the rabbit remained friends forever after that adventure.
            """
        let theme = "Friendship"

        let pages = try await storyProcessor.processIntoPages(longContent, theme: theme)

        #expect(pages.count >= 3)

        for i in 0..<pages.count {
            #expect(pages[i].pageNumber == i + 1)
        }

        let contentLengths = pages.map { $0.content.count }
        let maxLength = contentLengths.max() ?? 0
        let minLength = contentLengths.min() ?? 0

        #expect(minLength > 0)

        if maxLength > 0 {
            #expect(Double(minLength) / Double(maxLength) > 0.3)
        }
    }

    @Test("Empty content returns empty pages")
    @MainActor
    func testEmptyContent() async throws {
        let mockIllustrationService = MockIllustrationService()
        let storyProcessor = StoryProcessor(illustrationService: mockIllustrationService)

        let emptyContent = ""
        let theme = "Empty"

        let pages = try await storyProcessor.processIntoPages(emptyContent, theme: theme)

        #expect(pages.isEmpty)
    }

    @Test("Whitespace content returns empty pages")
    @MainActor
    func testWhitespaceContent() async throws {
        let mockIllustrationService = MockIllustrationService()
        let storyProcessor = StoryProcessor(illustrationService: mockIllustrationService)

        let whitespaceContent = "   \n   \t   "
        let theme = "Whitespace"

        let pages = try await storyProcessor.processIntoPages(whitespaceContent, theme: theme)

        #expect(pages.isEmpty)
    }

    @Test("Very long paragraph is split across pages")
    @MainActor
    func testVeryLongParagraph() async throws {
        let mockIllustrationService = MockIllustrationService()
        let storyProcessor = StoryProcessor(illustrationService: mockIllustrationService)

        let sentence = "This is a sentence that will be repeated to create a very long paragraph. "
        var longParagraph = ""
        for _ in 0..<20 {
            longParagraph += sentence
        }
        let theme = "Long"

        let pages = try await storyProcessor.processIntoPages(longParagraph, theme: theme)

        #expect(pages.count > 1)

        for page in pages {
            #expect(page.content.count <= StoryProcessor.maxPageContentLength + 100)
            #expect(!page.content.isEmpty)
        }
    }

    @Test("Content formatting preserved")
    @MainActor
    func testContentFormatting() async throws {
        let mockIllustrationService = MockIllustrationService()
        let storyProcessor = StoryProcessor(illustrationService: mockIllustrationService)

        let content = """
            First paragraph with some text.

            Second paragraph with more text.
            This is still the second paragraph.

            Third paragraph.
            """
        let theme = "Formatting"

        let pages = try await storyProcessor.processIntoPages(content, theme: theme)

        #expect(!pages.isEmpty)
        #expect(pages[0].content.contains("First paragraph"))

        let pageWithSecondParagraph = pages.first { $0.content.contains("Second paragraph") }
        #expect(pageWithSecondParagraph != nil, "Second paragraph should be found")
        let unwrappedPage = pageWithSecondParagraph!

        #expect(
            unwrappedPage.content.contains(
                "Second paragraph with more text.\nThis is still the second paragraph.")
                || unwrappedPage.content
                    == "Second paragraph with more text.\nThis is still the second paragraph."
        )
    }

    @Test("Reading progress calculation")
    @MainActor
    func testReadingProgress() async throws {
        let content = """
            First paragraph.

            Second paragraph.

            Third paragraph.

            Fourth paragraph.
            """
        let theme = "Progress"

        let mockIllustrationService = MockIllustrationService()
        let storyProcessor = StoryProcessor(illustrationService: mockIllustrationService)

        let pages = try await storyProcessor.processIntoPages(content, theme: theme)

        let expectedPageCount = 2
        #expect(pages.count == expectedPageCount)

        if pages.count == expectedPageCount {
            #expect(
                StoryProcessor.calculateReadingProgress(currentPage: 1, totalPages: pages.count)
                    == 0.5)
            #expect(
                StoryProcessor.calculateReadingProgress(
                    currentPage: pages.count, totalPages: pages.count) == 1.0)
            #expect(
                StoryProcessor.calculateReadingProgress(currentPage: 0, totalPages: pages.count)
                    == 0.0)
        }
    }

    @Test("Illustration service called for each page")
    @MainActor
    func testIllustrationServiceCalledForEachPage() async throws {
        let mockIllustrationService = MockIllustrationService()
        let storyProcessor = StoryProcessor(illustrationService: mockIllustrationService)

        let content = "Page 1 content.\n\nPage 2 content.\n\nPage 3 content."
        let theme = "Testing"
        mockIllustrationService.urlToReturn = URL(string: "https://test.com/img.png")!

        let pages = try await storyProcessor.processIntoPages(content, theme: theme)

        #expect(pages.count == 2)
        #expect(mockIllustrationService.generateIllustrationCallCount == pages.count)
    }

    @Test("Correct prompt passed to illustration service")
    @MainActor
    func testCorrectPromptPassedToIllustrationService() async throws {
        let mockIllustrationService = MockIllustrationService()
        let storyProcessor = StoryProcessor(illustrationService: mockIllustrationService)

        let shortContent = "Page 1 content."
        let theme = "Prompt Test"
        mockIllustrationService.urlToReturn = URL(string: "https://test.com/img.png")!

        let pages = try await storyProcessor.processIntoPages(shortContent, theme: theme)

        #expect(pages.count == 1)
        #expect(mockIllustrationService.generateIllustrationCallCount == 1)

        let lastParams = mockIllustrationService.lastCallParameters
        #expect(lastParams != nil, "Mock should have received parameters")
        #expect(lastParams!.pageText == shortContent)
        #expect(lastParams!.theme == theme)
    }

    @Test("Page illustration URL set on success")
    @MainActor
    func testPageIllustrationURLSetOnSuccess() async throws {
        let mockIllustrationService = MockIllustrationService()
        let storyProcessor = StoryProcessor(illustrationService: mockIllustrationService)

        let content = "Success test content."
        let theme = "Success"
        let expectedURL = URL(string: "https://success.url/image.jpg")!
        mockIllustrationService.urlToReturn = expectedURL

        let pages = try await storyProcessor.processIntoPages(content, theme: theme)

        #expect(pages.count == 1)
        #expect(pages[0].illustrationStatus == .success)
        #expect(pages[0].illustrationRelativePath != nil)
        #expect(pages[0].imagePrompt != nil)
    }

    @Test("Page illustration URL nil on service nil response")
    @MainActor
    func testPageIllustrationURLNilOnServiceNilResponse() async throws {
        let mockIllustrationService = MockIllustrationService()
        let storyProcessor = StoryProcessor(illustrationService: mockIllustrationService)

        let content = "Nil response test."
        let theme = "Nil Response"
        mockIllustrationService.urlToReturn = nil

        let pages = try await storyProcessor.processIntoPages(content, theme: theme)

        #expect(pages.count == 1)
        #expect(pages[0].illustrationRelativePath == nil)
        #expect(pages[0].illustrationStatus == .failed)
        #expect(pages[0].imagePrompt != nil)
    }

    @Test("Page illustration URL nil on service error")
    @MainActor
    func testPageIllustrationURLNilOnServiceError() async throws {
        let mockIllustrationService = MockIllustrationService()
        let storyProcessor = StoryProcessor(illustrationService: mockIllustrationService)

        let content = "Error test content."
        let theme = "Error"
        mockIllustrationService.generateIllustrationShouldThrowError =
            IllustrationError.networkError(NSError(domain: "TestError", code: 1))

        let pages = try await storyProcessor.processIntoPages(content, theme: theme)

        #expect(pages.count == 1)
        #expect(pages[0].illustrationRelativePath == nil)
        #expect(pages[0].illustrationStatus == .failed)
        #expect(pages[0].imagePrompt != nil)
    }
}
