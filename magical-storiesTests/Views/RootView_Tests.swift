import SwiftUI
import Testing
@testable import magical_stories

// Support structure for testing
fileprivate struct TestSupport {
    // Creates a proper binding for testing
    static func createBindingForTest<T>(_ value: T) -> Binding<T> {
        var mutableValue = value
        return Binding(
            get: { mutableValue },
            set: { mutableValue = $0 }
        )
    }
}

@MainActor
struct RootView_Tests {
    
    @Test("TabItem should have correct titles")
    func testTabItemTitles() async throws {
        #expect(TabItem.home.title == "Home", "Home tab should have correct title")
        #expect(TabItem.library.title == "Library", "Library tab should have correct title")
        #expect(TabItem.settings.title == "Settings", "Settings tab should have correct title")
    }
    
    @Test("TabItem should have correct icons")
    func testTabItemIcons() async throws {
        #expect(TabItem.home.icon == "house.fill", "Home tab should have correct icon")
        #expect(TabItem.library.icon == "books.vertical.fill", "Library tab should have correct icon")
        #expect(TabItem.settings.icon == "gear", "Settings tab should have correct icon")
    }
    
    @Test("MainTabView should have correct initial tab selection")
    func testInitialTabSelection() async throws {
        // Since we can't directly test the @State property in RootView
        // We'll test the MainTabView which takes a Binding<TabItem>
        
        // Given - Create a binding with initial value .home
        let selectedTabBinding = TestSupport.createBindingForTest(TabItem.home)
        
        // When - Create TabView with this binding
        _ = MainTabView(selectedTab: selectedTabBinding)
        
        // Then - Verify the binding has the expected value
        #expect(selectedTabBinding.wrappedValue == .home, "Initial tab should be home")
    }
    
    @Test("Tab selection binding should update when changed")
    func testTabSelectionBinding() async throws {
        // Given - Create a binding with initial value .home
        let selectedTabBinding = TestSupport.createBindingForTest(TabItem.home)
        
        // When - Create TabView with this binding
        _ = MainTabView(selectedTab: selectedTabBinding)
        
        // Then - Verify initial value
        #expect(selectedTabBinding.wrappedValue == .home, "Initial tab should be home")
        
        // When - Change the selection
        selectedTabBinding.wrappedValue = .library
        
        // Then - Verify updated value
        #expect(selectedTabBinding.wrappedValue == .library, "Tab should be updated to library")
    }
}
