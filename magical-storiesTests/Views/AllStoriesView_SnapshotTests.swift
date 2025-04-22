import SnapshotTesting
import SwiftData
import SwiftUI
import Testing

@testable import magical_stories

@Suite("AllStoriesView Snapshot Tests")
class AllStoriesView_SnapshotTests: XCTestCase {
    let size = CGSize(width: 390, height: 844)  // iPhone 11 size
    let recordMode = false

    func testAllStoriesView_LightMode_iPhone11() {
        let view = makeTestView()
        assertSnapshot(
            matching: view.environment(\.colorScheme, .light), as: .image(size: size),
            named: "AllStoriesView_iPhone11_Light", record: recordMode)
    }

    func testAllStoriesView_DarkMode_iPhone11() {
        let view = makeTestView()
        assertSnapshot(
            matching: view.environment(\.colorScheme, .dark), as: .image(size: size),
            named: "AllStoriesView_iPhone11_Dark", record: recordMode)
    }

    func testAllStoriesView_EmptyState_LightMode() {
        let view = makeEmptyTestView()
        assertSnapshot(
            matching: view.environment(\.colorScheme, .light), as: .image(size: size),
            named: "AllStoriesView_EmptyState_Light", record: recordMode)
    }

    func testAllStoriesView_EmptyState_DarkMode() {
        let view = makeEmptyTestView()
        assertSnapshot(
            matching: view.environment(\.colorScheme, .dark), as: .image(size: size),
            named: "AllStoriesView_EmptyState_Dark", record: recordMode)
    }

    func testAllStoriesView_SearchResults_LightMode() {
        let view = makeTestView(searchText: "Adventure")
        assertSnapshot(
            matching: view.environment(\.colorScheme, .light), as: .image(size: size),
            named: "AllStoriesView_SearchResults_Light", record: recordMode)
    }

    func testAllStoriesView_SearchResults_DarkMode() {
        let view = makeTestView(searchText: "Adventure")
        assertSnapshot(
            matching: view.environment(\.colorScheme, .dark), as: .image(size: size),
            named: "AllStoriesView_SearchResults_Dark", record: recordMode)
    }

    // MARK: - Helper Methods

    private func makeTestView(searchText: String = "") -> some View {
        let container = try! ModelContainer(
            for: StoryModel.self, configurations: .init(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let storyService = try! StoryService(context: context)

        // Add test stories
        let testStory1 = Story(
            title: "Adventure in Wonderland",
            childName: "Alice",
            childAge: 7,
            theme: "Adventure",
            favoriteCharacter: "Rabbit"
        )
        let testStory2 = Story(
            title: "The Magical Forest",
            childName: "Emma",
            childAge: 6,
            theme: "Fantasy",
            favoriteCharacter: "Dragon"
        )
        let testStory3 = Story(
            title: "Bedtime for Teddy",
            childName: "Ben",
            childAge: 4,
            theme: "Bedtime",
            favoriteCharacter: "Bear"
        )
        let testStory4 = Story(
            title: "Safari Adventure",
            childName: "Noah",
            childAge: 5,
            theme: "Adventure",
            favoriteCharacter: "Lion"
        )
        let testStory5 = Story(
            title: "Underwater Discovery",
            childName: "Lily",
            childAge: 6,
            theme: "Adventure",
            favoriteCharacter: "Dolphin"
        )

        Task {
            await storyService.addMockStories([
                testStory1, testStory2, testStory3, testStory4, testStory5,
            ])
        }

        return NavigationStack {
            AllStoriesView(searchText: searchText)
                .environmentObject(storyService)
                .environment(\.modelContext, context)
        }
    }

    private func makeEmptyTestView() -> some View {
        let container = try! ModelContainer(
            for: StoryModel.self, configurations: .init(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let storyService = try! StoryService(context: context)

        return NavigationStack {
            AllStoriesView()
                .environmentObject(storyService)
                .environment(\.modelContext, context)
        }
    }
}
