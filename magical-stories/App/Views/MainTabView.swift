import SwiftUI

struct MainTabView: View {
    @Binding var selectedTab: TabItem
    @EnvironmentObject private var storyService: StoryService
    @EnvironmentObject private var settingsService: SettingsService
    @EnvironmentObject private var textToSpeechService: TextToSpeechService
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label(TabItem.home.title, systemImage: TabItem.home.icon)
            }
            .tag(TabItem.home)
            
            NavigationStack {
                LibraryView()
            }
            .tabItem {
                Label(TabItem.library.title, systemImage: TabItem.library.icon)
            }
            .tag(TabItem.library)
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(TabItem.settings.title, systemImage: TabItem.settings.icon)
            }
            .tag(TabItem.settings)
        }
        .tint(Theme.Colors.primary)
    }
}

#Preview {
    MainTabView(selectedTab: .constant(.home))
        .environmentObject(StoryService())
        .environmentObject(SettingsService())
        .environmentObject(TextToSpeechService(settingsService: SettingsService()))
} 
