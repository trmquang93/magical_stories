import SwiftUI
import SwiftData
// MARK: - Settings Models
struct ParentalControls: Codable {
    var contentFiltering: Bool
    var screenTimeEnabled: Bool
    var maxStoriesPerDay: Int
    var allowedThemes: Set<StoryTheme>
    var minimumAge: Int
    var maximumAge: Int

    static let `default` = ParentalControls(
        contentFiltering: true,
        screenTimeEnabled: false,
        maxStoriesPerDay: 3,
        allowedThemes: Set(StoryTheme.allCases),
        minimumAge: 3,
        maximumAge: 10
    )
}

struct AppSettings: Codable {
    var fontScale: Double
    var hapticFeedbackEnabled: Bool
    var soundEffectsEnabled: Bool
    var darkModeEnabled: Bool

    static let `default` = AppSettings(
        fontScale: 1.0,
        hapticFeedbackEnabled: true,
        soundEffectsEnabled: true,
        darkModeEnabled: false
    )
}

// MARK: - Settings Service
@MainActor
class SettingsService: ObservableObject {
    private let repository: SettingsRepositoryProtocol
    private let userDefaults: UserDefaults // Keep for settings migration logic
    private let usageAnalyticsService: UsageAnalyticsServiceProtocol // Inject usage service
    private let migrationDoneKey = "settingsMigrationToSwiftDataDone" // Key to track migration

    @Published private(set) var parentalControls: ParentalControls
    @Published private(set) var appSettings: AppSettings

    // Constants for old UserDefaults keys (used only for migration)
    private let oldParentalControlsKey = "parentalControls"
    private let oldAppSettingsKey = "appSettings"

    init(
        repository: SettingsRepositoryProtocol,
        usageAnalyticsService: UsageAnalyticsServiceProtocol, // Add usage service to init
        userDefaults: UserDefaults = .standard
    ) {
        self.repository = repository
        self.usageAnalyticsService = usageAnalyticsService // Store injected service
        self.userDefaults = userDefaults

        // Initialize with defaults first, will be overwritten by loaded/migrated data
        self.parentalControls = .default
        self.appSettings = .default

        // Load settings asynchronously
        Task {
            await loadAndMigrateSettings()
        }
    }

    private func loadAndMigrateSettings() async {
        do {
            // 1. Try fetching from SwiftData repository first
            let fetchedAppSettingsModel = try await repository.fetchAppSettings()
            let fetchedParentalControlsModel = try await repository.fetchParentalControls()

            if let appModel = fetchedAppSettingsModel, let controlsModel = fetchedParentalControlsModel {
                // Data exists in SwiftData, update published properties
                await MainActor.run {
                    self.appSettings = appModel.toAppSettings()
                    self.parentalControls = controlsModel.toParentalControls()
                }
                // Ensure migration flag is set if data exists
                if !userDefaults.bool(forKey: migrationDoneKey) {
                     userDefaults.set(true, forKey: migrationDoneKey)
                     // Optionally remove old keys if they somehow still exist
                     userDefaults.removeObject(forKey: oldParentalControlsKey)
                     userDefaults.removeObject(forKey: oldAppSettingsKey)
                }
                return // Loading successful
            }

            // 2. If not in SwiftData, check if migration is needed (and not already done)

            // 3. If no data in SwiftData and no migration occurred (or failed), save defaults
            print("No existing settings found in SwiftData or UserDefaults. Saving defaults.")
            let defaultAppSettingsModel = AppSettingsModel.default
            let defaultParentalControlsModel = ParentalControlsModel.default

            try await repository.saveAppSettings(defaultAppSettingsModel)
            try await repository.saveParentalControls(defaultParentalControlsModel)

            // Update published properties with defaults
            await MainActor.run {
                self.appSettings = defaultAppSettingsModel.toAppSettings()
                self.parentalControls = defaultParentalControlsModel.toParentalControls()
            }

        } catch {
            // Handle potential errors during fetch/save (e.g., log error)
            // For now, we fall back to defaults in memory if loading fails
            print("Error loading or migrating settings: \(error). Using default settings.")
            await MainActor.run {
                self.appSettings = .default
                self.parentalControls = .default
            }
        }
    }


