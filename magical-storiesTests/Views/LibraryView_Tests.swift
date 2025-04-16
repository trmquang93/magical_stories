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

    @MainActor
    @Test("Deleting a story removes it from the service and UI")
    func testDeleteStoryRemovesFromServiceAndUI() async throws {
        // Arrange
        let story = Story.preview
        let service = try await makeStoryService(with: [story])
        let controller = hostLibraryView(with: service)
        // Precondition: Story is present
        #expect(service.stories.contains(where: { $0.id == story.id }))
        // Act: Delete the story
        await service.deleteStory(id: story.id)
        // Assert: Story is removed from service
        #expect(!service.stories.contains(where: { $0.id == story.id }))
        // TODO: UI-level test for swipe-to-delete and alert presentation requires UI automation or ViewInspector
    }
}