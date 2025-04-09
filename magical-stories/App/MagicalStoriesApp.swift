import SwiftUI
import SwiftData
import Foundation

// Use local Configuration file for API keys
@main
struct MagicalStoriesApp: App {
    // Initialize services using StateObject to maintain their state throughout the app lifetime
    @StateObject private var settingsService: SettingsService
    @StateObject private var storyService: StoryService
    private let container: ModelContainer
    
    // Initialization to handle dependencies between services
    init() {
        // Initialize SwiftData container
        let container = try! ModelContainer()
        let context = container.mainContext

        // Initialize services in dependency order
        // 1. Repositories first (need context)
        let userProfileRepository = UserProfileRepository(modelContext: context)
        let settingsRepository = SettingsRepository(modelContext: context)

        // 2. Services that depend on repositories
        let usageAnalyticsService = UsageAnalyticsService(userProfileRepository: userProfileRepository)
        let settings = SettingsService(repository: settingsRepository, usageAnalyticsService: usageAnalyticsService)
        let story = try! StoryService(apiKey: AppConfig.geminiApiKey, context: context) // Assuming StoryService init is correct

        // Assign to StateObjects
        _settingsService = StateObject(wrappedValue: settings)
        _storyService = StateObject(wrappedValue: story)

        // Store container for environment injection
        self.container = container
    }
    
    var body: some Scene {
        WindowGroup {
            // Pass all services as environment objects to make them available throughout the view hierarchy
            RootView()
                .environmentObject(settingsService)
                .environmentObject(storyService)
                .modelContainer(container)
        }
    }
}
