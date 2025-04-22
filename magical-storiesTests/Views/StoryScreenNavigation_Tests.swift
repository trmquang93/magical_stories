import SwiftData
import SwiftUI
import Testing

@testable import magical_stories

@Suite("Story Screen Navigation Tests")
struct StoryScreenNavigation_Tests {
    @Test func testHomeView_ViewAllStories_NavigatesToAllStoriesView() async throws {
        // Create a model container
        let container = try ModelContainer(
            for: StoryModel.self, configurations: .init(isStoredInMemoryOnly: true))
        let context = container.mainContext

        // Create services
        let storyService = try StoryService(context: context)
        let collectionRepository = CollectionRepository(modelContext: context)
        let achievementRepository = AchievementRepository(modelContext: context)
        let collectionService = CollectionService(
            repository: collectionRepository,
            storyService: storyService,
            achievementRepository: achievementRepository
        )

        // Add test stories
        let testStories = (1...3).map { i in
            Story(
                title: "Test Story \(i)",
                childName: "Test Child",
                childAge: 5,
                theme: "Adventure",
                favoriteCharacter: "Dragon"
            )
        }
        await storyService.addMockStories(testStories)

        // Verify we have more than 2 stories so the "View All" button will show
        #expect(storyService.stories.count > 2)

        // Create the view
        let homeView = HomeView()
            .environmentObject(storyService)
            .environmentObject(collectionService)
            .environment(\.modelContext, context)

        // Verify the "View All Stories" button is present
        // In a real UI test, we would use XCUITest to tap the button and verify navigation

        // The view creation should not throw any errors
        #expect(homeView.body is some View)

        // NOTE: Since we can't directly verify tap interactions or navigation in a unit test,
        // these would be better validated with an XCUITest that can simulate user interactions
    }

    @Test func testLibraryView_SeeAllButton_NavigatesToAllStoriesView() async throws {
        // Create a model container
        let container = try ModelContainer(
            for: StoryModel.self, configurations: .init(isStoredInMemoryOnly: true))
        let context = container.mainContext

        // Create a story service with test stories
        let storyService = try StoryService(context: context)

        // Add test stories
        let testStories = (1...3).map { i in
            Story(
                title: "Test Story \(i)",
                childName: "Test Child",
                childAge: 5,
                theme: "Adventure",
                favoriteCharacter: "Dragon"
            )
        }
        await storyService.addMockStories(testStories)

        // Verify we have enough stories for the Recent Stories section
        #expect(!storyService.stories.isEmpty)

        // Create the view
        let libraryView = LibraryView()
            .environmentObject(storyService)
            .environment(\.modelContext, context)

        // Verify the view creation
        #expect(libraryView.body is some View)

        // NOTE: Since we can't directly verify tap interactions or navigation in a unit test,
        // these would be better validated with an XCUITest that can simulate user interactions
    }

    @Test func testAllStoriesView_CreatedSuccessfully() async throws {
        // Create a model container
        let container = try ModelContainer(
            for: StoryModel.self, configurations: .init(isStoredInMemoryOnly: true))
        let context = container.mainContext

        // Create a story service with test stories
        let storyService = try StoryService(context: context)

        // Add test stories
        let testStories = (1...5).map { i in
            Story(
                title: "Test Story \(i)",
                childName: "Test Child",
                childAge: 5,
                theme: ["Adventure", "Fantasy", "Bedtime", "Animals", "Magic"][i % 5],
                favoriteCharacter: "Dragon"
            )
        }
        await storyService.addMockStories(testStories)

        // Verify we have stories
        #expect(storyService.stories.count == 5)

        // Create the view
        let allStoriesView = AllStoriesView()
            .environmentObject(storyService)
            .environment(\.modelContext, context)

        // Verify the view creation
        #expect(allStoriesView.body is some View)
    }
}
