import Foundation
import SwiftData
import SwiftUI

// Use local Configuration file for API keys
@main
@MainActor
struct MagicalStoriesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Initialize services using StateObject to maintain their state throughout the app lifetime
    @StateObject private var settingsService: SettingsService
    @StateObject private var storyService: StoryService
    @StateObject private var collectionService: CollectionService
    @StateObject private var persistenceService: PersistenceService
    @StateObject private var simpleIllustrationService: SimpleIllustrationService
    @StateObject private var characterReferenceService: CharacterReferenceService
    @StateObject private var appRouter: AppRouter // Add AppRouter
    @StateObject private var purchaseService: PurchaseService
    @StateObject private var entitlementManager: EntitlementManager
    @StateObject private var usageTracker: UsageTracker
    @StateObject private var transactionObserver: TransactionObserver
    @StateObject private var accessCodeValidator: AccessCodeValidator
    @StateObject private var accessCodeStorage: AccessCodeStorage
    @StateObject private var clarityAnalytics: ClarityAnalyticsService
    @StateObject private var readingProgressService: ReadingProgressService
    @StateObject private var ratingService: RatingService
    @StateObject private var featureFlagService: FeatureFlagService
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

        // Initialize new SimpleIllustrationService first
        let simpleIllustration: SimpleIllustrationService
        do {
            simpleIllustration = try SimpleIllustrationService(apiKey: AppConfig.geminiApiKey)
            print("[MagicalStoriesApp] Successfully created SimpleIllustrationService")
        } catch {
            fatalError("Failed to create SimpleIllustrationService: \(error)")
        }
        
        // Initialize CharacterReferenceService with SimpleIllustrationService
        let characterReferenceService = CharacterReferenceService(
            illustrationService: simpleIllustration
        )
        print("[MagicalStoriesApp] Successfully created CharacterReferenceService")
        
        let story: StoryService
        do {
            story = try StoryService(
                apiKey: AppConfig.geminiApiKey, 
                context: context,
                characterReferenceService: characterReferenceService
            )
        } catch {
            fatalError("Failed to create StoryService: \(error)")
        }

        let collectionService = CollectionService(
            repository: collectionRepository, storyService: story,
            achievementRepository: achievementRepository)

        let persistenceService = PersistenceService(context: context)

        // Update SimpleIllustrationService with CharacterReferenceService
        do {
            try simpleIllustration.setCharacterReferenceService(characterReferenceService)
            print("[MagicalStoriesApp] Successfully linked CharacterReferenceService to SimpleIllustrationService")
        } catch {
            fatalError("Failed to link CharacterReferenceService: \(error)")
        }
        
        // Initialize subscription services
        let purchaseService = PurchaseService()
        let entitlementManager = EntitlementManager()
        let usageTracker = UsageTracker(usageAnalyticsService: usageAnalyticsService)
        let transactionObserver = TransactionObserver()
        
        // Initialize access code services
        let accessCodeValidator = AccessCodeValidator()
        let accessCodeStorage = AccessCodeStorage()
        
        // Initialize analytics service
        let clarityAnalytics = ClarityAnalyticsService.shared
        
        // Initialize reading progress service
        let readingProgressService = ReadingProgressService(
            persistenceService: persistenceService,
            collectionService: collectionService
        )
        
        // Initialize feature flag service
        let featureFlagService = FeatureFlagService.shared
        
        // Initialize rating service
        let ratingService = RatingService(
            analyticsService: clarityAnalytics,
            featureFlagService: featureFlagService
        )
        
        // Set up dependencies between subscription services
        purchaseService.setEntitlementManager(entitlementManager)
        purchaseService.setAnalyticsService(clarityAnalytics)
        story.setAnalyticsService(clarityAnalytics)
        entitlementManager.setUsageTracker(usageTracker)
        entitlementManager.setUsageAnalyticsService(usageAnalyticsService)
        entitlementManager.setAccessCodeValidator(accessCodeValidator)
        entitlementManager.setAccessCodeStorage(accessCodeStorage)
        story.setEntitlementManager(entitlementManager)
        
        // Set up rating service dependencies
        purchaseService.setRatingService(ratingService)
        entitlementManager.setRatingService(ratingService)
        story.setRatingService(ratingService)
        collectionService.setRatingService(ratingService)
        readingProgressService.setRatingService(ratingService)
        
        // Set up transaction observer dependencies
        transactionObserver.setEntitlementManager(entitlementManager)
        transactionObserver.setPurchaseService(purchaseService)
        
        print("[MagicalStoriesApp] Successfully created subscription services")

        // Assign to StateObjects
        _settingsService = StateObject(wrappedValue: settings)
        _storyService = StateObject(wrappedValue: story)
        _collectionService = StateObject(wrappedValue: collectionService)
        _persistenceService = StateObject(wrappedValue: persistenceService)
        _simpleIllustrationService = StateObject(wrappedValue: simpleIllustration)
        _characterReferenceService = StateObject(wrappedValue: characterReferenceService)
        _appRouter = StateObject(wrappedValue: router) // Assign AppRouter
        _purchaseService = StateObject(wrappedValue: purchaseService)
        _entitlementManager = StateObject(wrappedValue: entitlementManager)
        _usageTracker = StateObject(wrappedValue: usageTracker)
        _transactionObserver = StateObject(wrappedValue: transactionObserver)
        _accessCodeValidator = StateObject(wrappedValue: accessCodeValidator)
        _accessCodeStorage = StateObject(wrappedValue: accessCodeStorage)
        _clarityAnalytics = StateObject(wrappedValue: clarityAnalytics)
        _readingProgressService = StateObject(wrappedValue: readingProgressService)
        _ratingService = StateObject(wrappedValue: ratingService)
        _featureFlagService = StateObject(wrappedValue: featureFlagService)

        // Store container for environment injection
        self.container = container
        
        // Initialize Clarity Analytics if enabled
        if ClarityConfiguration.shouldInitializeAnalytics() {
            Task { @MainActor in
                clarityAnalytics.initialize(projectId: ClarityConfiguration.projectId)
                
                // Set initial user properties
                clarityAnalytics.setUserProperty(key: "app_version", value: Bundle.main.appVersion)
                clarityAnalytics.setUserProperty(key: "device_type", value: UIDevice.current.model)
                
                // Track app launch
                let launchTime = CFAbsoluteTimeGetCurrent()
                clarityAnalytics.trackAppLaunchTime(duration: launchTime)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            // Pass all services as environment objects to make them available throughout the view hierarchy
            RootView()
                .environmentObject(settingsService)
                .environmentObject(storyService)
                .environmentObject(collectionService)
                .environmentObject(persistenceService)
                .environmentObject(simpleIllustrationService)
                .environmentObject(characterReferenceService)
                .environmentObject(appRouter) // Inject AppRouter
                .environmentObject(purchaseService) // Inject subscription services
                .environmentObject(entitlementManager)
                .environmentObject(usageTracker)
                .environmentObject(transactionObserver) // Inject transaction observer
                .environmentObject(accessCodeValidator) // Inject access code services
                .environmentObject(accessCodeStorage)
                .environmentObject(clarityAnalytics) // Inject analytics service
                .environmentObject(readingProgressService) // Inject reading progress service
                .environmentObject(ratingService) // Inject rating service
                .environmentObject(featureFlagService) // Inject feature flag service
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
        
        // Screenshot-specific configurations
        if arguments.contains("CREATE_SCREENSHOT_DATA") {
            print("[MagicalStoriesApp] Creating premium screenshot data")
            // Enable premium subscription for screenshots
            UserDefaults.standard.set("premium_active", forKey: "subscription_status")
            UserDefaults.standard.set(Date().addingTimeInterval(86400 * 365), forKey: "subscription_expiry") // 1 year
            // Show some usage but not at limit
            UserDefaults.standard.set(1, forKey: "monthly_story_count")
            UserDefaults.standard.set(Date(), forKey: "last_reset_date")
        }
        
        if arguments.contains("SKIP_ONBOARDING") {
            print("[MagicalStoriesApp] Skipping onboarding for screenshots")
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        }
        
        if arguments.contains("PERFECT_STORIES") {
            print("[MagicalStoriesApp] Will create showcase stories for screenshots")
            // This flag will be handled in RootView to create premium content
        }
    }
}
