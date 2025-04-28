import SwiftUI
import XCTest

@testable import magical_stories

final class IllustrationPlaceholderView_Tests: XCTestCase {

    func testPlaceholderView_PendingState() {
        // Test that the placeholder shows the correct UI for the pending state
        let status: IllustrationStatus = .pending
        let placeholder = IllustrationPlaceholderView(
            status: status,
            height: 200,
            onRetry: nil
        )

        // Verify the placeholder shows the shimmer effect for pending state
        XCTAssertEqual(placeholder.status, .pending)
        XCTAssertTrue(placeholder.shouldShowShimmer)
        XCTAssertFalse(placeholder.shouldShowSpinner)
        XCTAssertFalse(placeholder.shouldShowRetryButton)
    }

    func testPlaceholderView_GeneratingState() {
        // Test that the placeholder shows the correct UI for the generating state
        let status: IllustrationStatus = .generating
        let placeholder = IllustrationPlaceholderView(
            status: status,
            height: 200,
            onRetry: nil
        )

        // Verify the placeholder shows the spinner for generating state
        XCTAssertEqual(placeholder.status, .generating)
        XCTAssertFalse(placeholder.shouldShowShimmer)
        XCTAssertTrue(placeholder.shouldShowSpinner)
        XCTAssertFalse(placeholder.shouldShowRetryButton)
    }

    func testPlaceholderView_FailedState() {
        // Test that the placeholder shows the correct UI for the failed state
        var retryActionCalled = false
        let retryAction = { retryActionCalled = true }

        let status: IllustrationStatus = .failed
        let placeholder = IllustrationPlaceholderView(
            status: status,
            height: 200,
            onRetry: retryAction
        )

        // Verify the placeholder shows the retry button for failed state
        XCTAssertEqual(placeholder.status, .failed)
        XCTAssertFalse(placeholder.shouldShowShimmer)
        XCTAssertFalse(placeholder.shouldShowSpinner)
        XCTAssertTrue(placeholder.shouldShowRetryButton)

        // Test retry action
        XCTAssertNotNil(placeholder.onRetry)
        placeholder.onRetry?()
        XCTAssertTrue(retryActionCalled, "Retry action should be called")
    }

    func testPlaceholderView_ReadyState() {
        // Test that the placeholder doesn't show special UI for the ready state
        let status: IllustrationStatus = .ready
        let placeholder = IllustrationPlaceholderView(
            status: status,
            height: 200,
            onRetry: nil
        )

        // Verify the placeholder doesn't show any loading UI for ready state
        XCTAssertEqual(placeholder.status, .ready)
        XCTAssertFalse(placeholder.shouldShowShimmer)
        XCTAssertFalse(placeholder.shouldShowSpinner)
        XCTAssertFalse(placeholder.shouldShowRetryButton)
    }

    func testPlaceholderView_CustomHeight() {
        // Test that the placeholder respects the custom height
        let customHeight: CGFloat = 300
        let placeholder = IllustrationPlaceholderView(
            status: .pending,
            height: customHeight,
            onRetry: nil
        )

        XCTAssertEqual(placeholder.height, customHeight)
    }

    func testPlaceholderView_AccessibilityLabels() {
        // Test the accessibility labels for different states
        let pendingPlaceholder = IllustrationPlaceholderView(
            status: .pending, height: 200, onRetry: nil)
        let generatingPlaceholder = IllustrationPlaceholderView(
            status: .generating, height: 200, onRetry: nil)
        let failedPlaceholder = IllustrationPlaceholderView(
            status: .failed, height: 200, onRetry: nil)

        XCTAssertEqual(pendingPlaceholder.accessibilityLabel, "Illustration will be created soon")
        XCTAssertEqual(generatingPlaceholder.accessibilityLabel, "Generating illustration")
        XCTAssertEqual(failedPlaceholder.accessibilityLabel, "Illustration failed to load")
    }
}
