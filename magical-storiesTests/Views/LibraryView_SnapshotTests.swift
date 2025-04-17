import XCTest
import SwiftUI
import SnapshotTesting
import SwiftData

@testable import magical_stories

@MainActor
final class LibraryView_SnapshotTests: XCTestCase {
    // Helper to create a mock StoryService with demo stories
    func makeMockStoryService() -> StoryService {
        // If you have StoryService.mockWithDemoStories(), use it. Otherwise, create a minimal mock:
        let schema = Schema([StoryModel.self, PageModel.self])
        let container = try! ModelContainer(for: schema, configurations: [.init(isStoredInMemoryOnly: true)])
        let context = ModelContext(container)
        let mockPersistence = MockPersistenceService()
        mockPersistence.storiesToLoad = [
            Story.previewStory(title: "The Magic Garden"),
            Story.previewStory(title: "Dragon's Birthday")
        ]
        let service = try! StoryService(
            apiKey: "",
            context: context,
            persistenceService: mockPersistence
        )
        Task { await service.loadStories() }
        // Wait for async load (in real test, use expectation or await)
        usleep(100_000)
        return service
    }

    func makeEmptyStoryService() -> StoryService {
        let schema = Schema([StoryModel.self, PageModel.self])
        let container = try! ModelContainer(for: schema, configurations: [.init(isStoredInMemoryOnly: true)])
        let context = ModelContext(container)
        let mockPersistence = MockPersistenceService()
        mockPersistence.storiesToLoad = []
        let service = try! StoryService(
            apiKey: "",
            context: context,
            persistenceService: mockPersistence
        )
        Task { await service.loadStories() }
        usleep(100_000)
        return service
    }

    func testLibraryView_LightMode_iPhone11() {
        let service = makeMockStoryService()
        let view = LibraryView().environmentObject(service)
        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812) // iPhone 11 size
        host.overrideUserInterfaceStyle = .light
        assertSnapshot(of: host, as: .image, named: "LibraryView_iPhone11_Light")
    }

    func testLibraryView_DarkMode_iPhone11() {
        let service = makeMockStoryService()
        let view = LibraryView().environmentObject(service)
        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812) // iPhone 11 size
        host.overrideUserInterfaceStyle = .dark
        assertSnapshot(of: host, as: .image, named: "LibraryView_iPhone11_Dark")
    }

    func testLibraryView_EmptyState_LightMode() {
        let service = makeEmptyStoryService()
        let view = LibraryView().environmentObject(service)
        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        host.overrideUserInterfaceStyle = .light
        assertSnapshot(of: host, as: .image, named: "LibraryView_EmptyState_Light")
    }

    func testLibraryView_EmptyState_DarkMode() {
        let service = makeEmptyStoryService()
        let view = LibraryView().environmentObject(service)
        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        host.overrideUserInterfaceStyle = .dark
        assertSnapshot(of: host, as: .image, named: "LibraryView_EmptyState_Dark")
    }

    func testLibraryView_SearchResults_LightMode() {
        let service = makeMockStoryService()
        // Simulate search by injecting searchText via reflection (not ideal, but works for snapshot)
        let view = LibraryViewWithSearchText(searchText: "Dragon").environmentObject(service)
        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        host.overrideUserInterfaceStyle = .light
        assertSnapshot(of: host, as: .image, named: "LibraryView_SearchResults_Light")
    }

    func testLibraryView_SearchResults_DarkMode() {
        let service = makeMockStoryService()
        let view = LibraryViewWithSearchText(searchText: "Dragon").environmentObject(service)
        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        host.overrideUserInterfaceStyle = .dark
        assertSnapshot(of: host, as: .image, named: "LibraryView_SearchResults_Dark")
    }
}

// Helper for injecting search text into LibraryView for snapshot
struct LibraryViewWithSearchText: View {
    @State var searchText: String
    @EnvironmentObject var storyService: StoryService
    var body: some View {
        LibraryView()
            .environmentObject(storyService)
            .onAppear { _searchText.wrappedValue = searchText }
    }
} 