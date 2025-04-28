import XCTest

class CollectionsUITests: XCTestCase {
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

    // MARK: - Collections Tab Navigation

    func testCollectionsTabNavigation() throws {
        // Navigate to the Collections tab
        app.tabBars.buttons["Collections"].tap()

        // Verify the navigation title is correct
        XCTAssertTrue(app.navigationBars["Growth Collections"].exists)

        // Verify key UI elements are present
        XCTAssertTrue(app.searchFields["Search collections..."].exists)

        // Check that filter buttons are present
        XCTAssertTrue(app.buttons["All"].exists)
        XCTAssertTrue(app.buttons["In Progress"].exists)
        XCTAssertTrue(app.buttons["Completed"].exists)
    }

    // MARK: - Collection Card Interaction

    func testCollectionCardInteraction() throws {
        // Navigate to Collections tab
        app.tabBars.buttons["Collections"].tap()

        // Find a collection card and tap it (assuming there's at least one collection)
        // Note: We need to make the test more robust if there are no collections
        let collectionCards = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "CollectionCardView-"))

        if collectionCards.count > 0 {
            // Tap the first collection
            collectionCards.element(boundBy: 0).tap()

            // Verify we're on the collection detail view
            // We can't check for the specific collection title, but we can verify tab structure is present
            XCTAssertTrue(app.buttons["Stories"].exists)
            XCTAssertTrue(app.buttons["About"].exists)
            XCTAssertTrue(app.buttons["Achievements"].exists)

            // Go back to collections list
            app.navigationBars.buttons.element(boundBy: 0).tap()
        } else {
            // No collections available, verify empty state is shown
            XCTAssertTrue(app.staticTexts["Growth Collections"].exists)
            XCTAssertTrue(app.buttons["Create First Collection"].exists)
        }
    }

    // MARK: - Collection Filter Tests

    func testCollectionFilters() throws {
        // Navigate to Collections tab
        app.tabBars.buttons["Collections"].tap()

        // Try different filters
        app.buttons["Completed"].tap()
        app.buttons["In Progress"].tap()
        app.buttons["All"].tap()

        // Category filters may vary based on existing data
        // This just verifies the filter interaction works, not the actual filtering logic
    }

    // MARK: - Collection Search Tests

    func testCollectionSearch() throws {
        // Navigate to Collections tab
        app.tabBars.buttons["Collections"].tap()

        // Enter search text
        let searchField = app.searchFields["Search collections..."]
        searchField.tap()
        searchField.typeText("test")

        // Clear search
        let clearButton = searchField.buttons["Clear text"].firstMatch
        if clearButton.exists {
            clearButton.tap()
        }
    }

    // MARK: - Create Collection Flow

    func testCreateCollectionButton() throws {
        // Navigate to Collections tab
        app.tabBars.buttons["Collections"].tap()

        // Tap the create button in the toolbar
        app.buttons["CollectionsListView_AddButton"].tap()

        // Verify the collection form is presented
        XCTAssertTrue(app.navigationBars["Create Collection"].exists)

        // Dismiss the form
        app.buttons["Cancel"].tap()
    }

    // MARK: - Collection Detail View Navigation

    func testCollectionDetailNavigation() throws {
        // Navigate to Collections tab
        app.tabBars.buttons["Collections"].tap()

        // Find a collection card (if any exist)
        let collectionCards = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "CollectionCardView-"))

        guard collectionCards.count > 0 else {
            // Skip the test if no collections exist
            return
        }

        // Tap the first collection
        collectionCards.element(boundBy: 0).tap()

        // Verify we're on the detail view by checking tabs
        XCTAssertTrue(app.buttons["Stories"].exists)

        // Switch tabs
        app.buttons["About"].tap()
        XCTAssertTrue(app.staticTexts["Description"].exists)

        app.buttons["Achievements"].tap()

        // Back to Stories tab
        app.buttons["Stories"].tap()

        // If stories exist, tap on one
        let storyElements = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier CONTAINS 'story'"))
        if storyElements.count > 0 {
            storyElements.element(boundBy: 0).tap()

            // Verify story detail view appears
            // We can't check the title, but we can verify standard story navigation is present
            XCTAssertTrue(app.pageIndicators.element.exists)

            // Go back to collection detail
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }

        // Go back to collections list
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }

    // MARK: - Home to Collections Navigation

    func testHomeToCollectionsNavigation() throws {
        // Start on Home tab
        app.tabBars.buttons["Home"].tap()

        // Find and tap a collection card in the horizontal scroll view (if any exist)
        let homeCollectionCards = app.scrollViews["HomeView_CollectionsScrollView"].descendants(
            matching: .any
        ).matching(NSPredicate(format: "identifier BEGINSWITH %@", "CollectionCardView-"))

        if homeCollectionCards.count > 0 {
            homeCollectionCards.element(boundBy: 0).tap()

            // Verify we're on collection detail view
            XCTAssertTrue(app.buttons["Stories"].exists)
            XCTAssertTrue(app.buttons["About"].exists)

            // Navigate back
            app.navigationBars.buttons.element(boundBy: 0).tap()
        } else {
            // If no collections, check if "Create Collection" button exists instead
            let createCollectionButton = app.buttons["HomeView_CreateCollectionCard"]
            if createCollectionButton.exists {
                createCollectionButton.tap()

                // Verify collection form appears
                XCTAssertTrue(app.navigationBars["Create Collection"].exists)

                // Dismiss form
                app.buttons["Cancel"].tap()
            }
        }
    }
}
