// magical-storiesTests/Services/StoryProcessorTests.swift
import XCTest // Use XCTest
import Foundation
@testable import magical_stories

// MARK: - Mock Illustration Service
class MockIllustrationService: IllustrationServiceProtocol {
    var generateIllustrationCallCount = 0
    // Store the parameters received by the last call
    var lastCallParameters: (pageText: String, theme: String)?
    var generateIllustrationPrompts: [(pageText: String, theme: String)] = [] // Store all parameters received
    var generateIllustrationShouldReturnURL: URL? = URL(string: "https://mock.url/image.png") // Default success URL
    var generateIllustrationShouldThrowError: Error? = nil // Default no error
    var urlToReturn: URL? = URL(string: "https://mock.url/image.png") // Control return value

    // Update signature to match protocol
    func generateIllustration(for pageText: String, theme: String) async throws -> URL? {
        generateIllustrationCallCount += 1
        lastCallParameters = (pageText, theme) // Store last parameters
        generateIllustrationPrompts.append((pageText, theme)) // Store all parameters

        if let error = generateIllustrationShouldThrowError {
            print("--- MockIllustrationService: Throwing error for pageText: \(pageText.prefix(50))..., theme: \(theme) ---")
            throw error
        }
        print("--- MockIllustrationService: Returning URL \(urlToReturn?.absoluteString ?? "nil") for pageText: \(pageText.prefix(50))..., theme: \(theme) ---")
        return urlToReturn // Use the controllable urlToReturn property
    }

    func reset() {
        generateIllustrationCallCount = 0
        lastCallParameters = nil
        generateIllustrationPrompts = []
        generateIllustrationShouldThrowError = nil
        urlToReturn = URL(string: "https://mock.url/image.png")
    }
}

// Simple error for mocking
enum MockError: Error {
    case simulatedError
}


// MARK: - Story Processor Tests
@MainActor
final class StoryProcessorTests: XCTestCase { // Changed to class inheriting from XCTestCase

    // MARK: - Test Setup
    var storyProcessor: StoryProcessor!
    var mockIllustrationService: MockIllustrationService! // Add mock instance variable

