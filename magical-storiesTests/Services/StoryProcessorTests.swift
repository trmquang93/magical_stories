import Testing
import XCTest
import Foundation
@testable import magical_stories

@MainActor
struct StoryProcessorTests {
    
    // MARK: - Test Setup
    var storyProcessor: StoryProcessor!
    
    mutating func setUp() {
        storyProcessor = StoryProcessor()
    }
    
    // MARK: - Basic Text Segmentation Tests
    
    @Test("Short story should create at least one page")
    mutating func testShortStorySegmentation() {
        // Given
        setUp()
        let shortContent = "Once upon a time, there was a brave lion."
        
        // When
        let pages = storyProcessor.processIntoPages(shortContent)
        
        // Then
        #expect(!pages.isEmpty)
        #expect(pages.count == 1)
        #expect(pages[0].content == shortContent)
        #expect(pages[0].pageNumber == 1)
    }
    
    @Test("Paragraph-based segmentation for medium story")
    mutating func testMediumStorySegmentation() {
        // Given
        setUp()
        let mediumContent = """
        Once upon a time, there was a brave lion who lived in the forest.
        
        The lion was very kind and helped all the animals in need.
        
        One day, the lion found a lost rabbit and helped it find its way home.
        
        The rabbit was very grateful and they became good friends.
        """
        
        // When
        let pages = storyProcessor.processIntoPages(mediumContent)
        
        // Then
        #expect(pages.count > 1)
        #expect(pages[0].pageNumber == 1)
        #expect(pages[1].pageNumber == 2)
        
        // Verify content is properly segmented by paragraphs
        #expect(pages[0].content.contains("Once upon a time"))
        #expect(pages[0].content.contains("lion was very kind")) // Paragraph 2 should be on page 1
        #expect(pages[1].content.contains("found a lost rabbit")) // Paragraph 3 should be on page 2
    }
    
    @Test("Long story with multiple paragraphs should be properly segmented")
    mutating func testLongStorySegmentation() {
        // Given
        setUp()
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
        
        // When
        let pages = storyProcessor.processIntoPages(longContent)
        
        // Then
        #expect(pages.count >= 3)
        
        // Verify page numbers are sequential
        for i in 0..<pages.count {
            #expect(pages[i].pageNumber == i + 1)
        }
        
        // Verify content distribution (should be somewhat evenly distributed)
        let contentLengths = pages.map { $0.content.count }
        let maxLength = contentLengths.max() ?? 0
        let minLength = contentLengths.min() ?? 0
        
        // No page should be empty
        #expect(minLength > 0)
        
        // Pages should have somewhat balanced content
        // (This is a flexible test - adjust based on actual algorithm)
        #expect(Double(minLength) / Double(maxLength) > 0.3)
    }
    
    // MARK: - Edge Cases
    
    @Test("Empty content should return empty page collection")
    mutating func testEmptyContent() {
        // Given
        setUp()
        let emptyContent = ""
        
        // When
        let pages = storyProcessor.processIntoPages(emptyContent)
        
        // Then
        #expect(pages.isEmpty)
    }
    
    @Test("Content with only whitespace should return empty page collection")
    mutating func testWhitespaceContent() {
        // Given
        setUp()
        let whitespaceContent = "   \n   \t   "
        
        // When
        let pages = storyProcessor.processIntoPages(whitespaceContent)
        
        // Then
        #expect(pages.isEmpty)
    }
    
    @Test("Very long paragraph should be split into multiple pages")
    mutating func testVeryLongParagraph() {
        // Given
        setUp()
        // Create a very long paragraph (over 1000 characters)
        let sentence = "This is a sentence that will be repeated to create a very long paragraph. "
        var longParagraph = ""
        for _ in 0..<20 {
            longParagraph += sentence
        }
        
        // When
        let pages = storyProcessor.processIntoPages(longParagraph)
        
        // Then
        #expect(pages.count > 1)
        
        // Verify each page has reasonable content length
        for page in pages {
            #expect(page.content.count <= StoryProcessor.maxPageContentLength)
        }
    }
    
    // MARK: - Content Formatting Tests
    
    @Test("Content formatting preserves paragraph structure")
    mutating func testContentFormatting() throws {
        // Given
        setUp()
        let content = """
        First paragraph with some text.
        
        Second paragraph with more text.
        This is still the second paragraph.
        
        Third paragraph.
        """
        
        // When
        let pages = storyProcessor.processIntoPages(content)
        
        // Then
        #expect(!pages.isEmpty)
        
        // Check that paragraphs are preserved in the segmentation
        #expect(pages[0].content.contains("First paragraph"))
        
        // Find the page with "Second paragraph"
        let pageWithSecondParagraph = pages.first { $0.content.contains("Second paragraph") }
        try #require(pageWithSecondParagraph != nil)
        
        // Ensure paragraph structure is maintained
        #expect(pageWithSecondParagraph!.content.contains("Second paragraph with more text.\nThis is still the second paragraph."))
    }
    
    // MARK: - Reading Progress Tests
    
    @Test("Reading progress calculation")
    mutating func testReadingProgress() {
        // Given
        setUp()
        let content = """
        First paragraph.
        
        Second paragraph.
        
        Third paragraph.
        
        Fourth paragraph.
        """
        
        // When
        let pages = storyProcessor.processIntoPages(content)
        
        // Then
        #expect(pages.count == 2) // 4 paragraphs, 2 per page = 2 pages
        
        // Test progress calculation
        #expect(storyProcessor.calculateReadingProgress(currentPage: 1, totalPages: pages.count) == 0.5) // Page 1 of 2 is 50%
        #expect(storyProcessor.calculateReadingProgress(currentPage: pages.count, totalPages: pages.count) == 1.0) // Last page is 100%
        #expect(storyProcessor.calculateReadingProgress(currentPage: 0, totalPages: pages.count) == 0.0) // Page 0 is 0%
    }
    
    // MARK: - Page Model Tests
    
    @Test("Page model initialization")
    func testPageModelInitialization() {
        // Given
        let content = "Test content"
        let pageNumber = 3
        
        // When
        let page = Page(content: content, pageNumber: pageNumber)
        
        // Then
        #expect(page.id != UUID())  // Should have a valid UUID
        #expect(page.content == content)
        #expect(page.pageNumber == pageNumber)
        #expect(page.illustration == nil)
    }
}
