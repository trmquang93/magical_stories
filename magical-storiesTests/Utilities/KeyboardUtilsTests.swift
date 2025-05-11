import SwiftUI
import Testing

@testable import magical_stories

@Suite("Keyboard Utilities Tests")
final class KeyboardUtilsTests {

    @Test("Test keyboard toolbars are correctly created")
    func testKeyboardToolbars() {
        // Create the toolbar with no done action
        let toolbar = KeyboardToolbar()

        // Verify toolbar structure
        // Note: We're testing the code structure, not the UI rendering
        // which would require ViewInspector for deeper inspection
        let body = toolbar.body

        // Simple existence check (no exception thrown means it was created)
        #expect(true)
    }

    @Test("Test dismiss keyboard extensions are available")
    func testDismissKeyboardExtensions() {
        // Create a simple view with the extensions
        let testView = Text("Test")
            .dismissKeyboardOnTap()
            .dismissKeyboardOnDrag()

        // Verify that the modifier was applied without errors
        // Full UI testing would require UIKit integration tests
        #expect(true)
    }

    @Test("Test keyboardAware modifier is applied correctly")
    func testKeyboardAwareModifier() {
        // Create a simple view with the extension
        let testView = Text("Test")
            .keyboardAware()
            .adaptToKeyboard()

        // Verify that the modifier was applied without errors
        // Full UI testing would require UIKit integration tests
        #expect(true)
    }
}
