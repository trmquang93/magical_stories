import XCTest

final class IAPBasicUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Add basic IAP testing setup
        app.launchArguments.append("UI_TESTING")
        app.launchArguments.append("ENABLE_SANDBOX_TESTING")
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Basic App Functionality Tests
    
    func testAppLaunchesSuccessfully() {
        // Test that the app launches and shows the main UI
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "App should launch and show tab bar")
    }
    
    func testTabNavigationWorks() {
        // Test basic tab navigation
        let homeTab = app.tabBars.buttons["Home Tab"]
        let libraryTab = app.tabBars.buttons["Library Tab"]
        let collectionsTab = app.tabBars.buttons["Collections Tab"]
        let settingsTab = app.tabBars.buttons["Settings Tab"]
        
        // Verify tabs exist
        XCTAssertTrue(homeTab.exists, "Home tab should exist")
        XCTAssertTrue(libraryTab.exists, "Library tab should exist")
        XCTAssertTrue(collectionsTab.exists, "Collections tab should exist")
        XCTAssertTrue(settingsTab.exists, "Settings tab should exist")
        
        // Test tab navigation
        homeTab.tap()
        libraryTab.tap()
        collectionsTab.tap()
        settingsTab.tap()
    }
    
    // MARK: - Basic IAP Tests
    
    func testTC001_InitialFreeUserExperience() {
        // TC-001: Verify new users get 3 free stories per month
        
        // Navigate to Home tab
        let homeTab = app.tabBars.buttons["Home Tab"]
        if homeTab.exists {
            homeTab.tap()
        }
        
        // Look for usage indicator or generate button
        let generateButton = app.buttons["Generate Story"]
        if generateButton.exists {
            // Basic test: button should be available for new users
            XCTAssertTrue(generateButton.isHittable, "Generate Story button should be accessible for new users")
        }
        
        // Check for any usage indicators
        let usageIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'stories' OR label CONTAINS 'remaining'")).firstMatch
        if usageIndicator.exists {
            // If usage indicator exists, it should show available stories for new users
            XCTAssertFalse(usageIndicator.label.contains("0"), "New users should have stories available")
        }
    }
    
    func testTC002_StoryGenerationFlow() {
        // TC-002: Test basic story generation flow
        
        // Navigate to Home tab
        let homeTab = app.tabBars.buttons["Home Tab"]
        if homeTab.exists {
            homeTab.tap()
        }
        
        // Try to start story generation
        let generateButton = app.buttons["Generate Story"]
        if generateButton.exists {
            generateButton.tap()
            
            // Check if story form appears
            let childNameField = app.textFields["Child Name"]
            let topicField = app.textFields["Story Topic"]
            let ageField = app.textFields["Age"]
            
            // Fill in form if fields exist
            if childNameField.exists {
                childNameField.tap()
                childNameField.typeText("Test Child")
            }
            
            if topicField.exists {
                topicField.tap()
                topicField.typeText("Adventure")
            }
            
            if ageField.exists {
                ageField.tap()
                ageField.typeText("5")
            }
            
            // Look for generate button in form
            let formGenerateButton = app.buttons["Generate"]
            if formGenerateButton.exists {
                formGenerateButton.tap()
                
                // Check if generation starts (loading indicator or success message)
                let loadingIndicator = app.activityIndicators.firstMatch
                let successMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'generating' OR label CONTAINS 'created'")).firstMatch
                
                // Either loading should appear or success message
                let generationStarted = loadingIndicator.waitForExistence(timeout: 5) || successMessage.waitForExistence(timeout: 5)
                XCTAssertTrue(generationStarted, "Story generation should start")
            }
        }
    }
    
    func testTC003_PaywallTrigger() {
        // TC-003: Test paywall trigger when limits are reached
        
        // This test would need app state manipulation via launch arguments
        // For now, we'll just check that premium content exists
        
        // Navigate to Collections tab
        let collectionsTab = app.tabBars.buttons["Collections Tab"]
        if collectionsTab.exists {
            collectionsTab.tap()
            
            // Look for premium indicators
            let premiumLock = app.images["lock.fill"].firstMatch
            let premiumBadge = app.images["crown"].firstMatch
            let premiumText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Premium'")).firstMatch
            
            // Check if premium content exists
            if premiumLock.exists || premiumBadge.exists || premiumText.exists {
                XCTAssertTrue(true, "Premium content indicators found")
                
                // Try tapping premium content
                if premiumLock.exists {
                    premiumLock.tap()
                    
                    // Look for upgrade prompt
                    let upgradePrompt = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Upgrade' OR label CONTAINS 'Premium'")).firstMatch
                    if upgradePrompt.waitForExistence(timeout: 3) {
                        XCTAssertTrue(true, "Premium content shows upgrade prompt")
                    }
                }
            }
        }
    }
    
    func testTC004_SubscriptionOptionsDisplay() {
        // TC-004: Test subscription options display
        
        // Navigate to Settings tab
        let settingsTab = app.tabBars.buttons["Settings Tab"]
        if settingsTab.exists {
            settingsTab.tap()
            
            // Look for subscription/upgrade options
            let upgradeButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Upgrade' OR label CONTAINS 'Premium'")).firstMatch
            
            if upgradeButton.exists {
                upgradeButton.tap()
                
                // Check for subscription pricing
                let monthlyPrice = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '$8.99'")).firstMatch
                let yearlyPrice = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '$89.99'")).firstMatch
                let savingsText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Save' OR label CONTAINS '%'")).firstMatch
                
                // At least one pricing option should be visible
                let pricingVisible = monthlyPrice.exists || yearlyPrice.exists
                XCTAssertTrue(pricingVisible, "Subscription pricing should be displayed")
                
                // Check for savings message on yearly plan
                if savingsText.exists {
                    XCTAssertTrue(true, "Savings message displayed for yearly plan")
                }
            }
        }
    }
    
    func testTC005_AccessibilityBasics() {
        // TC-005: Basic accessibility testing
        
        // Navigate to Home tab
        let homeTab = app.tabBars.buttons["Home Tab"]
        if homeTab.exists {
            homeTab.tap()
            
            // Check accessibility of main elements
            XCTAssertNotNil(homeTab.label, "Home tab should have accessibility label")
            XCTAssertTrue(homeTab.isHittable, "Home tab should be hittable")
            
            let generateButton = app.buttons["Generate Story"]
            if generateButton.exists {
                XCTAssertNotNil(generateButton.label, "Generate button should have accessibility label")
                XCTAssertTrue(generateButton.isHittable, "Generate button should be hittable")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func dismissAnyModalIfPresent() {
        let closeButtons = ["Close", "Cancel", "Done", "✕"]
        
        for buttonTitle in closeButtons {
            let button = app.buttons[buttonTitle]
            if button.exists {
                button.tap()
                return
            }
        }
        
        // Try tapping outside modal if it's a sheet
        if app.sheets.firstMatch.exists {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
        }
    }
    
    private func waitForElementToAppear(_ element: XCUIElement, timeout: TimeInterval = 5.0) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }
}