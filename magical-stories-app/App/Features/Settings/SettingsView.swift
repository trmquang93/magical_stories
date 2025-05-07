import Foundation
import SwiftData
import SwiftUI

/// Main settings view for the application
struct SettingsView: View {
    @EnvironmentObject private var settingsService: SettingsService
    @Environment(\.colorScheme) private var colorScheme

    // User profile settings
    @State private var childName = ""
    
    // App preferences
    @State private var isDarkMode: Bool = false
    @State private var fontScale: Double = 1.0
    @State private var hapticFeedbackEnabled: Bool = true
    @State private var soundEffectsEnabled: Bool = true
    
    // Parental Controls
    @State private var contentFiltering: Bool = true
    @State private var screenTimeEnabled: Bool = false
    @State private var maxStoriesPerDay: Int = 3
    @State private var minimumAge: Int = 3
    @State private var maximumAge: Int = 10
    @State private var selectedThemes: Set<StoryTheme> = Set(StoryTheme.allCases)

    var body: some View {
        NavigationStack {
            ZStack {
                UITheme.Colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UITheme.Spacing.lg) {
                        ProfileCard(childName: $childName)
                        
                        ParentalControlsCard(
                            contentFiltering: $contentFiltering,
                            screenTimeEnabled: $screenTimeEnabled,
                            maxStoriesPerDay: $maxStoriesPerDay,
                            minimumAge: $minimumAge,
                            maximumAge: $maximumAge,
                            selectedThemes: $selectedThemes
                        )
                        
                        AboutCard()
                    }
                    .padding(.horizontal, UITheme.Spacing.lg)
                    .padding(.vertical, UITheme.Spacing.xl)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Load all settings when view appears
                loadAllSettings()
            }
            .onChange(of: colorScheme) { _, _ in
                // Refresh dark mode setting when system appearance changes
                isDarkMode = settingsService.appSettings.darkModeEnabled
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Load all settings from the service
    private func loadAllSettings() {
        // Load app settings
        isDarkMode = settingsService.appSettings.darkModeEnabled
        fontScale = settingsService.appSettings.fontScale
        hapticFeedbackEnabled = settingsService.appSettings.hapticFeedbackEnabled
        soundEffectsEnabled = settingsService.appSettings.soundEffectsEnabled

        // Load parental controls
        contentFiltering = settingsService.parentalControls.contentFiltering
        screenTimeEnabled = settingsService.parentalControls.screenTimeEnabled
        maxStoriesPerDay = settingsService.parentalControls.maxStoriesPerDay
        minimumAge = settingsService.parentalControls.minimumAge
        maximumAge = settingsService.parentalControls.maximumAge
        selectedThemes = settingsService.parentalControls.allowedThemes

        // Load child name from user defaults
        childName = UserDefaults.standard.string(forKey: "childName") ?? ""
    }
}

// MARK: - Preview Helpers
// Break down the preview setup into smaller functions to help the compiler with type checking
#Preview {
    // Create the preview model container
    let container = createPreviewModelContainer()

    // Return the view with dependencies using a separate function for actor-isolated work
    return createPreviewView(container: container)
}

// Helper function to create a preview model container
private func createPreviewModelContainer() -> ModelContainer {
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

// Helper function to create the view with all dependencies
@MainActor  // Mark this function as running on the main actor
private func createPreviewView(container: ModelContainer) -> some View {
    let settingsService = createSettingsService(container: container)

    return SettingsView()
        .modelContainer(container)
        .environmentObject(settingsService)
}

// Helper function to create settings service
@MainActor  // Mark this function as running on the main actor
private func createSettingsService(container: ModelContainer) -> SettingsService {
    let context = container.mainContext
    let userProfileRepo = UserProfileRepository(modelContext: context)
    let settingsRepo = SettingsRepository(modelContext: context)
    let usageService = UsageAnalyticsService(userProfileRepository: userProfileRepo)
    let settingsService = SettingsService(
        repository: settingsRepo, usageAnalyticsService: usageService)

    return settingsService
}
