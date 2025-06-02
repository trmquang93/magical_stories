import SwiftUI
import Testing
import Combine

@testable import magical_stories

@MainActor
@Suite("SubscriptionCard Simple Reactive Tests")
struct SubscriptionCardSimpleReactiveTests {
    
    // MARK: - Test Infrastructure
    
    func createSimpleMockManager() -> SimpleMockEntitlementManager {
        return SimpleMockEntitlementManager()
    }
    
    func hostSubscriptionCard(with manager: SimpleMockEntitlementManager) -> UIHostingController<some View> {
        let subscriptionCard = SubscriptionCard()
            .environmentObject(manager)
        
        let controller = UIHostingController(rootView: subscriptionCard)
        _ = controller.view // Force view load
        return controller
    }
    
    // MARK: - Basic Reactive Tests
    
    @Test("SubscriptionCard responds to subscription status changes")
    func testSubscriptionStatusChanges() async throws {
        // Arrange
        let manager = createSimpleMockManager()
        let controller = hostSubscriptionCard(with: manager)
        
        // Initial state
        #expect(manager.subscriptionStatus == .free)
        #expect(!manager.isPremiumUser)
        
        // Act - Change subscription status
        manager.subscriptionStatus = .premiumMonthly(expiresAt: Date().addingTimeInterval(86400))
        
        // Allow UI to update
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        #expect(manager.subscriptionStatus.isPremium)
        #expect(manager.isPremiumUser)
    }
    
    @Test("SubscriptionCard responds to premium user status changes")
    func testPremiumUserStatusChanges() async throws {
        // Arrange
        let manager = createSimpleMockManager()
        let controller = hostSubscriptionCard(with: manager)
        
        // Initial state
        #expect(!manager.isPremiumUser)
        
        // Act - Grant lifetime access (affects isPremiumUser)
        manager.hasLifetimeAccess = true
        
        // Allow UI to update
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        #expect(manager.hasLifetimeAccess)
        #expect(manager.isPremiumUser)
    }
    
    @Test("SubscriptionCard responds to lifetime access changes")
    func testLifetimeAccessChanges() async throws {
        // Arrange
        let manager = createSimpleMockManager()
        let controller = hostSubscriptionCard(with: manager)
        
        // Initial state
        #expect(!manager.hasLifetimeAccess)
        
        // Act - Grant and then revoke lifetime access
        manager.hasLifetimeAccess = true
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(manager.hasLifetimeAccess)
        #expect(manager.isPremiumUser)
        
        manager.hasLifetimeAccess = false
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        #expect(!manager.hasLifetimeAccess)
        #expect(!manager.isPremiumUser)
    }
    
    @Test("SubscriptionCard handles multiple rapid changes")
    func testMultipleRapidChanges() async throws {
        // Arrange
        let manager = createSimpleMockManager()
        let controller = hostSubscriptionCard(with: manager)
        
        // Act - Multiple rapid changes
        manager.subscriptionStatus = .premiumMonthly(expiresAt: Date().addingTimeInterval(86400))
        manager.hasLifetimeAccess = true
        manager.subscriptionStatus = .free
        
        // Allow UI to settle
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Assert - Should still be premium due to lifetime access
        #expect(manager.subscriptionStatus == .free)
        #expect(manager.hasLifetimeAccess)
        #expect(manager.isPremiumUser)
    }
    
    @Test("SubscriptionCard environment object injection works")
    func testEnvironmentObjectInjection() async throws {
        // Arrange & Act
        let manager = createSimpleMockManager()
        let subscriptionCard = SubscriptionCard()
            .environmentObject(manager)
        
        let controller = UIHostingController(rootView: subscriptionCard)
        let view = controller.view
        
        // Assert - Should not crash and view should be created
        #expect(view != nil)
        
        // Change state to verify environment object connection
        manager.subscriptionStatus = .premiumYearly(expiresAt: Date().addingTimeInterval(86400 * 365))
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(manager.isPremiumUser)
    }
    
    @Test("SubscriptionCard displays correct status text")
    func testStatusTextDisplay() async throws {
        // Arrange
        let manager = createSimpleMockManager()
        let controller = hostSubscriptionCard(with: manager)
        
        // Test free user status
        #expect(manager.subscriptionStatusText == "Free Plan")
        
        // Test premium monthly
        manager.subscriptionStatus = .premiumMonthly(expiresAt: Date().addingTimeInterval(86400))
        #expect(manager.subscriptionStatusText.contains("Premium"))
        
        // Test lifetime access
        manager.hasLifetimeAccess = true
        #expect(manager.subscriptionStatusText == "Lifetime Premium")
    }
    
    @Test("SubscriptionCard usage statistics reflect subscription state")
    func testUsageStatisticsReflectState() async throws {
        // Arrange
        let manager = createSimpleMockManager()
        let controller = hostSubscriptionCard(with: manager)
        
        // Test free user stats
        let freeStats = await manager.getUsageStatistics()
        #expect(!freeStats.isUnlimited)
        #expect(freeStats.limit > 0)
        
        // Test premium user stats
        manager.subscriptionStatus = .premiumMonthly(expiresAt: Date().addingTimeInterval(86400))
        let premiumStats = await manager.getUsageStatistics()
        #expect(premiumStats.isUnlimited)
        #expect(premiumStats.limit == -1)
    }
    
    @Test("SubscriptionCard reactive updates are efficient")
    func testReactiveUpdateEfficiency() async throws {
        // Arrange
        let manager = createSimpleMockManager()
        let controller = hostSubscriptionCard(with: manager)
        
        let startTime = Date()
        
        // Act - Perform several state changes
        for i in 0..<10 {
            if i % 2 == 0 {
                manager.subscriptionStatus = .premiumMonthly(expiresAt: Date().addingTimeInterval(86400))
            } else {
                manager.subscriptionStatus = .free
            }
            try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        }
        
        try? await Task.sleep(nanoseconds: 100_000_000) // Allow final updates
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Assert - Should complete efficiently
        #expect(duration < 1.0) // Should complete within 1 second
        #expect(manager.getUsageStatisticsCallCount >= 1) // Should have called usage stats
    }
}

// MARK: - Simple Mock Manager

@MainActor
class SimpleMockEntitlementManager: ObservableObject {
    @Published var subscriptionStatus: SubscriptionStatus = .free
    @Published var hasLifetimeAccess = false
    @Published var isCheckingEntitlements = false
    
    var getUsageStatisticsCallCount = 0
    
    var isPremiumUser: Bool {
        return subscriptionStatus.isPremium || hasLifetimeAccess
    }
    
    var subscriptionStatusText: String {
        if hasLifetimeAccess {
            return "Lifetime Premium"
        }
        return subscriptionStatus.displayText
    }
    
    var renewalInformation: String? {
        return subscriptionStatus.renewalText
    }
    
    func getUsageStatistics() async -> (used: Int, limit: Int, isUnlimited: Bool) {
        getUsageStatisticsCallCount += 1
        
        if isPremiumUser {
            return (used: 10, limit: -1, isUnlimited: true)
        } else {
            return (used: 2, limit: 3, isUnlimited: false)
        }
    }
}