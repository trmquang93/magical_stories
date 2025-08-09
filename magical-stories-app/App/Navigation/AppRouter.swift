import SwiftUI // For NavigationPath, ObservableObject, @Published

// Assuming TabItem is defined in RootView.swift and accessible globally.
// If not, it might need to be moved to a more common location or imported.
// Ensure TabItem is Hashable (Swift synthesizes this for simple enums).

@MainActor
class AppRouter: ObservableObject {
    @Published var homePath = NavigationPath()
    @Published var libraryPath = NavigationPath()
    @Published var collectionsPath = NavigationPath()
    @Published var settingsPath = NavigationPath()

    @Published var activeTab: TabItem = .home

    func navigateTo(_ destination: AppDestination, inTab tab: TabItem? = nil) {
        let targetTab = tab ?? activeTab
        
        if targetTab != activeTab {
            activeTab = targetTab
            // Ensure UI update for tab switch completes before appending to path
            DispatchQueue.main.async {
                self._append(destination: destination, toPathForTab: targetTab)
            }
        } else {
            _append(destination: destination, toPathForTab: targetTab)
        }
    }

    private func _append(destination: AppDestination, toPathForTab tab: TabItem) {
        switch tab {
        case .home:
            homePath.append(destination)
        case .library:
            libraryPath.append(destination)
        case .collections:
            collectionsPath.append(destination)
        case .settings:
            settingsPath.append(destination)
        // No default case needed if TabItem covers all navigable tabs
        }
    }

    func pop(fromTab tab: TabItem? = nil) {
        let targetTab = tab ?? activeTab
        switch targetTab {
        case .home:
            if !homePath.isEmpty { homePath.removeLast() }
        case .library:
            if !libraryPath.isEmpty { libraryPath.removeLast() }
        case .collections:
            if !collectionsPath.isEmpty { collectionsPath.removeLast() }
        case .settings:
            if !settingsPath.isEmpty { settingsPath.removeLast() }
        }
    }
    
    func popToRoot(forTab tab: TabItem? = nil) {
        let targetTab = tab ?? activeTab
        switch targetTab {
        case .home:
            homePath = NavigationPath()
        case .library:
            libraryPath = NavigationPath()
        case .collections:
            collectionsPath = NavigationPath()
        case .settings:
            settingsPath = NavigationPath()
        }
    }
}
