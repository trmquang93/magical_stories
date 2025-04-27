import XCTest

final class GrowthCollectionsUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCollectionsTabNavigation() throws {
        let app = XCUIApplication()
        app.launch()

        // Tap the Collections tab button
        // Ensure MainTabView.swift has .accessibilityIdentifier("CollectionsTabButton") for the Collections tab
        app.tabBars.buttons["CollectionsTabButton"].tap()

        // Assert that the navigation title "Collections" exists
        // Ensure CollectionsListView.swift has .navigationTitle("Collections")
        XCTAssertTrue(app.navigationBars["Collections"].exists)

        // Assert that either the list or the empty state view is present
        // Ensure CollectionsListView.swift has .accessibilityIdentifier("CollectionsList") for the List
        // and .accessibilityIdentifier("EmptyStateView") for the empty state VStack
        let collectionsListExists = app.collectionViews["CollectionsList"].waitForExistence(timeout: 5)
        let emptyStateExists = app.otherElements["EmptyStateView"].waitForExistence(timeout: 5)
        
        XCTAssertTrue(collectionsListExists || emptyStateExists, "Neither CollectionsList nor EmptyStateView was found after tapping the Collections tab.")
    }
    
    func testCreateCollectionFlow() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to home tab
        // Ensure MainTabView.swift has .accessibilityIdentifier("HomeTabButton")
        app.tabBars.buttons["HomeTabButton"].tap()

        // Tap create collection button
        // Ensure HomeView.swift has .accessibilityIdentifier("CreateCollectionButton")
        app.buttons["CreateCollectionButton"].tap()

        // Fill out collection form
        // Ensure CollectionFormView.swift has identifiers:
        // - ChildNameField
        // - AgeGroupPicker
        // - DevelopmentalFocusPicker
        // - InterestsField
        // - GenerateCollectionButton
        let childNameField = app.textFields["ChildNameField"]
        XCTAssertTrue(childNameField.waitForExistence(timeout: 5), "Child Name field not found")
        childNameField.tap()
        childNameField.typeText("Test Child")

        // Select age group
        let ageGroupPicker = app.pickers["AgeGroupPicker"]
        XCTAssertTrue(ageGroupPicker.waitForExistence(timeout: 5), "Age Group picker not found")
        ageGroupPicker.tap()
        // On iOS 16+, pickers might present differently. Adjust if needed.
        // This assumes a wheel picker. If it's a menu, interaction will differ.
        // Let's try tapping the desired value directly if it's visible.
        if app.pickerWheels.element.exists {
             app.pickerWheels.element.adjust(toPickerWheelValue: "Elementary (6-8)")
             // Dismiss the picker if necessary (e.g., tap Done)
             if app.buttons["Done"].exists {
                 app.buttons["Done"].tap()
             }
        } else {
            // Handle menu-style picker
            app.buttons["Elementary (6-8)"].tap() // Assuming the option is a button in the menu
        }


        // Select developmental focus
        let developmentalFocusPicker = app.pickers["DevelopmentalFocusPicker"]
        XCTAssertTrue(developmentalFocusPicker.waitForExistence(timeout: 5), "Developmental Focus picker not found")
        developmentalFocusPicker.tap()
        if app.pickerWheels.element.exists {
            app.pickerWheels.element.adjust(toPickerWheelValue: "Emotional Intelligence")
            if app.buttons["Done"].exists {
                 app.buttons["Done"].tap()
             }
        } else {
            app.buttons["Emotional Intelligence"].tap()
        }


        // Enter interests
        let interestsField = app.textFields["InterestsField"]
        XCTAssertTrue(interestsField.waitForExistence(timeout: 5), "Interests field not found")
        interestsField.tap()
        interestsField.typeText("Dinosaurs, Space")

        // Generate collection
        let generateButton = app.buttons["GenerateCollectionButton"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 5), "Generate Collection button not found")
        generateButton.tap()

        // Wait for generation to complete and navigate back (implicitly closes sheet)
        // Then navigate to Collections tab
        app.tabBars.buttons["CollectionsTabButton"].tap()

        // Verify collection appears in the list
        // Ensure CollectionsListView.swift / CollectionCardView.swift uses the identifier
        // "CollectionCard_Emotional Intelligence" for the NavigationLink/Button
        let collectionCard = app.buttons["CollectionCard_Emotional Intelligence"] // Adjusted identifier
        XCTAssertTrue(collectionCard.waitForExistence(timeout: 60), "Expected collection card 'Emotional Intelligence' not found after generation.") // Increased timeout for generation
    }

    func testViewCollectionDetailsFlow() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to the Collections tab
        app.tabBars.buttons["CollectionsTabButton"].tap()

        // Ensure that the collections list is present
        let collectionsList = app.collectionViews["CollectionsList"]
        XCTAssertTrue(collectionsList.waitForExistence(timeout: 5), "Collections list not found")

        // Tap on a collection card
        // Assuming that CollectionCardView.swift uses the identifier "CollectionCard_\(collection.title)"
        let collectionCard = app.buttons.containing(NSPredicate(format: "identifier BEGINSWITH 'CollectionCard_'")).firstMatch
        XCTAssertTrue(collectionCard.waitForExistence(timeout: 5), "Collection card not found")
        collectionCard.tap()

        // Verify the collection details screen is displayed
        // Ensure CollectionDetailView.swift has .accessibilityIdentifier("CollectionDetailView")
        let collectionDetailView = app.otherElements["CollectionDetailView"]
        XCTAssertTrue(collectionDetailView.waitForExistence(timeout: 5), "Collection detail view not found")

        // Verify the collection title is displayed
        // Ensure CollectionDetailView.swift has .accessibilityIdentifier("CollectionTitle")
        let collectionTitle = app.staticTexts["CollectionTitle"]
        XCTAssertTrue(collectionTitle.waitForExistence(timeout: 5), "Collection title not found")

        // Verify the collection description is displayed
        // Ensure CollectionDetailView.swift has .accessibilityIdentifier("CollectionDescription")
        let collectionDescription = app.staticTexts["CollectionDescription"]
        XCTAssertTrue(collectionDescription.waitForExistence(timeout: 5), "Collection description not found")

        // Verify the collection progress is displayed
        // Ensure CollectionDetailView.swift has .accessibilityIdentifier("CollectionProgress")
        let collectionProgress = app.progressIndicators["CollectionProgress"]
        XCTAssertTrue(collectionProgress.waitForExistence(timeout: 5), "Collection progress not found")

        // Verify that stories within the collection are displayed
        // Ensure CollectionDetailView.swift has .accessibilityIdentifier("StoryList")
        let storyList = app.collectionViews["StoryList"]
        XCTAssertTrue(storyList.waitForExistence(timeout: 5), "Story list not found")
    }

    func testCompleteStoryWithinCollectionFlow() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to the Collections tab
        app.tabBars.buttons["CollectionsTabButton"].tap()

        // Ensure that the collections list is present
        let collectionsList = app.collectionViews["CollectionsList"]
        XCTAssertTrue(collectionsList.waitForExistence(timeout: 5), "Collections list not found")

        // Tap on a collection card
        let collectionCard = app.buttons.containing(NSPredicate(format: "identifier BEGINSWITH 'CollectionCard_'")).firstMatch
        XCTAssertTrue(collectionCard.waitForExistence(timeout: 5), "Collection card not found")
        collectionCard.tap()

        // Verify the collection details screen is displayed
        let collectionDetailView = app.otherElements["CollectionDetailView"]
        XCTAssertTrue(collectionDetailView.waitForExistence(timeout: 5), "Collection detail view not found")

        // Select a story from the collection
        // Assuming that the story items have an accessibility identifier "StoryItem_\(story.title)"
        let storyItem = app.buttons.containing(NSPredicate(format: "identifier BEGINSWITH 'StoryItem_'")).firstMatch
        XCTAssertTrue(storyItem.waitForExistence(timeout: 5), "Story item not found")
        storyItem.tap()

        // Read through the story (paging through)
        // Assuming that the page view has a button to go to the next page with accessibility identifier "NextPageButton"
        while app.buttons["NextPageButton"].exists {
            app.buttons["NextPageButton"].tap()
        }

        // Wait for the story to complete (e.g., last page)
        sleep(2)

        // Return to the collection detail view
        app.buttons["BackButton"].tap() // Assuming there is a back button

        // Observe updated progress for the collection
        let collectionProgress = app.progressIndicators["CollectionProgress"]
        XCTAssertTrue(collectionProgress.waitForExistence(timeout: 5), "Collection progress not found")
        // You might want to add a more specific assertion about the progress value
        // For example, if you know the collection has 3 stories and one is completed, the progress should be 0.33
        // XCTAssertEqual(collectionProgress.value as! Double, 0.33, accuracy: 0.01)
    }

    func testAccessibilityVerification() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to the Collections tab
        app.tabBars.buttons["CollectionsTabButton"].tap()

        // Ensure that the collections list is present
        let collectionsList = app.collectionViews["CollectionsList"]
        XCTAssertTrue(collectionsList.waitForExistence(timeout: 5), "Collections list not found")

        // Verify accessibility labels on collection cards
        let collectionCard = app.buttons.containing(NSPredicate(format: "identifier BEGINSWITH 'CollectionCard_'")).firstMatch
        XCTAssertTrue(collectionCard.waitForExistence(timeout: 5), "Collection card not found")
        XCTAssertNotNil(collectionCard.accessibilityLabel, "Collection card should have an accessibility label")

        // Tap on a collection card
        collectionCard.tap()

        // Verify the collection details screen is displayed
        let collectionDetailView = app.otherElements["CollectionDetailView"]
        XCTAssertTrue(collectionDetailView.waitForExistence(timeout: 5), "Collection detail view not found")

        // Verify accessibility labels on story items
        let storyItem = app.buttons.containing(NSPredicate(format: "identifier BEGINSWITH 'StoryItem_'")).firstMatch
        XCTAssertTrue(storyItem.waitForExistence(timeout: 5), "Story item not found")
        XCTAssertNotNil(storyItem.accessibilityLabel, "Story item should have an accessibility label")

        // Verify accessibility labels on progress indicators
        let collectionProgress = app.progressIndicators["CollectionProgress"]
        XCTAssertTrue(collectionProgress.waitForExistence(timeout: 5), "Collection progress not found")
        XCTAssertNotNil(collectionProgress.accessibilityLabel, "Collection progress should have an accessibility label")
        XCTAssertEqual(collectionProgress.accessibilityTraits, .progressBar, "Collection progress should have accessibility trait of progressBar")
    }

    func testNavigationAndTabSwitching() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to the Collections tab
        app.tabBars.buttons["CollectionsTabButton"].tap()

        // Ensure that the collections list is present
        let collectionsList = app.collectionViews["CollectionsList"]
        XCTAssertTrue(collectionsList.waitForExistence(timeout: 5), "Collections list not found")

        // Tap on a collection card
        let collectionCard = app.buttons.containing(NSPredicate(format: "identifier BEGINSWITH 'CollectionCard_'")).firstMatch
        XCTAssertTrue(collectionCard.waitForExistence(timeout: 5), "Collection card not found")
        collectionCard.tap()

        // Verify the collection details screen is displayed
        let collectionDetailView = app.otherElements["CollectionDetailView"]
        XCTAssertTrue(collectionDetailView.waitForExistence(timeout: 5), "Collection detail view not found")

        // Select a story from the collection
        let storyItem = app.buttons.containing(NSPredicate(format: "identifier BEGINSWITH 'StoryItem_'")).firstMatch
        XCTAssertTrue(storyItem.waitForExistence(timeout: 5), "Story item not found")
        storyItem.tap()

        // Verify that we navigated to the story detail view
        // Assuming StoryDetailView.swift has .accessibilityIdentifier("StoryDetailView")
        let storyDetailView = app.otherElements["StoryDetailView"]
        XCTAssertTrue(storyDetailView.waitForExistence(timeout: 5), "Story detail view not found")

        // Navigate back to the collection detail view
        app.buttons["BackButton"].tap()

        // Verify that we are back on the collection detail view
        XCTAssertTrue(collectionDetailView.waitForExistence(timeout: 5), "Collection detail view not found after back navigation")

        // Navigate back to the home tab
        app.tabBars.buttons["HomeTabButton"].tap()

        // Verify that we are on the home view
        // Assuming HomeView.swift has .accessibilityIdentifier("HomeView")
        let homeView = app.otherElements["HomeView"]
        XCTAssertTrue(homeView.waitForExistence(timeout: 5), "Home view not found after tab switch")

        // Navigate back to the collections tab
        app.tabBars.buttons["CollectionsTabButton"].tap()

        // Verify that we are back on the collections list view
        XCTAssertTrue(collectionsList.waitForExistence(timeout: 5), "Collections list not found after tab switch")
    }
}