import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settingsService: SettingsService
    
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
    SettingsView()
        .environmentObject(SettingsService())
}