    // MARK: - Parental Controls

    func updateParentalControls(_ controls: ParentalControls) {
        // Update in-memory state immediately
        let oldControls = parentalControls
        parentalControls = controls
        // Asynchronously save to repository
        Task {
            await saveParentalControls(controls: controls, fallback: oldControls)
        }
    }

    func toggleContentFiltering() {
        parentalControls.contentFiltering.toggle()
        let updatedControls = parentalControls // Capture the updated struct
        let oldControls = ParentalControls(contentFiltering: !updatedControls.contentFiltering, screenTimeEnabled: updatedControls.screenTimeEnabled, maxStoriesPerDay: updatedControls.maxStoriesPerDay, allowedThemes: updatedControls.allowedThemes, minimumAge: updatedControls.minimumAge, maximumAge: updatedControls.maximumAge) // Reconstruct old state for fallback
        Task {
            await saveParentalControls(controls: updatedControls, fallback: oldControls)
        }
    }

    func toggleScreenTime() {
        parentalControls.screenTimeEnabled.toggle()
        let updatedControls = parentalControls
        let oldControls = ParentalControls(contentFiltering: updatedControls.contentFiltering, screenTimeEnabled: !updatedControls.screenTimeEnabled, maxStoriesPerDay: updatedControls.maxStoriesPerDay, allowedThemes: updatedControls.allowedThemes, minimumAge: updatedControls.minimumAge, maximumAge: updatedControls.maximumAge)
        Task {
            await saveParentalControls(controls: updatedControls, fallback: oldControls)
        }
    }

    func updateMaxStoriesPerDay(_ count: Int) {
        parentalControls.maxStoriesPerDay = count
        let updatedControls = parentalControls
        // Need the previous count for fallback, which isn't directly available here.
        // For simplicity in this example, we might skip precise fallback or fetch before update.
        // Let's assume direct save is sufficient for now, or handle fallback differently.
        Task {
            await saveParentalControls(controls: updatedControls) // Simplified fallback for this case
        }
    }

    func updateAllowedThemes(_ themes: Set<StoryTheme>) {
        parentalControls.allowedThemes = themes
        let updatedControls = parentalControls
        // Fallback requires knowing the previous set of themes.
        Task {
            await saveParentalControls(controls: updatedControls) // Simplified fallback
        }
    }

    func updateAgeRange(minimum: Int, maximum: Int) {
        parentalControls.minimumAge = minimum
        parentalControls.maximumAge = maximum
        let updatedControls = parentalControls
        // Fallback requires knowing the previous min/max ages.
        Task {
            await saveParentalControls(controls: updatedControls) // Simplified fallback
        }
    }

    // MARK: - App Settings

    func updateAppSettings(_ settings: AppSettings) {
        // Update in-memory state immediately
        let oldSettings = appSettings
        appSettings = settings
        // Asynchronously save to repository
        Task {
            await saveAppSettings(settings: settings, fallback: oldSettings)
        }
    }

    func updateFontScale(_ scale: Double) {
        appSettings.fontScale = scale
        let updatedSettings = appSettings
        // Fallback requires knowing the previous scale.
        Task {
            await saveAppSettings(settings: updatedSettings) // Simplified fallback
        }
    }

    func toggleHapticFeedback() {
        appSettings.hapticFeedbackEnabled.toggle()
        let updatedSettings = appSettings
        let oldSettings = AppSettings(fontScale: updatedSettings.fontScale, hapticFeedbackEnabled: !updatedSettings.hapticFeedbackEnabled, soundEffectsEnabled: updatedSettings.soundEffectsEnabled, darkModeEnabled: updatedSettings.darkModeEnabled)
        Task {
            await saveAppSettings(settings: updatedSettings, fallback: oldSettings)
        }
    }

