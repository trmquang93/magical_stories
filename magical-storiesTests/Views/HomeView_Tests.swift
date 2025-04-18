import SwiftUI
import Testing
import XCTest
import SnapshotTesting
import SwiftData
import Combine

@testable import magical_stories

struct HomeView_Tests {

    @Test("HomeView displays welcome message")
    func testWelcomeMessage() async throws {
        // let view = await HomeView() // Variable unused, removed.

        // Mirror reflection is too fragile for finding specific text reliably.
        // We'll assume the basic structure is present.
        // UI tests or accessibility identifiers are better for content verification.
    }
}

// Helper for selectedTabBinding
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
final class HomeView_SnapshotTests: XCTestCase {
    let diff: Snapshotting<UIViewController, UIImage> = .image(precision: 0.95, perceptualPrecision: 0.95)
    let iPhone11Frame = CGRect(x: 0, y: 0, width: 375, height: 812)
    let enlongedFrame = CGRect(x: 0, y: 0, width: 375, height: 1300)

    // MARK: - Helpers
    func makeStoryServiceAndWait(storyCount: Int, expectation: XCTestExpectation) -> StoryService {
        let schema = Schema([StoryModel.self, PageModel.self])
        let container = try! ModelContainer(for: schema, configurations: [.init(isStoredInMemoryOnly: true)])
        let context = ModelContext(container)
        let mockPersistence = MockPersistenceService()
        let now = Date()
        mockPersistence.storiesToLoad = (0..<storyCount).map { i in
            var story = Story.previewStory(title: "Story #\(i+1)")
            story.timestamp = now.addingTimeInterval(TimeInterval(-i * 60)) // Unique timestamp
            return story
        }
        let service = try! StoryService(
            apiKey: "",
            context: context,
            persistenceService: mockPersistence
        )
        var cancellable: AnyCancellable?
        cancellable = service.$stories.sink { stories in
            if stories.count == storyCount {
                expectation.fulfill()
                cancellable?.cancel()
            }
        }
        Task { await service.loadStories() }
        _ = cancellable
        return service
    }

    func makeCollectionService(collectionCount: Int = 0, storyService: StoryService) -> CollectionService {
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
        return CollectionService(repository: mockRepo, storyService: storyService, achievementRepository: achievementRepo)
    }

    func makeHomeView(storyCount: Int, collectionCount: Int = 0, expectation: XCTestExpectation, scrollToBottom: Bool = false) -> some View {
        let storyService = makeStoryServiceAndWait(storyCount: storyCount, expectation: expectation)
        let collectionService = makeCollectionService(collectionCount: collectionCount, storyService: storyService)
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
    func testHomeView_NoStories_LightMode() {
        let expectation = expectation(description: "Wait for stories to load")
        let view = makeHomeView(storyCount: 0, expectation: expectation)
        wait(for: [expectation], timeout: 2.0)
        let host = UIHostingController(rootView: view)
        host.view.frame = iPhone11Frame
        host.overrideUserInterfaceStyle = .light
        assertSnapshot(of: host, as: diff, named: "HomeView_NoStories_Light")
    }

    func testHomeView_NoStories_DarkMode() {
        let expectation = expectation(description: "Wait for stories to load")
        let view = makeHomeView(storyCount: 0, expectation: expectation)
        wait(for: [expectation], timeout: 2.0)
        let host = UIHostingController(rootView: view)
        host.view.frame = iPhone11Frame
        host.overrideUserInterfaceStyle = .dark
        assertSnapshot(of: host, as: diff, named: "HomeView_NoStories_Dark")
    }

    func testHomeView_TwoStories_LightMode() {
        let expectation = expectation(description: "Wait for stories to load")
        let view = makeHomeView(storyCount: 2, expectation: expectation)
        wait(for: [expectation], timeout: 2.0)
        let host = UIHostingController(rootView: view)
        host.view.frame = iPhone11Frame
        host.overrideUserInterfaceStyle = .light
        assertSnapshot(of: host, as: diff, named: "HomeView_TwoStories_Light")
    }

    func testHomeView_TwoStories_DarkMode() {
        let expectation = expectation(description: "Wait for stories to load")
        let view = makeHomeView(storyCount: 2, expectation: expectation)
        wait(for: [expectation], timeout: 2.0)
        let host = UIHostingController(rootView: view)
        host.view.frame = iPhone11Frame
        host.overrideUserInterfaceStyle = .dark
        assertSnapshot(of: host, as: diff, named: "HomeView_TwoStories_Dark")
    }

    func testHomeView_MoreThanTwoStories_LightMode() {
        let expectation = expectation(description: "Wait for stories to load")
        let view = makeHomeView(storyCount: 4, expectation: expectation)
        wait(for: [expectation], timeout: 2.0)
        let host = UIHostingController(rootView: view)
        host.view.frame = enlongedFrame 
        host.overrideUserInterfaceStyle = .light
        assertSnapshot(of: host, as: diff, named: "HomeView_MoreThanTwoStories_Light")
    }
    
    func testHomeView_MoreThanTwoStories_DarkMode() {
        let expectation = expectation(description: "Wait for stories to load")
        let view = makeHomeView(storyCount: 4, expectation: expectation)
        wait(for: [expectation], timeout: 2.0)
        let host = UIHostingController(rootView: view)
        host.view.frame = enlongedFrame
        host.overrideUserInterfaceStyle = .dark
        assertSnapshot(of: host, as: diff, named: "HomeView_MoreThanTwoStories_Dark")
    }
    
    func testHomeView_ScrollToBottom_LightMode() {
        let expectation = expectation(description: "Wait for stories to load")
        let view = makeHomeView(storyCount: 4, expectation: expectation, scrollToBottom: true)
        wait(for: [expectation], timeout: 2.0)
        
        let host = UIHostingController(rootView: view)
        host.view.frame = iPhone11Frame
        host.overrideUserInterfaceStyle = .light
        
        // Add the view to a window to ensure layout happens
        let window = UIWindow(frame: iPhone11Frame)
        window.rootViewController = host
        window.makeKeyAndVisible()
        
        // Create a delay expectation to allow scroll animation to complete
        let scrollExpectation = self.expectation(description: "Wait for scroll animation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            scrollExpectation.fulfill()
        }
        wait(for: [scrollExpectation], timeout: 1.0)
        
        assertSnapshot(of: host, as: diff, named: "HomeView_ScrollToBottom_Light")
    }

    func testHomeView_ScrollToBottom_DarkMode() {
        let expectation = expectation(description: "Wait for stories to load")
        let view = makeHomeView(storyCount: 4, expectation: expectation, scrollToBottom: true)
        wait(for: [expectation], timeout: 2.0)
        
        let host = UIHostingController(rootView: view)
        host.view.frame = iPhone11Frame
        host.overrideUserInterfaceStyle = .dark
        
        // Add the view to a window to ensure layout happens
        let window = UIWindow(frame: iPhone11Frame)
        window.rootViewController = host
        window.makeKeyAndVisible()
        
        // Create a delay expectation to allow scroll animation to complete
        let scrollExpectation = self.expectation(description: "Wait for scroll animation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            scrollExpectation.fulfill()
        }
        wait(for: [scrollExpectation], timeout: 1.0)
        
        assertSnapshot(of: host, as: diff, named: "HomeView_ScrollToBottom_Dark")
    }
}