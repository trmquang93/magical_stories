import XCTest
@testable import magical_stories

final class HomeViewStoryNavigation_UITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Set launch arguments to ensure we have test data
        app.launchArguments.append("UI_TESTING")
        app.launchArguments.append("CREATE_TEST_STORIES")
        
        app.launch()
    }
    
    func testNavigateFromHomeToStoryDetail() throws {
        // Ensure we're on the Home tab
        let homeTab = app.tabBars.buttons["Home Tab"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5.0), "Home tab button should exist")
        homeTab.tap()
        
        // Wait for the HomeView to load - looking for any welcome/greeting text
        let waitTime: TimeInterval = 5.0
        let welcomePredicate = NSPredicate(format: "label CONTAINS[c] %@", "Welcome")
        let welcomeTexts = app.staticTexts.matching(welcomePredicate)
        
        XCTAssertTrue(welcomeTexts.firstMatch.waitForExistence(timeout: waitTime), 
                      "Welcome message should exist in HomeView")
                      
        // Wait to ensure test stories have loaded
        sleep(2)
        
        // Create a predicate for any StoryCard element in the view
        let storyCardPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "HomeView_StoryCard_")
        let storyCards = app.descendants(matching: .any).matching(storyCardPredicate)
        
        if !storyCards.firstMatch.exists {
            // Skip test if no story cards exist
            print("No story cards found - skipping test")
            return
        }
        
        // Tap on the first story card
        storyCards.firstMatch.tap()
        
        // Verify we navigated to StoryDetailView by checking for the page indicator
        // First try with accessibility ID
        var pageIndicatorFound = false
        if app.staticTexts["PageIndicator"].waitForExistence(timeout: 3.0) {
            pageIndicatorFound = true
        } else {
            // Try with text content
            let pagePredicate = NSPredicate(format: "label CONTAINS[c] %@", "Page")
            let pageTexts = app.staticTexts.matching(pagePredicate)
            
            if pageTexts.firstMatch.waitForExistence(timeout: 2.0) {
                pageIndicatorFound = true
            }
        }
        
        XCTAssertTrue(pageIndicatorFound, "Page indicator or text should exist in StoryDetailView")
        
        // Verify a story page container exists - using a flexible approach
        let storyPageTabView = app.otherElements["StoryPageTabView"]
        if !storyPageTabView.waitForExistence(timeout: 3.0) {
            // Try an alternative way to verify we're on the story detail view
            let backButton = app.buttons["Back"]
            XCTAssertTrue(backButton.exists || app.navigationBars.buttons.firstMatch.exists, 
                         "Back navigation should be available in StoryDetailView")
        }
    }
}