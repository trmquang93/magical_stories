import Foundation
import SwiftData
import SwiftUI

// Use local Configuration file for API keys
@main
struct MagicalStoriesApp: App {
    // Initialize services using StateObject to maintain their state throughout the app lifetime
    @StateObject private var settingsService: SettingsService
    @StateObject private var storyService: StoryService
    @StateObject private var collectionService: CollectionService
    @StateObject private var persistenceService: PersistenceService
    @StateObject private var illustrationService: IllustrationService
    private let container: ModelContainer

    // Initialization to handle dependencies between services
    init() {
        // Initialize SwiftData container with schema
        let container: ModelContainer
        do {
            container = try ModelContainer(
                for: StoryModel.self, PageModel.self, AchievementModel.self, StoryCollection.self,
                configurations: ModelConfiguration()
            )
            print(
                "[MagicalStoriesApp] Successfully created ModelContainer with StoryCollection schema"
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        let context = container.mainContext

        // Initialize services in dependency order
        // 1. Repositories first (need context)
        let userProfileRepository = UserProfileRepository(modelContext: context)
        let settingsRepository = SettingsRepository(modelContext: context)
        let collectionRepository = CollectionRepository(modelContext: context)
        let achievementRepository = AchievementRepository(modelContext: context)

        // 2. Services that depend on repositories
        let usageAnalyticsService = UsageAnalyticsService(
            userProfileRepository: userProfileRepository)
        let settings = SettingsService(
            repository: settingsRepository, usageAnalyticsService: usageAnalyticsService)

        let story: StoryService
        do {
            story = try StoryService(apiKey: AppConfig.geminiApiKey, context: context)
        } catch {
            fatalError("Failed to create StoryService: \(error)")
        }

        let collectionService = CollectionService(
            repository: collectionRepository, storyService: story,
            achievementRepository: achievementRepository)

        let persistenceService = PersistenceService(context: context)

        // Initialize IllustrationService
        let illustration: IllustrationService
        do {
            illustration = try IllustrationService(apiKey: AppConfig.geminiApiKey)
            print("[MagicalStoriesApp] Successfully created IllustrationService")
        } catch {
            fatalError("Failed to create IllustrationService: \(error)")
        }

        // Assign to StateObjects
        _settingsService = StateObject(wrappedValue: settings)
        _storyService = StateObject(wrappedValue: story)
        _collectionService = StateObject(wrappedValue: collectionService)
        _persistenceService = StateObject(wrappedValue: persistenceService)
        _illustrationService = StateObject(wrappedValue: illustration)

        // Store container for environment injection
        self.container = container
    }

    var body: some Scene {
        WindowGroup {
            // Pass all services as environment objects to make them available throughout the view hierarchy
            RootView()
                .environmentObject(settingsService)
                .environmentObject(storyService)
                .environmentObject(collectionService)
                .environmentObject(persistenceService)
                .environmentObject(illustrationService)
                .modelContainer(container)
        }
    }
}
