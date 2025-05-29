import Foundation
import SwiftData
import Testing

@testable import magical_stories

struct Story_CategoryTests {

    @Test("Story model should initialize with categoryName")
    func testStoryInitializesWithCategoryName() {
        // Arrange
        let id = UUID()
        let title = "Test Story"
        let parameters = StoryParameters(
            theme: "Adventure",
            childAge: 7,
            childName: "Alex",
            favoriteCharacter: "Dragon"
        )
        let pages = [
            Page(content: "Test page content", pageNumber: 1)
        ]
        let categoryName = "Adventure"

        // Act
        let story = Story(
            id: id,
            title: title,
            pages: pages,
            parameters: parameters,
            categoryName: categoryName
        )

        // Assert
        #expect(story.id == id)
        #expect(story.title == title)
        #expect(story.pages.count == 1)
        #expect(story.pages[0].content == "Test page content")
        #expect(story.parameters.childName == "Alex")
        #expect(story.categoryName == "Adventure")
    }

    @Test("Story model should encode and decode categoryName")
    func testStoryEncodesAndDecodesCategoryName() throws {
        // Arrange
        let story = Story(
            title: "Test Story",
            pages: [Page(content: "Test content", pageNumber: 1)],
            parameters: StoryParameters(
                theme: "Adventure",
                childAge: 7,
                childName: "Alex",
                favoriteCharacter: "Dragon"
            ),
            categoryName: "Fantasy"
        )

        // Act: Encode to data
        let encoder = JSONEncoder()
        let data = try encoder.encode(story)

        // Act: Decode back to Story
        let decoder = JSONDecoder()
        let decodedStory = try decoder.decode(Story.self, from: data)

        // Assert
        #expect(decodedStory.categoryName == "Fantasy")
    }

    @Test("Story preview should support categoryName")
    func testStoryPreviewWithCategoryName() {
        // Act
        let storyWithDefaultCategory = Story.previewStory()
        let storyWithCustomCategory = Story.previewStory(categoryName: "Fantasy")

        // Assert
        #expect(storyWithCustomCategory.categoryName == "Fantasy")
        // The default preview should also have a category
        #expect(storyWithDefaultCategory.categoryName != nil)
    }
}
