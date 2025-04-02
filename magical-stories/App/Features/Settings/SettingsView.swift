import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settingsService: SettingsService
    
    @State private var childName = ""
    @State private var isDarkMode: Bool = false
    @State private var useTextToSpeech: Bool = true
    @State private var readingSpeed: Double = 1.0
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
                        .onChange(of: isDarkMode) { newValue in
                            var settings = settingsService.appSettings
                            settings.darkModeEnabled = newValue
                            settingsService.updateAppSettings(settings)
                        }
                    
                    Toggle("Text-to-Speech", isOn: $useTextToSpeech)
                        .onChange(of: useTextToSpeech) { newValue in
                            var settings = settingsService.appSettings
                            settings.textToSpeechEnabled = newValue
                            settingsService.updateAppSettings(settings)
                        }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reading Speed")
                            .font(Theme.Typography.bodyLarge)
                        
                        HStack {
                            Text("Slow")
                                .font(Theme.Typography.bodySmall)
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            Slider(value: $readingSpeed, in: 0.5...1.5, step: 0.1)
                                .onChange(of: readingSpeed) { newValue in
                                    var settings = settingsService.appSettings
                                    settings.readingSpeed = newValue
                                    settingsService.updateAppSettings(settings)
                                }
                            
                            Text("Fast")
                                .font(Theme.Typography.bodySmall)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                    }
                }
                
                // Parental Controls Section
                Section("Parental Controls") {
                    Toggle("Content Filtering", isOn: $contentFiltering)
                        .onChange(of: contentFiltering) { newValue in
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
                useTextToSpeech = settingsService.appSettings.textToSpeechEnabled
                readingSpeed = settingsService.appSettings.readingSpeed
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
