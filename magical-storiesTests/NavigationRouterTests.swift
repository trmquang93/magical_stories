import Testing
import SwiftUI
import Foundation
@testable import magical_stories

@Suite("Navigation Router Tests", .serialized)
@MainActor
struct NavigationRouterTests {
    
    // MARK: - Test Setup
    
    private let mockStoryID = UUID()
    private let mockCollectionID = UUID()
    
    // MARK: - AppRouter Initialization Tests
    
    @Test("AppRouter initializes with correct default state")
    func testAppRouterInitialization() async throws {
        let router = AppRouter()
        
        #expect(router.activeTab == .home)
        #expect(router.homePath.isEmpty)
        #expect(router.libraryPath.isEmpty)
        #expect(router.collectionsPath.isEmpty)
        #expect(router.settingsPath.isEmpty)
    }
    
    // MARK: - Basic Navigation Tests
    
    @Test("Navigate to destination in current tab")
    func testNavigateToDestinationInCurrentTab() async throws {
        let router = AppRouter()
        router.activeTab = .home
        
        let destination = AppDestination.storyDetail(storyID: mockStoryID)
        router.navigateTo(destination)
        
        #expect(router.homePath.count == 1)
        #expect(router.libraryPath.isEmpty)
        #expect(router.collectionsPath.isEmpty)
        #expect(router.settingsPath.isEmpty)
        #expect(router.activeTab == .home)
    }
    
    @Test("Navigate to destination in different tab")
    func testNavigateToDestinationInDifferentTab() async throws {
        let router = AppRouter()
        router.activeTab = .home
        
        let destination = AppDestination.collectionDetail(collectionID: mockCollectionID)
        router.navigateTo(destination, inTab: .collections)
        
        // Active tab should change
        #expect(router.activeTab == .collections)
        
        // Wait for async dispatch
        await Task.yield()
        
        // Destination should be in collections path
        #expect(router.collectionsPath.count == 1)
        #expect(router.homePath.isEmpty)
        #expect(router.libraryPath.isEmpty)
        #expect(router.settingsPath.isEmpty)
    }
    
    @Test("Navigate to specific destinations in each tab")
    func testNavigateToSpecificDestinationsInEachTab() async throws {
        let router = AppRouter()
        
        // Test home tab navigation
        router.navigateTo(.storyDetail(storyID: mockStoryID), inTab: .home)
        #expect(router.activeTab == .home)
        #expect(router.homePath.count == 1)
        
        // Test library tab navigation
        router.navigateTo(.contentFilters, inTab: .library)
        await Task.yield() // Wait for async dispatch
        #expect(router.activeTab == .library)
        #expect(router.libraryPath.count == 1)
        
        // Test collections tab navigation
        router.navigateTo(.collectionDetail(collectionID: mockCollectionID), inTab: .collections)
        await Task.yield() // Wait for async dispatch
        #expect(router.activeTab == .collections)
        #expect(router.collectionsPath.count == 1)
        
        // Test settings tab navigation
        router.navigateTo(.contentFilters, inTab: .settings)
        await Task.yield() // Wait for async dispatch
        #expect(router.activeTab == .settings)
        #expect(router.settingsPath.count == 1)
    }
    
    // MARK: - Navigation Stack Management Tests
    
    @Test("Multiple navigation pushes to same tab")
    func testMultipleNavigationPushesToSameTab() async throws {
        let router = AppRouter()
        router.activeTab = .library
        
        let destination1 = AppDestination.storyDetail(storyID: mockStoryID)
        let destination2 = AppDestination.contentFilters
        let destination3 = AppDestination.collectionDetail(collectionID: mockCollectionID)
        
        router.navigateTo(destination1)
        router.navigateTo(destination2)
        router.navigateTo(destination3)
        
        #expect(router.libraryPath.count == 3)
        #expect(router.activeTab == .library)
    }
    
    @Test("Navigation stack isolation between tabs")
    func testNavigationStackIsolationBetweenTabs() async throws {
        let router = AppRouter()
        
        // Add destinations to different tabs
        router.navigateTo(.storyDetail(storyID: mockStoryID), inTab: .home)
        router.navigateTo(.contentFilters, inTab: .library)
        router.navigateTo(.collectionDetail(collectionID: mockCollectionID), inTab: .collections)
        
        await Task.yield()
        
        // Each tab should have its own navigation stack
        #expect(router.homePath.count == 1)
        #expect(router.libraryPath.count == 1)
        #expect(router.collectionsPath.count == 1)
        #expect(router.settingsPath.isEmpty)
    }
    
    // MARK: - Pop Navigation Tests
    
