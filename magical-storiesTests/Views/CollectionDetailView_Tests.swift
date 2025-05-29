import Testing
@testable import magical_stories
import SwiftUI
import SwiftData

@Suite("CollectionDetailView Tests")
@MainActor
struct CollectionDetailView_Tests {
    @Test("Renders stories (model state only)")
    func testRendersStoriesModelState() async throws {
        let container = try ModelContainer(for: StoryCollection.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        // Create stories
        let story1 = Story(title: "Story 1", pages: [], parameters: StoryParameters(theme: "T1", childAge: 5, childName: "A", favoriteCharacter: "Bear"), timestamp: Date())
        let story2 = Story(title: "Story 2", pages: [], parameters: StoryParameters(theme: "T2", childAge: 6, childName: "B", favoriteCharacter: "Cat"), timestamp: Date())
        // Create collection
        let collection = StoryCollection(title: "Growth", descriptionText: "Desc", category: "cat", ageGroup: "elem", stories: [story1, story2], createdAt: Date(), updatedAt: Date())
        context.insert(collection)
        try context.save()
        // Check model state - order may be different than created since array order is not guaranteed
        #expect(collection.stories?.count == 2)
        
        // Instead of checking specific order, just check if both stories exist in the collection
        let storyTitles = collection.stories?.map { $0.title } ?? []
        #expect(storyTitles.contains("Story 1"))
        #expect(storyTitles.contains("Story 2"))
        
        // TODO: Use ViewInspector or UI test to assert icon rendering and completion indicator if available
    }

    @Test("ProgressView reflects collection.completionProgress (model state only)")
    func testProgressViewReflectsCompletionProgressModelState() async throws {
        let container = try ModelContainer(for: StoryCollection.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let story = Story(title: "Story", pages: [], parameters: StoryParameters(theme: "T1", childAge: 5, childName: "A", favoriteCharacter: "Bear"), timestamp: Date())
        let collection = StoryCollection(title: "Growth", descriptionText: "Desc", category: "cat", ageGroup: "elem", stories: [story], createdAt: Date(), updatedAt: Date())
        collection.completionProgress = 0.5
        context.insert(collection)
        try context.save()
        #expect(collection.completionProgress == 0.5)
    }

    @Test("NavigationLink exists for each story (model state only)")
    func testNavigationLinkExistsForEachStoryModelState() async throws {
        let container = try ModelContainer(for: StoryCollection.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let story1 = Story(title: "Story 1", pages: [], parameters: StoryParameters(theme: "T1", childAge: 5, childName: "A", favoriteCharacter: "Bear"), timestamp: Date())
        let story2 = Story(title: "Story 2", pages: [], parameters: StoryParameters(theme: "T2", childAge: 6, childName: "B", favoriteCharacter: "Cat"), timestamp: Date())
        let collection = StoryCollection(title: "Growth", descriptionText: "Desc", category: "cat", ageGroup: "elem", stories: [story1, story2], createdAt: Date(), updatedAt: Date())
        context.insert(collection)
        try context.save()
        #expect(collection.stories?.count == 2)
        // TODO: UI navigation cannot be fully tested in unit tests; document as limitation
    }

    @Test("Live updates when collection changes (model state only)")
    func testLiveUpdatesOnCollectionChangeModelState() async throws {
        let container = try ModelContainer(for: StoryCollection.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let story = Story(title: "Story", pages: [], parameters: StoryParameters(theme: "T1", childAge: 5, childName: "A", favoriteCharacter: "Bear"), timestamp: Date())
        let collection = StoryCollection(title: "Growth", descriptionText: "Desc", category: "cat", ageGroup: "elem", stories: [story], createdAt: Date(), updatedAt: Date())
        context.insert(collection)
        try context.save()
        #expect(collection.title == "Growth")
        // Simulate update
        collection.title = "Growth Updated"
        try context.save()
        #expect(collection.title == "Growth Updated")
    }
} 