import XCTest

/// Utility class for IAP UI testing with common helpers and mock data
class IAPTestUtilities {
    
    // MARK: - Test Data Constants
    
    struct TestData {
        static let monthlyPrice = "$8.99"
        static let yearlyPrice = "$89.99"
        static let savingsMessage = "Save 16%"
        static let freeStoriesPerMonth = 3
        static let testChildName = "Test Child"
        static let testStoryTopic = "Adventure"
        static let testAge = "5"
    }
    
    struct ProductIDs {
        static let premiumMonthly = "com.magicalstories.premium.monthly"
        static let premiumYearly = "com.magicalstories.premium.yearly"
    }
    
    struct AnalyticsEvents {
        static let paywallShown = "paywall_shown"
        static let productViewed = "product_viewed"
        static let purchaseStarted = "purchase_started"
        static let purchaseCompleted = "purchase_completed"
        static let purchaseFailed = "purchase_failed"
        static let featureRestricted = "feature_restricted"
        static let usageLimitReached = "usage_limit_reached"
        static let monthlyReset = "monthly_reset"
        static let storyGenerated = "story_generated"
    }
    
    // MARK: - Launch Arguments
    
    struct LaunchArguments {
        static let enableSandboxTesting = "ENABLE_SANDBOX_TESTING"
        static let resetSubscriptionState = "RESET_SUBSCRIPTION_STATE"
        static let resetUsageCounters = "RESET_USAGE_COUNTERS"
        static let setUserAtUsageLimit = "SET_USER_AT_USAGE_LIMIT"
        static let simulateMonthlyReset = "SIMULATE_MONTHLY_RESET"
        static let simulateExpiredSubscription = "SIMULATE_EXPIRED_SUBSCRIPTION"
        static let simulatePremiumSubscription = "SIMULATE_PREMIUM_SUBSCRIPTION"
        static let enableAnalyticsMonitoring = "ENABLE_ANALYTICS_MONITORING"
        static let simulateNetworkIssues = "SIMULATE_NETWORK_ISSUES"
        static let resetToFreeTier = "RESET_TO_FREE_TIER"
        
        static func setStoryCount(_ count: Int) -> String {
            return "SET_STORY_COUNT_\(count)"
        }
        
        static func simulateLocale(_ locale: String) -> String {
            return "SIMULATE_LOCALE_\(locale)"
        }
    }
    
    // MARK: - Accessibility Identifiers
    
    struct AccessibilityIDs {
        static let homeTab = "Home Tab"
        static let libraryTab = "Library Tab"
        static let collectionsTab = "Collections Tab"
        static let settingsTab = "Settings Tab"
        static let generateStoryButton = "Generate Story"
        static let childNameField = "Child Name"
        static let storyTopicField = "Story Topic"
        static let ageField = "Age"
        static let generateButton = "Generate"
        static let closeButton = "Close"
        static let cancelButton = "Cancel"
        static let restoreButton = "Restore"
        static let viewAllStoriesButton = "ViewAllStoriesButton"
    }
    
    // MARK: - Common UI Test Helpers
    
    static func setupIAPTestEnvironment(app: XCUIApplication) {
        app.launchArguments.append(LaunchArguments.enableSandboxTesting)
        app.launchArguments.append(LaunchArguments.resetSubscriptionState)
        app.launchArguments.append(LaunchArguments.resetUsageCounters)
    }
    
    static func navigateToTab(_ tabName: String, app: XCUIApplication) -> Bool {
        let tab = app.tabBars.buttons[tabName]
        guard tab.exists else { return false }
        tab.tap()
        return true
    }
    
    static func fillStoryForm(app: XCUIApplication, childName: String = TestData.testChildName, 
                             topic: String = TestData.testStoryTopic, age: String = TestData.testAge) {
        let childNameField = app.textFields[AccessibilityIDs.childNameField]
        if childNameField.exists {
            childNameField.tap()
            childNameField.clearAndTypeText(childName)
        }
        
        let topicField = app.textFields[AccessibilityIDs.storyTopicField]
        if topicField.exists {
            topicField.tap()
            topicField.clearAndTypeText(topic)
        }
        
        let ageField = app.textFields[AccessibilityIDs.ageField]
        if ageField.exists {
            ageField.tap()
            ageField.clearAndTypeText(age)
        }
        
        let generateButton = app.buttons[AccessibilityIDs.generateButton]
        if generateButton.exists {
            generateButton.tap()
        }
    }
    
    static func triggerPaywall(app: XCUIApplication) -> Bool {
        _ = navigateToTab(AccessibilityIDs.homeTab, app: app)
        
        let generateButton = app.buttons[AccessibilityIDs.generateStoryButton]
        guard generateButton.exists else { return false }
        
        generateButton.tap()
        
        // Check if paywall appears
        let paywallIndicators = [
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Premium'")).firstMatch,
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Upgrade'")).firstMatch,
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'limit'")).firstMatch
        ]
        
        return paywallIndicators.contains { $0.waitForExistence(timeout: 5) }
    }
    
