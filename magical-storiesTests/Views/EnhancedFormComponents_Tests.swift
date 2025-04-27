import XCTest
import SwiftUI
import SnapshotTesting

@testable import magical_stories

final class EnhancedFormComponents_Tests: XCTestCase {

    override func setUp() {
        super.setUp()
        isRecording = false // Set to true to record new snapshots
    }

    func testValidatedTextField_ValidInput() throws {
        let text = State(initialValue: "valid input").projectedValue
        let sut = ValidatedTextField(text: text, label: "Test Field", validation: { _ in true }, errorMessage: "Error")
        
        let view = sut
            .frame(width: 300, height: 100) // Provide a fixed size for the snapshot
        
        let hostingController = UIHostingController(rootView: view)
        assertSnapshot(matching: hostingController, as: .image)
    }

    func testValidatedTextField_InvalidInput() throws {
        let text = State(initialValue: "").projectedValue
        let sut = ValidatedTextField(text: text, label: "Test Field", validation: { _ in false }, errorMessage: "Error")
        
        let view = sut
            .frame(width: 300, height: 100) // Provide a fixed size for the snapshot
        
        let hostingController = UIHostingController(rootView: view)
        assertSnapshot(matching: hostingController, as: .image)
    }
}