    @Test("Pop from navigation stack")
    func testPopFromNavigationStack() async throws {
        let router = AppRouter()
        router.activeTab = .home
        
        // Add multiple destinations
        router.navigateTo(.storyDetail(storyID: mockStoryID))
        router.navigateTo(.contentFilters)
        
        #expect(router.homePath.count == 2)
        
        // Pop one destination
        router.pop()
        
        #expect(router.homePath.count == 1)
        #expect(router.activeTab == .home)
    }
    
    @Test("Pop from specific tab")
    func testPopFromSpecificTab() async throws {
        let router = AppRouter()
        
        // Setup navigation stacks in multiple tabs
        router.navigateTo(.storyDetail(storyID: mockStoryID), inTab: .home)
        router.navigateTo(.contentFilters, inTab: .library)
        router.navigateTo(.collectionDetail(collectionID: mockCollectionID), inTab: .library)
        
        await Task.yield()
        
        #expect(router.homePath.count == 1)
        #expect(router.libraryPath.count == 2)
        
        // Pop from library tab specifically
        router.pop(fromTab: .library)
        
        #expect(router.homePath.count == 1) // Should remain unchanged
        #expect(router.libraryPath.count == 1) // Should be reduced
    }
    
    @Test("Pop from empty navigation stack")
    func testPopFromEmptyNavigationStack() async throws {
        let router = AppRouter()
        router.activeTab = .settings
        
        #expect(router.settingsPath.isEmpty)
        
        // Popping from empty stack should not crash
        router.pop()
        
        #expect(router.settingsPath.isEmpty)
        #expect(router.activeTab == .settings)
    }
    
    // MARK: - Pop to Root Tests
    
    @Test("Pop to root for current tab")
    func testPopToRootForCurrentTab() async throws {
        let router = AppRouter()
        router.activeTab = .collections
        
        // Add multiple destinations
        router.navigateTo(.storyDetail(storyID: mockStoryID))
        router.navigateTo(.contentFilters)
        router.navigateTo(.collectionDetail(collectionID: mockCollectionID))
        
        #expect(router.collectionsPath.count == 3)
        
        // Pop to root
        router.popToRoot()
        
        #expect(router.collectionsPath.isEmpty)
        #expect(router.activeTab == .collections)
    }
    
    @Test("Pop to root for specific tab")
    func testPopToRootForSpecificTab() async throws {
        let router = AppRouter()
        
        // Setup navigation stacks in multiple tabs
        router.navigateTo(.storyDetail(storyID: mockStoryID), inTab: .home)
        router.navigateTo(.contentFilters, inTab: .home)
        router.navigateTo(.collectionDetail(collectionID: mockCollectionID), inTab: .library)
        router.navigateTo(.contentFilters, inTab: .library)
        
        await Task.yield()
        
        #expect(router.homePath.count == 2)
        #expect(router.libraryPath.count == 2)
        
        // Pop library to root specifically
        router.popToRoot(forTab: .library)
        
        #expect(router.homePath.count == 2) // Should remain unchanged
        #expect(router.libraryPath.isEmpty) // Should be cleared
    }
    
    @Test("Pop to root all tabs")
    func testPopToRootAllTabs() async throws {
        let router = AppRouter()
        
        // Setup navigation stacks in all tabs
        router.navigateTo(.storyDetail(storyID: mockStoryID), inTab: .home)
        router.navigateTo(.contentFilters, inTab: .library)
        router.navigateTo(.collectionDetail(collectionID: mockCollectionID), inTab: .collections)
        router.navigateTo(.contentFilters, inTab: .settings)
        
        await Task.yield()
        
        // Pop to root for each tab
        for tab in [TabItem.home, .library, .collections, .settings] {
            router.popToRoot(forTab: tab)
        }
        
        #expect(router.homePath.isEmpty)
        #expect(router.libraryPath.isEmpty)
        #expect(router.collectionsPath.isEmpty)
        #expect(router.settingsPath.isEmpty)
    }
    
    // MARK: - AppDestination Tests
    
    @Test("AppDestination hashable conformance")
    func testAppDestinationHashableConformance() async throws {
        let destination1 = AppDestination.storyDetail(storyID: mockStoryID)
        let destination2 = AppDestination.storyDetail(storyID: mockStoryID)
        let destination3 = AppDestination.storyDetail(storyID: UUID())
        let destination4 = AppDestination.collectionDetail(collectionID: mockCollectionID)
        let destination5 = AppDestination.contentFilters
        
        // Same destinations should be equal
        #expect(destination1 == destination2)
        #expect(destination1.hashValue == destination2.hashValue)
        
        // Different UUIDs should not be equal
        #expect(destination1 != destination3)
        
        // Different destination types should not be equal
        #expect(destination1 != destination4)
        #expect(destination1 != destination5)
        #expect(destination4 != destination5)
    }
    