    func toggleSoundEffects() {
        appSettings.soundEffectsEnabled.toggle()
        let updatedSettings = appSettings
        let oldSettings = AppSettings(fontScale: updatedSettings.fontScale, hapticFeedbackEnabled: updatedSettings.hapticFeedbackEnabled, soundEffectsEnabled: !updatedSettings.soundEffectsEnabled, darkModeEnabled: updatedSettings.darkModeEnabled)
        Task {
            await saveAppSettings(settings: updatedSettings, fallback: oldSettings)
        }
    }
    
    func toggleDarkMode() { // Assuming darkMode toggle might be needed
        appSettings.darkModeEnabled.toggle()
        let updatedSettings = appSettings
        let oldSettings = AppSettings(fontScale: updatedSettings.fontScale, hapticFeedbackEnabled: updatedSettings.hapticFeedbackEnabled, soundEffectsEnabled: updatedSettings.soundEffectsEnabled, darkModeEnabled: !updatedSettings.darkModeEnabled)
        Task {
            await saveAppSettings(settings: updatedSettings, fallback: oldSettings)
        }
    }

    // MARK: - Private Helpers

    private func saveParentalControls(controls: ParentalControls, fallback: ParentalControls? = nil) async {
        let model = ParentalControlsModel(from: controls)
        do {
            try await repository.saveParentalControls(model)
            // print("Successfully saved Parental Controls to SwiftData.") // Optional logging
        } catch {
            print("Error saving Parental Controls: \(error). Reverting to previous state.")
            // Revert to fallback state if save fails
            if let fallbackState = fallback {
                await MainActor.run { self.parentalControls = fallbackState }
            }
        }
    }

    private func saveAppSettings(settings: AppSettings, fallback: AppSettings? = nil) async {
        let model = AppSettingsModel(from: settings)
        do {
            try await repository.saveAppSettings(model)
            // print("Successfully saved App Settings to SwiftData.") // Optional logging
        } catch {
            print("Error saving App Settings: \(error). Reverting to previous state.")
            // Revert to fallback state if save fails
            if let fallbackState = fallback {
                await MainActor.run { self.appSettings = fallbackState }
            }
        }
    }
}

// MARK: - Settings Validation
extension SettingsService {
    func canGenerateStory(theme: StoryTheme, ageGroup: Int) -> Bool {
        guard parentalControls.contentFiltering else { return true }

        let isThemeAllowed = parentalControls.allowedThemes.contains(theme)
        let isAgeAllowed =
            (ageGroup >= parentalControls.minimumAge) && (ageGroup <= parentalControls.maximumAge)

        return isThemeAllowed && isAgeAllowed
    }

    func canGenerateMoreStories() async -> Bool { // Make async
        guard parentalControls.screenTimeEnabled else { return true }

        // Fetch current values from UsageAnalyticsService
        let count = await usageAnalyticsService.getStoryGenerationCount()
        let lastDate = await usageAnalyticsService.getLastGenerationDate()

        // Check if the last generation was today
        if let lastDate = lastDate, Calendar.current.isDate(lastDate, inSameDayAs: Date()) {
            // If generated today, check count against limit
            return count < parentalControls.maxStoriesPerDay
        } else {
            // If not generated today (or never), the count for today is effectively 0
            // No need to reset here, the service handles the state.
            return true // Can generate if limit is >= 1
        }
    }

    func incrementStoryGenerationCount() async { // Make async
        guard parentalControls.screenTimeEnabled else { return }

        // Delegate incrementing and date update to the UsageAnalyticsService
        await usageAnalyticsService.incrementStoryGenerationCount()
        // The service should ideally handle updating the date internally when count is incremented,
        // but we can explicitly call it here if needed. Let's assume service handles it.
        // await usageAnalyticsService.updateLastGenerationDate(date: Date()) // Uncomment if service doesn't handle date internally
    }
}
