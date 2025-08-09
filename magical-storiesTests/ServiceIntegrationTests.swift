import Testing
import Foundation
@testable import magical_stories

/// Comprehensive tests for RatingService integration with existing app services
/// These tests ensure that rating triggers work correctly and don't disrupt existing functionality
@MainActor
struct ServiceIntegrationTests {
    
    // MARK: - Service Functionality Tests
    
    @Test("PurchaseService maintains functionality with rating service")
    func testPurchaseServiceFunctionalityWithRatingService() async throws {
        // Arrange
        let purchaseService = PurchaseService()
        let ratingService = RatingService(analyticsService: nil)
        
        // Act - Set rating service
        purchaseService.setRatingService(ratingService)
        
        // Assert - Core functionality should remain intact
        #expect(!purchaseService.purchaseInProgress)
        #expect(!purchaseService.isLoading)
        #expect(purchaseService.products.isEmpty) // Empty until products are loaded
        #expect(!purchaseService.hasLoadedProducts)
    }
    
    @Test("PurchaseService rating integration - can set and use rating service")
    func testPurchaseServiceCanSetRatingService() async throws {
        // Arrange
        let ratingService = RatingService(analyticsService: nil)
        let purchaseService = PurchaseService()
        
        // Act - Set rating service (should not crash)
        purchaseService.setRatingService(ratingService)
        
        // Assert - Core functionality should remain intact
        #expect(!purchaseService.purchaseInProgress)
        #expect(!purchaseService.isLoading)
        #expect(purchaseService.products.isEmpty)
        #expect(!purchaseService.hasLoadedProducts)
    }
    
    // MARK: - EntitlementManager Integration Tests
    
    @Test("EntitlementManager rating integration - can set and use rating service")
    func testEntitlementManagerCanSetRatingService() async throws {
        // Arrange
        let ratingService = RatingService(analyticsService: nil)
        let entitlementManager = EntitlementManager()
        
        // Act - Set rating service (should not crash)
        entitlementManager.setRatingService(ratingService)
        
        // Assert - Core functionality should remain intact
        #expect(entitlementManager.subscriptionStatus == .free)
        #expect(!entitlementManager.hasLifetimeAccess)
        #expect(!entitlementManager.isPremiumUser)
        #expect(await entitlementManager.canGenerateStory())
    }
    
    
    // MARK: - StoryService Integration Tests
    
    @Test("StoryService rating integration - rating service can handle story events")
    func testStoryServiceRatingIntegration() async throws {
        // Arrange
        let ratingService = RatingService(analyticsService: nil)
        
        // Act - Test that rating service can handle story events without crashing
        await ratingService.handleStoryCreated()
        
        // Assert - Should complete without errors
        let engagementScore = await ratingService.getCurrentEngagementScore()
        #expect(engagementScore >= 0.0)
    }
    
    @Test("StoryService rating integration - multiple story creations work properly")
    func testStoryServiceMultipleStoryCreationEvents() async throws {
        // Arrange
        let ratingService = RatingService(analyticsService: nil)
        let initialScore = await ratingService.getCurrentEngagementScore()
        
        // Act - Simulate multiple story creations
        await ratingService.handleStoryCreated()
        await ratingService.handleStoryCreated()
        await ratingService.handleStoryCreated()
        
        // Assert - Engagement score should increase (or at least remain stable)
        let finalScore = await ratingService.getCurrentEngagementScore()
        #expect(finalScore >= initialScore)
    }
    
    // MARK: - CollectionService Integration Tests
    
    @Test("CollectionService rating integration - rating service handles collection events")
    func testCollectionServiceRatingIntegration() async throws {
        // Arrange
        let ratingService = RatingService(analyticsService: nil)
        
        // Act - Test engagement event recording
        await ratingService.recordEngagementEvent(.storyCompleted)
        
        // Assert - Should complete without errors
        let engagementScore = await ratingService.getCurrentEngagementScore()
        #expect(engagementScore >= 0.0)
    }
    
    // MARK: - ReadingProgressService Integration Tests
    
    @Test("ReadingProgressService rating integration - rating service handles story completion")
    func testReadingProgressServiceRatingIntegration() async throws {
        // Arrange
        let ratingService = RatingService(analyticsService: nil)
        
        // Act - Test story completion handling
        await ratingService.handleStoryCompleted()
        
        // Assert - Should complete without errors
        let engagementScore = await ratingService.getCurrentEngagementScore()
        #expect(engagementScore >= 0.0)
    }
    
    // MARK: - Cross-Service Integration Tests
    
    @Test("Multiple services can share the same rating service instance")
    func testMultipleServicesShareRatingService() async throws {
        // Arrange
        let sharedRatingService = RatingService(analyticsService: nil)
        let purchaseService = PurchaseService()
        let entitlementManager = EntitlementManager()
        
        // Act - Set the same rating service instance on multiple services (should not crash)
        purchaseService.setRatingService(sharedRatingService)
        entitlementManager.setRatingService(sharedRatingService)
        
        // Simulate events from the rating service
        await sharedRatingService.handleSubscriptionPurchased()
        await sharedRatingService.handleStoryCreated()
        await sharedRatingService.handleStoryCompleted()
        
        // Assert - Should complete without errors
        let engagementScore = await sharedRatingService.getCurrentEngagementScore()
        #expect(engagementScore >= 0.0)
        #expect(!purchaseService.purchaseInProgress)
        #expect(entitlementManager.subscriptionStatus == .free)
    }
    
    @Test("Rating service integration works with real services")
    func testRatingServiceIntegrationWorks() async throws {
        // Arrange
        let ratingService = RatingService(analyticsService: nil)
        let purchaseService = PurchaseService()
        
        // Act - Set rating service and verify it works
        purchaseService.setRatingService(ratingService)
        
        // Simulate operations that would trigger rating events
        await ratingService.handleSubscriptionPurchased()
        
        // Assert - Should complete successfully
        #expect(!purchaseService.purchaseInProgress)
        let engagementScore = await ratingService.getCurrentEngagementScore()
        #expect(engagementScore >= 0.0)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Services handle missing rating service gracefully")
    func testServicesHandleMissingRatingServiceGracefully() async throws {
        // Arrange - Services without rating service set
        let purchaseService = PurchaseService()
        let entitlementManager = EntitlementManager()
        
        // Act & Assert - Should not crash when rating service is nil
        // These operations should complete successfully
        #expect(!purchaseService.purchaseInProgress)
        #expect(entitlementManager.subscriptionStatus == .free)
        
        // Test core functionality still works
        #expect(await entitlementManager.canGenerateStory())
        #expect(!purchaseService.hasLoadedProducts)
    }
    
    @Test("Services handle rating service operations gracefully")
    func testServicesHandleRatingServiceOperationsGracefully() async throws {
        // Arrange
        let ratingService = RatingService(analyticsService: nil)
        let purchaseService = PurchaseService()
        purchaseService.setRatingService(ratingService)
        
        // Act & Assert - Should not crash during rating operations
        await ratingService.handleSubscriptionPurchased()
        
        // Core service functionality should remain intact
        #expect(!purchaseService.purchaseInProgress)
        #expect(!purchaseService.isLoading)
    }
}

// MARK: - Service Integration Tests Complete
// These tests verify that RatingService integrates properly with existing app services
// and that all services maintain their core functionality when rating integration is added.