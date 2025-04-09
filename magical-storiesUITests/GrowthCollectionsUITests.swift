import XCTest
@testable import magical_stories

final class GrowthCollectionsUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Set up environment for predictable testing
        app.launchArguments = ["UITesting"]
        app.launchEnvironment = [
            "USE_DEMO_DATA": "true",  // Load demo collections
            "SKIP_ONBOARDING": "true", // Skip onboarding if it exists
            "FAST_ANIMATIONS": "true"  // Speed up animations
        ]
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        // Clean up after each test
        app.terminate()
    }
    
    // MARK: - Collection Creation Flow Test
    
    func testCreateCollectionFlow() throws {
        // Navigate to the Collections tab
        app.tabBars.buttons["Collections"].tap()
        
        // Tap the "Create Collection" button
        app.buttons["CreateCollectionButton"].tap()
        
        // Fill in the collection form
        let ageGroupPicker = app.pickers["AgeGroupPicker"]
        ageGroupPicker.swipeUp() // Simulate selecting an age group
        
        let focusPicker = app.pickers["DevelopmentalFocusPicker"]
        focusPicker.swipeUp() // Simulate selecting a focus
        
        // Select interests
        app.buttons["Animals"].tap()
        app.buttons["Space"].tap()
        
        // Start generation
        app.buttons["GenerateCollectionButton"].tap()
        
        // Wait for the generation to complete
        let generationCompleteIndicator = app.staticTexts["CollectionGeneratedTitle"]
        XCTAssertTrue(generationCompleteIndicator.waitForExistence(timeout: 10))
        
        // Verify the new collection appears in the list
        app.buttons["ViewCollectionButton"].tap()
        
        // Verify we're on the collections list with the new item
        let collectionsList = app.collectionViews["CollectionsListView"]
        XCTAssertTrue(collectionsList.exists)
        XCTAssertTrue(collectionsList.cells.count > 0)
    }
    
    // MARK: - View Collection Details Flow Test
    
    func testViewCollectionDetailsFlow() throws {
        // Navigate to the Collections tab
        app.tabBars.buttons["Collections"].tap()
        
        // Verify collections list exists
        let collectionsList = app.collectionViews["CollectionsListView"]
        XCTAssertTrue(collectionsList.exists)
        
        // Tap the first collection
        let firstCollection = collectionsList.cells.element(boundBy: 0)
        XCTAssertTrue(firstCollection.exists)
        firstCollection.tap()
        
        // Verify collection detail view loaded
        XCTAssertTrue(app.staticTexts["CollectionTitleLabel"].exists)
        XCTAssertTrue(app.staticTexts["CollectionDescriptionLabel"].exists)
        
        // Verify progress indicator exists
        XCTAssertTrue(app.progressIndicators["CollectionProgressIndicator"].exists)
        
        // Verify stories list exists
        let storiesList = app.collectionViews["CollectionStoriesListView"]
        XCTAssertTrue(storiesList.exists)
        XCTAssertTrue(storiesList.cells.count > 0)
        
        // Verify badges section exists
        XCTAssertTrue(app.staticTexts["BadgesSectionLabel"].exists)
    }
    
    // MARK: - Complete Story Within Collection Flow Test
    
    func testCompleteStoryWithinCollectionFlow() throws {
        // Navigate to the Collections tab
        app.tabBars.buttons["Collections"].tap()
        
        // Tap the first collection
        let collectionsList = app.collectionViews["CollectionsListView"]
        let firstCollection = collectionsList.cells.element(boundBy: 0)
        firstCollection.tap()
        
        // Get initial progress
        let progressIndicator = app.progressIndicators["CollectionProgressIndicator"]
        let initialProgress = progressIndicator.value as? String ?? "0%"
        
        // Tap the first story
        let storiesList = app.collectionViews["CollectionStoriesListView"]
        let firstStory = storiesList.cells.element(boundBy: 0)
        firstStory.tap()
        
        // Verify story detail view loaded
        XCTAssertTrue(app.staticTexts["StoryTitleLabel"].exists)
        
        // Navigate through all pages of the story
        let nextButton = app.buttons["NextPageButton"]
        while nextButton.exists && nextButton.isEnabled {
            nextButton.tap()
        }
        
        // Mark as complete or verify we reached the end
        if app.buttons["MarkAsCompleteButton"].exists {
            app.buttons["MarkAsCompleteButton"].tap()
        }
        
        // Check for achievement alert and dismiss it
        let achievementAlert = app.alerts["AchievementAlert"]
        if achievementAlert.waitForExistence(timeout: 5) {
            achievementAlert.buttons["OK"].tap()
        }
        
        // Navigate back to collection detail
        app.navigationBars.buttons.element(boundBy: 0).tap() // Back button
        
        // Check progress has increased
        let updatedProgress = progressIndicator.value as? String ?? "0%"
        
        // Convert percentage strings to numeric values for comparison
        let initialValue = Double(initialProgress.replacingOccurrences(of: "%", with: "")) ?? 0
        let updatedValue = Double(updatedProgress.replacingOccurrences(of: "%", with: "")) ?? 0
        
        // Verify progress increased or is at 100%
        XCTAssertTrue(updatedValue > initialValue || updatedValue == 100)
    }
} 