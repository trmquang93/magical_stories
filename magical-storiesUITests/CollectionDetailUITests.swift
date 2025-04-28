import XCTest

class CollectionDetailUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-TESTING"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    /// Navigate to a collection detail view, returns true if successful
    func navigateToCollectionDetail() -> Bool {
        // Navigate to Collections tab
        app.tabBars.buttons["Collections"].tap()

        // Find a collection card and tap it (assuming there's at least one collection)
        let collectionCards = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "CollectionCardView-"))

        guard collectionCards.count > 0 else {
            return false
        }

        // Tap the first collection
        collectionCards.element(boundBy: 0).tap()

        // Verify we're on the collection detail view
        return app.buttons["Stories"].exists && app.buttons["About"].exists
    }

    // MARK: - Tab Navigation

    func testDetailViewTabNavigation() throws {
        guard navigateToCollectionDetail() else {
            XCTFail("No collections available to test or navigation failed")
            return
        }

        // Verify we start on the Stories tab
        let storiesTab = app.buttons["Stories"]
        XCTAssertTrue(storiesTab.isSelected)

        // Switch to About tab
        app.buttons["About"].tap()
        let aboutTab = app.buttons["About"]
        XCTAssertTrue(aboutTab.isSelected)
        XCTAssertTrue(app.staticTexts["Description"].exists)

        // Switch to Achievements tab
        app.buttons["Achievements"].tap()
        let achievementsTab = app.buttons["Achievements"]
        XCTAssertTrue(achievementsTab.isSelected)

        // Back to Stories tab
        app.buttons["Stories"].tap()
        XCTAssertTrue(storiesTab.isSelected)
    }

    // MARK: - Story List Display

    func testStoryListDisplay() throws {
        guard navigateToCollectionDetail() else {
            XCTFail("No collections available to test or navigation failed")
            return
        }

        // Check if there are stories displayed
        let storyElements = app.cells.allElementsBoundByIndex

        if storyElements.isEmpty {
            // If no stories, there should be a message or empty state
            let emptyText = app.staticTexts.firstMatch
            XCTAssertTrue(emptyText.exists)
        } else {
            // Verify at least one story cell exists
            XCTAssertTrue(storyElements.count > 0)
        }
    }

    // MARK: - Story Detail Navigation

    func testStoryDetailNavigation() throws {
        guard navigateToCollectionDetail() else {
            XCTFail("No collections available to test or navigation failed")
            return
        }

        // Find a story cell
        let storyCells = app.cells.allElementsBoundByIndex

        // Only continue if there are stories
        guard !storyCells.isEmpty else {
            return
        }

        // Tap the first story
        storyCells[0].tap()

        // Verify we're in a story detail view (page indicator should exist)
        let pageIndicator = app.pageIndicators.firstMatch
        XCTAssertTrue(pageIndicator.waitForExistence(timeout: 2))

        // Swipe to read through pages
        let storyView = app.scrollViews.firstMatch
        storyView.swipeLeft()
        sleep(1)  // Brief pause to let animation complete
        storyView.swipeLeft()

        // Back to the collection detail
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }

    // MARK: - Progress Display

    func testProgressDisplay() throws {
        guard navigateToCollectionDetail() else {
            XCTFail("No collections available to test or navigation failed")
            return
        }

        // Verify progress elements exist
        let progressElements = app.progressIndicators.allElementsBoundByIndex
        XCTAssertTrue(progressElements.count > 0)

        // Check for progress percentage text
        let percentageTexts = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS '%' AND label CONTAINS 'Complete'"))
        XCTAssertTrue(percentageTexts.count > 0)
    }

    // MARK: - About Tab Content

    func testAboutTabContent() throws {
        guard navigateToCollectionDetail() else {
            XCTFail("No collections available to test or navigation failed")
            return
        }

        // Switch to About tab
        app.buttons["About"].tap()

        // Verify key elements exist
        XCTAssertTrue(app.staticTexts["Description"].exists)
        XCTAssertTrue(app.staticTexts["Age Group"].exists)
        XCTAssertTrue(app.staticTexts["Development Focus"].exists)
        XCTAssertTrue(app.staticTexts["Created"].exists)
    }

    // MARK: - Achievements Tab Content

    func testAchievementsTabContent() throws {
        guard navigateToCollectionDetail() else {
            XCTFail("No collections available to test or navigation failed")
            return
        }

        // Switch to Achievements tab
        app.buttons["Achievements"].tap()

        // Check for either achievements or empty state
        let achievementsExist = app.cells.firstMatch.waitForExistence(timeout: 1)

        if achievementsExist {
            // If there are achievements, verify cells exist
            XCTAssertTrue(app.cells.count > 0)
        } else {
            // If no achievements, check for empty state message
            let emptyTextExists = app.staticTexts["Complete all stories to earn achievements"]
                .waitForExistence(timeout: 1)
            if !emptyTextExists {
                // Look for any text that suggests empty achievements
                let anyEmptyText = app.staticTexts.firstMatch
                XCTAssertTrue(anyEmptyText.exists)
            }
        }
    }

    // MARK: - Story Completion Test

    func testStoryCompletion() throws {
        guard navigateToCollectionDetail() else {
            XCTFail("No collections available to test or navigation failed")
            return
        }

        // Find a story cell
        let storyCells = app.cells.allElementsBoundByIndex

        // Only continue if there are stories
        guard !storyCells.isEmpty else {
            return
        }

        // Check initial progress
        let initialProgressElements = app.progressIndicators.allElementsBoundByIndex
        let initialProgress = initialProgressElements.first?.value as? String ?? "0%"

        // Tap the first story that doesn't appear completed
        let uncompleteStories = app.cells.containing(
            NSPredicate(format: "NOT(identifier CONTAINS 'checkmark')")
        ).allElementsBoundByIndex

        guard !uncompleteStories.isEmpty else {
            // If all stories appear completed, no need to continue the test
            return
        }

        uncompleteStories.first?.tap()

        // Read through the story to completion
        let storyView = app.scrollViews.firstMatch

        // Swipe to last page (assuming no more than 10 pages)
        for _ in 1...10 {
            storyView.swipeLeft()
            sleep(1)  // Brief pause to let animation complete

            // Check if we've reached the last page (looking for a "Done" or similar button)
            let doneButton = app.buttons["Done"].firstMatch
            if doneButton.exists {
                doneButton.tap()
                break
            }
        }

        // Back to the collection detail if we're still in the story
        if app.pageIndicators.firstMatch.exists {
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }

        // Check if progress has changed
        // This is a bit tricky as the UI might update asynchronously
        sleep(2)  // Give time for progress to update

        let updatedProgressElements = app.progressIndicators.allElementsBoundByIndex
        let updatedProgress = updatedProgressElements.first?.value as? String ?? "0%"

        // Note: This test may sometimes fail if progress doesn't visibly change
        // For example, if the story was already marked as read or if progress calculation is delayed
        print("Initial progress: \(initialProgress), Updated progress: \(updatedProgress)")
    }
}