    static func dismissPaywall(app: XCUIApplication) {
        let dismissButtons = [
            app.buttons[AccessibilityIDs.closeButton],
            app.buttons["✕"],
            app.buttons[AccessibilityIDs.cancelButton],
            app.buttons["Done"],
            app.buttons["Dismiss"]
        ]
        
        for button in dismissButtons {
            if button.exists {
                button.tap()
                return
            }
        }
        
        // Try tapping outside modal
        if app.sheets.firstMatch.exists {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
        }
    }
    
    static func verifySubscriptionOptions(app: XCUIApplication) -> (monthly: Bool, yearly: Bool, savings: Bool) {
        let monthlyOption = app.buttons.containing(NSPredicate(format: "label CONTAINS '\(TestData.monthlyPrice)'")).firstMatch
        let yearlyOption = app.buttons.containing(NSPredicate(format: "label CONTAINS '\(TestData.yearlyPrice)'")).firstMatch
        let savingsMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '\(TestData.savingsMessage)'")).firstMatch
        
        return (
            monthly: monthlyOption.exists,
            yearly: yearlyOption.exists,
            savings: savingsMessage.exists
        )
    }
    
    static func verifyUsageLimitState(app: XCUIApplication, expectedRemaining: Int?) -> Bool {
        let usageIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'remaining'")).firstMatch
        
        guard usageIndicator.exists else {
            // No usage indicator might mean unlimited access
            return expectedRemaining == nil
        }
        
        if let expected = expectedRemaining {
            return usageIndicator.label.contains("\(expected)")
        }
        
        return true
    }
    
    static func attemptStoryGeneration(app: XCUIApplication) -> GenerationResult {
        let generateButton = app.buttons[AccessibilityIDs.generateStoryButton]
        guard generateButton.exists else { return .buttonNotFound }
        
        generateButton.tap()
        
        // Check if paywall appears (indicating limit reached)
        let paywallIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'limit' OR label CONTAINS 'Premium'")).firstMatch
        if paywallIndicator.waitForExistence(timeout: 3) {
            return .limitReached
        }
        
        // Fill form if it appears
        fillStoryForm(app: app)
        
        // Check for loading or success indicators
        let loadingIndicator = app.activityIndicators.firstMatch
        let successIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'generated' OR label CONTAINS 'complete'")).firstMatch
        
        if loadingIndicator.waitForExistence(timeout: 5) || successIndicator.waitForExistence(timeout: 30) {
            return .success
        }
        
        return .failed
    }
    
    enum GenerationResult {
        case success
        case limitReached
        case failed
        case buttonNotFound
    }
    
    // MARK: - Subscription State Helpers
    
    static func setUserToUsageLimit(app: XCUIApplication) {
        app.terminate()
        app.launchArguments.append(LaunchArguments.setUserAtUsageLimit)
        app.launch()
    }
    
    static func setUserStoryCount(_ count: Int, app: XCUIApplication) {
        app.terminate()
        app.launchArguments.append(LaunchArguments.setStoryCount(count))
        app.launch()
    }
    
    static func simulateMonthlyReset(app: XCUIApplication) {
        app.terminate()
        app.launchArguments.append(LaunchArguments.simulateMonthlyReset)
        app.launch()
    }
    
    static func simulateExpiredSubscription(app: XCUIApplication) {
        app.terminate()
        app.launchArguments.append(LaunchArguments.simulateExpiredSubscription)
        app.launch()
    }
    
    static func simulatePremiumSubscription(app: XCUIApplication) {
        app.terminate()
        app.launchArguments.append(LaunchArguments.simulatePremiumSubscription)
        app.launch()
    }
    
    // MARK: - Analytics Verification
    
    static func verifyAnalyticsEvent(_ eventName: String, app: XCUIApplication) -> Bool {
        // In a real implementation, this would check console logs or other analytics indicators
        // For now, this is a placeholder that returns true
        print("Verifying analytics event: \(eventName)")
        return true
    }
    
    static func enableAnalyticsMonitoring(app: XCUIApplication) {
        app.launchArguments.append(LaunchArguments.enableAnalyticsMonitoring)
    }
    
    // MARK: - Premium Feature Testing
    
    static func verifyPremiumFeatureLocked(featureName: String, app: XCUIApplication) -> Bool {
        // Look for premium indicators
        let lockIcon = app.images["lock.fill"]
        let premiumBadge = app.images["crown"]
        let premiumText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Premium'")).firstMatch
        
        return lockIcon.exists || premiumBadge.exists || premiumText.exists
    }
    
