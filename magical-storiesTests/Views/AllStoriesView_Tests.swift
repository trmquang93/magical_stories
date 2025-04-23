import SwiftData
import SwiftUI
import XCTest

@testable import magical_stories

@MainActor
class AllStoriesView_Tests: XCTestCase {

  // A simplified version of the filtering logic from AllStoriesView
  private func filterStories(stories: [Story], searchText: String) -> [Story] {
    if searchText.isEmpty {
      return stories
    } else {
      return stories.filter { story in
        story.title.localizedCaseInsensitiveContains(searchText)
          || story.parameters.childName.localizedCaseInsensitiveContains(searchText)
          || story.parameters.theme.localizedCaseInsensitiveContains(searchText)
      }
    }
  }

  // A simplified version of the sorting logic from AllStoriesView
  private func sortStories(stories: [Story], by sortOption: AllStoriesView.SortOption) -> [Story] {
    switch sortOption {
    case .newest:
      return stories.sorted(by: { $0.timestamp > $1.timestamp })
    case .oldest:
      return stories.sorted(by: { $0.timestamp < $1.timestamp })
    case .alphabetical:
      return stories.sorted(by: { $0.title < $1.title })
    case .mostRead:
      return stories.sorted(by: { $0.isCompleted && !$1.isCompleted })
    }
  }

  @MainActor
  func testFilterByTitle() async throws {
    // Create test stories
    let testStory1 = Story(
      title: "Adventure in Wonderland",
      pages: [Page(content: "Story content", pageNumber: 1)],
      parameters: StoryParameters(
        childName: "Alice",
        childAge: 7,
        theme: "Adventure",
        favoriteCharacter: "Rabbit"
      )
    )

    let testStory2 = Story(
      title: "The Magical Forest",
      pages: [Page(content: "Story content", pageNumber: 1)],
      parameters: StoryParameters(
        childName: "Emma",
        childAge: 6,
        theme: "Fantasy",
        favoriteCharacter: "Dragon"
      )
    )

    let stories = [testStory1, testStory2]

    // Test filtering by title
    let filteredStories = filterStories(stories: stories, searchText: "Adventure")

    XCTAssertEqual(filteredStories.count, 1, "There should be 1 filtered story")
    XCTAssertEqual(filteredStories.first?.title, "Adventure in Wonderland")
  }

  @MainActor
  func testFilterByChildName() async throws {
    // Create test stories
    let testStory1 = Story(
      title: "Adventure in Wonderland",
      pages: [Page(content: "Story content", pageNumber: 1)],
      parameters: StoryParameters(
        childName: "Alice",
        childAge: 7,
        theme: "Adventure",
        favoriteCharacter: "Rabbit"
      )
    )

    let testStory2 = Story(
      title: "The Magical Forest",
      pages: [Page(content: "Story content", pageNumber: 1)],
      parameters: StoryParameters(
        childName: "Emma",
        childAge: 6,
        theme: "Fantasy",
        favoriteCharacter: "Dragon"
      )
    )

    let stories = [testStory1, testStory2]

    // Test filtering by child name
    let filteredStories = filterStories(stories: stories, searchText: "Alice")

    XCTAssertEqual(filteredStories.count, 1, "There should be 1 filtered story")
    XCTAssertEqual(filteredStories.first?.title, "Adventure in Wonderland")
  }

  @MainActor
  func testFilterByTheme() async throws {
    // Create test stories
    let testStory1 = Story(
      title: "Adventure in Wonderland",
      pages: [Page(content: "Story content", pageNumber: 1)],
      parameters: StoryParameters(
        childName: "Alice",
        childAge: 7,
        theme: "Adventure",
        favoriteCharacter: "Rabbit"
      )
    )

    let testStory2 = Story(
      title: "The Magical Forest",
      pages: [Page(content: "Story content", pageNumber: 1)],
      parameters: StoryParameters(
        childName: "Emma",
        childAge: 6,
        theme: "Fantasy",
        favoriteCharacter: "Dragon"
      )
    )

    let stories = [testStory1, testStory2]

    // Test filtering by theme
    let filteredStories = filterStories(stories: stories, searchText: "Fantasy")

    XCTAssertEqual(filteredStories.count, 1, "There should be 1 filtered story")
    XCTAssertEqual(filteredStories.first?.title, "The Magical Forest")
  }

  @MainActor
  func testSortByNewest() async throws {
    // Create test stories with different timestamps
    let olderTimestamp = Date().addingTimeInterval(-3600)  // 1 hour ago
    let newerTimestamp = Date()  // now

    let testStory1 = Story(
      title: "Adventure in Wonderland",
      pages: [Page(content: "Story content", pageNumber: 1)],
      parameters: StoryParameters(
        childName: "Alice",
        childAge: 7,
        theme: "Adventure",
        favoriteCharacter: "Rabbit"
      ),
      timestamp: olderTimestamp
    )

    let testStory2 = Story(
      title: "The Magical Forest",
      pages: [Page(content: "Story content", pageNumber: 1)],
      parameters: StoryParameters(
        childName: "Emma",
        childAge: 6,
        theme: "Fantasy",
        favoriteCharacter: "Dragon"
      ),
      timestamp: newerTimestamp
    )

    let stories = [testStory1, testStory2]

    // Test sorting by newest
    let sortedStories = sortStories(stories: stories, by: .newest)

    XCTAssertEqual(sortedStories.count, 2, "There should be 2 stories")
    XCTAssertEqual(
      sortedStories.first?.title, "The Magical Forest", "The newest story should be first")
  }

  @MainActor
  func testEmptyFilter() async throws {
    let stories: [Story] = []

    // Test filtering with empty search text
    let filteredStories = filterStories(stories: stories, searchText: "")

    XCTAssertEqual(filteredStories.count, 0, "There should be 0 filtered stories")
  }
}