    // Use setUpWithError for XCTest
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockIllustrationService = MockIllustrationService()
        storyProcessor = StoryProcessor(illustrationService: mockIllustrationService) // Inject mock
    }

    // Use tearDownWithError for XCTest
    override func tearDownWithError() throws {
        storyProcessor = nil
        mockIllustrationService = nil
        try super.tearDownWithError()
    }

    // MARK: - Basic Text Segmentation Tests (Updated for async and theme)

    // Changed from @Test to func test...() async throws
    func testShortStorySegmentation() async throws {
        // Given
        let shortContent = "Once upon a time, there was a brave lion."
        let theme = "Bravery"

        // When
        let pages = try await storyProcessor.processIntoPages(shortContent, theme: theme) // Added await and theme

        // Then
        XCTAssertFalse(pages.isEmpty)
        XCTAssertEqual(pages.count, 1)
        XCTAssertEqual(pages[0].content, shortContent)
        XCTAssertEqual(pages[0].pageNumber, 1)
    }

    func testMediumStorySegmentation() async throws {
        // Given
        let mediumContent = """
        Once upon a time, there was a brave lion who lived in the forest.

        The lion was very kind and helped all the animals in need.

        One day, the lion found a lost rabbit and helped it find its way home.

        The rabbit was very grateful and they became good friends.
        """
        let theme = "Kindness"

        // When
        let pages = try await storyProcessor.processIntoPages(mediumContent, theme: theme) // Added await and theme

        // Then
        XCTAssertGreaterThan(pages.count, 1) // Exact count depends on limits, check > 1
        XCTAssertEqual(pages[0].pageNumber, 1)
        XCTAssertEqual(pages[1].pageNumber, 2)

        // Verify content is properly segmented by paragraphs (adjust based on limits)
        // This assumes maxParagraphsPerPage = 2
        XCTAssertTrue(pages[0].content.contains("Once upon a time"))
        XCTAssertTrue(pages[0].content.contains("lion was very kind")) // Paragraph 2 might be on page 1
        XCTAssertTrue(pages[1].content.contains("found a lost rabbit")) // Paragraph 3 might be on page 2
    }

    func testLongStorySegmentation() async throws {
        // Given
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

        // When
        let pages = try await storyProcessor.processIntoPages(longContent, theme: theme) // Added await and theme

        // Then
        XCTAssertGreaterThanOrEqual(pages.count, 3) // Expect multiple pages

        // Verify page numbers are sequential
        for i in 0..<pages.count {
            XCTAssertEqual(pages[i].pageNumber, i + 1)
        }

        // Verify content distribution (should be somewhat evenly distributed)
        let contentLengths = pages.map { $0.content.count }
        let maxLength = contentLengths.max() ?? 0
        let minLength = contentLengths.min() ?? 0

        // No page should be empty
        XCTAssertGreaterThan(minLength, 0)

        // Pages should have somewhat balanced content (flexible check)
        if maxLength > 0 { // Avoid division by zero
             XCTAssertGreaterThan(Double(minLength) / Double(maxLength), 0.3)
        }
    }

    // MARK: - Edge Cases (Updated for async and theme)

    func testEmptyContent() async throws {
        // Given
        let emptyContent = ""
        let theme = "Empty"

        // When
        let pages = try await storyProcessor.processIntoPages(emptyContent, theme: theme) // Added await and theme

        // Then
        XCTAssertTrue(pages.isEmpty)
    }

    func testWhitespaceContent() async throws {
        // Given
        let whitespaceContent = "   \n   \t   "
        let theme = "Whitespace"

        // When
        let pages = try await storyProcessor.processIntoPages(whitespaceContent, theme: theme) // Added await and theme

        // Then
        XCTAssertTrue(pages.isEmpty)
    }

    func testVeryLongParagraph() async throws {
        // Given
        let sentence = "This is a sentence that will be repeated to create a very long paragraph. "
        var longParagraph = ""
        for _ in 0..<20 { // Create paragraph > maxPageContentLength * 2
            longParagraph += sentence
        }
        let theme = "Long"

        // When
        let pages = try await storyProcessor.processIntoPages(longParagraph, theme: theme) // Added await and theme

        // Then
        XCTAssertGreaterThan(pages.count, 1) // Should be split

        // Verify each page has reasonable content length
        for page in pages {
            XCTAssertLessThanOrEqual(page.content.count, StoryProcessor.maxPageContentLength + 100) // Allow some buffer
            XCTAssertFalse(page.content.isEmpty)
        }
    }

    // MARK: - Content Formatting Tests (Updated for async and theme)

    func testContentFormatting() async throws {
        // Given
        let content = """
        First paragraph with some text.

        Second paragraph with more text.
        This is still the second paragraph.

        Third paragraph.
        """
        let theme = "Formatting"

        // When
        let pages = try await storyProcessor.processIntoPages(content, theme: theme) // Added await and theme

        // Then
        XCTAssertFalse(pages.isEmpty)

        // Check that paragraphs are preserved in the segmentation (adjust based on limits)
        XCTAssertTrue(pages[0].content.contains("First paragraph"))

        // Find the page with "Second paragraph"
        let pageWithSecondParagraph = pages.first { $0.content.contains("Second paragraph") }
        let unwrappedPage = try XCTUnwrap(pageWithSecondParagraph) // Use XCTUnwrap

        // Ensure paragraph structure is maintained within the page content
        // This check might need adjustment depending on how splitting interacts with maxParagraphsPerPage
        XCTAssertTrue(unwrappedPage.content.contains("Second paragraph with more text.\nThis is still the second paragraph.") || unwrappedPage.content == "Second paragraph with more text.\nThis is still the second paragraph.")
    }

    // MARK: - Reading Progress Tests (Updated for async and theme)

    func testReadingProgress() async throws {
        // Given
        let content = """
        First paragraph.

        Second paragraph.

        Third paragraph.

        Fourth paragraph.
        """
        let theme = "Progress"

        // When
        let pages = try await storyProcessor.processIntoPages(content, theme: theme) // Added await and theme

        // Then
        // Exact page count depends on limits (maxParagraphsPerPage = 2)
        let expectedPageCount = 2
        XCTAssertEqual(pages.count, expectedPageCount)

        // Test progress calculation
        if pages.count == expectedPageCount {
            XCTAssertEqual(StoryProcessor.calculateReadingProgress(currentPage: 1, totalPages: pages.count), 0.5) // Page 1 of 2 is 50%
            XCTAssertEqual(StoryProcessor.calculateReadingProgress(currentPage: pages.count, totalPages: pages.count), 1.0) // Last page is 100%
            XCTAssertEqual(StoryProcessor.calculateReadingProgress(currentPage: 0, totalPages: pages.count), 0.0) // Page 0 is 0%
        }
    }

    // MARK: - Illustration Generation Tests (NEW)

    func testIllustrationServiceCalledForEachPage() async throws {
        // Given
        let content = "Page 1 content.\n\nPage 2 content.\n\nPage 3 content." // Modified to force 2 pages due to maxParagraphsPerPage = 2
        let theme = "Testing"
        mockIllustrationService.urlToReturn = URL(string:"https://test.com/img.png")!

        // When
        let pages = try await storyProcessor.processIntoPages(content, theme: theme)

        // Then
        XCTAssertEqual(pages.count, 2)
        XCTAssertEqual(mockIllustrationService.generateIllustrationCallCount, pages.count) // Service called once per page
    }

    func testCorrectPromptPassedToIllustrationService() async throws {
        // Given
        let shortContent = "Page 1 content." // Define shortContent here
        let theme = "Prompt Test"
        // let expectedPrompt = "\(content)\n\nStyle: \(theme)" // This format is no longer used
        mockIllustrationService.urlToReturn = URL(string:"https://test.com/img.png")!

        // When
        let pages = try await storyProcessor.processIntoPages(shortContent, theme: theme) // Use shortContent

        // Then
        XCTAssertEqual(pages.count, 1)
        XCTAssertEqual(mockIllustrationService.generateIllustrationCallCount, 1)
        // Verify parameters passed to the mock
        let lastParams = try XCTUnwrap(mockIllustrationService.lastCallParameters)
        XCTAssertEqual(lastParams.pageText, shortContent) // Now shortContent is in scope
        XCTAssertEqual(lastParams.theme, theme) // Use the theme variable defined in the test
    }

    func testPageIllustrationURLSetOnSuccess() async throws {
        // Given
        let content = "Success test content."
        let theme = "Success"
        let expectedURL = URL(string: "https://success.url/image.jpg")!
        mockIllustrationService.urlToReturn = expectedURL // Configure mock for success

        // When
        let pages = try await storyProcessor.processIntoPages(content, theme: theme)

        // Then
        XCTAssertEqual(pages.count, 1)
        XCTAssertEqual(pages[0].illustrationURL, expectedURL, "Illustration URL should be set by the mock")
        XCTAssertNotNil(pages[0].imagePrompt, "Image prompt should be set even on success")
    }

    func testPageIllustrationURLNilOnServiceNilResponse() async throws {
        // Given
        let content = "Nil response test."
        let theme = "Nil Response"
        mockIllustrationService.urlToReturn = nil // Configure mock to return nil

        // When
        let pages = try await storyProcessor.processIntoPages(content, theme: theme)

        // Then
        XCTAssertEqual(pages.count, 1)
        XCTAssertNil(pages[0].illustrationURL, "Illustration URL should be nil when mock returns nil")
        XCTAssertNotNil(pages[0].imagePrompt, "Image prompt should be set even when mock returns nil")
    }

    func testPageIllustrationURLNilOnServiceError() async throws {
        // Given
        let content = "Error test content."
        let theme = "Error"
        mockIllustrationService.generateIllustrationShouldThrowError = IllustrationError.networkError(NSError(domain: "TestError", code: 1)) // Configure mock to throw

        // When
        let pages = try await storyProcessor.processIntoPages(content, theme: theme) // Error is caught internally

        // Then
        XCTAssertEqual(pages.count, 1)
        XCTAssertNil(pages[0].illustrationURL, "Illustration URL should be nil when mock throws error")
        XCTAssertNotNil(pages[0].imagePrompt, "Image prompt should be set even when mock throws error")
    }

    // Removed testPageModelInitialization as Page is now in StoryModels
}
