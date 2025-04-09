import Testing
import Foundation
import SwiftData
@testable import magical_stories

// Minimal mock for usage analytics dependency

@MainActor

class StatefulMockUsageAnalyticsService: UsageAnalyticsServiceProtocol {
    private var storyCount: Int = 0
    private var lastDate: Date? = nil

    func getStoryGenerationCount() async -> Int {
        if let lastDate = lastDate, Calendar.current.isDate(lastDate, inSameDayAs: Date()) {
            return storyCount
        } else {
            return 0
        }
    }

    func incrementStoryGenerationCount() async {
        let today = Date()
        if let lastDate = lastDate, Calendar.current.isDate(lastDate, inSameDayAs: today) {
            storyCount += 1
        } else {
            storyCount = 1
            lastDate = today
        }
    }

    func updateLastGenerationDate(date: Date?) async {
        lastDate = date
    }

    func getLastGenerationDate() async -> Date? {
        return lastDate
    }

    func updateLastGeneratedStoryId(id: UUID?) async { }

    func getLastGeneratedStoryId() async -> UUID? { nil }
}

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
            let modelContext = await modelContainer.mainContext // Use mainContext for @MainActor service
            repository = SettingsRepository(modelContext: modelContext)

            // Create a fresh instance of SettingsService with the repository and test UserDefaults
            settingsService = await SettingsService(
                repository: repository,
                usageAnalyticsService: StatefulMockUsageAnalyticsService(),
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
        #expect(await settingsService.parentalControls.contentFiltering == true)
        #expect(await settingsService.parentalControls.maxStoriesPerDay == 3)
        #expect(Set(await settingsService.parentalControls.allowedThemes) == Set(StoryTheme.allCases))
        #expect(await settingsService.parentalControls.minimumAge == 3)
        #expect(await settingsService.parentalControls.maximumAge == 10)
        
        #expect(await settingsService.appSettings.fontScale == 1.0)
        #expect(await settingsService.appSettings.hapticFeedbackEnabled == true)
        #expect(await settingsService.appSettings.soundEffectsEnabled == true)
        #expect(await settingsService.appSettings.darkModeEnabled == false)
    }
    
    @Test("Updating parental controls should persist changes")
    mutating func testUpdateParentalControls() async throws {
        // Given: Setup is done in init
        var controls = await settingsService.parentalControls // Get current (likely default)
        controls.contentFiltering = false
        controls.maxStoriesPerDay = 5
        controls.allowedThemes = [StoryTheme.adventure] // Change themes too

        // When
        await settingsService.updateParentalControls(controls)
        await waitForAsyncOperations() // Allow save task to run

        // Then - Verify in-memory changes
        #expect(await settingsService.parentalControls.contentFiltering == false)
        #expect(await settingsService.parentalControls.maxStoriesPerDay == 5)
        #expect(await settingsService.parentalControls.allowedThemes == [StoryTheme.adventure])

        // Then - Verify persistence by creating a new service with the SAME repository
        let newService = await SettingsService(
            repository: repository,
            usageAnalyticsService: MockUsageAnalyticsService(),
            userDefaults: userDefaults
        )
        await waitForAsyncOperations(durationInSeconds: 0.3) // Allow more time for async init to load

        #expect(await newService.parentalControls.contentFiltering == false)
        #expect(await newService.parentalControls.maxStoriesPerDay == 5)
        #expect(await newService.parentalControls.allowedThemes == [.adventure])
    }
    
    @Test("Updating app settings should persist changes")
    mutating func testUpdateAppSettings() async throws {
        // Given: Setup is done in init
        var settings = await settingsService.appSettings // Make mutable to change
        settings.fontScale = 1.5
        settings.darkModeEnabled = true

        // When
        await settingsService.updateAppSettings(settings)
        await waitForAsyncOperations() // Allow save task to run

        // Then - Verify in-memory changes
        #expect(await settingsService.appSettings.fontScale == 1.5)
        #expect(await settingsService.appSettings.darkModeEnabled == true)

        // Then - Verify persistence
        let newService = await SettingsService(
            repository: repository,
            usageAnalyticsService: MockUsageAnalyticsService(),
            userDefaults: userDefaults
        )
        await waitForAsyncOperations(durationInSeconds: 0.3) // Allow more time for async init to load

        #expect(await newService.appSettings.fontScale == 1.5)
        #expect(await newService.appSettings.darkModeEnabled == true)
    }
    
    @Test("Story generation validation should respect parental controls")
    mutating func testStoryGenerationValidation() async throws {
        // Given: Setup is done in init
        var controls = await settingsService.parentalControls // Get current (likely default)
        controls.contentFiltering = true
        controls.allowedThemes = [.adventure, .friendship]
        controls.minimumAge = 5
        controls.maximumAge = 8
        await settingsService.updateParentalControls(controls)
        await waitForAsyncOperations() // Allow save task to run

        // Then - Valid case
        #expect(await settingsService.canGenerateStory(theme: StoryTheme.adventure, ageGroup: 6) == true)
                
        // Then - Invalid theme
        #expect(await settingsService.canGenerateStory(theme: StoryTheme.learning, ageGroup: 6) == false)
                
        // Then - Invalid age
        #expect(await settingsService.canGenerateStory(theme: StoryTheme.adventure, ageGroup: 4) == false)
        #expect(await settingsService.canGenerateStory(theme: StoryTheme.adventure, ageGroup: 9) == false)
    }
    
    @Test("Story count limit should respect screen time settings")
    mutating func testStoryCountLimit() async throws {
        // Given: Setup is done in init
        // This test primarily interacts with UserDefaults for count, which remains unchanged
        var controls = await settingsService.parentalControls
        controls.screenTimeEnabled = true
        controls.maxStoriesPerDay = 2
        await settingsService.updateParentalControls(controls)
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
