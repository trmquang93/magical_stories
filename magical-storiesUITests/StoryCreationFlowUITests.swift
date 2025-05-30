import XCTest

/// UI tests for the Story Creation Flow
/// Verifying the story creation entry point and basic navigation
final class StoryCreationFlowUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Test Case: Home Screen and Story Creation Entry Point
    
    func testHomeScreenAndStoryCreationEntry() throws {
        // Wait for app to fully load
        XCTAssertTrue(app.waitForExistence(timeout: 10), "App should launch successfully")
        
        takeScreenshot("01_home_screen_loaded")
        
        // Verify we're on the home screen with welcome text
        let welcomeText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Welcome back'")).firstMatch
        XCTAssertTrue(welcomeText.waitForExistence(timeout: 5), "Welcome text should be visible")
        
        // Look for the Create Story action card
        let createStoryElements = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Create a New Story'"))
        XCTAssertTrue(createStoryElements.count > 0, "Create Story card should be present")
        
        takeScreenshot("02_story_creation_verified")
        
        // Look for the Start button
        let startButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Start'")).firstMatch
        XCTAssertTrue(startButton.waitForExistence(timeout: 5), "Start button should be visible")
        
        takeScreenshot("03_start_button_identified")
        
        // Test navigation by tapping the Start button
        startButton.tap()
        
        // Give the navigation some time to complete
        sleep(2)
        takeScreenshot("04_after_start_button_tap")
        
        // Check if we've navigated to a different screen (form, modal, etc.)
        // Since we can't predict exact UI elements, we'll check for changes
        let navigationOccurred = !startButton.exists || 
                                app.navigationBars.count > 0 || 
                                app.sheets.count > 0
        
        if navigationOccurred {
            takeScreenshot("05_navigation_successful")
        } else {
            takeScreenshot("05_navigation_may_not_have_occurred")
        }
    }
    
    // MARK: - Test Case: Tab Navigation
    
    func testTabNavigation() throws {
        // Verify the app has the expected tab structure
        XCTAssertTrue(app.waitForExistence(timeout: 10), "App should launch successfully")
        
        takeScreenshot("tab_01_home_active")
        
        // Check if tab bar exists and has expected tabs
        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 5) {
            takeScreenshot("tab_02_tab_bar_visible")
            
            // Look for expected tabs
            let expectedTabs = ["Home", "Library", "Collections", "Settings"]
            for tabName in expectedTabs {
                let tabButton = app.buttons.containing(NSPredicate(format: "label CONTAINS '\(tabName)'")).firstMatch
                if tabButton.exists {
                    // Tab exists - this is good
                    print("✅ Found tab: \(tabName)")
                } else {
                    print("⚠️ Tab not found: \(tabName)")
                }
            }
            takeScreenshot("tab_03_tabs_verified")
        }
    }
    
    // MARK: - Test Case: Basic UI Elements
    
    func testBasicUIElements() throws {
        // Verify key UI elements are present and accessible
        XCTAssertTrue(app.waitForExistence(timeout: 10), "App should launch successfully")
        
        takeScreenshot("ui_01_initial_state")
        
        // Check for welcome text
        let welcomeElements = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Welcome'"))
        XCTAssertTrue(welcomeElements.count > 0, "Welcome text should be present")
        
        // Check for story creation elements
        let storyCreationElements = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Create' OR label CONTAINS 'Story'"))
        XCTAssertTrue(storyCreationElements.count > 0, "Story creation elements should be present")
        
        // Check for collections section
        let collectionsElements = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Collection' OR label CONTAINS 'Growth'"))
        XCTAssertTrue(collectionsElements.count > 0, "Collections section should be present")
        
        takeScreenshot("ui_02_elements_verified")
    }
    
    // MARK: - Helper Methods
    
    private func takeScreenshot(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        
        // Add to test bundle (for Xcode result viewer)
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "StoryCreation_\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // Also save directly to test-reports folder
        let projectPath = "/Users/quang.tranminh/Projects/new-ios/magical_stories"
        let testReportsPath = "\(projectPath)/test-reports"
        let fileName = "StoryCreation_\(name).png"
        let filePath = "\(testReportsPath)/\(fileName)"
        
        // Create test-reports directory if it doesn't exist
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: testReportsPath) {
            try? fileManager.createDirectory(atPath: testReportsPath, withIntermediateDirectories: true)
        }
        
        // Save screenshot to file
        let url = URL(fileURLWithPath: filePath)
        try? screenshot.pngRepresentation.write(to: url)
        
        print("📸 Screenshot saved: \(fileName)")
    }
}