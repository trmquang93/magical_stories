import SwiftUI
import XCTest

@testable import magical_stories

// Test class for the ShimmerEffect view component
final class ShimmerEffect_Tests: XCTestCase {

    func testShimmerEffect_InitialState() {
        // Setup
        let shimmer = ShimmerEffect()

        // Verify initial properties
        XCTAssertFalse(shimmer.isStatic, "Shimmer should be animated by default")
    }

    func testShimmerEffect_StaticMode() {
        // Setup
        let shimmer = ShimmerEffect(isStatic: true)

        // Verify
        XCTAssertTrue(shimmer.isStatic, "Shimmer should be static when isStatic is true")
    }

    func testShimmerEffect_CustomColors() {
        // Setup
        let startColor = Color.red.opacity(0.0)
        let centerColor = Color.red.opacity(0.6)
        let endColor = Color.red.opacity(0.0)

        // Just verify initialization doesn't crash
        let shimmer = ShimmerEffect(
            isStatic: false,
            startColor: startColor,
            centerColor: centerColor,
            endColor: endColor
        )

        // Testing the gradient itself is challenging; just verify basic properties
        XCTAssertFalse(shimmer.isStatic)
    }

    func testShimmerEffect_ReduceMotion() {
        // This would typically test if the animation is disabled when reduce motion is enabled
        // However, testing UIAccessibility.isReduceMotionEnabled requires more advanced testing
        // approaches that are beyond the scope of this simple test

        // Instead, we'll verify our isAnimating computed property logic
        let shimmer = ShimmerEffect()

        // Test the mocked isAnimating logic
        XCTAssertFalse(
            shimmer.isAnimating(isReduceMotion: true),
            "Animation should be disabled when reduce motion is enabled")
        XCTAssertFalse(
            shimmer.isAnimating(isReduceMotion: false, isStatic: true),
            "Animation should be disabled when isStatic is true")
        XCTAssertTrue(
            shimmer.isAnimating(isReduceMotion: false, isStatic: false),
            "Animation should be enabled when both reduce motion and isStatic are false")
    }
}
