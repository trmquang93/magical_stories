import SwiftData
import SwiftUI
import Testing

@testable import magical_stories

@MainActor
struct AllStoriesView_Tests {
  // Helper: Filtering logic from AllStoriesView
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

  // Helper: Sorting logic from AllStoriesView
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

  @Test("Filter by title")
  func testFilterByTitle() async throws {
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
    let filteredStories = filterStories(stories: stories, searchText: "Adventure")
    #expect(filteredStories.count == 1)
    #expect(filteredStories.first?.title == "Adventure in Wonderland")
  }

  @Test("Filter by child name")
  func testFilterByChildName() async throws {
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
    let filteredStories = filterStories(stories: stories, searchText: "Alice")
    #expect(filteredStories.count == 1)
    #expect(filteredStories.first?.title == "Adventure in Wonderland")
  }

  @Test("Filter by theme")
  func testFilterByTheme() async throws {
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
    let filteredStories = filterStories(stories: stories, searchText: "Fantasy")
    #expect(filteredStories.count == 1)
    #expect(filteredStories.first?.title == "The Magical Forest")
  }

  @Test("Sort by newest")
  func testSortByNewest() async throws {
    let olderTimestamp = Date().addingTimeInterval(-3600)
    let newerTimestamp = Date()
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
    let sortedStories = sortStories(stories: stories, by: .newest)
    #expect(sortedStories.count == 2)
    #expect(sortedStories.first?.title == "The Magical Forest")
  }

  @Test("Empty filter returns empty array")
  func testEmptyFilter() async throws {
    let stories: [Story] = []
    let filteredStories = filterStories(stories: stories, searchText: "")
    #expect(filteredStories.count == 0)
  }
}
