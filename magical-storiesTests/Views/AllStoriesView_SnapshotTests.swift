import SnapshotTesting
import SwiftData
import SwiftUI
import XCTest

@testable import magical_stories

@MainActor
class AllStoriesView_SnapshotTests: XCTestCase {
    let diff: Snapshotting<UIViewController, UIImage> = .image(
        precision: 0.95, perceptualPrecision: 0.95)
    let size = CGSize(width: 390, height: 844)  // iPhone 11 size
    let recordMode = false

    @MainActor
    func testAllStoriesView_LightMode_iPhone11() async throws {
        let view = await makeTestView()
        let host = UIHostingController(rootView: view.environment(\.colorScheme, .light))
        host.view.frame = CGRect(origin: .zero, size: size)
        assertSnapshot(
            of: host, as: diff, named: "AllStoriesView_iPhone11_Light", record: recordMode)
    }

    @MainActor
    func testAllStoriesView_DarkMode_iPhone11() async throws {
        let view = await makeTestView()
        let host = UIHostingController(rootView: view.environment(\.colorScheme, .dark))
        host.view.frame = CGRect(origin: .zero, size: size)
        assertSnapshot(
            of: host, as: diff, named: "AllStoriesView_iPhone11_Dark", record: recordMode)
    }

    @MainActor
    func testAllStoriesView_EmptyState_LightMode() async throws {
        let view = await makeEmptyTestView()
        let host = UIHostingController(rootView: view.environment(\.colorScheme, .light))
        host.view.frame = CGRect(origin: .zero, size: size)
        assertSnapshot(
            of: host, as: diff, named: "AllStoriesView_EmptyState_Light", record: recordMode)
    }

    @MainActor
    func testAllStoriesView_EmptyState_DarkMode() async throws {
        let view = await makeEmptyTestView()
        let host = UIHostingController(rootView: view.environment(\.colorScheme, .dark))
        host.view.frame = CGRect(origin: .zero, size: size)
        assertSnapshot(
            of: host, as: diff, named: "AllStoriesView_EmptyState_Dark", record: recordMode)
    }

    @MainActor
    func testAllStoriesView_SearchResults_LightMode() async throws {
        let view = await makeTestView(searchText: "Adventure")
        let host = UIHostingController(rootView: view.environment(\.colorScheme, .light))
        host.view.frame = CGRect(origin: .zero, size: size)
        assertSnapshot(
            of: host, as: diff, named: "AllStoriesView_SearchResults_Light", record: recordMode)
    }

    @MainActor
    func testAllStoriesView_SearchResults_DarkMode() async throws {
        let view = await makeTestView(searchText: "Adventure")
        let host = UIHostingController(rootView: view.environment(\.colorScheme, .dark))
        host.view.frame = CGRect(origin: .zero, size: size)
        assertSnapshot(
            of: host, as: diff, named: "AllStoriesView_SearchResults_Dark", record: recordMode)
    }

    // MARK: - Helper Methods

    @MainActor
    private func makeTestView(searchText: String = "") async -> some View {
        let container = try! ModelContainer(
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
        let testStory4 = Story(
            title: "Safari Adventure",
            pages: [Page(content: "Story content for Safari Adventure", pageNumber: 1)],
            parameters: StoryParameters(
                childName: "Noah",
                childAge: 5,
                theme: "Adventure",
                favoriteCharacter: "Lion"
            )
        )
        let testStory5 = Story(
            title: "Underwater Discovery",
            pages: [Page(content: "Story content for Underwater Discovery", pageNumber: 1)],
            parameters: StoryParameters(
                childName: "Lily",
                childAge: 6,
                theme: "Adventure",
                favoriteCharacter: "Dolphin"
            )
        )

        await storyService.addMockStories([
            testStory1, testStory2, testStory3, testStory4, testStory5,
        ])

        return NavigationStack {
            AllStoriesView(searchText: searchText)
                .environmentObject(storyService)
                .environment(\.modelContext, context)
        }
    }

    @MainActor
    private func makeEmptyTestView() async -> some View {
        let container = try! ModelContainer(
            for: StoryModel.self, configurations: .init(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let storyService = TestMockStoryService()

        return NavigationStack {
            AllStoriesView()
                .environmentObject(storyService)
                .environment(\.modelContext, context)
        }
    }
}
