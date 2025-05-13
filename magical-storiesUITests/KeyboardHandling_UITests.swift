import XCTest
@testable import magical_stories

final class KeyboardHandling_UITests: UITestBase {
    
    func testStoryFormKeyboardHandling() throws {
        // Navigate to the Home tab
        let homeTab = app.tabBars.buttons["Home Tab"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5.0), "Home tab button should exist")
        homeTab.tap()
        
        // Tap Create New Story button to open StoryFormView
        let createStoryCard = app.buttons["HomeView_CreateStoryCard"]
        XCTAssertTrue(safeTap(createStoryCard, message: "Create Story card should be tappable"), "Should be able to tap the Create Story card")
        
        // Wait for form to appear
        let childNameTextField = app.textFields["childNameTextField"]
        XCTAssertTrue(childNameTextField.waitForExistence(timeout: 5.0), "Child name text field should exist")
        
        // Tap the text field to bring up the keyboard
        childNameTextField.tap()
        
        // Wait for the keyboard to appear
        XCTAssertTrue(waitForKeyboard(), "Keyboard should appear")
        
        // Verify the child name field is still visible/accessible
        verifyTextFieldAccessible(childNameTextField, fieldName: "Child name")
        
        // Type some text to verify the form remains visible during typing
        childNameTextField.typeText("Test Child")
        
        // Tap another text field to test keyboard adjustment
        let favoriteCharacterTextField = app.textFields["favoriteCharacterTextField"]
        XCTAssertTrue(favoriteCharacterTextField.waitForExistence(timeout: 2.0), "Favorite character text field should exist")
        favoriteCharacterTextField.tap()
        
        // Verify the field remains accessible after switching fields
        verifyTextFieldAccessible(favoriteCharacterTextField, fieldName: "Favorite character")
        
        // Type some text in the character field
        favoriteCharacterTextField.typeText("Dragon")
        
        // Try to interact with a character suggestion button to validate they're accessible
        let dragonSuggestion = app.buttons["character_Dragon"]
        if dragonSuggestion.exists {
            XCTAssertTrue(dragonSuggestion.isHittable, "Character suggestion buttons should be accessible")
        }
    }
    
    func testCollectionFormKeyboardHandling() throws {
        // Navigate to the Collections tab
        let collectionsTab = app.tabBars.buttons["Collections Tab"]
        XCTAssertTrue(collectionsTab.waitForExistence(timeout: 5.0), "Collections tab button should exist")
        collectionsTab.tap()
        
        // Find and tap "Add Collection" button
        // Try different potential identifiers since we're unsure which one is correct
        var addCollectionButton: XCUIElement? = nil
        
        for identifier in ["CollectionsListView_AddButton", "AddCollectionButton", "AddCollectionCardView"] {
            let button = app.buttons[identifier]
            if button.exists {
                addCollectionButton = button
                break
            }
        }
        
        XCTAssertNotNil(addCollectionButton, "Add Collection button should exist with one of the expected identifiers")
        guard let addButton = addCollectionButton else { return }
        
        safeTap(addButton, message: "Add Collection button should be tappable")
        
        // Wait for form to appear and find the child name text field
        let childNameTextField = app.textFields["childNameTextField"]
        XCTAssertTrue(childNameTextField.waitForExistence(timeout: 5.0), "Child name text field should exist")
        
        // Tap the text field to bring up the keyboard
        childNameTextField.tap()
        
        // Wait for the keyboard to appear
        XCTAssertTrue(waitForKeyboard(), "Keyboard should appear")
        
        // Verify the child name field is still visible/accessible
        verifyTextFieldAccessible(childNameTextField, fieldName: "Child name")
        
        // Type some text to verify the form remains visible during typing
        childNameTextField.typeText("Test Child")
        
        // Tap the characters field to test keyboard adjustment
        let charactersTextField = app.textFields["charactersTextField"]
        XCTAssertTrue(charactersTextField.waitForExistence(timeout: 2.0), "Characters text field should exist")
        charactersTextField.tap()
        
        // Verify the field remains accessible after switching fields
        verifyTextFieldAccessible(charactersTextField, fieldName: "Characters")
        
        // Type some text in the characters field
        charactersTextField.typeText("Dragon, Unicorn")
        
        // Tap the interests field which is at the bottom of the form - this is critical to test
        // as it's likely to be affected by keyboard issues
        let interestsTextField = app.textFields["interestsTextField"]
        XCTAssertTrue(interestsTextField.waitForExistence(timeout: 2.0), "Interests text field should exist")
        interestsTextField.tap()
        
        // Verify the interests field is visible and accessible
        verifyTextFieldAccessible(interestsTextField, fieldName: "Interests")
    }
}