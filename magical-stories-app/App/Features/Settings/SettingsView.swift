import Foundation
import SwiftData
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settingsService: SettingsService
    @Environment(\.colorScheme) private var colorScheme

    @State private var childName = ""
    @State private var isDarkMode: Bool = false
    @State private var contentFiltering: Bool = true
    @State private var screenTimeEnabled: Bool = false
    @State private var maxStoriesPerDay: Int = 3
    @State private var minimumAge: Int = 3
    @State private var maximumAge: Int = 10
    @State private var fontScale: Double = 1.0
    @State private var hapticFeedbackEnabled: Bool = true
    @State private var soundEffectsEnabled: Bool = true
    @State private var selectedThemes: Set<StoryTheme> = Set(StoryTheme.allCases)

    var body: some View {
        NavigationStack {
            Form {
                // Profile Section
                Section("Profile") {
                    TextField("Child's Name", text: $childName)
                        .font(Theme.Fonts.bodyMedium)
                        .onSubmit {
                            UserDefaults.standard.set(childName, forKey: "childName")
                        }
                }

                // Preferences Section
                Section("Preferences") {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                        .onChange(of: isDarkMode) { _, newValue in
                            var settings = settingsService.appSettings
                            settings.darkModeEnabled = newValue
                            settingsService.updateAppSettings(settings)
                        }

                    Toggle("Haptic Feedback", isOn: $hapticFeedbackEnabled)
                        .onChange(of: hapticFeedbackEnabled) { _, newValue in
                            var settings = settingsService.appSettings
                            settings.hapticFeedbackEnabled = newValue
                            settingsService.updateAppSettings(settings)
                        }

                    Toggle("Sound Effects", isOn: $soundEffectsEnabled)
                        .onChange(of: soundEffectsEnabled) { _, newValue in
                            var settings = settingsService.appSettings
                            settings.soundEffectsEnabled = newValue
                            settingsService.updateAppSettings(settings)
                        }

                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Text Size")

                        HStack {
                            Text("A")
                                .font(Theme.Fonts.caption)

                            Slider(value: $fontScale, in: 0.8...1.3, step: 0.1)
                                .onChange(of: fontScale) { _, newValue in
                                    var settings = settingsService.appSettings
                                    settings.fontScale = newValue
                                    settingsService.updateAppSettings(settings)
                                }

                            Text("A")
                                .font(Theme.Fonts.header)
                        }
                    }
                }

                // Parental Controls Section
                Section("Parental Controls") {
                    Toggle("Content Filtering", isOn: $contentFiltering)
                        .onChange(of: contentFiltering) { _, newValue in
                            var controls = settingsService.parentalControls
                            controls.contentFiltering = newValue
                            settingsService.updateParentalControls(controls)
                        }

                    Toggle("Screen Time Limits", isOn: $screenTimeEnabled)
                        .onChange(of: screenTimeEnabled) { _, newValue in
                            var controls = settingsService.parentalControls
                            controls.screenTimeEnabled = newValue
                            settingsService.updateParentalControls(controls)
                        }

                    if screenTimeEnabled {
                        Stepper(value: $maxStoriesPerDay, in: 1...10) {
                            HStack {
                                Text("Max Stories Per Day")
                                Spacer()
                                Text("\(maxStoriesPerDay)")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onChange(of: maxStoriesPerDay) { _, newValue in
                            var controls = settingsService.parentalControls
                            controls.maxStoriesPerDay = newValue
                            settingsService.updateParentalControls(controls)
                        }
                    }

                    NavigationLink("Content Filters") {
                        ContentFiltersView(
                            selectedThemes: $selectedThemes, minimumAge: $minimumAge,
                            maximumAge: $maximumAge)
                    }
                }

                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://www.magical-stories.app/privacy")!) {
                        Text("Privacy Policy")
                    }

                    Link(destination: URL(string: "https://www.magical-stories.app/terms")!) {
                        Text("Terms of Service")
                    }
                }
            }
            .navigationTitle("Settings")
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

// MARK: - Content Filters View
struct ContentFiltersView: View {
    @EnvironmentObject private var settingsService: SettingsService
    @Binding var selectedThemes: Set<StoryTheme>
    @Binding var minimumAge: Int
    @Binding var maximumAge: Int

    var body: some View {
        Form {
            ageRangeSection
            allowedThemesSection
        }
        .navigationTitle("Content Filters")
    }

    // Extract age range section to simplify the body
    private var ageRangeSection: some View {
        Section("Age Range") {
            minimumAgeRow
            maximumAgeRow
        }
    }

    // Extract minimum age row to simplify the body
    private var minimumAgeRow: some View {
        HStack {
            Text("Minimum Age")
            Spacer()
            minimumAgePicker
        }
        .onChange(of: minimumAge) { _, newValue in
            handleMinimumAgeChange(newValue)
        }
    }

    // Extract picker to simplify the row
    private var minimumAgePicker: some View {
        Picker("", selection: $minimumAge) {
            ForEach(3...12, id: \.self) { age in
                Text("\(age)").tag(age)
            }
        }
        .pickerStyle(.menu)
        .frame(width: 80)
    }

    // Extract maximum age row to simplify the body
    private var maximumAgeRow: some View {
        HStack {
            Text("Maximum Age")
            Spacer()
            maximumAgePicker
        }
        .onChange(of: maximumAge) { _, newValue in
            updateAgeRange()
        }
    }

    // Extract picker to simplify the row
    private var maximumAgePicker: some View {
        Picker("", selection: $maximumAge) {
            ForEach(minimumAge...15, id: \.self) { age in
                Text("\(age)").tag(age)
            }
        }
        .pickerStyle(.menu)
        .frame(width: 80)
    }

    // Extract allowed themes section to simplify the body
    private var allowedThemesSection: some View {
        Section("Allowed Themes") {
            ForEach(StoryTheme.allCases) { theme in
                themeRow(theme)
            }
        }
        .onChange(of: selectedThemes) { _, newValue in
            updateAllowedThemes(newValue)
        }
    }

    // Extract theme row to simplify the section
    private func themeRow(_ theme: StoryTheme) -> some View {
        Button(action: {
            toggleTheme(theme)
        }) {
            HStack {
                Image(systemName: theme.iconName)
                    .foregroundColor(Theme.Colors.appPrimary)

                Text(theme.title)

                Spacer()

                if selectedThemes.contains(theme) {
                    Image(systemName: "checkmark")
                        .foregroundColor(Theme.Colors.appPrimary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // Helper methods
    private func handleMinimumAgeChange(_ newValue: Int) {
        if newValue > maximumAge {
            maximumAge = newValue
        }
        updateAgeRange()
    }

    private func updateAllowedThemes(_ newValue: Set<StoryTheme>) {
        var controls = settingsService.parentalControls
        controls.allowedThemes = newValue
        settingsService.updateParentalControls(controls)
    }

    private func toggleTheme(_ theme: StoryTheme) {
        if selectedThemes.contains(theme) {
            // Only allow deselection if at least one theme remains selected
            if selectedThemes.count > 1 {
                selectedThemes.remove(theme)
            }
        } else {
            selectedThemes.insert(theme)
        }
    }

    private func updateAgeRange() {
        var controls = settingsService.parentalControls
        controls.minimumAge = minimumAge
        controls.maximumAge = maximumAge
        settingsService.updateParentalControls(controls)
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
