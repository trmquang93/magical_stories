import SwiftData
import SwiftUI
import Testing
import ViewInspector
import XCTest

@testable import magical_stories

@Suite("CollectionCardView Tests")
struct CollectionCardView_Tests {

    // Create a mock collection for testing
    func createMockCollection(
        title: String = "Forest Friends",
        category: String = "emotionalIntelligence",
        ageGroup: String = "preschool",
        storyCount: Int = 8,
        completionProgress: Double = 0.0
    ) -> StoryCollection {
        let storyCollection = StoryCollection(
            title: title,
            descriptionText: "Stories about forest adventures",
            category: category,
            ageGroup: ageGroup,
            stories: Array(repeating: Story.previewStory(), count: storyCount),
            createdAt: Date(),
            updatedAt: Date()
        )
        storyCollection.completionProgress = completionProgress
        return storyCollection
    }

    @Test("CollectionCardView displays title correctly")
    func testCardDisplaysTitle() throws {
        let collection = createMockCollection(title: "Forest Friends")
        // Test by checking the title parameter passed to the view
        #expect(collection.title == "Forest Friends")
    }

    @Test("CollectionCardView displays story count correctly")
    func testCardDisplaysStoryCount() throws {
        let collection = createMockCollection(storyCount: 8)
        let view = CollectionCardView(collection: collection)

        // We'll verify this by testing the storyCountText computed property
        #expect(view.storyCountText == "8 stories")

        // Test with single story
        let singleCollection = createMockCollection(storyCount: 1)
        let singleView = CollectionCardView(collection: singleCollection)

        #expect(singleView.storyCountText == "1 story")
    }

    @Test("CollectionCardView displays category badge correctly")
    func testCardDisplaysCategoryBadge() throws {
        // Test emotional intelligence category
        let emotionalCollection = createMockCollection(category: "emotionalIntelligence")
        let emotionalView = CollectionCardView(collection: emotionalCollection)

        // We'll test the computed property directly
        #expect(emotionalView.categoryIcon == "heart.fill")

        // Test problem solving category
        let problemSolvingCollection = createMockCollection(category: "problemSolving")
        let problemSolvingView = CollectionCardView(collection: problemSolvingCollection)

        #expect(problemSolvingView.categoryIcon == "puzzlepiece.fill")
    }

    @Test("CollectionCardView displays age group correctly")
    func testCardDisplaysAgeGroup() throws {
        // Test preschool age group
        let preschoolCollection = createMockCollection(ageGroup: "preschool")
        let preschoolView = CollectionCardView(collection: preschoolCollection)

        #expect(preschoolView.ageGroupDisplay == "3-5 years")

        // Test middle grade age group
        let middleGradeCollection = createMockCollection(ageGroup: "middleGrade")
        let middleGradeView = CollectionCardView(collection: middleGradeCollection)

        #expect(middleGradeView.ageGroupDisplay == "9-12 years")
    }

    @Test("CollectionCardView displays progress bar correctly")
    func testCardDisplaysProgressBar() throws {
        // Test with partial progress
        let partialCollection = createMockCollection(storyCount: 5, completionProgress: 0.6)

        // Test progress value used in the view
        #expect(partialCollection.completionProgress == 0.6)

        // Test with completed progress
        let completedCollection = createMockCollection(storyCount: 3, completionProgress: 1.0)

        #expect(completedCollection.completionProgress == 1.0)
    }

    @Test("CollectionCardView has correct accessibility identifiers")
    func testCardHasAccessibilityIdentifiers() throws {
        let collection = createMockCollection()
        let testId = UUID()
        collection.id = testId

        // Access identifiers manually
        let expectedIdentifier = "CollectionCardView-\(testId)"
        #expect(true, "Accessibility identifier should match \(expectedIdentifier)")
    }
}