    @Test("AppDestination codable conformance")
    func testAppDestinationCodableConformance() async throws {
        let destinations = [
            AppDestination.storyDetail(storyID: mockStoryID),
            AppDestination.collectionDetail(collectionID: mockCollectionID),
            AppDestination.contentFilters
        ]
        
        for destination in destinations {
            // Encode
            let encoded = try JSONEncoder().encode(destination)
            #expect(!encoded.isEmpty)
            
            // Decode
            let decoded = try JSONDecoder().decode(AppDestination.self, from: encoded)
            #expect(decoded == destination)
        }
    }
    
    // MARK: - TabItem Tests
    
    @Test("TabItem localized titles")
    func testTabItemLocalizedTitles() async throws {
        let tabs: [TabItem] = [.home, .library, .collections, .settings]
        
        for tab in tabs {
            let title = tab.title
            #expect(!title.isEmpty)
            #expect(title.count > 0)
        }
        
        // Verify each tab has a unique title
        let titles = tabs.map { $0.title }
        let uniqueTitles = Set(titles)
        #expect(titles.count == uniqueTitles.count)
    }
    
    @Test("TabItem system icons")
    func testTabItemSystemIcons() async throws {
        let expectedIcons = [
            TabItem.home: "house.fill",
            TabItem.library: "books.vertical.fill",
            TabItem.collections: "square.grid.2x2.fill",
            TabItem.settings: "gear"
        ]
        
        for (tab, expectedIcon) in expectedIcons {
            #expect(tab.icon == expectedIcon)
        }
    }
    
    // MARK: - Navigation State Consistency Tests
    
    @Test("Active tab consistency during navigation")
    func testActiveTabConsistencyDuringNavigation() async throws {
        let router = AppRouter()
        
        // Start at home
        #expect(router.activeTab == .home)
        
        // Navigate within home tab
        router.navigateTo(.storyDetail(storyID: mockStoryID))
        #expect(router.activeTab == .home)
        
        // Navigate to different tab
        router.navigateTo(.contentFilters, inTab: .settings)
        #expect(router.activeTab == .settings)
        
        // Pop should maintain current tab
        await Task.yield()
        router.pop()
        #expect(router.activeTab == .settings)
        
        // Pop to root should maintain current tab
        router.popToRoot()
        #expect(router.activeTab == .settings)
    }
    
    @Test("Navigation path state after tab switching")
    func testNavigationPathStateAfterTabSwitching() async throws {
        let router = AppRouter()
        
        // Setup navigation in home tab
        router.activeTab = .home
        router.navigateTo(.storyDetail(storyID: mockStoryID))
        router.navigateTo(.contentFilters)
        
        let homePathCount = router.homePath.count
        #expect(homePathCount == 2)
        
        // Switch to library tab and add navigation
        router.activeTab = .library
        router.navigateTo(.collectionDetail(collectionID: mockCollectionID))
        
        let libraryPathCount = router.libraryPath.count
        #expect(libraryPathCount == 1)
        
        // Switch back to home tab
        router.activeTab = .home
        
        // Home path should remain unchanged
        #expect(router.homePath.count == homePathCount)
        #expect(router.libraryPath.count == libraryPathCount)
    }
    
    // MARK: - Deep Linking Simulation Tests
    
    @Test("Deep link navigation simulation")
    func testDeepLinkNavigationSimulation() async throws {
        let router = AppRouter()
        
        // Simulate deep link to specific story in collections tab
        let targetStoryID = UUID()
        router.navigateTo(.storyDetail(storyID: targetStoryID), inTab: .collections)
        
        #expect(router.activeTab == .collections)
        
        await Task.yield()
        
        #expect(router.collectionsPath.count == 1)
        #expect(router.homePath.isEmpty)
        #expect(router.libraryPath.isEmpty)
        #expect(router.settingsPath.isEmpty)
    }
    
    @Test("Multiple deep link navigation simulation")
    func testMultipleDeepLinkNavigationSimulation() async throws {
        let router = AppRouter()
        
        // Simulate multiple deep link navigations
        let storyID1 = UUID()
        let storyID2 = UUID()
        let collectionID = UUID()
        
        // Deep link sequence
        router.navigateTo(.storyDetail(storyID: storyID1), inTab: .home)
        router.navigateTo(.collectionDetail(collectionID: collectionID), inTab: .collections)
        router.navigateTo(.storyDetail(storyID: storyID2), inTab: .library)
        
        await Task.yield()
        
        // Final tab should be library
        #expect(router.activeTab == .library)
        
        // Each tab should have the appropriate navigation
        #expect(router.homePath.count == 1)
        #expect(router.libraryPath.count == 1)
        #expect(router.collectionsPath.count == 1)
        #expect(router.settingsPath.isEmpty)
    }
    
