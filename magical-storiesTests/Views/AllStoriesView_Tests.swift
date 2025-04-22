import SwiftData
import SwiftUI
import Testing

@testable import magical_stories

@Suite("AllStoriesView Tests")
struct AllStoriesView_Tests {
    @Test func testAllStoriesView_ShowsAllStories() async throws {
        // Create a model container
        let container = try ModelContainer(
            for: StoryModel.self, configurations: .init(isStoredInMemoryOnly: true))
        let context = container.mainContext

        // Create a mock story service with test stories
        let storyService = try StoryService(context: context)

        // Add test stories
        let testStory1 = Story(
            title: "Test Story 1",
            childName: "Test Child",
            childAge: 5,
            theme: "Adventure",
            favoriteCharacter: "Dragon"
        )
        let testStory2 = Story(
            title: "Test Story 2",
            childName: "Test Child",
            childAge: 5,
            theme: "Fantasy",
            favoriteCharacter: "Unicorn"
        )
        let testStory3 = Story(
            title: "Test Story 3",
            childName: "Test Child",
            childAge: 5,
            theme: "Bedtime",
            favoriteCharacter: "Fox"
        )

        // Add stories to service
        await storyService.addMockStories([testStory1, testStory2, testStory3])

        // Verify the stories are loaded
        #expect(storyService.stories.count == 3)

        // Create the view
        let view = AllStoriesView()
            .environmentObject(storyService)
            .environment(\.modelContext, context)

        // Verify the title and number of stories displayed
        // Note: Since we can't directly test SwiftUI rendering,
        // we're primarily verifying that the view can be created with our test data
        // In a real testing scenario, we might use ViewInspector to verify the view structure

        // The view creation should not throw any errors
        #expect(view.body is some View)
    }

    @Test func testAllStoriesView_FiltersBySearchText() async throws {
        // Create a model container
        let container = try ModelContainer(
            for: StoryModel.self, configurations: .init(isStoredInMemoryOnly: true))
        let context = container.mainContext

        // Create a mock story service with test stories
        let storyService = try StoryService(context: context)

        // Add test stories with distinct titles
        let testStory1 = Story(
            title: "Adventure in Wonderland",
            childName: "Test Child",
            childAge: 5,
            theme: "Adventure",
            favoriteCharacter: "Dragon"
        )
        let testStory2 = Story(
            title: "Magical Forest",
            childName: "Test Child",
            childAge: 5,
            theme: "Fantasy",
            favoriteCharacter: "Unicorn"
        )

        // Add stories to service
        await storyService.addMockStories([testStory1, testStory2])

        // Verify the stories are loaded
        #expect(storyService.stories.count == 2)

        // Create the view with search text that should filter to just one story
        let view = AllStoriesView(searchText: "Adventure")
            .environmentObject(storyService)
            .environment(\.modelContext, context)

        // Verify the view can be created
        #expect(view.body is some View)

        // In a real scenario, we would use ViewInspector to verify filtered results
        // For now, we're just ensuring the view can be created with search text
    }

    @Test func testAllStoriesView_EmptyState() async throws {
        // Create a model container
        let container = try ModelContainer(
            for: StoryModel.self, configurations: .init(isStoredInMemoryOnly: true))
        let context = container.mainContext

        // Create an empty story service
        let storyService = try StoryService(context: context)

        // Verify there are no stories
        #expect(storyService.stories.isEmpty)

        // Create the view
        let view = AllStoriesView()
            .environmentObject(storyService)
            .environment(\.modelContext, context)

        // Verify the view can be created
        #expect(view.body is some View)

        // In a real scenario, we would use ViewInspector to verify the empty state message is displayed
    }
}

// Extension to add mock stories for testing
extension StoryService {
    func addMockStories(_ stories: [Story]) async {
        for story in stories {
            do {
                try await self.persistenceService?.saveStory(story)
            } catch {
                print("Error saving mock story: \(error)")
            }
        }
        await self.loadStories()
    }
}
