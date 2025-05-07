import SwiftUI

/// Preferences section card for settings
struct PreferencesCard: View {
    @EnvironmentObject private var settingsService: SettingsService
    @Binding var isDarkMode: Bool
    @Binding var fontScale: Double
    @Binding var hapticFeedbackEnabled: Bool
    @Binding var soundEffectsEnabled: Bool
    
    var body: some View {
        SettingsCard(title: "Preferences", icon: "gear") {
            VStack(spacing: UITheme.Spacing.md) {
                EnhancedToggle(title: "Dark Mode", isOn: $isDarkMode) { newValue in
                    var settings = settingsService.appSettings
                    settings.darkModeEnabled = newValue
                    settingsService.updateAppSettings(settings)
                }
                
                EnhancedToggle(title: "Haptic Feedback", isOn: $hapticFeedbackEnabled) { newValue in
                    var settings = settingsService.appSettings
                    settings.hapticFeedbackEnabled = newValue
                    settingsService.updateAppSettings(settings)
                }
                
                EnhancedToggle(title: "Sound Effects", isOn: $soundEffectsEnabled) { newValue in
                    var settings = settingsService.appSettings
                    settings.soundEffectsEnabled = newValue
                    settingsService.updateAppSettings(settings)
                }
                
                fontSizeSlider
            }
        }
    }
    
    private var fontSizeSlider: some View {
        VStack(alignment: .leading, spacing: UITheme.Spacing.xs) {
            Text("Text Size")
                .font(UITheme.Typography.bodyMedium)
                .foregroundColor(UITheme.Colors.textPrimary)

            HStack(spacing: UITheme.Spacing.sm) {
                Text("A")
                    .font(UITheme.Typography.bodySmall)
                    .foregroundColor(UITheme.Colors.textSecondary)

                Slider(value: $fontScale, in: 0.8...1.3, step: 0.1)
                    .accentColor(UITheme.Colors.primary)
                    .onChange(of: fontScale) { _, newValue in
                        var settings = settingsService.appSettings
                        settings.fontScale = newValue
                        settingsService.updateAppSettings(settings)
                    }

                Text("A")
                    .font(UITheme.Typography.headingLarge)
                    .foregroundColor(UITheme.Colors.textSecondary)
            }
        }
    }
}