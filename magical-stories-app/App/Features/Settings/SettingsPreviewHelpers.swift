import SwiftUI
import SwiftData

// MARK: - Preview Helpers
extension SettingsView {
    /// Create a SwiftUI Preview
    static func createPreview() -> some View {
        // Create the preview model container
        let container = createPreviewModelContainer()

        // Return the view with dependencies
        return createPreviewView(container: container)
    }

    /// Helper function to create a preview model container
    private static func createPreviewModelContainer() -> ModelContainer {
        let schema = Schema([
            UserProfile.self,
            AppSettingsModel.self,
            ParentalControlsModel.self,
            Story.self,
            Page.self,
            AchievementModel.self,
        ])

        let config = ModelConfiguration(isStoredInMemoryOnly: true)

        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create preview ModelContainer: \(error)")
        }
    }

    /// Helper function to create the preview view with all dependencies
    @MainActor
    private static func createPreviewView(container: ModelContainer) -> some View {
        let settingsService = createSettingsService(container: container)

        return SettingsView()
            .modelContainer(container)
            .environmentObject(settingsService)
    }

    /// Helper function to create settings service
    @MainActor
    private static func createSettingsService(container: ModelContainer) -> SettingsService {
        let context = container.mainContext
        let userProfileRepo = UserProfileRepository(modelContext: context)
        let settingsRepo = SettingsRepository(modelContext: context)
        let usageService = UsageAnalyticsService(userProfileRepository: userProfileRepo)
        let settingsService = SettingsService(
            repository: settingsRepo, usageAnalyticsService: usageService)

        return settingsService
    }
}

// Default preview provider
#Preview {
    SettingsView.createPreview()
}