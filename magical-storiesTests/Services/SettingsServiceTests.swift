import Testing
import Foundation
import SwiftData
@testable import magical_stories

// Minimal mock for usage analytics dependency

@MainActor
struct SettingsServiceTests {
    var settingsService: SettingsService!
    var userDefaults: UserDefaults!
    var modelContainer: ModelContainer!
    var repository: SettingsRepositoryProtocol!

    // Helper for waiting briefly for async operations in tests
    func waitForAsyncOperations(durationInSeconds: Double = 0.1) async {
        try? await Task.sleep(for: .seconds(durationInSeconds))
    }
    // Using `init` for setup as recommended by swift-testing for actor isolation
    init() async throws {
        // Create a unique suite name for each test run
        let suiteName = "test_suite_\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)!

        // Clear any existing UserDefaults data
        userDefaults.removePersistentDomain(forName: suiteName)

        // Configure an in-memory SwiftData store
        let schema = Schema([AppSettingsModel.self, ParentalControlsModel.self])
        let configuration = ModelConfiguration(suiteName, schema: schema, isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            let modelContext = modelContainer.mainContext // Use mainContext for @MainActor service
            repository = SettingsRepository(modelContext: modelContext)

            // Create a fresh instance of SettingsService with the repository and test UserDefaults
            settingsService = SettingsService(
                repository: repository,
                usageAnalyticsService: MockUsageAnalyticsService(),
                userDefaults: userDefaults
            )

            // Allow time for async initialization in SettingsService to complete
            await waitForAsyncOperations()

        } catch {
            fatalError("Failed to create in-memory ModelContainer: \(error)")
        }
    }
    
    @Test("Initial settings should load default values")
    mutating func testInitialSettings() async throws {
        // Given: Setup is done in init

        // Then - Verify default values (after async init)
        // Note: setUp() is now implicitly called via init()
        // Then - Verify default values
        #expect(settingsService.parentalControls.contentFiltering == true)
        #expect(settingsService.parentalControls.maxStoriesPerDay == 3)
        #expect(Set(settingsService.parentalControls.allowedThemes) == Set(StoryTheme.allCases))
        #expect(settingsService.parentalControls.minimumAge == 3)
        #expect(settingsService.parentalControls.maximumAge == 10)
        
        #expect(settingsService.appSettings.fontScale == 1.0)
        #expect(settingsService.appSettings.hapticFeedbackEnabled == true)
        #expect(settingsService.appSettings.soundEffectsEnabled == true)
        #expect(settingsService.appSettings.darkModeEnabled == false)
    }
    
    @Test("Updating parental controls should persist changes")
    mutating func testUpdateParentalControls() async throws {
        // Given: Setup is done in init
        var controls = settingsService.parentalControls // Get current (likely default)
        controls.contentFiltering = false
        controls.maxStoriesPerDay = 5
        controls.allowedThemes = [StoryTheme.adventure] // Change themes too

        // When
        settingsService.updateParentalControls(controls)
        await waitForAsyncOperations() // Allow save task to run

        // Then - Verify in-memory changes
        #expect(settingsService.parentalControls.contentFiltering == false)
        #expect(settingsService.parentalControls.maxStoriesPerDay == 5)
        #expect(settingsService.parentalControls.allowedThemes == [StoryTheme.adventure])

        // Then - Verify persistence by creating a new service with the SAME repository
        let newService = SettingsService(
            repository: repository,
            usageAnalyticsService: MockUsageAnalyticsService(),
            userDefaults: userDefaults
        )
        await waitForAsyncOperations() // Allow new service's async init to load

        #expect(newService.parentalControls.contentFiltering == false)
        #expect(newService.parentalControls.maxStoriesPerDay == 5)
        #expect(newService.parentalControls.allowedThemes == [.adventure])
    }
    
    @Test("Updating app settings should persist changes")
    mutating func testUpdateAppSettings() async throws {
        // Given: Setup is done in init
        var settings = settingsService.appSettings // Make mutable to change
        settings.fontScale = 1.5
        settings.darkModeEnabled = true

        // When
        settingsService.updateAppSettings(settings)
        await waitForAsyncOperations() // Allow save task to run

        // Then - Verify in-memory changes
        #expect(settingsService.appSettings.fontScale == 1.5)
        #expect(settingsService.appSettings.darkModeEnabled == true)

        // Then - Verify persistence
        let newService = SettingsService(
            repository: repository,
            usageAnalyticsService: MockUsageAnalyticsService(),
            userDefaults: userDefaults
        )
        await waitForAsyncOperations() // Allow new service's async init to load

        #expect(newService.appSettings.fontScale == 1.5)
        #expect(newService.appSettings.darkModeEnabled == true)
    }
    
    @Test("Story generation validation should respect parental controls")
    mutating func testStoryGenerationValidation() async throws {
        // Given: Setup is done in init
        var controls = settingsService.parentalControls // Get current (likely default)
        controls.contentFiltering = true
        controls.allowedThemes = [.adventure, .friendship]
        controls.minimumAge = 5
        controls.maximumAge = 8
        settingsService.updateParentalControls(controls)
        await waitForAsyncOperations() // Allow save task to run

        // Then - Valid case
        #expect(settingsService.canGenerateStory(theme: StoryTheme.adventure, ageGroup: 6) == true)
                
        // Then - Invalid theme
        #expect(settingsService.canGenerateStory(theme: StoryTheme.learning, ageGroup: 6) == false)
                
        // Then - Invalid age
        #expect(settingsService.canGenerateStory(theme: StoryTheme.adventure, ageGroup: 4) == false)
        #expect(settingsService.canGenerateStory(theme: StoryTheme.adventure, ageGroup: 9) == false)
    }
    
