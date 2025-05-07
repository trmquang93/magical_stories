import SwiftUI

/// Profile section card for settings
struct ProfileCard: View {
    @Binding var childName: String
    
    var body: some View {
        SettingsCard(title: "Profile", icon: "person.circle.fill") {
            VStack(spacing: UITheme.Spacing.md) {
                MagicalTextField(
                    title: "Child's Name",
                    placeholder: "Enter child's name",
                    text: $childName
                )
                .onChange(of: childName) { _, newValue in
                    UserDefaults.standard.set(newValue, forKey: "childName")
                }
            }
        }
    }
}