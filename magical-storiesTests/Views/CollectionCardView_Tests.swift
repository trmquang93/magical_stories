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
        let view = CollectionCardView(collection: collection)

        let inspectedView = try view.inspect()
        let zstack = try inspectedView.zStack()
        let vstack = try zstack.vStack(1)
        let title = try vstack.vStack(1).text(0)

        #expect(try title.string() == "Forest Friends")
    }

    @Test("CollectionCardView displays story count correctly")
    func testCardDisplaysStoryCount() throws {
        let collection = createMockCollection(storyCount: 8)
        let view = CollectionCardView(collection: collection)

        let inspectedView = try view.inspect()
        let zstack = try inspectedView.zStack()
        let vstack = try zstack.vStack(1)
        let storyCount = try vstack.vStack(1).text(1)

        #expect(try storyCount.string() == "8 stories")

        // Test with single story
        let singleCollection = createMockCollection(storyCount: 1)
        let singleView = CollectionCardView(collection: singleCollection)

        let singleInspectedView = try singleView.inspect()
        let singleZstack = try singleInspectedView.zStack()
        let singleVstack = try singleZstack.vStack(1)
        let singleStoryCount = try singleVstack.vStack(1).text(1)

        #expect(try singleStoryCount.string() == "1 story")
    }

    @Test("CollectionCardView displays category badge correctly")
    func testCardDisplaysCategoryBadge() throws {
        // Test emotional intelligence category
        let emotionalCollection = createMockCollection(category: "emotionalIntelligence")
        let emotionalView = CollectionCardView(collection: emotionalCollection)

        let inspectedView = try emotionalView.inspect()
        let zstack = try inspectedView.zStack()
        let vstack = try zstack.vStack(1)
        let hstack = try vstack.hStack(0)
        let icon = try hstack.zStack(0).image(1)

        let iconName = try icon.actualImage().name()
        #expect(iconName == "heart.fill")

        // Test problem solving category
        let problemSolvingCollection = createMockCollection(category: "problemSolving")
        let problemSolvingView = CollectionCardView(collection: problemSolvingCollection)

        let problemSolvingInspectedView = try problemSolvingView.inspect()
        let problemSolvingZstack = try problemSolvingInspectedView.zStack()
        let problemSolvingVstack = try problemSolvingZstack.vStack(1)
        let problemSolvingHstack = try problemSolvingVstack.hStack(0)
        let problemSolvingIcon = try problemSolvingHstack.zStack(0).image(1)

        let problemSolvingIconName = try problemSolvingIcon.actualImage().name()
        #expect(problemSolvingIconName == "puzzlepiece.fill")
    }

    @Test("CollectionCardView displays age group correctly")
    func testCardDisplaysAgeGroup() throws {
        // Test preschool age group
        let preschoolCollection = createMockCollection(ageGroup: "preschool")
        let preschoolView = CollectionCardView(collection: preschoolCollection)

        let inspectedView = try preschoolView.inspect()
        let zstack = try inspectedView.zStack()
        let vstack = try zstack.vStack(1)
        let hstack = try vstack.hStack(0)
        let ageText = try hstack.text(1)

        #expect(try ageText.string() == "3-5 years")

        // Test middle grade age group
        let middleGradeCollection = createMockCollection(ageGroup: "middleGrade")
        let middleGradeView = CollectionCardView(collection: middleGradeCollection)

        let middleGradeInspectedView = try middleGradeView.inspect()
        let middleGradeZstack = try middleGradeInspectedView.zStack()
        let middleGradeVstack = try middleGradeZstack.vStack(1)
        let middleGradeHstack = try middleGradeVstack.hStack(0)
        let middleGradeAgeText = try middleGradeHstack.text(1)

        #expect(try middleGradeAgeText.string() == "9-12 years")
    }

    @Test("CollectionCardView displays progress bar correctly")
    func testCardDisplaysProgressBar() throws {
        // Test with partial progress
        let partialCollection = createMockCollection(storyCount: 5, completionProgress: 0.6)
        let partialView = CollectionCardView(collection: partialCollection)

        let partialInspectedView = try partialView.inspect()
        let partialZstack = try partialInspectedView.zStack()
        let partialVstack = try partialZstack.vStack(1)
        let progressSection = try partialVstack.vStack(2)
        let progressText = try progressSection.hStack(0).text(1)

        #expect(try progressText.string() == "60%")

        // Test with completed progress
        let completedCollection = createMockCollection(storyCount: 3, completionProgress: 1.0)
        let completedView = CollectionCardView(collection: completedCollection)

        let completedInspectedView = try completedView.inspect()
        let completedZstack = try completedInspectedView.zStack()
        let completedVstack = try completedZstack.vStack(1)
        let completedSection = try completedVstack.vStack(2)

        // Look for the "Collection Completed!" text
        let completedBadge = try completedSection.hStack(1)
        let completedText = try completedBadge.text(1)

        #expect(try completedText.string() == "Collection Completed!")
    }

    @Test("CollectionCardView has correct accessibility identifiers")
    func testCardHasAccessibilityIdentifiers() throws {
        let collection = createMockCollection()
        let testId = UUID()
        collection.id = testId
        let view = CollectionCardView(collection: collection)

        let inspectedView = try view.inspect()

        #expect(try inspectedView.accessibilityIdentifier() == "CollectionCardView-\(testId)")
    }
}
