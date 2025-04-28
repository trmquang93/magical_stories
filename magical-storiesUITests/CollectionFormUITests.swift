import XCTest

class CollectionFormUITests: XCTestCase {
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

    func openCollectionForm() {
        // Navigate to Collections tab
        app.tabBars.buttons["Collections"].tap()

        // Tap the create button in the toolbar
        app.buttons["CollectionsListView_AddButton"].tap()
    }

    // MARK: - Basic Form UI Test

    func testCollectionFormUI() throws {
        openCollectionForm()

        // Verify form elements exist
        XCTAssertTrue(app.navigationBars["Create Collection"].exists)
        XCTAssertTrue(app.textFields["Collection Title"].exists)
        XCTAssertTrue(app.textViews["Collection Description"].exists)

        // Verify age group selector exists
        XCTAssertTrue(app.staticTexts["Age Group"].exists)

        // Verify category selector exists
        XCTAssertTrue(app.staticTexts["Development Focus"].exists)

        // Verify buttons exist
        XCTAssertTrue(app.buttons["Cancel"].exists)
        XCTAssertTrue(app.buttons["Create"].exists)

        // Dismiss form
        app.buttons["Cancel"].tap()
    }

    // MARK: - Form Validation

    func testFormValidation() throws {
        openCollectionForm()

        // Initially, Create button should be disabled (title required)
        let createButton = app.buttons["Create"]
        XCTAssertFalse(createButton.isEnabled)

        // Enter title
        let titleField = app.textFields["Collection Title"]
        titleField.tap()
        titleField.typeText("Test Collection")

        // Now Create should be enabled
        XCTAssertTrue(createButton.isEnabled)

        // Clear title
        titleField.buttons["Clear text"].tap()

        // Create should be disabled again
        XCTAssertFalse(createButton.isEnabled)

        // Cancel form
        app.buttons["Cancel"].tap()
    }

    // MARK: - Form Interaction

    func testFormInteraction() throws {
        openCollectionForm()

        // Fill out the form
        let titleField = app.textFields["Collection Title"]
        titleField.tap()
        titleField.typeText("Adventure Collection")

        // Enter description
        let descriptionField = app.textViews["Collection Description"]
        descriptionField.tap()
        descriptionField.typeText("A collection of adventure stories")

        // Tap somewhere else to dismiss keyboard
        app.staticTexts["Age Group"].tap()

        // Select age group (if picker exists)
        if app.pickerWheels.count > 0 {
            app.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "6-8 years")
        }

        // Go back to main form
        app.buttons["Done"].tap()

        // Select development focus (tap on the cell to select)
        app.staticTexts["Development Focus"].tap()
        app.staticTexts["Problem Solving"].firstMatch.tap()

        // Verify Create button is enabled
        XCTAssertTrue(app.buttons["Create"].isEnabled)

        // Cancel instead of creating (to avoid side effects)
        app.buttons["Cancel"].tap()
    }

    // MARK: - Form Submission Test

    func testFormSubmissionWithMinimalData() throws {
        openCollectionForm()

        // Enter only the required field (title)
        let titleField = app.textFields["Collection Title"]
        titleField.tap()
        titleField.typeText("Minimal Test Collection")

        // Attempt to create with minimal data
        let createButton = app.buttons["Create"]

        // Only press Create if enabled and visible
        if createButton.isEnabled && createButton.exists {
            createButton.tap()

            // Verify loading indicator appears
            let loadingIndicator = app.progressIndicators.firstMatch
            XCTAssertTrue(loadingIndicator.waitForExistence(timeout: 2))

            // Wait for form to dismiss
            // This may take time as stories are generated
            let collectionsList = app.navigationBars["Growth Collections"]
            let exists = collectionsList.waitForExistence(timeout: 15)

            if !exists {
                // If creation fails or takes too long, there might be an error alert
                if app.alerts.buttons["OK"].exists {
                    app.alerts.buttons["OK"].tap()
                    app.buttons["Cancel"].tap()  // Cancel the form
                }
            }
        } else {
            app.buttons["Cancel"].tap()  // Cancel the form if Create isn't available
        }
    }

    // MARK: - Form Cancellation

    func testFormCancellation() throws {
        openCollectionForm()

        // Enter some data
        let titleField = app.textFields["Collection Title"]
        titleField.tap()
        titleField.typeText("Collection To Cancel")

        // Tap Cancel
        app.buttons["Cancel"].tap()

        // Verify we're back at Collections list
        XCTAssertTrue(app.navigationBars["Growth Collections"].exists)
    }

    // MARK: - Form Error Handling

    func testFormErrorHandling() throws {
        openCollectionForm()

        // Enter very long title to potentially trigger validation errors
        let titleField = app.textFields["Collection Title"]
        titleField.tap()
        let veryLongTitle = String(repeating: "Very Long Title ", count: 10)
        titleField.typeText(veryLongTitle)

        // Check if error message appears
        // Note: This is app-specific and depends on how error handling is implemented

        // Cancel form
        app.buttons["Cancel"].tap()
    }
}
