import SwiftUI

struct SettingsView: View {
    @State private var isDarkMode = false
    @State private var useTextToSpeech = true
    
    var body: some View {
        NavigationStack {
            Form {
                // Profile Section
                Section("Profile") {
                    TextField("Child's Name", text: .constant(""))
                        .font(Theme.Typography.bodyLarge)
                }
                
                // Preferences Section
                Section("Preferences") {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                    Toggle("Text-to-Speech", isOn: $useTextToSpeech)
                }
                
                // Parental Controls Section
                Section("Parental Controls") {
                    NavigationLink("Content Filters") {
                        Text("Content Filters")
                    }
                    NavigationLink("Screen Time") {
                        Text("Screen Time")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
