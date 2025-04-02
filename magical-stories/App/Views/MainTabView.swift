import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var storyService: StoryService
    @EnvironmentObject private var settingsService: SettingsService
    @EnvironmentObject private var textToSpeechService: TextToSpeechService
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(0)
            
            NavigationStack {
                LibraryView()
            }
            .tabItem {
                Label("Library", systemImage: "books.vertical")
            }
            .tag(1)
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(2)
        }
        .tint(Theme.Colors.primary)
    }
}

#Preview {
    MainTabView()
        .environmentObject(StoryService())
        .environmentObject(SettingsService())
        .environmentObject(TextToSpeechService(settingsService: SettingsService()))
} 
