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
        let homeTab = app.tabBars.buttons["HomeTabButton"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5.0), "Home tab button should exist")
        homeTab.tap()
        
        // Wait for stories to load
        // The stories in HomeView are in the "HomeView_LibrarySection"
        let librarySection = app.otherElements["HomeView_LibrarySection"]
        XCTAssertTrue(librarySection.waitForExistence(timeout: 5.0), "Library section should exist in HomeView")
        
        // Find the first story card - we look for StoryCard with any ID as child of librarySection
        let storyCardPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "HomeView_StoryCard_")
        let storyCards = librarySection.descendants(matching: .any).matching(storyCardPredicate)
        
        XCTAssertTrue(storyCards.firstMatch.waitForExistence(timeout: 5.0), "Story card should exist")
        
        // Tap on the first story card
        storyCards.firstMatch.tap()
        
        // Verify we navigated to StoryDetailView by checking for the page indicator
        let pageIndicator = app.staticTexts["PageIndicator"]
        XCTAssertTrue(pageIndicator.waitForExistence(timeout: 5.0), "Page indicator should exist in StoryDetailView")
        
        // Verify story page container exists
        let storyPageTabView = app.otherElements["StoryPageTabView"]
        XCTAssertTrue(storyPageTabView.waitForExistence(timeout: 3.0), "Story page tab view should exist")
    }
}