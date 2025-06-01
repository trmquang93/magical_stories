import SwiftData
import SwiftUI
import Testing
import XCTest

@testable import magical_stories

// Note: All ViewInspector tests have been removed as ViewInspector's API has changed
// These tests should be replaced with a different testing approach in the future (UI tests, snapshot tests)

class CollectionsUI_Tests: XCTestCase {
    // Mock services and data
    var modelContainer: ModelContainer!
    var storyService: StoryService!
    var collectionService: CollectionService!
    var collectionRepository: CollectionRepository!
    var achievementRepository: AchievementRepository!

    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        // Create in-memory container for testing
        let schema = Schema([StoryCollection.self, Story.self, AchievementModel.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: configuration)

        // Set up services
        collectionRepository = CollectionRepository(modelContext: modelContainer.mainContext)
        achievementRepository = AchievementRepository(modelContext: modelContainer.mainContext)
        storyService = try StoryService(context: modelContainer.mainContext)
        collectionService = CollectionService(
            repository: collectionRepository,
            storyService: storyService,
            achievementRepository: achievementRepository
        )

        // Add sample data
        setupSampleData()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        modelContainer = nil
        storyService = nil
        collectionService = nil
        collectionRepository = nil
        achievementRepository = nil
    }

    // Create sample data for testing
    @MainActor
    private func setupSampleData() {
        // Create collections with different states
        let categories = ["emotionalIntelligence", "socialSkills", "problemSolving"]
        let ageGroups = ["preschool", "earlyReader", "middleGrade"]

        // Collection 1: In progress
        let collection1 = StoryCollection(
            title: "Emotional Growth",
            descriptionText: "Develop emotional intelligence",
            category: categories[0],
            ageGroup: ageGroups[0],
            stories: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        collection1.completionProgress = 0.5

        // Collection 2: Completed
        let collection2 = StoryCollection(
            title: "Social Skills",
            descriptionText: "Learn how to make friends",
            category: categories[1],
            ageGroup: ageGroups[1],
            stories: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        collection2.completionProgress = 1.0

        // Collection 3: Not started
        let collection3 = StoryCollection(
            title: "Problem Solvers",
            descriptionText: "Tackle challenges together",
            category: categories[2],
            ageGroup: ageGroups[2],
            stories: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        collection3.completionProgress = 0.0

        // Add stories to Collection 1
        let story1 = Story.previewStory(title: "Happy Day", categoryName: "Emotions")
        story1.isCompleted = true
        let story2 = Story.previewStory(title: "Sad Rainy Day", categoryName: "Emotions")
        story2.isCompleted = false

        collection1.stories = [story1, story2]

        // Add achievement to Collection 2
        let achievement = AchievementModel(
            name: "Social Master",
            achievementDescription: "Completed the Social Skills collection",
            type: .growthPathProgress,
            earnedAt: Date(),
            iconName: "person.2.fill",
            progress: 1.0
        )

        // Add the collections to the context
        modelContainer.mainContext.insert(collection1)
        modelContainer.mainContext.insert(collection2)
        modelContainer.mainContext.insert(collection3)

        // Also insert the achievement
        modelContainer.mainContext.insert(achievement)
    }

    // MARK: - Model Tests

    @MainActor
    func testCollectionModelsAreCreatedCorrectly() throws {
        // Fetch collections from the context
        let collectionsDescriptor = FetchDescriptor<StoryCollection>()
        let collections = try modelContainer.mainContext.fetch(collectionsDescriptor)

        // Verify we have 3 collections
        XCTAssertEqual(collections.count, 3, "Should have created 3 collections")

        // Verify we have collections with different completion statuses
        let completedCollections = collections.filter { $0.completionProgress >= 1.0 }
        XCTAssertEqual(completedCollections.count, 1, "Should have one completed collection")

        // Verify the completed collection has the correct title
        XCTAssertEqual(
            completedCollections.first?.title, "Social Skills",
            "Completed collection should be Social Skills")

        // Verify we have one collection with stories
        let collectionsWithStories = collections.filter { $0.stories?.isEmpty == false }
        XCTAssertEqual(collectionsWithStories.count, 1, "Should have one collection with stories")

        // Verify the stories collection is "Emotional Growth"
        XCTAssertEqual(
            collectionsWithStories.first?.title, "Emotional Growth",
            "Collection with stories should be Emotional Growth")

        // Verify the stories in the collection
        let stories = collectionsWithStories.first?.stories ?? []
        XCTAssertEqual(stories.count, 2, "Emotional Growth collection should have 2 stories")
        XCTAssertTrue(
            stories.contains(where: { $0.isCompleted }),
            "Collection should have one completed story")
        XCTAssertTrue(
            stories.contains(where: { !$0.isCompleted }),
            "Collection should have one incomplete story")
    }
}