    // MARK: - Error Handling and Edge Cases
    
    @Test("Navigation with invalid UUID handling")
    func testNavigationWithInvalidUUIDHandling() async throws {
        let router = AppRouter()
        
        // Create destinations with empty UUID
        let emptyUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        let destination = AppDestination.storyDetail(storyID: emptyUUID)
        
        // Navigation should still work
        router.navigateTo(destination)
        
        #expect(router.homePath.count == 1)
    }
    
    @Test("Rapid navigation operations")
    func testRapidNavigationOperations() async throws {
        let router = AppRouter()
        
        // Perform rapid navigation operations
        for i in 0..<10 {
            let storyID = UUID()
            router.navigateTo(.storyDetail(storyID: storyID))
        }
        
        #expect(router.homePath.count == 10)
        
        // Rapid pop operations
        for _ in 0..<5 {
            router.pop()
        }
        
        #expect(router.homePath.count == 5)
        
        // Pop to root
        router.popToRoot()
        
        #expect(router.homePath.isEmpty)
    }
    
    @Test("Concurrent navigation operations")
    func testConcurrentNavigationOperations() async throws {
        let router = AppRouter()
        
        // Simulate concurrent navigation operations
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask {
                    await MainActor.run {
                        let storyID = UUID()
                        router.navigateTo(.storyDetail(storyID: storyID), inTab: .home)
                    }
                }
            }
        }
        
        await Task.yield()
        
        // All operations should complete successfully
        #expect(router.homePath.count == 5)
        #expect(router.activeTab == .home)
    }
    
    // MARK: - Memory Management Tests
    
    @Test("NavigationPath memory efficiency")
    func testNavigationPathMemoryEfficiency() async throws {
        let router = AppRouter()
        
        // Add many destinations
        for i in 0..<100 {
            let storyID = UUID()
            router.navigateTo(.storyDetail(storyID: storyID))
        }
        
        #expect(router.homePath.count == 100)
        
        // Clear the path
        router.popToRoot()
        
        #expect(router.homePath.isEmpty)
        
        // Memory should be released (can't directly test, but path should be empty)
        #expect(router.homePath.count == 0)
    }
    
    // MARK: - Integration Tests with ViewFactory
    
    @Test("ViewFactory handles all AppDestination cases")
    func testViewFactoryHandlesAllAppDestinationCases() async throws {
        let destinations = [
            AppDestination.storyDetail(storyID: mockStoryID),
            AppDestination.collectionDetail(collectionID: mockCollectionID),
            AppDestination.contentFilters
        ]
        
        for destination in destinations {
            // ViewFactory should not crash for any destination
            let generatedView = view(for: destination)
            
            // Basic check that a view is returned (type erasure makes detailed checks difficult)
            #expect(generatedView != nil)
        }
    }
}

// MARK: - Navigation Router Observable Tests

@Suite("Navigation Router Observable Tests", .serialized)
@MainActor
struct NavigationRouterObservableTests {
    
    @Test("AppRouter publishes changes correctly")
    func testAppRouterPublishesChangesCorrectly() async throws {
        let router = AppRouter()
        var activeTabChanges: [TabItem] = []
        var pathChanges: [Int] = []
        
        // This is a simplified test - in a real app you'd use Combine or observation
        let initialTab = router.activeTab
        let initialPathCount = router.homePath.count
        
        activeTabChanges.append(initialTab)
        pathChanges.append(initialPathCount)
        
        // Change active tab
        router.activeTab = .library
        activeTabChanges.append(router.activeTab)
        
        // Add navigation
        router.navigateTo(.contentFilters)
        pathChanges.append(router.libraryPath.count)
        
        #expect(activeTabChanges == [.home, .library])
        #expect(pathChanges == [0, 1])
    }
    
    @Test("Navigation state remains consistent during rapid changes")
    func testNavigationStateRemainsConsistentDuringRapidChanges() async throws {
        let router = AppRouter()
        
        // Rapid tab and navigation changes
        router.activeTab = .collections
        router.navigateTo(.storyDetail(storyID: UUID()))
        router.activeTab = .settings
        router.navigateTo(.contentFilters)
        router.pop()
        router.activeTab = .home
        
        // State should be consistent
        #expect(router.activeTab == .home)
        #expect(router.homePath.isEmpty)
        #expect(router.collectionsPath.count == 1)
        #expect(router.settingsPath.isEmpty) // Should be empty after pop
    }
}