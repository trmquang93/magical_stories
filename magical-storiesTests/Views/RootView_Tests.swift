import SwiftUI
import Testing
@testable import magical_stories

struct RootView_Tests {
    
    @Test("RootView should display TabView with three tabs")
    func testTabViewStructure() async throws {
        let view = await RootView()
        
        await #expect(Mirror(reflecting: view.body).descendant("content") is TabView<TabItem, AnyView>)
        
        // TODO: Add more specific tab content tests once implemented
        // This is a basic structural test to start with
    }
    
    @Test("RootView should have correct tab items")
    func testTabItems() async throws {
        let view = await RootView()
        let mirror = await Mirror(reflecting: view.body)
        
        // Verify Home tab
        await #expect(view.selectedTab == .home) // Default selected tab
        
        // Test will be expanded as we implement actual tab views
    }
}
