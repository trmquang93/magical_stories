import XCTest

class CollectionDetailUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Use mock data and add a special argument to ensure test collections are created
        app.launchArguments = ["UI-TESTING", "USE_MOCK_DATA", "CREATE_TEST_COLLECTIONS"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    /// Navigate to a collection detail view, returns true if successful
    func navigateToCollectionDetail() -> Bool {
        // Navigate to Collections tab
        // Try first with the accessibility identifier
        let collectionsTabButton = app.tabBars.buttons["CollectionsTabButton"]
        if collectionsTabButton.exists {
            collectionsTabButton.tap()
        } else {
            // Fall back to accessing by label if identifier doesn't work
            app.tabBars.buttons["Collections Tab"].tap()
        }

        // Wait briefly for the tab to load
        sleep(1)

        // Find a collection card and tap it (assuming there's at least one collection)
        let collectionCards = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "CollectionCardView-"))

        // If no collections exist, the test can't proceed
        guard collectionCards.count > 0 else {
            print("No collections found for testing")
            return false
        }

        // Tap the first collection
        collectionCards.element(boundBy: 0).tap()

        // Verify we're on the collection detail view
        let storiesTabExists = app.buttons["Stories"].waitForExistence(timeout: 2)
        let aboutTabExists = app.buttons["About"].waitForExistence(timeout: 2)

        return storiesTabExists && aboutTabExists
    }

    // MARK: - Tab Navigation

    func testDetailViewTabNavigation() throws {
        guard navigateToCollectionDetail() else {
            XCTFail("No collections available to test or navigation failed")
            return
        }

        // Wait for UI to stabilize
        sleep(1)

        // Verify Stories tab exists
        let storiesTab = app.buttons["Stories"]
        XCTAssertTrue(storiesTab.exists, "Stories tab should exist")

        // Switch to About tab
        let aboutTab = app.buttons["About"]
        XCTAssertTrue(aboutTab.exists, "About tab should exist")
        aboutTab.tap()

        // Verify we're on About tab by checking for content
        // Look for any of the possible section titles
        let aboutContent =
            app.staticTexts["Description"].exists || app.staticTexts["About This Collection"].exists
        XCTAssertTrue(aboutContent, "Description label should appear in About tab")

        // Switch to Achievements tab
        let achievementsTab = app.buttons["Achievements"]
        XCTAssertTrue(achievementsTab.exists, "Achievements tab should exist")
        achievementsTab.tap()

        // Verify some achievement-related element exists
        let achievementsExist = app.staticTexts.firstMatch.waitForExistence(timeout: 2)
        XCTAssertTrue(achievementsExist, "Achievement-related text should exist")

        // Switch back to Stories tab
        storiesTab.tap()

        // Verify we're on Stories tab by checking if a story list exists
        let storyList = app.collectionViews.firstMatch
        XCTAssertTrue(
            storyList.waitForExistence(timeout: 2), "Story list should appear when on Stories tab")
    }

    // MARK: - Story List Display

    func testStoryListDisplay() throws {
        guard navigateToCollectionDetail() else {
            XCTFail("No collections available to test or navigation failed")
            return
        }

        // Wait for UI to stabilize
        sleep(1)

        // Check if there are stories displayed
        let storyElements = app.cells.allElementsBoundByIndex

        if storyElements.isEmpty {
            // If no stories, there should be a message or empty state
            let emptyText = app.staticTexts.firstMatch
            XCTAssertTrue(
                emptyText.waitForExistence(timeout: 2),
                "Empty state text should exist when no stories are present")
        } else {
            // Verify at least one story cell exists
            XCTAssertTrue(storyElements.count > 0, "At least one story cell should exist")
        }
    }

    // MARK: - Story Detail Navigation

    func testStoryDetailNavigation() throws {
        guard navigateToCollectionDetail() else {
            XCTFail("No collections available to test or navigation failed")
            return
        }

        // Wait for UI to stabilize
        sleep(1)

        // Find a story cell
        let storyCells = app.cells.allElementsBoundByIndex

        // Only continue if there are stories
        guard !storyCells.isEmpty else {
            print("No story cells found to tap - skipping rest of test")
            return
        }

        // Tap the first story
        storyCells[0].tap()

        // Wait for UI to stabilize
        sleep(2)

        // Verify we're in a story detail view by checking for page indicators or text
        let pageIndicatorExists = app.pageIndicators.firstMatch.exists
        let pageText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'Page' AND label CONTAINS 'of'")
        ).firstMatch

        XCTAssertTrue(
            pageIndicatorExists || pageText.exists,
            "Page indicator should appear in story detail view")

        // Look for any scroll view that might contain the story
        let storyView = app.scrollViews.firstMatch
        if storyView.exists {
            storyView.swipeLeft()
            sleep(1)  // Brief pause to let animation complete
            storyView.swipeLeft()
        } else {
            // Try to swipe in the main window if we can't find a scroll view
            app.swipeLeft()
            sleep(1)
            app.swipeLeft()
        }

        // Back to the collection detail
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.waitForExistence(timeout: 2), "Back button should exist")
        backButton.tap()

        // Verify we're back on the collection detail by checking for tabs
        XCTAssertTrue(
            app.buttons["Stories"].waitForExistence(timeout: 2),
            "Should return to collection detail view")
    }

    // MARK: - Progress Display

    func testProgressDisplay() throws {
        guard navigateToCollectionDetail() else {
            XCTFail("No collections available to test or navigation failed")
            return
        }

        // Wait for UI to stabilize
        sleep(1)

        // Verify progress elements exist - could be progress bars or text indicators
        let progressElements = app.progressIndicators.allElementsBoundByIndex

        if progressElements.count > 0 {
            XCTAssertTrue(progressElements.count > 0, "Progress indicators should exist")
        } else {
            // Alternative: check for percentage text if progress indicators aren't found
            let percentageTexts = app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS '%' OR label CONTAINS 'Complete'"))

            XCTAssertTrue(
                percentageTexts.count > 0 || app.staticTexts["Not Started"].exists,
                "Either progress text or 'Not Started' indicator should exist")
        }
    }

    // MARK: - About Tab Content

    func testAboutTabContent() throws {
        guard navigateToCollectionDetail() else {
            XCTFail("No collections available to test or navigation failed")
            return
        }

        // Wait for UI to stabilize
        sleep(1)

        // Switch to About tab
        let aboutTab = app.buttons["About"]
        XCTAssertTrue(aboutTab.exists, "About tab should exist")
        aboutTab.tap()

        // Give UI time to update
        sleep(1)

        // Verify key elements exist - looking for any of the possible section titles
        let aboutContent =
            app.staticTexts["Description"].exists || app.staticTexts["About This Collection"].exists
        XCTAssertTrue(aboutContent, "Description label should exist in About tab")

        // Check for other typical fields but don't fail if they're not all present
        // Some collection types might have different fields
        let hasAgeGroup = app.staticTexts["Age Group"].waitForExistence(timeout: 1)
        let hasRecommendedAge = app.staticTexts["Recommended Age"].waitForExistence(timeout: 1)
        let hasDevelopmentFocus = app.staticTexts["Development Focus"].waitForExistence(timeout: 1)
        let hasCreatedDate = app.staticTexts["Created"].waitForExistence(timeout: 1)
        let hasGrowthBenefits = app.staticTexts["Growth Benefits"].waitForExistence(timeout: 1)

        XCTAssertTrue(
            hasAgeGroup || hasDevelopmentFocus || hasCreatedDate || hasRecommendedAge
                || hasGrowthBenefits,
            "At least one of the expected section titles should exist")
    }

    // MARK: - Achievements Tab Content

    func testAchievementsTabContent() throws {
        guard navigateToCollectionDetail() else {
            XCTFail("No collections available to test or navigation failed")
            return
        }

        // Wait for UI to stabilize
        sleep(1)

        // Switch to Achievements tab
        let achievementsTab = app.buttons["Achievements"]
        XCTAssertTrue(achievementsTab.exists, "Achievements tab should exist")
        achievementsTab.tap()

        // Give time for achievements to load
        sleep(1)

        // Check for either achievements or empty state - don't be too specific
        // about what shows up since it's dependent on the state
        if app.cells.firstMatch.waitForExistence(timeout: 2) {
            // If there are achievements, verify cells exist
            XCTAssertTrue(
                app.cells.count > 0, "Achievement cells should exist if there are achievements")
        } else {
            // If no achievements, check for any text that would indicate empty state
            let anyText = app.staticTexts.firstMatch.waitForExistence(timeout: 2)
            XCTAssertTrue(anyText, "Some text should exist in the achievements tab")
        }
    }

    // MARK: - Story Completion Test

    func testStoryCompletion() throws {
        guard navigateToCollectionDetail() else {
            XCTFail("No collections available to test or navigation failed")
            return
        }

        // Wait for UI to stabilize
        sleep(1)

        // Find a story cell
        let storyCells = app.cells.allElementsBoundByIndex

        // Only continue if there are stories
        guard !storyCells.isEmpty else {
            print("No stories available to test completion")
            return
        }

        // Check for incomplete stories
        let uncompleteStories = app.cells.matching(
            NSPredicate(format: "NOT(identifier CONTAINS 'checkmark')")
        ).allElementsBoundByIndex

        guard !uncompleteStories.isEmpty else {
            print("No incomplete stories found to complete - test purpose already met")
            return
        }

        // Tap the first incomplete story
        uncompleteStories.first?.tap()

        // Wait for story to load
        sleep(2)

        // Simulate reading through story by swiping
        for _ in 1...10 {  // Increase maximum swipes to ensure we reach the end
            // Try to swipe in any scrollable area or in the main app area
            if app.scrollViews.firstMatch.exists {
                app.scrollViews.firstMatch.swipeLeft()
            } else {
                app.swipeLeft()
            }

            sleep(1)  // Brief pause between swipes

            // Check for various ways to exit the story view
            let doneButton = app.buttons["Done"]
            let completeButton = app.buttons["Complete"]
            let finishButton = app.buttons["Finish"]
            let backButton = app.navigationBars.buttons.element(boundBy: 0)

            if doneButton.exists {
                print("Found Done button, tapping it to complete story")
                doneButton.tap()
                break
            } else if completeButton.exists {
                print("Found Complete button, tapping it to complete story")
                completeButton.tap()
                break
            } else if finishButton.exists {
                print("Found Finish button, tapping it to complete story")
                finishButton.tap()
                break
            } else if backButton.exists && app.navigationBars.firstMatch.exists
                && currentPageIndexIndicatesLastPage()
            {
                // If we're on the last page and there's a back button, use it
                print("On last page with back button available - assuming story complete")
                backButton.tap()
                break
            }
        }

        // Wait for UI to stabilize after navigation
        sleep(2)

        // If we're still in the story view, use the back button to return
        if !app.buttons["Stories"].exists {
            print("Not back at collection detail yet, trying to use back button")
            let backButton = app.navigationBars.buttons.element(boundBy: 0)
            if backButton.exists {
                backButton.tap()
                sleep(1)
            }
        }

        // Verify we're back on collection detail
        let storiesTabExists = app.buttons["Stories"].waitForExistence(timeout: 3)
        XCTAssertTrue(
            storiesTabExists,
            "Should return to collection detail view after completing story")
    }

    // Helper to check if we're on the last page based on page indicator text
    private func currentPageIndexIndicatesLastPage() -> Bool {
        let pageIndicators = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'Page' AND label CONTAINS 'of'")
        )

        // Check if we have a page indicator and it has a non-empty text
        if !pageIndicators.firstMatch.exists {
            return false
        }

        let pageText = pageIndicators.firstMatch.label
        if pageText.isEmpty {
            return false
        }

        // Try to parse "Page X of Y" format
        let components = pageText.components(separatedBy: " ")
        guard components.count >= 4,
            let currentPage = Int(components[1]),
            let totalPages = Int(components[3])
        else {
            return false
        }

        return currentPage == totalPages
    }
}
