import Foundation
import SwiftData

// MARK: - App Settings SwiftData Model
@Model
final class AppSettingsModel {
    var fontScale: Double
    var hapticFeedbackEnabled: Bool
    var soundEffectsEnabled: Bool
    var darkModeEnabled: Bool
    // Add a unique identifier or assume only one instance exists
    // For simplicity, let's assume only one instance and fetch it directly.
    // If multiple profiles were needed, a unique ID would be essential.

    init(fontScale: Double = 1.0,
         hapticFeedbackEnabled: Bool = true,
         soundEffectsEnabled: Bool = true,
         darkModeEnabled: Bool = false)
    {
        self.fontScale = fontScale
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
        self.soundEffectsEnabled = soundEffectsEnabled
        self.darkModeEnabled = darkModeEnabled
    }

    // Convenience initializer from the non-persistent struct
    convenience init(from settings: AppSettings) {
        self.init(
            fontScale: settings.fontScale,
            hapticFeedbackEnabled: settings.hapticFeedbackEnabled,
            soundEffectsEnabled: settings.soundEffectsEnabled,
            darkModeEnabled: settings.darkModeEnabled
        )
    }

    // Method to convert back to the non-persistent struct
    func toAppSettings() -> AppSettings {
        AppSettings(
            fontScale: self.fontScale,
            hapticFeedbackEnabled: self.hapticFeedbackEnabled,
            soundEffectsEnabled: self.soundEffectsEnabled,
            darkModeEnabled: self.darkModeEnabled
        )
    }

    // Static default instance based on the struct's default
    static var `default`: AppSettingsModel {
        AppSettingsModel(from: AppSettings.default)
    }
}


// MARK: - Parental Controls SwiftData Model
@Model
final class ParentalControlsModel {
    var contentFiltering: Bool
    var screenTimeEnabled: Bool
    var maxStoriesPerDay: Int
    // Store raw values for the Set<StoryTheme>
    var allowedThemesRaw: [String]
    var minimumAge: Int
    var maximumAge: Int
    // Assume only one instance exists

    // Computed property for easy access to allowedThemes
    var allowedThemes: Set<StoryTheme> {
        get {
            Set(allowedThemesRaw.compactMap { StoryTheme(rawValue: $0) })
        }
        set {
            allowedThemesRaw = newValue.map { $0.rawValue }.sorted() // Store sorted for consistency
        }
    }

    init(contentFiltering: Bool = true,
         screenTimeEnabled: Bool = false,
         maxStoriesPerDay: Int = 3,
         allowedThemes: Set<StoryTheme> = Set(StoryTheme.allCases),
         minimumAge: Int = 3,
         maximumAge: Int = 10)
    {
        self.contentFiltering = contentFiltering
        self.screenTimeEnabled = screenTimeEnabled
        self.maxStoriesPerDay = maxStoriesPerDay
        self.allowedThemesRaw = allowedThemes.map { $0.rawValue }.sorted()
        self.minimumAge = minimumAge
        self.maximumAge = maximumAge
    }

    // Convenience initializer from the non-persistent struct
    convenience init(from controls: ParentalControls) {
        self.init(
            contentFiltering: controls.contentFiltering,
            screenTimeEnabled: controls.screenTimeEnabled,
            maxStoriesPerDay: controls.maxStoriesPerDay,
            allowedThemes: controls.allowedThemes,
            minimumAge: controls.minimumAge,
            maximumAge: controls.maximumAge
        )
    }

    // Method to convert back to the non-persistent struct
    func toParentalControls() -> ParentalControls {
        ParentalControls(
            contentFiltering: self.contentFiltering,
            screenTimeEnabled: self.screenTimeEnabled,
            maxStoriesPerDay: self.maxStoriesPerDay,
            allowedThemes: self.allowedThemes, // Use computed property
            minimumAge: self.minimumAge,
            maximumAge: self.maximumAge
        )
    }

    // Static default instance based on the struct's default
    static var `default`: ParentalControlsModel {
        ParentalControlsModel(from: ParentalControls.default)
    }
}