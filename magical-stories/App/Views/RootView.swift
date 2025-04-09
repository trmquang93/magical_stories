import SwiftUI
import SwiftData

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
    
    var body: some View {
        MainTabView(selectedTab: $selectedTab)
            .environmentObject(storyService)
            .environmentObject(settingsService)
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
    RootView()
        .modelContainer(container) // Provide the in-memory container
        .environmentObject(settingsService) // Provide the initialized SettingsService
        .environmentObject(storyService) // Provide the initialized StoryService
}
