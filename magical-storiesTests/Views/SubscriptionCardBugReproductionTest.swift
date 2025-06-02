import XCTest
import SwiftUI
import Combine
@testable import magical_stories

/// Test to reproduce the subscription status update bug
/// This test focuses on the core issue: SubscriptionCard not updating after EntitlementManager changes
@MainActor
class SubscriptionCardBugReproductionTest: XCTestCase {
    
    func testSubscriptionCardReactivityIssue() async throws {
        print("🧪 TESTING: SubscriptionCard reactivity after subscription changes")
        
        // STEP 1: Create EntitlementManager and track its state
        let entitlementManager = EntitlementManager()
        
        // STEP 2: Verify initial state
        XCTAssertFalse(entitlementManager.isPremiumUser, "Initial state should be free")
        XCTAssertEqual(entitlementManager.subscriptionStatus, .free, "Initial status should be free")
        print("✅ Initial state: Free user")
        
        // STEP 3: Set up monitoring for changes
        let changeExpectation = XCTestExpectation(description: "EntitlementManager should change")
        
        var cancellables = Set<AnyCancellable>()
        
        // Monitor objectWillChange - this is what SwiftUI SubscriptionCard listens to
        entitlementManager.objectWillChange
            .sink {
                print("📡 EntitlementManager.objectWillChange fired")
                changeExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // STEP 4: Manually trigger the subscription status update
        // This simulates what happens after a successful purchase
        print("🛒 Simulating successful subscription update...")
        
        // Force a subscription status change by calling the internal update method
        // We'll use reflection to access the private setter, simulating what happens during purchase
        await entitlementManager.refreshEntitlementStatus()
        
        // STEP 5: Wait for change notification
        print("⏳ Waiting for EntitlementManager to notify changes...")
        
        // Give it some time for the async operations
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // STEP 6: Verify the core issue
        print("🔍 Checking if the issue exists...")
        
        // The key test: Even if EntitlementManager properties are correct,
        // does SwiftUI's reactive system properly detect computed property changes?
        let isPremiumProperty = entitlementManager.isPremiumUser
        let statusProperty = entitlementManager.subscriptionStatus
        
        print("📊 Current EntitlementManager state:")
        print("   isPremiumUser: \(isPremiumProperty)")
        print("   subscriptionStatus: \(statusProperty)")
        print("   subscriptionStatusText: \(entitlementManager.subscriptionStatusText)")
        
        // STEP 7: Test the SubscriptionCard's view of the data
        // This is the critical test - does the view get the right data?
        print("🎨 Testing what SubscriptionCard would see...")
        
        // Create expectations for SubscriptionCard reactive updates
        let cardUpdateExpectation = XCTestExpectation(description: "SubscriptionCard should see updates")
        
        // Simulate what SubscriptionCard does with onChange modifiers
        entitlementManager.$subscriptionStatus
            .sink { status in
                print("📱 SubscriptionCard would see status: \(status)")
                if status != .free {
                    cardUpdateExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // STEP 8: Create a test to identify the exact failure point
        print("🔥 CRITICAL TEST: Identifying where the reactive chain breaks...")
        
        // This test will help us identify if the issue is:
        // A) EntitlementManager not updating properly
        // B) SwiftUI not detecting @Published changes  
        // C) Computed properties not triggering objectWillChange
        // D) SubscriptionCard's onChange modifiers not working
        
        // The bug is likely in the reactive chain between EntitlementManager and SubscriptionCard
        print("✅ BUG REPRODUCTION TEST SETUP COMPLETE")
        print("🔍 Monitor the console output to see where the reactive chain breaks")
        
        // Let the test run for a bit to see what happens
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        print("📋 FINAL DIAGNOSIS:")
        print("   EntitlementManager.isPremiumUser: \(entitlementManager.isPremiumUser)")
        print("   EntitlementManager.subscriptionStatus: \(entitlementManager.subscriptionStatus)")
        print("   If these values are correct but SubscriptionCard shows 'Free Plan',")
        print("   then the bug is in the SwiftUI reactive update mechanism.")
    }
    
    func testDirectSubscriptionStatusUpdate() async throws {
        print("🧪 TESTING: Direct subscription status update simulation")
        
        // Create EntitlementManager
        let entitlementManager = EntitlementManager()
        
        // Test if we can force a state change to verify the reactive system works
        let expectation = XCTestExpectation(description: "Status should change")
        
        var cancellables = Set<AnyCancellable>()
        entitlementManager.$subscriptionStatus
            .dropFirst()
            .sink { newStatus in
                print("📊 Status changed to: \(newStatus)")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Try to trigger an entitlement refresh
        await entitlementManager.refreshEntitlementStatus()
        
        // Wait a reasonable time
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        print("📋 Test completed - check if any status changes occurred")
    }
}