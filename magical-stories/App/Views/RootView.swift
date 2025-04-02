import SwiftUI

enum TabItem {
    case home
    case library
    case settings

    var title: String {
        switch self {
        case .home:
            return "Home"
        case .library:
            return "Library"
        case .settings:
            return "Settings"
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
        }
    }
}

struct RootView: View {
    @State var selectedTab: TabItem = .home
    @EnvironmentObject var storyService: StoryService
    @EnvironmentObject var settingsService: SettingsService
    @EnvironmentObject var textToSpeechService: TextToSpeechService
    
    var body: some View {
        MainTabView(selectedTab: $selectedTab)
            .environmentObject(storyService)
            .environmentObject(settingsService)
            .environmentObject(textToSpeechService)
    }
}

#Preview {
    RootView()
        .environmentObject(StoryService())
        .environmentObject(SettingsService())
        .environmentObject(TextToSpeechService(settingsService: SettingsService()))
}
