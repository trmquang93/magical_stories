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

#Preview {
    // Define a helper function or struct for preview setup if it gets complex,
    // or perform setup directly before returning the view.
    // Using a simple direct setup here:
    let container: ModelContainer = {
        // Define the schema including all necessary models for the preview context
        let schema = Schema([
            UserProfile.self,
            AppSettingsModel.self,
            ParentalControlsModel.self,
            StoryModel.self,
            StoryPage.self,
            AchievementModel.self
        ])
        // Configure for in-memory storage
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            // Create the container
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            // Handle potential errors during container creation
            fatalError("Failed to create preview ModelContainer: \(error)")
        }
    }() // Immediately execute the closure to get the container

    // Create instances of repositories and services needed for the preview
    let context = container.mainContext
    let userProfileRepo = UserProfileRepository(modelContext: context)
    let settingsRepo = SettingsRepository(modelContext: context)
    let usageService = UsageAnalyticsService(userProfileRepository: userProfileRepo)
    let settingsService = SettingsService(repository: settingsRepo, usageAnalyticsService: usageService)

    // StoryService dependencies
    // Use a placeholder API key for previews or handle potential errors gracefully
    let previewApiKey = "PREVIEW_API_KEY" // Or load from a safe place if needed
    let illustrationService = try! IllustrationService(apiKey: previewApiKey) // Use try! carefully in previews
    let storyProcessor = StoryProcessor(illustrationService: illustrationService)
    let storyService = try! StoryService(
        apiKey: previewApiKey,
        context: context,
        storyProcessor: storyProcessor // Inject the processor
    )

    // Return the view, injecting the container and environment objects
    MainTabView(selectedTab: .constant(.home)) // Assuming TabItem.home exists
        .modelContainer(container) // Provide the in-memory container
        .environmentObject(settingsService) // Provide the initialized SettingsService
        .environmentObject(storyService) // Provide the initialized StoryService
}
