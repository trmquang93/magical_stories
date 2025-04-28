import Combine
import CoreData
import SnapshotTesting
import SwiftData
import SwiftUI
import Testing

@testable import magical_stories

// Helper for selectedTabBinding
private struct TestSupport {
    static func createBindingForTest<T>(_ value: T) -> Binding<T> {
        var mutableValue = value
        return Binding(
            get: { mutableValue },
            set: { mutableValue = $0 }
        )
    }
}

@MainActor
struct HomeView_SnapshotTests {
    var window: UIWindow?
    var diff: Snapshotting<UIViewController, UIImage> {
        return .imageWithRootDirectory(precision: 0.9, perceptualPrecision: 0.9)
    }

    // Reset record option - set to nil to compare against saved reference images
    let record: Bool? = nil

    // MARK: - Helpers
    func makeStoryServiceAndWait(storyCount: Int) async -> StoryService {
        let schema = Schema([StoryModel.self, PageModel.self])
        let container = try! ModelContainer(
            for: schema, configurations: [.init(isStoredInMemoryOnly: true)])
        let context = ModelContext(container)
        let mockPersistence = MockPersistenceService()
        let now = Date()
        mockPersistence.stories = (0..<storyCount).map { i in
            let story = Story.previewStory(title: "Story #\(i+1)")
            story.timestamp = now.addingTimeInterval(TimeInterval(-i * 60))  // Unique timestamp
            return story
        }
        let service = try! StoryService(
            apiKey: "",
            context: context,
            persistenceService: mockPersistence
        )
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            var cancellable: AnyCancellable?
            var didResume = false
            cancellable = service.$stories.sink { stories in
                if stories.count == storyCount && !didResume {
                    didResume = true
                    continuation.resume()
                    cancellable?.cancel()
                }
            }
            Task { await service.loadStories() }
            _ = cancellable
        }
        return service
    }

    func makeCollectionService(collectionCount: Int = 0, storyService: StoryService)
        -> CollectionService
    {
        let mockRepo = MockCollectionRepository()
        for i in 0..<collectionCount {
            let collection = StoryCollection(
                title: "Collection #\(i+1)",
                descriptionText: "Description for collection #\(i+1)",
                category: "Growth",
                ageGroup: "4-6"
            )
            try? mockRepo.saveCollection(collection)
        }
        let achievementRepo = MockAchievementRepository()
        return CollectionService(
            repository: mockRepo, storyService: storyService, achievementRepository: achievementRepo
        )
    }

    func makeHomeView(storyCount: Int, collectionCount: Int = 0, scrollToBottom: Bool = false) async
        -> some View
    {
        let storyService = await makeStoryServiceAndWait(storyCount: storyCount)
        let collectionService = makeCollectionService(
            collectionCount: collectionCount, storyService: storyService)
        collectionService.loadCollections(forceReload: true)

        // Wait for collections to be published if expecting collections
        if collectionCount > 0 {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                var cancellable: AnyCancellable?
                cancellable = collectionService.$collections.sink { collections in
                    if collections.count == collectionCount {
                        continuation.resume()
                        cancellable?.cancel()
                    }
                }
            }
        }

        let selectedTabBinding = TestSupport.createBindingForTest(TabItem.home)
        #if DEBUG
            return HomeView(scrollToBottom: scrollToBottom)
                .environmentObject(storyService)
                .environmentObject(collectionService)
                .environment(\.selectedTabBinding, selectedTabBinding)
        #else
            return HomeView()
                .environmentObject(storyService)
                .environmentObject(collectionService)
                .environment(\.selectedTabBinding, selectedTabBinding)
        #endif
    }

    // MARK: - Tests
    @Test("Test HomeView with no stories")
    func testHomeView_NoStories_LightMode() async {
        let view = await makeHomeView(storyCount: 0)
        let host = UIHostingController(rootView: view)
        host.view.frame = SnapshotTestExtensions.Frames.enlarged
        host.overrideUserInterfaceStyle = .light
        assertSnapshot(of: host, as: diff, named: "HomeView_NoStories_Light", record: record)
    }

    @Test("Test HomeView with no stories in dark mode")
    func testHomeView_NoStories_DarkMode() async {
        let view = await makeHomeView(storyCount: 0)
        let host = UIHostingController(rootView: view)
        host.view.frame = SnapshotTestExtensions.Frames.iPhone11
        host.overrideUserInterfaceStyle = .dark
        assertSnapshot(of: host, as: diff, named: "HomeView_NoStories_Dark", record: record)
    }

    @Test("Test HomeView with two stories in light mode")
    func testHomeView_TwoStories_LightMode() async {
        let view = await makeHomeView(storyCount: 2)
        let host = UIHostingController(rootView: view)
        host.view.frame = SnapshotTestExtensions.Frames.iPhone11
        host.overrideUserInterfaceStyle = .light
        assertSnapshot(of: host, as: diff, named: "HomeView_TwoStories_Light", record: record)
    }

    @Test("Test HomeView with two stories in dark mode")
    func testHomeView_TwoStories_DarkMode() async {
        let view = await makeHomeView(storyCount: 2)
        let host = UIHostingController(rootView: view)
        host.view.frame = SnapshotTestExtensions.Frames.iPhone11
        host.overrideUserInterfaceStyle = .dark
        assertSnapshot(of: host, as: diff, named: "HomeView_TwoStories_Dark", record: record)
    }

    @Test("Test HomeView with more than two stories in light mode")
    func testHomeView_MoreThanTwoStories_LightMode() async {
        let view = await makeHomeView(storyCount: 4)
        let host = UIHostingController(rootView: view)
        host.view.frame = SnapshotTestExtensions.Frames.enlarged
        host.overrideUserInterfaceStyle = .light
        assertSnapshot(
            of: host, as: diff, named: "HomeView_MoreThanTwoStories_Light", record: record)
    }

    @Test("Test HomeView with more than two stories in dark mode")
    func testHomeView_MoreThanTwoStories_DarkMode() async {
        let view = await makeHomeView(storyCount: 4)
        let host = UIHostingController(rootView: view)
        host.view.frame = SnapshotTestExtensions.Frames.enlarged
        host.overrideUserInterfaceStyle = .dark
        assertSnapshot(
            of: host, as: diff, named: "HomeView_MoreThanTwoStories_Dark", record: record)
    }

    // New snapshot tests for collections
    @Test("Test HomeView with collections in light mode")
    func testHomeView_WithCollections_LightMode() async {
        let view = await makeHomeView(storyCount: 2, collectionCount: 3)
        let host = UIHostingController(rootView: view)
        host.view.frame = SnapshotTestExtensions.Frames.enlarged
        host.overrideUserInterfaceStyle = .light
        assertSnapshot(of: host, as: diff, named: "HomeView_WithCollections_Light", record: record)
    }

    @Test("Test HomeView with collections in dark mode")
    func testHomeView_WithCollections_DarkMode() async {
        let view = await makeHomeView(storyCount: 2, collectionCount: 3)
        let host = UIHostingController(rootView: view)
        host.view.frame = SnapshotTestExtensions.Frames.enlarged
        host.overrideUserInterfaceStyle = .dark
        assertSnapshot(of: host, as: diff, named: "HomeView_WithCollections_Dark", record: record)
    }

    @Test("Test HomeView with no collections but with stories in light mode")
    func testHomeView_NoCollections_WithStories_LightMode() async {
        let view = await makeHomeView(storyCount: 3, collectionCount: 0)
        let host = UIHostingController(rootView: view)
        host.view.frame = SnapshotTestExtensions.Frames.enlarged
        host.overrideUserInterfaceStyle = .light
        assertSnapshot(
            of: host, as: diff, named: "HomeView_NoCollections_WithStories_Light", record: record)
    }

    @Test("Test HomeView with no collections but with stories in dark mode")
    func testHomeView_NoCollections_WithStories_DarkMode() async {
        let view = await makeHomeView(storyCount: 3, collectionCount: 0)
        let host = UIHostingController(rootView: view)
        host.view.frame = SnapshotTestExtensions.Frames.enlarged
        host.overrideUserInterfaceStyle = .dark
        assertSnapshot(
            of: host, as: diff, named: "HomeView_NoCollections_WithStories_Dark", record: record)
    }

    @Test("Test HomeView with collections but no stories in light mode")
    func testHomeView_WithCollections_NoStories_LightMode() async {
        let view = await makeHomeView(storyCount: 0, collectionCount: 3)
        let host = UIHostingController(rootView: view)
        host.view.frame = SnapshotTestExtensions.Frames.enlarged
        host.overrideUserInterfaceStyle = .light
        assertSnapshot(
            of: host, as: diff, named: "HomeView_WithCollections_NoStories_Light", record: record)
    }

    @Test("Test HomeView with collections but no stories in dark mode")
    func testHomeView_WithCollections_NoStories_DarkMode() async {
        let view = await makeHomeView(storyCount: 0, collectionCount: 3)
        let host = UIHostingController(rootView: view)
        host.view.frame = SnapshotTestExtensions.Frames.enlarged
        host.overrideUserInterfaceStyle = .dark
        assertSnapshot(
            of: host, as: diff, named: "HomeView_WithCollections_NoStories_Dark", record: record)
    }

    @Test("Test HomeView with scroll to bottom in light mode")
    func testHomeView_ScrollToBottom_LightMode() async {
        let view = await makeHomeView(storyCount: 4, scrollToBottom: true)
        let host = UIHostingController(rootView: view)
        host.view.frame = SnapshotTestExtensions.Frames.iPhone11
        host.overrideUserInterfaceStyle = .light
        // Add the view to a window to ensure layout happens
        let window = UIWindow(frame: SnapshotTestExtensions.Frames.iPhone11)
        window.rootViewController = host
        window.makeKeyAndVisible()
        // Create a delay expectation to allow scroll animation to complete
        // (This will be addressed in a separate edit if needed)
        assertSnapshot(of: host, as: diff, named: "HomeView_ScrollToBottom_Light", record: record)
    }

    @Test("Test HomeView with scroll to bottom in dark mode")
    func testHomeView_ScrollToBottom_DarkMode() async {
        let view = await makeHomeView(storyCount: 4, scrollToBottom: true)
        let host = UIHostingController(rootView: view)
        host.view.frame = SnapshotTestExtensions.Frames.iPhone11
        host.overrideUserInterfaceStyle = .dark
        // Add the view to a window to ensure layout happens
        let window = UIWindow(frame: SnapshotTestExtensions.Frames.iPhone11)
        window.rootViewController = host
        window.makeKeyAndVisible()
        // Create a delay expectation to allow scroll animation to complete
        // (This will be addressed in a separate edit if needed)
        assertSnapshot(of: host, as: diff, named: "HomeView_ScrollToBottom_Dark", record: record)
    }
}
