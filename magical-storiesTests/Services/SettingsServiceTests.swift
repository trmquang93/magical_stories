import Testing
@testable import magical_stories
import Foundation

// MARK: - Mock Settings Repository
class MockSettingsRepository: SettingsRepositoryProtocol {
    var appSettingsModel: AppSettingsModel? = AppSettingsModel.default
    var parentalControlsModel: ParentalControlsModel? = ParentalControlsModel.default
    var saveAppSettingsCalled = false
    var saveParentalControlsCalled = false
    
    func fetchAppSettings() async throws -> AppSettingsModel? {
        appSettingsModel
    }
    func saveAppSettings(_ settings: AppSettingsModel) async throws {
        appSettingsModel = settings
        saveAppSettingsCalled = true
    }
    func fetchParentalControls() async throws -> ParentalControlsModel? {
        parentalControlsModel
    }
    func saveParentalControls(_ controls: ParentalControlsModel) async throws {
        parentalControlsModel = controls
        saveParentalControlsCalled = true
    }
}

// MARK: - Test Suite
@Suite("SettingsService Unit Tests")
struct SettingsServiceTests {
    @Test
    func testInitialLoadDefaults() async throws {
        let repository = MockSettingsRepository()
        let analytics = await MockUsageAnalyticsService()
        let service = await SettingsService(repository: repository, usageAnalyticsService: analytics)
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(await service.appSettings.darkModeEnabled == false)
        #expect(await service.parentalControls.contentFiltering == true)
    }

    @Test
    func testToggleDarkMode() async throws {
        let repository = MockSettingsRepository()
        let analytics = await MockUsageAnalyticsService()
        let service = await SettingsService(repository: repository, usageAnalyticsService: analytics)
        try await Task.sleep(nanoseconds: 100_000_000)
        let initial = await service.appSettings.darkModeEnabled
        await service.toggleDarkMode()
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(await service.appSettings.darkModeEnabled != initial)
        #expect(repository.saveAppSettingsCalled)
    }

    @Test
    func testUpdateFontScale() async throws {
        let repository = MockSettingsRepository()
        let analytics = await MockUsageAnalyticsService()
        let service = await SettingsService(repository: repository, usageAnalyticsService: analytics)
        try await Task.sleep(nanoseconds: 100_000_000)
        await service.updateFontScale(1.2)
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(await service.appSettings.fontScale == 1.2)
        #expect(repository.saveAppSettingsCalled)
    }

    @Test
    func testToggleHapticFeedback() async throws {
        let repository = MockSettingsRepository()
        let analytics = await MockUsageAnalyticsService()
        let service = await SettingsService(repository: repository, usageAnalyticsService: analytics)
        try await Task.sleep(nanoseconds: 100_000_000)
        let initial = await service.appSettings.hapticFeedbackEnabled
        await service.toggleHapticFeedback()
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(await service.appSettings.hapticFeedbackEnabled != initial)
        #expect(repository.saveAppSettingsCalled)
    }

    @Test
    func testToggleSoundEffects() async throws {
        let repository = MockSettingsRepository()
        let analytics = await MockUsageAnalyticsService()
        let service = await SettingsService(repository: repository, usageAnalyticsService: analytics)
        try await Task.sleep(nanoseconds: 100_000_000)
        let initial = await service.appSettings.soundEffectsEnabled
        await service.toggleSoundEffects()
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(await service.appSettings.soundEffectsEnabled != initial)
        #expect(repository.saveAppSettingsCalled)
    }

    @Test
    func testToggleContentFiltering() async throws {
        let repository = MockSettingsRepository()
        let analytics = await MockUsageAnalyticsService()
        let service = await SettingsService(repository: repository, usageAnalyticsService: analytics)
        try await Task.sleep(nanoseconds: 100_000_000)
        let initial = await service.parentalControls.contentFiltering
        await service.toggleContentFiltering()
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(await service.parentalControls.contentFiltering != initial)
        #expect(repository.saveParentalControlsCalled)
    }

    @Test
    func testToggleScreenTime() async throws {
        let repository = MockSettingsRepository()
        let analytics = await MockUsageAnalyticsService()
        let service = await SettingsService(repository: repository, usageAnalyticsService: analytics)
        try await Task.sleep(nanoseconds: 100_000_000)
        let initial = await service.parentalControls.screenTimeEnabled
        await service.toggleScreenTime()
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(await service.parentalControls.screenTimeEnabled != initial)
        #expect(repository.saveParentalControlsCalled)
    }

    @Test
    func testUpdateMaxStoriesPerDay() async throws {
        let repository = MockSettingsRepository()
        let analytics = await MockUsageAnalyticsService()
        let service = await SettingsService(repository: repository, usageAnalyticsService: analytics)
        try await Task.sleep(nanoseconds: 100_000_000)
        await service.updateMaxStoriesPerDay(7)
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(await service.parentalControls.maxStoriesPerDay == 7)
        #expect(repository.saveParentalControlsCalled)
    }

    @Test
    func testUpdateAllowedThemes() async throws {
        let repository = MockSettingsRepository()
        let analytics = await MockUsageAnalyticsService()
        let service = await SettingsService(repository: repository, usageAnalyticsService: analytics)
        try await Task.sleep(nanoseconds: 100_000_000)
        let newThemes: Set<StoryTheme> = [.adventure, .courage]
        await service.updateAllowedThemes(newThemes)
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(await service.parentalControls.allowedThemes == newThemes)
        #expect(repository.saveParentalControlsCalled)
    }

    @Test
    func testUpdateAgeRange() async throws {
        let repository = MockSettingsRepository()
        let analytics = await MockUsageAnalyticsService()
        let service = await SettingsService(repository: repository, usageAnalyticsService: analytics)
        try await Task.sleep(nanoseconds: 100_000_000)
        await service.updateAgeRange(minimum: 5, maximum: 12)
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(await service.parentalControls.minimumAge == 5)
        #expect(await service.parentalControls.maximumAge == 12)
        #expect(repository.saveParentalControlsCalled)
    }
}
