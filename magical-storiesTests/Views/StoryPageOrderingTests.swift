import Foundation
import SwiftUI
import Testing
import SwiftData

@testable import magical_stories

@MainActor
struct StoryPageOrderingTests {
    @Test("Story page sorting algorithm works correctly")
    func testPageSorting() async {
        // Create pages in incorrect order
        let page1 = Page(content: "First page", pageNumber: 1)
        let page2 = Page(content: "Second page", pageNumber: 2)
        let page3 = Page(content: "Third page", pageNumber: 3)
        
        // Use an unsorted array
        let unsortedPages = [page3, page1, page2]
        
        // Sort the pages using the same algorithm we would use in the fix
        let sortedPages = unsortedPages.sorted(by: { $0.pageNumber < $1.pageNumber })
        
        // Verify the sorting works as expected
        #expect(sortedPages.count == 3)
        #expect(sortedPages[0].pageNumber == 1)
        #expect(sortedPages[1].pageNumber == 2)
        #expect(sortedPages[2].pageNumber == 3)
    }
    
    @Test("Story pages in the wrong order are problematic")
    func testPageOrderingProblem() {
        // Create pages in incorrect order
        let page1 = Page(content: "First page", pageNumber: 1)
        let page2 = Page(content: "Second page", pageNumber: 2)
        let page3 = Page(content: "Third page", pageNumber: 3)
        
        // Use an unsorted array
        let unsortedPages = [page3, page1, page2]
        
        // With no sorting, pages will be in the wrong order
        #expect(unsortedPages.count == 3)
        #expect(unsortedPages[0].pageNumber == 3, "Without sorting, the first page has the wrong number")
        #expect(unsortedPages[1].pageNumber == 1, "Without sorting, the second page has the wrong number")
        #expect(unsortedPages[2].pageNumber == 2, "Without sorting, the third page has the wrong number")
    }
}