    @Test("Story count limit should respect screen time settings")
    mutating func testStoryCountLimit() async throws {
        // Given: Setup is done in init
        // This test primarily interacts with UserDefaults for count, which remains unchanged
        var controls = settingsService.parentalControls
        controls.screenTimeEnabled = true
        controls.maxStoriesPerDay = 2
        settingsService.updateParentalControls(controls)
        await waitForAsyncOperations() // Allow save task to run

        // Then - Initial state
        #expect(await settingsService.canGenerateMoreStories() == true)
        
        // When - Generate stories
        await settingsService.incrementStoryGenerationCount()
        #expect(await settingsService.canGenerateMoreStories() == true)
        
        await settingsService.incrementStoryGenerationCount()
        #expect(await settingsService.canGenerateMoreStories() == false)
    }

    // MARK: - Migration Test

    @Test("Settings should migrate from UserDefaults to SwiftData")
    mutating func testUserDefaultsMigration() async throws {
        // --- Setup Phase ---
        // 1. Prepare UserDefaults with old data
        let suiteName = "migration_test_suite_\(UUID().uuidString)"
        let migrationUserDefaults = UserDefaults(suiteName: suiteName)!
        migrationUserDefaults.removePersistentDomain(forName: suiteName) // Clean slate

        let oldControls = ParentalControls(
            contentFiltering: false,
            screenTimeEnabled: true,
            maxStoriesPerDay: 10,
            allowedThemes: [StoryTheme.friendship, StoryTheme.adventure],
            minimumAge: 7,
            maximumAge: 12
        )
        let oldSettings = AppSettings(
            fontScale: 0.8,
            hapticFeedbackEnabled: false,
            soundEffectsEnabled: false,
            darkModeEnabled: true
        )

        let jsonEncoder = JSONEncoder()
        let controlsData = try jsonEncoder.encode(oldControls)
        let settingsData = try jsonEncoder.encode(oldSettings)

        let oldParentalControlsKey = "parentalControls" // Match key used in old service version
        let oldAppSettingsKey = "appSettings"       // Match key used in old service version
        let migrationDoneKey = "settingsMigrationToSwiftDataDone"

        migrationUserDefaults.set(controlsData, forKey: oldParentalControlsKey)
        migrationUserDefaults.set(settingsData, forKey: oldAppSettingsKey)
        migrationUserDefaults.set(false, forKey: migrationDoneKey) // Ensure migration hasn't run

        // 2. Prepare SwiftData (in-memory)
        let schema = Schema([AppSettingsModel.self, ParentalControlsModel.self])
        let configuration = ModelConfiguration(suiteName, schema: schema, isStoredInMemoryOnly: true)
        let migrationContainer = try ModelContainer(for: schema, configurations: [configuration])
        let migrationContext = migrationContainer.mainContext
        let migrationRepository = SettingsRepository(modelContext: migrationContext)

        // --- Execution Phase ---
        // 3. Initialize SettingsService - This triggers the migration logic
        let migrationService = SettingsService(
            repository: migrationRepository,
            usageAnalyticsService: MockUsageAnalyticsService(),
            userDefaults: migrationUserDefaults
        )
        await waitForAsyncOperations(durationInSeconds: 0.2) // Allow more time for migration logic

        // --- Verification Phase ---
        // 4. Verify service loaded migrated data
        #expect(migrationService.parentalControls.contentFiltering == false)
        #expect(migrationService.parentalControls.maxStoriesPerDay == 10)
        #expect(migrationService.parentalControls.allowedThemes == [StoryTheme.friendship, StoryTheme.adventure])
        #expect(migrationService.appSettings.fontScale == 0.8)
        #expect(migrationService.appSettings.darkModeEnabled == true)

        // 5. Verify data exists in SwiftData store directly
        let fetchedControls = try await migrationRepository.fetchParentalControls()
        let fetchedSettings = try await migrationRepository.fetchAppSettings()

        #expect(fetchedControls != nil)
        #expect(fetchedSettings != nil)
        #expect(fetchedControls?.contentFiltering == false)
        #expect(fetchedControls?.maxStoriesPerDay == 10)
        #expect(fetchedControls?.allowedThemes == [StoryTheme.friendship, StoryTheme.adventure])
        #expect(fetchedSettings?.fontScale == 0.8)
        #expect(fetchedSettings?.darkModeEnabled == true)

        // 6. Verify migration flag is set in UserDefaults
        #expect(migrationUserDefaults.bool(forKey: migrationDoneKey) == true)

        // 7. Verify old keys are removed from UserDefaults
        #expect(migrationUserDefaults.data(forKey: oldParentalControlsKey) == nil)
        #expect(migrationUserDefaults.data(forKey: oldAppSettingsKey) == nil)
    }
}
