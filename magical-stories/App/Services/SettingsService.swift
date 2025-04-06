import SwiftUI

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
    private let userDefaults: UserDefaults
    private let parentalControlsKey = "parentalControls"
    private let appSettingsKey = "appSettings"

    @Published private(set) var parentalControls: ParentalControls
    @Published private(set) var appSettings: AppSettings

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        // Initialize with defaults first
        self.parentalControls = .default
        self.appSettings = .default

        // Then try to load from storage
        let jsonDecoder = JSONDecoder()

        if let data = userDefaults.data(forKey: parentalControlsKey),
           let controls = try? jsonDecoder.decode(ParentalControls.self, from: data)
        {
            self.parentalControls = controls
        }

        if let data = userDefaults.data(forKey: appSettingsKey),
           let settings = try? jsonDecoder.decode(AppSettings.self, from: data)
        {
            self.appSettings = settings
        }
    }

    // MARK: - Parental Controls

    func updateParentalControls(_ controls: ParentalControls) {
        parentalControls = controls
        saveParentalControls()
    }

    func toggleContentFiltering() {
        parentalControls.contentFiltering.toggle()
        saveParentalControls()
    }

    func toggleScreenTime() {
        parentalControls.screenTimeEnabled.toggle()
        saveParentalControls()
    }

    func updateMaxStoriesPerDay(_ count: Int) {
        parentalControls.maxStoriesPerDay = count
        saveParentalControls()
    }

    func updateAllowedThemes(_ themes: Set<StoryTheme>) {
        parentalControls.allowedThemes = themes
        saveParentalControls()
    }

    func updateAgeRange(minimum: Int, maximum: Int) {
        parentalControls.minimumAge = minimum
        parentalControls.maximumAge = maximum
        saveParentalControls()
    }

    // MARK: - App Settings

    func updateAppSettings(_ settings: AppSettings) {
        appSettings = settings
        saveAppSettings()
    }

    func updateFontScale(_ scale: Double) {
        appSettings.fontScale = scale
        saveAppSettings()
    }

    func toggleHapticFeedback() {
        appSettings.hapticFeedbackEnabled.toggle()
        saveAppSettings()
    }

    func toggleSoundEffects() {
        appSettings.soundEffectsEnabled.toggle()
        saveAppSettings()
    }
    
    func toggleDarkMode() { // Assuming darkMode toggle might be needed
        appSettings.darkModeEnabled.toggle()
        saveAppSettings()
    }

    // MARK: - Private Helpers

    private func saveParentalControls() {
        let jsonEncoder = JSONEncoder()
        guard let data = try? jsonEncoder.encode(parentalControls) else { return }
        userDefaults.set(data, forKey: parentalControlsKey)
    }

    private func saveAppSettings() {
        let jsonEncoder = JSONEncoder()
        guard let data = try? jsonEncoder.encode(appSettings) else { return }
        userDefaults.set(data, forKey: appSettingsKey)
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

    func canGenerateMoreStories() -> Bool {
        guard parentalControls.screenTimeEnabled else { return true }

        let count = userDefaults.integer(forKey: "storyGenerationCount")
        let lastDate = userDefaults.object(forKey: "lastGenerationDate") as? Date

        // Reset count if it's a new day
        if let lastDate = lastDate,
           !Calendar.current.isDate(lastDate, inSameDayAs: Date())
        {
            userDefaults.set(0, forKey: "storyGenerationCount")
            return true
        }

        return count < parentalControls.maxStoriesPerDay
    }

    func incrementStoryGenerationCount() {
        guard parentalControls.screenTimeEnabled else { return }

        let count = userDefaults.integer(forKey: "storyGenerationCount")
        userDefaults.set(count + 1, forKey: "storyGenerationCount")
        userDefaults.set(Date(), forKey: "lastGenerationDate")
    }
}
