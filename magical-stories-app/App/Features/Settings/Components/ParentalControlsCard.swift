import SwiftUI

/// Parental Controls section card for settings
struct ParentalControlsCard: View {
    @EnvironmentObject private var settingsService: SettingsService
    @Binding var contentFiltering: Bool
    @Binding var screenTimeEnabled: Bool
    @Binding var maxStoriesPerDay: Int
    @Binding var minimumAge: Int
    @Binding var maximumAge: Int
    @Binding var selectedThemes: Set<StoryTheme>
    
    var body: some View {
        SettingsCard(title: "Parental Controls", icon: "lock.fill") {
            VStack(spacing: UITheme.Spacing.md) {
                EnhancedToggle(title: "Content Filtering", isOn: $contentFiltering) { newValue in
                    var controls = settingsService.parentalControls
                    controls.contentFiltering = newValue
                    settingsService.updateParentalControls(controls)
                }
                
                EnhancedToggle(title: "Screen Time Limits", isOn: $screenTimeEnabled) { newValue in
                    var controls = settingsService.parentalControls
                    controls.screenTimeEnabled = newValue
                    settingsService.updateParentalControls(controls)
                }
                
                if screenTimeEnabled {
                    CounterStepper(
                        title: "Max Stories Per Day",
                        value: $maxStoriesPerDay,
                        range: 1...10
                    ) { newValue in
                        var controls = settingsService.parentalControls
                        controls.maxStoriesPerDay = newValue
                        settingsService.updateParentalControls(controls)
                    }
                }
                
                contentFiltersLink
            }
        }
    }
    
    private var contentFiltersLink: some View {
        NavigationLink {
            ContentFiltersView(
                selectedThemes: $selectedThemes,
                minimumAge: $minimumAge,
                maximumAge: $maximumAge
            )
        } label: {
            HStack {
                Text("Content Filters")
                    .font(UITheme.Typography.bodyMedium)
                    .foregroundColor(UITheme.Colors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(UITheme.Colors.textSecondary)
            }
        }
    }
}