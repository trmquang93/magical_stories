import SwiftUI
import SwiftData

enum TabItem {
    case home
    case library
    case settings
    case collections

    var title: String {
        switch self {
        case .home:
            return "Home"
        case .library:
            return "Library"
        case .settings:
            return "Settings"
        case .collections:
            return "Collections"
        }
    }

    var icon: String {
        switch self {
        case .home:
            return "house.fill"
        case .library:
            return "books.vertical.fill"
        case .settings:
            return "gear"
        case .collections:
            return "square.grid.2x2.fill"
        }
    }
}

private struct SelectedTabBindingKey: EnvironmentKey {
    static let defaultValue: Binding<TabItem>? = nil
}

extension EnvironmentValues {
    var selectedTabBinding: Binding<TabItem>? {
        get { self[SelectedTabBindingKey.self] }
        set { self[SelectedTabBindingKey.self] = newValue }
    }
}

struct RootView: View {
    @State var selectedTab: TabItem = .home
    @EnvironmentObject var storyService: StoryService
    @EnvironmentObject var settingsService: SettingsService
    @EnvironmentObject var persistenceService: PersistenceService
    @EnvironmentObject var collectionService: CollectionService
    
    var body: some View {
        MainTabView(selectedTab: $selectedTab)
            .environmentObject(storyService)
            .environmentObject(settingsService)
            .environmentObject(persistenceService)
            .environmentObject(collectionService)
            .preferredColorScheme(settingsService.appSettings.darkModeEnabled ? .dark : .light)
            .environment(\.fontScale, settingsService.appSettings.fontScale)
            .environment(\.selectedTabBinding, $selectedTab)
    }
}