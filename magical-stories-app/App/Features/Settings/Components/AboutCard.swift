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
                
                ShareAppButton(
                    title: R.string.localizable.settingsShareApp(),
                    appStoreId: "6747953770"
                )
                
                AboutLink(title: "Privacy Policy", url: AppConfig.privacyPolicyURL)
                
                AboutLink(title: "Terms of Service", url: AppConfig.termsOfUseURL)
            }
        }
    }
}