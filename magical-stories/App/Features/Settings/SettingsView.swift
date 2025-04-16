import SwiftUI
import SwiftData
import Foundation

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
                        .font(Theme.Typography.bodyLarge)
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
                                .font(Theme.Typography.bodySmall)
                            
                            Slider(value: $fontScale, in: 0.8...1.3, step: 0.1)
                                .onChange(of: fontScale) { _, newValue in
                                    var settings = settingsService.appSettings
                                    settings.fontScale = newValue
                                    settingsService.updateAppSettings(settings)
                                }
                            
                            Text("A")
                                .font(Theme.Typography.bodyLarge)
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
                        ContentFiltersView(selectedThemes: $selectedThemes, minimumAge: $minimumAge, maximumAge: $maximumAge)
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
            Section("Age Range") {
                HStack {
                    Text("Minimum Age")
                    Spacer()
                    Picker("", selection: $minimumAge) {
                        ForEach(3...12, id: \.self) { age in
                            Text("\(age)").tag(age)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 80)
                }
                .onChange(of: minimumAge) { _, newValue in
                    if newValue > maximumAge {
                        maximumAge = newValue
                    }
                    updateAgeRange()
                }
                
                HStack {
                    Text("Maximum Age")
                    Spacer()
                    Picker("", selection: $maximumAge) {
                        ForEach(minimumAge...15, id: \.self) { age in
                            Text("\(age)").tag(age)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 80)
                }
                .onChange(of: maximumAge) { _, newValue in
                    updateAgeRange()
                }
            }
            
            Section("Allowed Themes") {
                ForEach(StoryTheme.allCases) { theme in
                    Button(action: {
                        toggleTheme(theme)
                    }) {
                        HStack {
                            Image(systemName: theme.iconName)
                                .foregroundColor(Theme.Colors.primary)
                            
                            Text(theme.title)
                            
                            Spacer()
                            
                            if selectedThemes.contains(theme) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Theme.Colors.primary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .onChange(of: selectedThemes) { _, newValue in
                var controls = settingsService.parentalControls
                controls.allowedThemes = newValue
                settingsService.updateParentalControls(controls)
            }
        }
        .navigationTitle("Content Filters")
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

#Preview {
    // Define a helper function or struct for preview setup if it gets complex,
    // or perform setup directly before returning the view.
    // Using a simple direct setup here:
    let container: ModelContainer = {
        // Define the schema including all necessary models for the preview context
        let schema = Schema([
            UserProfile.self,
            AppSettingsModel.self,
            ParentalControlsModel.self,
            StoryModel.self, // Use the @Model class
            PageModel.self,    // Use the @Model class
            AchievementModel.self // Use the @Model class
        ])
        // Configure for in-memory storage
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            // Create the container
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            // Handle potential errors during container creation
            fatalError("Failed to create preview ModelContainer: \(error)")
        }
    }() // Immediately execute the closure to get the container

    // Create instances of repositories and services needed for the preview
    let context = container.mainContext
    let userProfileRepo = UserProfileRepository(modelContext: context)
    let settingsRepo = SettingsRepository(modelContext: context)
    let usageService = UsageAnalyticsService(userProfileRepository: userProfileRepo)
    let settingsService = SettingsService(repository: settingsRepo, usageAnalyticsService: usageService)

    // Return the view, injecting the container and environment objects
    // No explicit 'return' needed here due to ViewBuilder
    SettingsView()
        .modelContainer(container) // Provide the in-memory container
        .environmentObject(settingsService) // Provide the initialized service
}
