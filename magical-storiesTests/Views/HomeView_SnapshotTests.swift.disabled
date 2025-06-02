import Combine
import CoreData
import SnapshotTesting
import SwiftData
import SwiftUI
import Testing

@testable import magical_stories

@MainActor
@Suite
struct HomeView_SnapshotTests {
    var window: UIWindow?
    var diff: Snapshotting<UIViewController, UIImage> {
        return .imageWithRootDirectory(precision: 0, perceptualPrecision: 0)
    }

    // Reset record option - set to nil to compare against saved reference images
    let record = false

    // MARK: - Helpers
    func makeStoryServiceAndWait(storyCount: Int) async -> StoryService {
        let schema = Schema([Story.self, Page.self])
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
                category: i % 2 == 0 ? "socialSkills" : "problemSolving",
                ageGroup: "preschool"
            )
            // Add different completion progress for testing
            if i == 1 {
                collection.completionProgress = 0.66
            } else if i == 2 {
                collection.completionProgress = 1.0
            }
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

        // Create a mock AppRouter for navigation
        let appRouter = AppRouter()
        return HomeView()
            .environmentObject(storyService)
            .environmentObject(collectionService)
            .environmentObject(appRouter)
    }

    // MARK: - Tests
    @Test("Test HomeView with no data")
    func testHomeView_NoData() async {
        let view = await makeHomeView(storyCount: 0)
        let host = UIHostingController(rootView: view)
        host.view.frame = SnapshotTestExtensions.Frames.enlarged
        host.overrideUserInterfaceStyle = .light
        assertSnapshot(of: host, as: diff, record: record)
    }

    @Test("Test HomeView with full data")
    func testHomeView_FullData() async {
        let view = await makeHomeView(storyCount: 4, collectionCount: 3)
        let host = UIHostingController(rootView: view)
        host.view.frame = SnapshotTestExtensions.Frames.enlarged
        host.overrideUserInterfaceStyle = .light
        assertSnapshot(of: host, as: diff, record: record)
    }
}
