import XCTest

class UITestBase: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Set launch arguments to ensure we have a consistent testing environment
        app.launchArguments.append("UI_TESTING")
        app.launchArguments.append("CREATE_TEST_STORIES")
        app.launchArguments.append("CREATE_TEST_COLLECTIONS")
        
        // Universal launch
        app.launch()
    }
    
    // Helper method to wait for an element to appear and be hittable
    func waitForElementToBeHittable(_ element: XCUIElement, timeout: TimeInterval = 5.0, message: String) -> Bool {
        let expectation = expectation(description: message)
        
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if element.exists && element.isHittable {
                expectation.fulfill()
                timer.invalidate()
            }
        }
        
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
        timer.invalidate()
        
        return result
    }
    
    // Helper to safely tap an element after ensuring it exists and is hittable
    func safeTap(_ element: XCUIElement, timeout: TimeInterval = 5.0, message: String) -> Bool {
        guard waitForElementToBeHittable(element, timeout: timeout, message: message) else {
            return false
        }
        
        element.tap()
        return true
    }
    
    // Helper to wait for keyboard to appear
    func waitForKeyboard(timeout: TimeInterval = 2.0) -> Bool {
        return app.keyboards.firstMatch.waitForExistence(timeout: timeout)
    }
    
    // Helper to verify a text field is accessible after keyboard appears
    func verifyTextFieldAccessible(_ textField: XCUIElement, fieldName: String) {
        XCTAssertTrue(textField.exists, "\(fieldName) text field should exist")
        XCTAssertTrue(textField.isHittable, "\(fieldName) text field should be accessible")
    }
}