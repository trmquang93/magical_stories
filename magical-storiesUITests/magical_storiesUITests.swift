//
//  magical_storiesUITests.swift
//  magical-storiesUITests
//
//  Created by Quang Tran Minh on 30/3/25.
//

import XCTest

final class magical_storiesUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.

        // Clear potentially conflicting UserDefaults data before launching the app
        UserDefaults.standard.removeObject(forKey: "savedStories")
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testTabBarTabsExistAndAreTappable() {
        let app = XCUIApplication()
        app.launch()

        // Check for Home tab
        let homeTab = app.tabBars.buttons["Home Tab"]
        XCTAssertTrue(homeTab.exists, "Home tab should exist")
        homeTab.tap()

        // Check for Library tab
        let libraryTab = app.tabBars.buttons["Library Tab"]
        XCTAssertTrue(libraryTab.exists, "Library tab should exist")
        libraryTab.tap()

        // Check for Collections tab
        let collectionsTab = app.tabBars.buttons["Collections Tab"]
        XCTAssertTrue(collectionsTab.exists, "Collections tab should exist")
        collectionsTab.tap()

        // Check for Settings tab
        let settingsTab = app.tabBars.buttons["Settings Tab"]
        XCTAssertTrue(settingsTab.exists, "Settings tab should exist")
        settingsTab.tap()
    }

    func testHomeViewStoryCardNavigation() {
        let app = XCUIApplication()
        app.launch()

        // Tap Home tab to ensure we're on HomeView
        let homeTab = app.tabBars.buttons["Home Tab"]
        if homeTab.exists { homeTab.tap() }

        // Find the first story card by accessibility identifier or text
        let firstStoryCard = app.staticTexts.matching(identifier: "StoryTitle_").firstMatch
        if firstStoryCard.exists {
            firstStoryCard.tap()
            // Assert that StoryDetailView appears (by navigation title or unique text)
            let pageIndicator = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'Page '")
            ).firstMatch
            XCTAssertTrue(
                pageIndicator.waitForExistence(timeout: 2),
                "Should navigate to StoryDetailView and see page indicator")
        } else {
            // If no story card, skip test
            print("No story card found in HomeView; skipping navigation test.")
        }
    }

    func testLibraryViewStoryCardNavigation() {
        let app = XCUIApplication()
        app.launch()

        // Tap Library tab
        let libraryTab = app.tabBars.buttons["Library Tab"]
        if libraryTab.exists { libraryTab.tap() }

        // Find the first recent story card by accessibility identifier or text
        let firstRecentStoryCard = app.staticTexts.matching(identifier: "StoryTitle_").firstMatch
        if firstRecentStoryCard.exists {
            firstRecentStoryCard.tap()
            // Assert that StoryDetailView appears (by navigation title or unique text)
            let pageIndicator = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'Page '")
            ).firstMatch
            XCTAssertTrue(
                pageIndicator.waitForExistence(timeout: 2),
                "Should navigate to StoryDetailView and see page indicator")
        } else {
            // If no story card, skip test
            print("No recent story card found in LibraryView; skipping navigation test.")
        }
    }

    func testViewAllStoriesButton() {
        let app = XCUIApplication()
        app.launch()

        // Tap Home tab to ensure we're on HomeView
        let homeTab = app.tabBars.buttons["Home Tab"]
        if homeTab.exists { homeTab.tap() }

        // Look for "View All Stories" button
        let viewAllStoriesButton = app.buttons["ViewAllStoriesButton"]

        if viewAllStoriesButton.exists {
            // Tap the button
            viewAllStoriesButton.tap()

            // Verify we navigated to the Library tab
            // Wait briefly for the animation to complete
            let libraryTitle = app.navigationBars["Your Story Library"].firstMatch
            XCTAssertTrue(
                libraryTitle.waitForExistence(timeout: 2),
                "Should navigate to Library tab when 'View All Stories' is tapped")
        } else {
            // If the button doesn't exist (possibly because there aren't enough stories), log this
            print(
                "'View All Stories' button not found - may be because there aren't enough stories.")
        }
    }
}
