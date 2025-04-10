import SwiftUI
import SwiftData
import Foundation

struct MainTabView: View {
    @Binding var selectedTab: TabItem // Assuming TabItem is defined elsewhere
    @EnvironmentObject private var storyService: StoryService // Keep env objects
    @EnvironmentObject private var settingsService: SettingsService // Keep env objects
    
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
        // .tint(Theme.Colors.primary) // Commenting out Theme temporarily if it causes issues
    }
}

extension MainTabView {
    static func makePreview() -> some View {
        let container: ModelContainer = {
            let schema = Schema([
                UserProfile.self,
                AppSettingsModel.self,
                ParentalControlsModel.self,
                StoryModel.self,
                StoryPage.self,
                AchievementModel.self
            ])
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: config)
            } catch {
                fatalError("Failed to create preview ModelContainer: \(error)")
            }
        }()

        let context = container.mainContext
        let userProfileRepo = UserProfileRepository(modelContext: context)
        let settingsRepo = SettingsRepository(modelContext: context)
        let usageService = UsageAnalyticsService(userProfileRepository: userProfileRepo)
        let settingsService = SettingsService(repository: settingsRepo, usageAnalyticsService: usageService)

        let previewApiKey = "PREVIEW_API_KEY"
        let illustrationService: IllustrationService
        do {
            illustrationService = try IllustrationService(apiKey: previewApiKey)
        } catch {
            fatalError("Failed to create IllustrationService: \(error)")
        }
        let storyProcessor = StoryProcessor(illustrationService: illustrationService)
        let storyService: StoryService
        do {
            storyService = try StoryService(
                apiKey: previewApiKey,
                context: context,
                storyProcessor: storyProcessor
            )
        } catch {
            fatalError("Failed to create StoryService: \(error)")
        }

        return MainTabView(selectedTab: .constant(.home))
            .modelContainer(container)
            .environmentObject(settingsService)
            .environmentObject(storyService)
    }
}

#Preview {
    MainTabView.makePreview()
}
