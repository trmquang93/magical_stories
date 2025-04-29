import Combine
import CoreData
import SnapshotTesting
import SwiftData
import SwiftUI
import Testing
import XCTest

@testable import magical_stories

// Helper struct for binding
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
final class CollectionFormView_SnapshotTests: XCTestCase {
    let diff: Snapshotting<UIViewController, UIImage> = .image(
        precision: 0.95, perceptualPrecision: 0.95)
    let iPhone11Frame = CGRect(x: 0, y: 0, width: 375, height: 812)
    // Reset record option - set to nil to compare against saved reference images
    let record: Bool? = true

    // MARK: - Helpers

    func makeCollectionService() -> CollectionService {
        let mockRepo = MockCollectionRepository()
        let storyService = makeStoryService()
        let achievementRepo = MockAchievementRepository()
        return CollectionService(
            repository: mockRepo,
            storyService: storyService,
            achievementRepository: achievementRepo
        )
    }

    func makeStoryService() -> StoryService {
        // Create a mock persistence service
        let schema = Schema([StoryModel.self, PageModel.self])
        let container = try! ModelContainer(
            for: schema, configurations: [.init(isStoredInMemoryOnly: true)])
        let context = ModelContext(container)
        let mockPersistence = MockPersistenceService()

        // We don't need to load stories for this test
        let service = try! StoryService(
            apiKey: "",
            context: context,
            persistenceService: mockPersistence
        )

        return service
    }

    // Create a simple wrapper to preview the form with test state
    struct CollectionFormViewTestWrapper: View {
        @StateObject var collectionService: CollectionService
        var showLoadingOverlay: Bool

        var body: some View {
            ZStack {
                CollectionFormView()
                    .environmentObject(collectionService)

                if showLoadingOverlay {
                    // Simulate the loading overlay state
                    Color.black.opacity(0.6)
                        .edgesIgnoringSafeArea(.all)

                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#7B61FF").opacity(0.2))
                                .frame(width: 80, height: 80)

                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color(hex: "#7B61FF"))
                        }
                        .frame(width: 100, height: 100)

                        VStack(spacing: 8) {
                            Text("Creating your collection...")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)

                            Text("Weaving together the perfect growth stories")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(hex: "#121828"))
                            .opacity(0.9)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: "#7B61FF"), Color(hex: "#FF617B")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: Color(hex: "#7B61FF").opacity(0.3), radius: 20, x: 0, y: 10)
                    .padding(32)
                }
            }
        }
    }

    // MARK: - Tests

    func testCollectionFormView_DefaultState_LightMode() {
        let collectionService = makeCollectionService()
        let view = CollectionFormViewTestWrapper(
            collectionService: collectionService,
            showLoadingOverlay: false
        )

        let host = UIHostingController(rootView: view)
        host.view.frame = iPhone11Frame
        host.overrideUserInterfaceStyle = .light

        assertSnapshot(
            of: host, as: diff, named: "CollectionFormView_Default_Light", record: record)
    }

    func testCollectionFormView_DefaultState_DarkMode() {
        let collectionService = makeCollectionService()
        let view = CollectionFormViewTestWrapper(
            collectionService: collectionService,
            showLoadingOverlay: false
        )

        let host = UIHostingController(rootView: view)
        host.view.frame = iPhone11Frame
        host.overrideUserInterfaceStyle = .dark

        assertSnapshot(of: host, as: diff, named: "CollectionFormView_Default_Dark", record: record)
    }

    func testCollectionFormView_Loading_LightMode() {
        let collectionService = makeCollectionService()
        let view = CollectionFormViewTestWrapper(
            collectionService: collectionService,
            showLoadingOverlay: true
        )

        let host = UIHostingController(rootView: view)
        host.view.frame = iPhone11Frame
        host.overrideUserInterfaceStyle = .light

        assertSnapshot(
            of: host, as: diff, named: "CollectionFormView_Loading_Light", record: record)
    }

    func testCollectionFormView_Loading_DarkMode() {
        let collectionService = makeCollectionService()
        let view = CollectionFormViewTestWrapper(
            collectionService: collectionService,
            showLoadingOverlay: true
        )

        let host = UIHostingController(rootView: view)
        host.view.frame = iPhone11Frame
        host.overrideUserInterfaceStyle = .dark

        assertSnapshot(of: host, as: diff, named: "CollectionFormView_Loading_Dark", record: record)
    }
}
