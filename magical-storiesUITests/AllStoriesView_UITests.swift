import XCTest

final class AllStoriesView_UITests: XCTestCase {
    func testHomeView_ViewAllStoriesNavigation() throws {
        // Setup
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        // Navigate to Home tab
        app.tabBars.buttons["Home"].tap()

        // Get the "View All Stories" button
        let viewAllStoriesButton = app.buttons["ViewAllStoriesButton"]

        // Ensure it exists and is visible
        XCTAssertTrue(viewAllStoriesButton.exists, "View All Stories button should exist")
        XCTAssertTrue(viewAllStoriesButton.isHittable, "View All Stories button should be hittable")

        // Tap the button
        viewAllStoriesButton.tap()

        // Verify that AllStoriesView has appeared
        let allStoriesHeader = app.staticTexts["AllStoriesView_Header"]

        // Wait for the header to appear with a reasonable timeout
        let exists = NSPredicate(format: "exists == true")
        expectation(for: exists, evaluatedWith: allStoriesHeader, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)

        // Verify the header text
        XCTAssertEqual(
            allStoriesHeader.label, "All Stories", "AllStoriesView header should be 'All Stories'")
    }

    func testLibraryView_SeeAllNavigation() throws {
        // Setup
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        // Navigate to Library tab
        app.tabBars.buttons["Library"].tap()

        // Get the "See All" button
        let seeAllButton = app.buttons["LibraryView_SeeAllButton"]

        // Ensure it exists and is visible
        XCTAssertTrue(seeAllButton.exists, "See All button should exist")
        XCTAssertTrue(seeAllButton.isHittable, "See All button should be hittable")

        // Tap the button
        seeAllButton.tap()

        // Verify that AllStoriesView has appeared
        let allStoriesHeader = app.staticTexts["AllStoriesView_Header"]

        // Wait for the header to appear with a reasonable timeout
        let exists = NSPredicate(format: "exists == true")
        expectation(for: exists, evaluatedWith: allStoriesHeader, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)

        // Verify the header text
        XCTAssertEqual(
            allStoriesHeader.label, "All Stories", "AllStoriesView header should be 'All Stories'")
    }

    func testAllStoriesView_SearchFunctionality() throws {
        // Setup
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        // Navigate to Library tab and then to AllStoriesView
        app.tabBars.buttons["Library"].tap()
        app.buttons["LibraryView_SeeAllButton"].tap()

        // Verify search field exists
        let searchField = app.textFields["AllStoriesView_SearchField"]
        XCTAssertTrue(searchField.exists, "Search field should exist")

        // Tap search field and enter search text
        searchField.tap()
        searchField.typeText("Adventure")

        // Verify that stories are filtered (this is basic, would need specific test data setup)
        // For a more robust test, we'd need to setup specific story data and check specific results
    }

    func testAllStoriesView_SortFunctionality() throws {
        // Setup
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        // Navigate to Library tab and then to AllStoriesView
        app.tabBars.buttons["Library"].tap()
        app.buttons["LibraryView_SeeAllButton"].tap()

        // Verify sort picker exists
        let sortPicker = app.pickers["AllStoriesView_SortPicker"]
        XCTAssertTrue(sortPicker.exists, "Sort picker should exist")

        // Test changing sort option (basic test)
        sortPicker.tap()
        app.pickerWheels.element.adjust(toPickerWheelValue: "A-Z")

        // Tap outside to dismiss picker
        app.otherElements.element.tap()

        // For a more robust test, we'd need to verify the actual sorting order with specific test data
    }
}
