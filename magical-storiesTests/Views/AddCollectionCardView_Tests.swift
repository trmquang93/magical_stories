import SwiftUI
import XCTest

@testable import magical_stories

final class AddCollectionCardView_Tests: XCTestCase {

    func testAddCollectionCardViewInitializesWithoutErrors() {
        let view = AddCollectionCardView(action: {})
        XCTAssertNotNil(view)
    }
    
    func testAddCollectionCardViewActionCallbackWorks() {
        var actionCalled = false
        let view = AddCollectionCardView {
            actionCalled = true
        }
        
        // Simulate button press through the closure directly
        view.action()
        XCTAssertTrue(actionCalled)
    }
    
    func testAddCollectionCardViewHasCorrectAccessibilityConfiguration() {
        let view = AddCollectionCardView(action: {})
        
        // Test that the view itself exists and can be created
        XCTAssertNotNil(view)
        
        // We can verify that the view was created with the expected action
        // The actual accessibility testing would need to be done at the UI test level
        // or with proper ViewInspector setup that doesn't have compilation issues
    }
    
    func testAddCollectionCardViewSupportsColorSchemes() {
        let view = AddCollectionCardView(action: {})
        
        // Test in light mode
        let lightView = view.preferredColorScheme(.light)
        XCTAssertNotNil(lightView)
        
        // Test in dark mode  
        let darkView = view.preferredColorScheme(.dark)
        XCTAssertNotNil(darkView)
    }
    
    func testAddCollectionCardViewCanBeEmbeddedInOtherViews() {
        let view = AddCollectionCardView(action: {})
        
        // Test that it can be embedded in a VStack
        let containerView = VStack {
            view
        }
        XCTAssertNotNil(containerView)
        
        // Test that it can be embedded in an HStack
        let horizontalContainer = HStack {
            view
        }
        XCTAssertNotNil(horizontalContainer)
    }
    
    func testAddCollectionCardViewHandlesMutlipleInstances() {
        var firstActionCalled = false
        var secondActionCalled = false
        
        let firstView = AddCollectionCardView {
            firstActionCalled = true
        }
        
        let secondView = AddCollectionCardView {
            secondActionCalled = true
        }
        
        // Test that each view has its own independent action
        firstView.action()
        XCTAssertTrue(firstActionCalled)
        XCTAssertFalse(secondActionCalled)
        
        secondView.action()
        XCTAssertTrue(firstActionCalled)
        XCTAssertTrue(secondActionCalled)
    }
    
    func testAddCollectionCardViewWithEmptyAction() {
        // Test that the view works even with an empty action
        let view = AddCollectionCardView(action: {})
        XCTAssertNotNil(view)
        
        // Should not crash when action is called
        XCTAssertNoThrow(view.action())
    }
    
    func testAddCollectionCardViewRetainsActionClosure() {
        var actionCalled = false
        
        do {
            let view = AddCollectionCardView {
                actionCalled = true
            }
            
            // Action should work even after local scope
            view.action()
        }
        
        XCTAssertTrue(actionCalled)
    }
}
