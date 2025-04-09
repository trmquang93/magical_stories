import Foundation
import SwiftData

// Protocol defining the operations for settings persistence
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

// Implementation using SwiftData's ModelContext
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
        // Check if an instance already exists to avoid duplicates.
        // If it exists, SwiftData tracks changes automatically.
        // If not, insert the new one.
        if try await fetchAppSettings() == nil {
            modelContext.insert(settings)
        }
        // Save changes (either insert or update modifications)
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
        // Check if an instance already exists.
        if try await fetchParentalControls() == nil {
            modelContext.insert(controls)
        }
        // Save changes (either insert or update modifications)
        try modelContext.save()
    }
}