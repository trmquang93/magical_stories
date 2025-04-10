import Testing
import SwiftData
import SwiftUI
@testable import magical_stories


@Suite("LibraryView Tests")
struct LibraryViewTests {
    @MainActor
    func makeStoryService(with stories: [Story]) async throws -> StoryService {
        let schema = Schema([StoryModel.self, PageModel.self])
        let container = try ModelContainer(for: schema, configurations: [.init(isStoredInMemoryOnly: true)])
        let context = ModelContext(container)

        let mockPersistence = MockPersistenceService()
        mockPersistence.storiesToLoad = stories

        let service = try StoryService(
            apiKey: "",
            context: context,
            persistenceService: mockPersistence
        )
        await service.loadStories()
        return service
    }

    @MainActor
    func hostLibraryView(with service: StoryService) -> UIHostingController<some View> {
        let controller = UIHostingController(rootView: LibraryView().environmentObject(service))
        _ = controller.view // Force view load
        return controller
    }

    func findSubview(in view: UIView, withIdentifier identifier: String) -> UIView? {
        if view.accessibilityIdentifier == identifier {
            return view
        }
        for subview in view.subviews {
            if let match = findSubview(in: subview, withIdentifier: identifier) {
                return match
            }
        }
        return nil
    }

}