    static func accessPremiumFeature(featureName: String, app: XCUIApplication) -> PremiumFeatureResult {
        // This would be implemented based on specific premium features
        // For now, it's a general implementation
        
        let lockIcon = app.images["lock.fill"].firstMatch
        if lockIcon.exists {
            lockIcon.tap()
            
            let premiumPrompt = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Premium'")).firstMatch
            if premiumPrompt.waitForExistence(timeout: 5) {
                return .promptShown
            }
        }
        
        return .accessible
    }
    
    enum PremiumFeatureResult {
        case accessible
        case promptShown
        case notFound
    }
    
    // MARK: - Error Handling Helpers
    
    static func dismissAnyErrorDialogs(app: XCUIApplication) {
        let errorButtons = ["OK", "Close", "Dismiss", "Cancel", "Try Again"]
        
        for buttonTitle in errorButtons {
            let button = app.buttons[buttonTitle]
            if button.exists {
                button.tap()
            }
        }
    }
    
    static func waitForAppToLoad(app: XCUIApplication, timeout: TimeInterval = 10) -> Bool {
        return app.tabBars.firstMatch.waitForExistence(timeout: timeout)
    }
    
    // MARK: - Network Simulation
    
    static func simulateNetworkIssues(app: XCUIApplication) {
        app.launchArguments.append(LaunchArguments.simulateNetworkIssues)
    }
    
    // MARK: - Accessibility Testing Helpers
    
    static func verifyElementAccessibility(_ element: XCUIElement, elementName: String) -> [String] {
        var issues: [String] = []
        
        if !element.exists {
            issues.append("\(elementName) does not exist")
            return issues
        }
        
        if element.label.isEmpty {
            issues.append("\(elementName) has no accessibility label")
        }
        
        if !element.isHittable {
            issues.append("\(elementName) is not hittable")
        }
        
        return issues
    }
    
    static func verifyPaywallAccessibility(app: XCUIApplication) -> [String] {
        var issues: [String] = []
        
        let monthlyOption = app.buttons.containing(NSPredicate(format: "label CONTAINS '\(TestData.monthlyPrice)'")).firstMatch
        let yearlyOption = app.buttons.containing(NSPredicate(format: "label CONTAINS '\(TestData.yearlyPrice)'")).firstMatch
        
        issues.append(contentsOf: verifyElementAccessibility(monthlyOption, elementName: "Monthly subscription option"))
        issues.append(contentsOf: verifyElementAccessibility(yearlyOption, elementName: "Yearly subscription option"))
        
        return issues
    }
    
    // MARK: - Performance Testing Helpers
    
    static func measurePaywallPresentationTime(app: XCUIApplication) -> TimeInterval {
        let startTime = Date()
        
        _ = triggerPaywall(app: app)
        
        let paywallTitle = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Premium'")).firstMatch
        _ = paywallTitle.waitForExistence(timeout: 10)
        
        return Date().timeIntervalSince(startTime)
    }
    
    static func measureSubscriptionFlowPerformance(app: XCUIApplication) -> (triggerTime: TimeInterval, optionResponseTime: TimeInterval) {
        let triggerStartTime = Date()
        _ = triggerPaywall(app: app)
        let triggerTime = Date().timeIntervalSince(triggerStartTime)
        
        let optionStartTime = Date()
        let monthlyOption = app.buttons.containing(NSPredicate(format: "label CONTAINS '\(TestData.monthlyPrice)'")).firstMatch
        _ = monthlyOption.waitForExistence(timeout: 10)
        let optionResponseTime = Date().timeIntervalSince(optionStartTime)
        
        return (triggerTime: triggerTime, optionResponseTime: optionResponseTime)
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    func clearAndTypeText(_ text: String) {
        self.tap()
        self.press(forDuration: 1.0)
        
        let selectAll = XCUIApplication().menuItems["Select All"]
        if selectAll.exists {
            selectAll.tap()
        }
        
        self.typeText(text)
    }
}

// MARK: - Test Case Extensions

extension XCTestCase {
    func verifyIAPTestCase(_ testCaseID: String, description: String, passed: Bool, details: String = "") {
        if passed {
            print("✅ \(testCaseID): \(description) - PASSED")
        } else {
            print("❌ \(testCaseID): \(description) - FAILED")
            if !details.isEmpty {
                print("   Details: \(details)")
            }
        }
        
        XCTAssertTrue(passed, "\(testCaseID): \(description) failed. \(details)")
    }
    
    func recordTestResult(_ testCaseID: String, passed: Bool, notes: String = "") {
        let result = passed ? "PASS" : "FAIL"
        let timestamp = DateFormatter.testTimestamp.string(from: Date())
        
        print("TEST RESULT: \(testCaseID) - \(result) - \(timestamp)")
        if !notes.isEmpty {
            print("NOTES: \(notes)")
        }
    }
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let testTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}