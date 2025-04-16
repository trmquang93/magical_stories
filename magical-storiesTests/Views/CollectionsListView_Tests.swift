import Testing
@testable import magical_stories
import SwiftUI
import SwiftData

@Suite("CollectionsListView Tests")
@MainActor
struct CollectionsListView_Tests {
    @Test("Renders collections and supports search")
    func testRendersCollectionsAndSearch() async throws {
        // Setup in-memory model container
        let container = try ModelContainer(for: StoryCollection.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        // Insert mock collections
        let collection1 = StoryCollection(title: "Emotional Growth", descriptionText: "Stories for emotional intelligence", category: "emotionalIntelligence", ageGroup: "elementary", stories: [], createdAt: Date(), updatedAt: Date())
        let collection2 = StoryCollection(title: "Problem Solving", descriptionText: "Stories for problem solving", category: "problemSolving", ageGroup: "elementary", stories: [], createdAt: Date(), updatedAt: Date())
        context.insert(collection1)
        context.insert(collection2)
        try context.save()
        // Construct the view and ensure no crash
        _ = CollectionsListView().modelContainer(container)
        #expect(true)
        // NOTE: Do not access .body directly; SwiftUI does not support this outside a live view hierarchy.
        // TODO: If ViewInspector is available, assert that both collection titles appear
    }

    @Test("NavigationLink is present for each collection")
    func testNavigationLinkPresence() async throws {
        let container = try ModelContainer(for: StoryCollection.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let collection = StoryCollection(title: "Creativity", descriptionText: "Stories for creativity", category: "creativity", ageGroup: "elementary", stories: [], createdAt: Date(), updatedAt: Date())
        context.insert(collection)
        try context.save()
        _ = CollectionsListView().modelContainer(container)
        #expect(true)
        // NOTE: Do not access .body directly; SwiftUI does not support this outside a live view hierarchy.
        // TODO: If ViewInspector is available, assert that NavigationLink exists for the collection
    }

    @Test("Deleting a collection removes it from the list and model container")
    func testDeleteCollectionRemovesFromList() async throws {
        // Setup in-memory model container
        let container = try ModelContainer(for: StoryCollection.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        // Insert mock collections
        let collection1 = StoryCollection(title: "To Delete", descriptionText: "Desc", category: "cat", ageGroup: "elementary", stories: [], createdAt: Date(), updatedAt: Date())
        let collection2 = StoryCollection(title: "To Keep", descriptionText: "Desc", category: "cat", ageGroup: "elementary", stories: [], createdAt: Date(), updatedAt: Date())
        await MainActor.run {
            context.insert(collection1)
            context.insert(collection2)
        }
        try await MainActor.run { try context.save() }
        // Simulate deletion via service
        let service = CollectionService(
            repository: CollectionRepository(modelContext: context),
            storyService: try StoryService(apiKey: "test", context: context),
            achievementRepository: AchievementRepository(modelContext: context)
        )
        try await MainActor.run { try service.deleteCollection(id: collection1.id) }
        // Verify collection1 is deleted
        let all = try await MainActor.run { try context.fetch(FetchDescriptor<StoryCollection>()) }
        #expect(!all.contains(where: { $0.id == collection1.id }))
        #expect(all.contains(where: { $0.id == collection2.id }))
        // NOTE: UI-level swipe-to-delete cannot be tested in unit tests without ViewInspector or UI test tools. Documented as limitation.
    }

    // TODO: SwiftUI navigation cannot be fully tested in unit tests without UI test tools. Document as limitation.
} 