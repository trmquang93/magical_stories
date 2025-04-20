import Testing
import SwiftUI
import SnapshotTesting
import CoreData
import Combine
import XCTest
import SwiftData

@testable import magical_stories

// Helper struct for binding
fileprivate struct TestSupport {
    static func createBindingForTest<T>(_ value: T) -> Binding<T> {
        var mutableValue = value
        return Binding(
            get: { mutableValue },
            set: { mutableValue = $0 }
        )
    }
}

@MainActor
final class LibraryView_SnapshotTests: XCTestCase {
    let diff: Snapshotting<UIViewController, UIImage> = .image(precision: 0.95, perceptualPrecision: 0.95)
    let iPhone11Frame = CGRect(x: 0, y: 0, width: 375, height: 812)
    let record: Bool? = nil
    
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
        host.view.frame = iPhone11Frame
        host.overrideUserInterfaceStyle = .light
        assertSnapshot(of: host, as: diff, named: "LibraryView_iPhone11_Light")
    }

    func testLibraryView_DarkMode_iPhone11() {
        let service = makeMockStoryService()
        let view = LibraryView().environmentObject(service)
        let host = UIHostingController(rootView: view)
        host.view.frame = iPhone11Frame
        host.overrideUserInterfaceStyle = .dark
        assertSnapshot(of: host, as: diff, named: "LibraryView_iPhone11_Dark")
    }

    func testLibraryView_EmptyState_LightMode() {
        let service = makeEmptyStoryService()
        let view = LibraryView().environmentObject(service)
        let host = UIHostingController(rootView: view)
        host.view.frame = iPhone11Frame
        host.overrideUserInterfaceStyle = .light
        assertSnapshot(of: host, as: diff, named: "LibraryView_EmptyState_Light")
    }

    func testLibraryView_EmptyState_DarkMode() {
        let service = makeEmptyStoryService()
        let view = LibraryView().environmentObject(service)
        let host = UIHostingController(rootView: view)
        host.view.frame = iPhone11Frame
        host.overrideUserInterfaceStyle = .dark
        assertSnapshot(of: host, as: diff, named: "LibraryView_EmptyState_Dark")
    }

    func testLibraryView_SearchResults_LightMode() {
        let service = makeMockStoryService()
        // Simulate search by injecting searchText via reflection (not ideal, but works for snapshot)
        let view = LibraryViewWithSearchText(searchText: "Dragon").environmentObject(service)
        let host = UIHostingController(rootView: view)
        host.view.frame = iPhone11Frame
        host.overrideUserInterfaceStyle = .light
        assertSnapshot(of: host, as: diff, named: "LibraryView_SearchResults_Light")
    }

    func testLibraryView_SearchResults_DarkMode() {
        let service = makeMockStoryService()
        let view = LibraryViewWithSearchText(searchText: "Dragon").environmentObject(service)
        let host = UIHostingController(rootView: view)
        host.view.frame = iPhone11Frame
        host.overrideUserInterfaceStyle = .dark
        assertSnapshot(of: host, as: diff, named: "LibraryView_SearchResults_Dark")
    }

    // Helper to create a mock StoryService with 3+ stories for recent stories section
    func makeRecentStoriesServiceAndWait(_ expectation: XCTestExpectation) -> StoryService {
        let schema = Schema([StoryModel.self, PageModel.self])
        let container = try! ModelContainer(for: schema, configurations: [.init(isStoredInMemoryOnly: true)])
        let context = ModelContext(container)
        let mockPersistence = MockPersistenceService()
        let now = Date()
        mockPersistence.storiesToLoad = [
            Story.previewStory(title: "Newest Story").withTimestamp(now),
            Story.previewStory(title: "Middle Story").withTimestamp(now.addingTimeInterval(-3600)),
            Story.previewStory(title: "Oldest Story").withTimestamp(now.addingTimeInterval(-7200))
        ]
        let service = try! StoryService(
            apiKey: "",
            context: context,
            persistenceService: mockPersistence
        )
        // Use Combine to observe the stories property
        var cancellable: AnyCancellable?
        cancellable = service.$stories.sink { stories in
            if stories.count == 3 {
                expectation.fulfill()
                cancellable?.cancel()
            }
        }
        Task { await service.loadStories() }
        // Keep cancellable alive until expectation is fulfilled
        _ = cancellable
        return service
    }

    func testLibraryView_RecentStoriesSection_LightMode() {
        let expectation = expectation(description: "Wait for stories to load")
        let service = makeRecentStoriesServiceAndWait(expectation)
        wait(for: [expectation], timeout: 2.0)
        let view = LibraryView().environmentObject(service)
        let host = UIHostingController(rootView: view)
        host.view.frame = iPhone11Frame
        host.overrideUserInterfaceStyle = .light
        assertSnapshot(of: host, as: diff, named: "LibraryView_RecentStoriesSection_Light")
    }

    func testLibraryView_RecentStoriesSection_DarkMode() {
        let expectation = expectation(description: "Wait for stories to load")
        let service = makeRecentStoriesServiceAndWait(expectation)
        wait(for: [expectation], timeout: 2.0)
        let view = LibraryView().environmentObject(service)
        let host = UIHostingController(rootView: view)
        host.view.frame = iPhone11Frame
        host.overrideUserInterfaceStyle = .dark
        assertSnapshot(of: host, as: diff, named: "LibraryView_RecentStoriesSection_Dark")
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

// Helper extension to set timestamp on Story
extension Story {
    func withTimestamp(_ date: Date) -> Story {
        self.timestamp = date
        return self
    }
} 