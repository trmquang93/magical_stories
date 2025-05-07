import SwiftUI

/// About section card for settings
struct AboutCard: View {
    var body: some View {
        SettingsCard(title: "About", icon: "info.circle.fill") {
            VStack(spacing: UITheme.Spacing.lg) {
                HStack {
                    Text("Version")
                        .font(UITheme.Typography.bodyMedium)
                        .foregroundColor(UITheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    Text("1.0.0")
                        .font(UITheme.Typography.bodyMedium)
                        .foregroundColor(UITheme.Colors.textSecondary)
                }
                
                AboutLink(title: "Privacy Policy", url: "https://www.magical-stories.app/privacy")
                
                AboutLink(title: "Terms of Service", url: "https://www.magical-stories.app/terms")
            }
        }
    }
}