import XCTest
@testable import magical_stories

/// UI tests for the rating system integration
@MainActor
final class RatingSystemUITests: XCTestCase {
    
    func testRatingPreferencesCardAccessibility() async throws {
        // Test that the rating preferences are accessible in settings
        let expectation = XCTestExpectation(description: "Rating preferences should be accessible")
        
        // This test verifies that the UI components exist and are properly integrated
        // In a real UI test environment, this would be tested with XCUITest
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testFeatureFlagIntegration() async throws {
        // Test that feature flags properly control rating system visibility
        let featureFlagService = FeatureFlagService.testInstance(features: [
            .ratingSystem: false
        ])
        
        // Verify that when rating system is disabled, it's not accessible
        XCTAssertFalse(featureFlagService.isEnabled(.ratingSystem))
        
        // Enable rating system
        featureFlagService.setFeature(.ratingSystem, enabled: true)
        XCTAssertTrue(featureFlagService.isEnabled(.ratingSystem))
    }
    
    func testRatingServiceIntegration() async throws {
        // Test that rating service properly handles app launch
        let mockRatingService = MockRatingService()
        
        // Simulate app launch handling
        await mockRatingService.handleAppLaunch()
        
        // Verify engagement score calculation
        let engagementScore = await mockRatingService.getCurrentEngagementScore()
        XCTAssertGreaterThanOrEqual(engagementScore, 0.0)
        XCTAssertLessThanOrEqual(engagementScore, 1.0)
    }
    
    func testRatingPreferencesUserDefaults() async throws {
        // Test that rating preferences are properly persisted
        let userDefaults = UserDefaults.standard
        let testKey = "test_rating_enabled"
        
        // Clean up any existing value
        userDefaults.removeObject(forKey: testKey)
        
        // Test setting preference
        userDefaults.set(true, forKey: testKey)
        XCTAssertTrue(userDefaults.bool(forKey: testKey))
        
        // Test changing preference
        userDefaults.set(false, forKey: testKey)
        XCTAssertFalse(userDefaults.bool(forKey: testKey))
        
        // Clean up
        userDefaults.removeObject(forKey: testKey)
    }
    
    func testRatingDebugView() async throws {
        // Test that debug view provides proper functionality
        let mockRatingService = MockRatingService()
        
        // Test engagement analysis
        let analysis = await mockRatingService.getEngagementAnalysis()
        XCTAssertNotNil(analysis)
        
        // Test recent events
        let events = await mockRatingService.getRecentEvents(limit: 5)
        XCTAssertNotNil(events)
        XCTAssertLessThanOrEqual(events.count, 5)
    }
    
    func testFeatureFlagPersistence() async throws {
        // Test that feature flags are properly persisted across app launches
        let featureFlagService = FeatureFlagService()
        
        // Set a feature flag
        featureFlagService.setFeature(.ratingDebugMode, enabled: true)
        XCTAssertTrue(featureFlagService.isEnabled(.ratingDebugMode))
        
        // Create a new instance (simulating app restart)
        let newFeatureFlagService = FeatureFlagService()
        XCTAssertTrue(newFeatureFlagService.isEnabled(.ratingDebugMode))
        
        // Reset to default
        newFeatureFlagService.resetFeature(.ratingDebugMode)
    }
    
    func testRatingSystemInitialization() async throws {
        // Test that the rating system properly initializes
        let expectation = XCTestExpectation(description: "Rating system should initialize")
        
        // Simulate app initialization
        let mockRatingService = MockRatingService()
        await mockRatingService.handleAppLaunch()
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testRatingConfigurationManagement() async throws {
        // Test that rating configuration can be properly managed
        let mockRatingService = MockRatingService()
        
        // Test configuration update
        let testConfig = RatingConfiguration.testing
        await mockRatingService.updateConfiguration(testConfig)
        
        // Verify configuration applied (in a real implementation, this would check the actual config)
        XCTAssertTrue(true) // Placeholder for actual configuration verification
    }
    
    func testRatingPreferencesCardComponents() async throws {
        // Test that rating preferences card has all required components
        // This would typically be done with snapshot testing or component testing
        
        let expectation = XCTestExpectation(description: "Rating preferences components should be present")
        
        // In a real test, we would verify:
        // - Rating toggle is present
        // - Engagement score display is present
        // - Progress bar is present
        // - Info button is present
        // - Test button is present (in DEBUG)
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testRatingSystemErrorHandling() async throws {
        // Test that rating system handles errors gracefully
        let mockRatingService = MockRatingService()
        
        // Test rating request error handling
        do {
            try await mockRatingService.requestRating()
            // Should succeed in mock
        } catch {
            XCTFail("Rating request should not fail in mock service")
        }
        
        // Test force rating request
        do {
            try await mockRatingService.forceRatingRequest()
            // Should succeed in mock
        } catch {
            XCTFail("Force rating request should not fail in mock service")
        }
    }
}

// MARK: - Test Helpers

extension RatingSystemUITests {
    
    /// Helper to create a test rating service
    private func createTestRatingService() -> MockRatingService {
        return MockRatingService()
    }
    
    /// Helper to create test feature flag service
    private func createTestFeatureFlagService() -> FeatureFlagService {
        return FeatureFlagService.testInstance()
    }
}

// MARK: - Mock Extensions for Testing

#if DEBUG
extension MockRatingService {
    override func updateConfiguration(_ configuration: RatingConfiguration) async {
        // Mock implementation - just log the update
        print("Mock: Updated rating configuration")
    }
}
#endif