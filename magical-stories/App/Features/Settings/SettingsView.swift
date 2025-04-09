import SwiftUI
import SwiftData
@testable import magical_stories
// Add necessary imports
import Foundation
// Assuming direct access to these modules/files based on project structure
// Adjust paths or use `@_exported import ModuleName` in App file if needed
// import Models // If models are in a separate module
// import Services
// import Repositories
// import DesignSystem

struct SettingsView: View {
    @EnvironmentObject private var settingsService: SettingsService // Keep this, assuming it will resolve
    
    @State private var childName = ""
    @State private var isDarkMode: Bool = false
    @State private var contentFiltering: Bool = true
    
    var body: some View {
        NavigationStack {
            Form {
                // Profile Section
                Section("Profile") {
                    TextField("Child's Name", text: $childName)
                        .font(Theme.Typography.bodyLarge)
                        .onSubmit {
                            // Save child name in user defaults
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
                    
                }
                
                // Parental Controls Section
                Section("Parental Controls") {
                    Toggle("Content Filtering", isOn: $contentFiltering)
                        .onChange(of: contentFiltering) { _, newValue in
                            var controls = settingsService.parentalControls
                            controls.contentFiltering = newValue
                            settingsService.updateParentalControls(controls)
                        }
                    
                    NavigationLink("Content Filters") {
                        Text("Content Filters Settings")
                            .navigationTitle("Content Filters")
                    }
                    
                    NavigationLink("Screen Time") {
                        Text("Screen Time Settings")
                            .navigationTitle("Screen Time")
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
                // Load settings when view appears
                isDarkMode = settingsService.appSettings.darkModeEnabled
                contentFiltering = settingsService.parentalControls.contentFiltering
                
                // Load child name from user defaults
                childName = UserDefaults.standard.string(forKey: "childName") ?? ""
            }
        }
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
