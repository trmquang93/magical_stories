import XCTest

class CollectionFormUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Use a launch argument to potentially mock services for UI tests if needed
        app.launchArguments = ["UI-TESTING"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func openCollectionForm() {
        // Navigate to Collections tab
        app.tabBars.buttons["CollectionsTabButton"].tap()

        // Tap the create button in the toolbar (using the accessibility identifier)
        app.buttons["CollectionsListView_AddButton"].tap()
        
        // Wait for the form to appear
        XCTAssertTrue(app.navigationBars["New Collection"].waitForExistence(timeout: 5))
    }

    // MARK: - Basic Form UI Test

    func testCollectionFormUI() throws {
        openCollectionForm()

        // Verify form elements exist using accessibility identifiers or labels
        XCTAssertTrue(app.navigationBars["New Collection"].exists) // Updated title
        XCTAssertTrue(app.staticTexts["Age Group"].exists)
        XCTAssertTrue(app.staticTexts["Developmental Focus"].exists) // Updated label
        XCTAssertTrue(app.staticTexts["Interests"].exists)
        XCTAssertTrue(app.staticTexts["Characters"].exists)
        XCTAssertTrue(app.buttons["Generate Collection"].exists) // Updated button label
        XCTAssertTrue(app.buttons["CollectionForm_CancelButton"].exists) // Using identifier

        // Dismiss form
        app.buttons["CollectionForm_CancelButton"].tap()
        XCTAssertTrue(app.navigationBars["Growth Collections"].waitForExistence(timeout: 5)) // Verify dismissal
    }
    
    func testCollectionFormUI_DarkMode() throws {
        // Set device to dark mode
        XCUIDevice.shared.appearance = .dark
        
        openCollectionForm()

        // Verify form elements exist in dark mode (basic check)
        XCTAssertTrue(app.navigationBars["New Collection"].exists)
        XCTAssertTrue(app.staticTexts["Age Group"].exists)
        XCTAssertTrue(app.staticTexts["Developmental Focus"].exists)
        XCTAssertTrue(app.staticTexts["Interests"].exists)
        XCTAssertTrue(app.staticTexts["Characters"].exists)
        XCTAssertTrue(app.buttons["Generate Collection"].exists)
        XCTAssertTrue(app.buttons["CollectionForm_CancelButton"].exists)

        // Dismiss form
        app.buttons["CollectionForm_CancelButton"].tap()
        XCTAssertTrue(app.navigationBars["Growth Collections"].waitForExistence(timeout: 5)) // Verify dismissal
        
        // Reset device appearance
        XCUIDevice.shared.appearance = .light
    }


    // MARK: - Form Validation

    func testFormValidation() throws {
        openCollectionForm()

        // Initially, Generate button should be disabled (Interests required)
        let generateButton = app.buttons["Generate Collection"]
        XCTAssertFalse(generateButton.isEnabled)

        // Enter interests
        let interestsTextView = app.textViews.containing(.staticText, identifier: "Interests").firstMatch // Find the TextView associated with the "Interests" label
        interestsTextView.tap()
        interestsTextView.typeText("Test Interests")

        // Now Generate should be enabled
        XCTAssertTrue(generateButton.isEnabled)

        // Clear interests
        interestsTextView.buttons["Clear text"].tap() // Assuming TextEditor has a clear button

        // Generate should be disabled again
        XCTAssertFalse(generateButton.isEnabled)

        // Cancel form
        app.buttons["CollectionForm_CancelButton"].tap()
        XCTAssertTrue(app.navigationBars["Growth Collections"].waitForExistence(timeout: 5)) // Verify dismissal
    }

    // MARK: - Form Interaction

    func testFormInteraction() throws {
        openCollectionForm()

        // Fill out the form
        let interestsTextView = app.textViews.containing(.staticText, identifier: "Interests").firstMatch
        interestsTextView.tap()
        interestsTextView.typeText("Adventure, Dragons")
        
        let charactersTextField = app.textFields.containing(.staticText, identifier: "Characters").firstMatch
        charactersTextField.tap()
        charactersTextField.typeText("Sparky the Dragon")

        // Tap somewhere else to dismiss keyboard
        app.staticTexts["Age Group"].tap()

        // Select age group (if picker exists)
        // Assuming AgeGroupField uses a SegmentedPicker
        let ageGroupPicker = app.segmentedControls.firstMatch
        if ageGroupPicker.exists {
             ageGroupPicker.buttons["6-8 years"].tap() // Tap the segment for 6-8 years
        }

        // Select development focus (tap on the cell to select)
        // Assuming DevelopmentalFocusField uses a MenuPicker
        let developmentalFocusPicker = app.buttons.containing(.staticText, identifier: "Developmental Focus").firstMatch
        developmentalFocusPicker.tap()
        app.collectionViews.staticTexts["Problem Solving"].tap() // Tap the menu item

        // Verify Generate button is enabled
        XCTAssertTrue(app.buttons["Generate Collection"].isEnabled)

        // Cancel instead of creating (to avoid side effects)
        app.buttons["CollectionForm_CancelButton"].tap()
        XCTAssertTrue(app.navigationBars["Growth Collections"].waitForExistence(timeout: 5)) // Verify dismissal
    }

    // MARK: - Form Submission Test (Simulating Success)

    func testFormSubmission_Success() throws {
        openCollectionForm()

        // Fill out the required field
        let interestsTextView = app.textViews.containing(.staticText, identifier: "Interests").firstMatch
        interestsTextView.tap()
        interestsTextView.typeText("Test Interests for Success")

        // Tap the Generate button
        let generateButton = app.buttons["Generate Collection"]
        XCTAssertTrue(generateButton.isEnabled)
        generateButton.tap()

        // Verify loading overlay appears
        let loadingOverlay = app.otherElements["CollectionLoadingOverlay"] // Using accessibility identifier
        XCTAssertTrue(loadingOverlay.waitForExistence(timeout: 2))

        // Wait for the form to dismiss (simulating successful generation)
        // This relies on the app's logic to dismiss the form on success
        XCTAssertTrue(app.navigationBars["Growth Collections"].waitForExistence(timeout: 15)) // Wait for the collections list to appear
        XCTAssertFalse(app.navigationBars["New Collection"].exists) // Ensure the form is gone
    }
    
    // MARK: - Form Submission Test (Simulating Error)
    
    func testFormSubmission_Error() throws {
        openCollectionForm()

        // Fill out the required field
        let interestsTextView = app.textViews.containing(.staticText, identifier: "Interests").firstMatch
        interestsTextView.tap()
        interestsTextView.typeText("Test Interests for Error")

        // Tap the Generate button
        let generateButton = app.buttons["Generate Collection"]
        XCTAssertTrue(generateButton.isEnabled)
        
        // TODO: Add a launch argument or mock to force the service to return an error
        // For now, we'll just tap the button and check for the alert if it appears.
        generateButton.tap()
        
        // Verify loading overlay appears
        let loadingOverlay = app.otherElements["CollectionLoadingOverlay"]
        XCTAssertTrue(loadingOverlay.waitForExistence(timeout: 2))

        // Wait for the error alert to appear (simulating generation failure)
        let errorAlert = app.alerts["Error Creating Collection"]
        XCTAssertTrue(errorAlert.waitForExistence(timeout: 15)) // Wait for the alert

        // Verify alert message contains the expected text (or part of it)
        XCTAssertTrue(errorAlert.staticTexts["Failed to generate collection: The operation couldn’t be completed."].exists) // Adjust based on actual error message

        // Dismiss the alert
        errorAlert.buttons["Try Again"].tap() // Or "Cancel" depending on test goal

        // Verify the alert is dismissed
        XCTAssertFalse(errorAlert.exists)
        
        // Cancel the form after handling the error
        app.buttons["CollectionForm_CancelButton"].tap()
        XCTAssertTrue(app.navigationBars["Growth Collections"].waitForExistence(timeout: 5)) // Verify dismissal
    }


    // MARK: - Form Cancellation

    func testFormCancellation() throws {
        openCollectionForm()

        // Enter some data
        let interestsTextView = app.textViews.containing(.staticText, identifier: "Interests").firstMatch
        interestsTextView.tap()
        interestsTextView.typeText("Collection To Cancel")

        // Tap Cancel button (using accessibility identifier)
        app.buttons["CollectionForm_CancelButton"].tap()

        // Verify we're back at Collections list
        XCTAssertTrue(app.navigationBars["Growth Collections"].waitForExistence(timeout: 5))
    }
}
