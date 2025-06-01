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
    @StateObject private var illustrationTaskManager: IllustrationTaskManager
    @StateObject private var appRouter: AppRouter // Add AppRouter
    @StateObject private var purchaseService: PurchaseService
    @StateObject private var entitlementManager: EntitlementManager
    @StateObject private var usageTracker: UsageTracker
    @StateObject private var transactionObserver: TransactionObserver
    private let container: ModelContainer

    // Initialization to handle dependencies between services
    init() {
        // Handle UI testing launch arguments first
        Self.handleLaunchArguments()
        
        let router = AppRouter() // Initialize AppRouter
        // Initialize SwiftData container with schema
        let container: ModelContainer
        do {
            container = try ModelContainer(
                for: Story.self, Page.self, AchievementModel.self, StoryCollection.self, UserProfile.self,
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
        
        // Initialize IllustrationTaskManager
        let taskManager = IllustrationTaskManager()
        print("[MagicalStoriesApp] Successfully created IllustrationTaskManager")
        
        // Initialize subscription services
        let purchaseService = PurchaseService()
        let entitlementManager = EntitlementManager()
        let usageTracker = UsageTracker(usageAnalyticsService: usageAnalyticsService)
        let transactionObserver = TransactionObserver()
        
        // Set up dependencies between subscription services
        purchaseService.setEntitlementManager(entitlementManager)
        entitlementManager.setUsageTracker(usageTracker)
        entitlementManager.setUsageAnalyticsService(usageAnalyticsService)
        story.setEntitlementManager(entitlementManager)
        
        // Set up transaction observer dependencies
        transactionObserver.setEntitlementManager(entitlementManager)
        transactionObserver.setPurchaseService(purchaseService)
        
        print("[MagicalStoriesApp] Successfully created subscription services")

        // Assign to StateObjects
        _settingsService = StateObject(wrappedValue: settings)
        _storyService = StateObject(wrappedValue: story)
        _collectionService = StateObject(wrappedValue: collectionService)
        _persistenceService = StateObject(wrappedValue: persistenceService)
        _illustrationService = StateObject(wrappedValue: illustration)
        _illustrationTaskManager = StateObject(wrappedValue: taskManager)
        _appRouter = StateObject(wrappedValue: router) // Assign AppRouter
        _purchaseService = StateObject(wrappedValue: purchaseService)
        _entitlementManager = StateObject(wrappedValue: entitlementManager)
        _usageTracker = StateObject(wrappedValue: usageTracker)
        _transactionObserver = StateObject(wrappedValue: transactionObserver)

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
                .environmentObject(illustrationTaskManager)
                .environmentObject(appRouter) // Inject AppRouter
                .environmentObject(purchaseService) // Inject subscription services
                .environmentObject(entitlementManager)
                .environmentObject(usageTracker)
                .environmentObject(transactionObserver) // Inject transaction observer
                .modelContainer(container)
                .onAppear {
                    // Process current entitlements when app appears
                    Task {
                        await transactionObserver.processCurrentEntitlements()
                    }
                }
        }
    }
    
    // MARK: - UI Testing Support
    
    private static func handleLaunchArguments() {
        let arguments = ProcessInfo.processInfo.arguments
        
        if arguments.contains("UI_TESTING") {
            print("[MagicalStoriesApp] UI Testing mode enabled")
        }
        
        if arguments.contains("ENABLE_SANDBOX_TESTING") {
            print("[MagicalStoriesApp] Sandbox testing enabled")
            // Configure app for sandbox testing
        }
        
        if arguments.contains("RESET_SUBSCRIPTION_STATE") {
            print("[MagicalStoriesApp] Resetting subscription state for testing")
            // Reset subscription state
            UserDefaults.standard.removeObject(forKey: "subscription_status")
            UserDefaults.standard.removeObject(forKey: "usage_count")
        }
        
        if arguments.contains("RESET_USAGE_COUNTERS") {
            print("[MagicalStoriesApp] Resetting usage counters for testing")
            // Reset usage counters
            UserDefaults.standard.set(0, forKey: "monthly_story_count")
            UserDefaults.standard.set(Date(), forKey: "last_reset_date")
        }
        
        // Handle specific story count settings
        for argument in arguments {
            if argument.hasPrefix("SET_STORY_COUNT_") {
                let countString = String(argument.dropFirst("SET_STORY_COUNT_".count))
                if let count = Int(countString) {
                    print("[MagicalStoriesApp] Setting story count to \(count) for testing")
                    UserDefaults.standard.set(count, forKey: "monthly_story_count")
                }
            }
        }
        
        if arguments.contains("SET_USER_AT_USAGE_LIMIT") {
            print("[MagicalStoriesApp] Setting user at usage limit for testing")
            UserDefaults.standard.set(3, forKey: "monthly_story_count")
        }
        
        // Simulate subscription states
        if arguments.contains("SIMULATE_PREMIUM_SUBSCRIPTION") {
            print("[MagicalStoriesApp] Simulating premium subscription for testing")
            UserDefaults.standard.set("premium_active", forKey: "subscription_status")
            UserDefaults.standard.set(Date().addingTimeInterval(86400 * 30), forKey: "subscription_expiry") // 30 days
        }
        
        if arguments.contains("SIMULATE_EXPIRED_SUBSCRIPTION") {
            print("[MagicalStoriesApp] Simulating expired subscription for testing")
            UserDefaults.standard.set("premium_expired", forKey: "subscription_status")
            UserDefaults.standard.set(Date().addingTimeInterval(-86400), forKey: "subscription_expiry") // Yesterday
        }
        
        if arguments.contains("SIMULATE_MONTHLY_RESET") {
            print("[MagicalStoriesApp] Simulating monthly reset for testing")
            UserDefaults.standard.set(0, forKey: "monthly_story_count")
            UserDefaults.standard.set(Date(), forKey: "last_reset_date")
        }
    }
}
