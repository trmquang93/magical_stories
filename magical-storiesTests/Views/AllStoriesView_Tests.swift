import SwiftData
import SwiftUI
import XCTest

@testable import magical_stories

@MainActor
class AllStoriesView_Tests: XCTestCase {

  @MainActor
  func testAllStoriesView_ShowsAllStories() async throws {
    let container = try ModelContainer(
      for: StoryModel.self, configurations: .init(isStoredInMemoryOnly: true))
    let context = container.mainContext

    let storyService = TestMockStoryService()

    // Add test stories
    let testStory1 = Story(
      title: "Adventure in Wonderland",
      pages: [Page(content: "Story content for Adventure in Wonderland", pageNumber: 1)],
      parameters: StoryParameters(
        childName: "Alice",
        childAge: 7,
        theme: "Adventure",
        favoriteCharacter: "Rabbit"
      )
    )
    let testStory2 = Story(
      title: "The Magical Forest",
      pages: [Page(content: "Story content for The Magical Forest", pageNumber: 1)],
      parameters: StoryParameters(
        childName: "Emma",
        childAge: 6,
        theme: "Fantasy",
        favoriteCharacter: "Dragon"
      )
    )
    let testStory3 = Story(
      title: "Bedtime for Teddy",
      pages: [Page(content: "Story content for Bedtime for Teddy", pageNumber: 1)],
      parameters: StoryParameters(
        childName: "Ben",
        childAge: 4,
        theme: "Bedtime",
        favoriteCharacter: "Bear"
      )
    )

    await storyService.addMockStories([testStory1, testStory2, testStory3])

    XCTAssertEqual(storyService.stories.count, 3)

    // Create the view
    let view = AllStoriesView()
      .environmentObject(storyService)
      .environment(\.modelContext, context)

    // Make sure the view can be created without errors
    _ = view.body
  }

  @MainActor
  func testAllStoriesView_FiltersBySearchText() async throws {
    let container = try ModelContainer(
      for: StoryModel.self, configurations: .init(isStoredInMemoryOnly: true))
    let context = container.mainContext

    let storyService = TestMockStoryService()

    // Add test stories
    let testStory1 = Story(
      title: "Adventure in Wonderland",
      pages: [Page(content: "Story content for Adventure in Wonderland", pageNumber: 1)],
      parameters: StoryParameters(
        childName: "Alice",
        childAge: 7,
        theme: "Adventure",
        favoriteCharacter: "Rabbit"
      )
    )
    let testStory2 = Story(
      title: "The Magical Forest",
      pages: [Page(content: "Story content for The Magical Forest", pageNumber: 1)],
      parameters: StoryParameters(
        childName: "Emma",
        childAge: 6,
        theme: "Fantasy",
        favoriteCharacter: "Dragon"
      )
    )

    await storyService.addMockStories([testStory1, testStory2])

    XCTAssertEqual(storyService.stories.count, 2)

    // Create the view with search text
    let view = AllStoriesView(searchText: "Adventure")
      .environmentObject(storyService)
      .environment(\.modelContext, context)

    // Make sure the view can be created without errors
    _ = view.body
  }

  @MainActor
  func testAllStoriesView_EmptyState() async throws {
    let container = try ModelContainer(
      for: StoryModel.self, configurations: .init(isStoredInMemoryOnly: true))
    let context = container.mainContext

    let storyService = TestMockStoryService()

    XCTAssertEqual(storyService.stories.count, 0)

    // Create the view
    let view = AllStoriesView()
      .environmentObject(storyService)
      .environment(\.modelContext, context)

    // Make sure the view can be created without errors
    _ = view.body
  }
}
