import Foundation
import SwiftData

// Protocol defining the operations for settings persistence
@MainActor
protocol SettingsRepositoryProtocol {
    /// Fetches the single AppSettingsModel instance, if it exists.
    func fetchAppSettings() async throws -> AppSettingsModel?
    /// Saves or updates the AppSettingsModel instance.
    func saveAppSettings(_ settings: AppSettingsModel) async throws
    /// Fetches the single ParentalControlsModel instance, if it exists.
    func fetchParentalControls() async throws -> ParentalControlsModel?
    /// Saves or updates the ParentalControlsModel instance.
    func saveParentalControls(_ controls: ParentalControlsModel) async throws
}

@MainActor
class SettingsRepository: SettingsRepositoryProtocol {
    private let modelContext: ModelContext

    /// Initialize with a ModelContext
    /// - Parameter modelContext: The SwiftData model context to use for persistence operations
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - App Settings

    func fetchAppSettings() async throws -> AppSettingsModel? {
        // Fetch the single AppSettingsModel instance
        // Since we expect only one settings object, fetch without specific predicates.
        let descriptor = FetchDescriptor<AppSettingsModel>()
        // Assuming only one instance exists, fetch the first one
        return try modelContext.fetch(descriptor).first
    }

    func saveAppSettings(_ settings: AppSettingsModel) async throws {
        if let existing = try await fetchAppSettings() {
            // Update existing instance's properties
            existing.fontScale = settings.fontScale
            existing.hapticFeedbackEnabled = settings.hapticFeedbackEnabled
            existing.soundEffectsEnabled = settings.soundEffectsEnabled
            existing.darkModeEnabled = settings.darkModeEnabled
        } else {
            modelContext.insert(settings)
        }
        try modelContext.save()
    }

    // MARK: - Parental Controls

    func fetchParentalControls() async throws -> ParentalControlsModel? {
        // Fetch the single ParentalControlsModel instance
        let descriptor = FetchDescriptor<ParentalControlsModel>()
        // Assuming only one instance exists, fetch the first one
        return try modelContext.fetch(descriptor).first
    }

    func saveParentalControls(_ controls: ParentalControlsModel) async throws {
        if let existing = try await fetchParentalControls() {
            existing.contentFiltering = controls.contentFiltering
            existing.screenTimeEnabled = controls.screenTimeEnabled
            existing.maxStoriesPerDay = controls.maxStoriesPerDay
            existing.allowedThemes = controls.allowedThemes
            existing.minimumAge = controls.minimumAge
            existing.maximumAge = controls.maximumAge
        } else {
            modelContext.insert(controls)
        }
        try modelContext.save()
    }
}