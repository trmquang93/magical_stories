import SwiftUI

/// View for managing content filters settings
struct ContentFiltersView: View {
    @EnvironmentObject private var settingsService: SettingsService
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedThemes: Set<StoryTheme>
    @Binding var minimumAge: Int
    @Binding var maximumAge: Int

    var body: some View {
        ZStack {
            UITheme.Colors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: UITheme.Spacing.xl) {
                    ageRangeCard
                    allowedThemesCard
                }
                .padding(.horizontal, UITheme.Spacing.lg)
                .padding(.vertical, UITheme.Spacing.xl)
            }
        }
        .navigationTitle("Content Filters")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Age Range Card
    private var ageRangeCard: some View {
        SettingsCard(title: "Age Range", icon: "person.2.fill") {
            VStack(spacing: UITheme.Spacing.lg) {
                minimumAgeRow
                maximumAgeRow
            }
        }
    }

    private var minimumAgeRow: some View {
        HStack {
            Text("Minimum Age")
                .font(UITheme.Typography.bodyMedium)
                .foregroundColor(UITheme.Colors.textPrimary)
            
            Spacer()
            
            Menu {
                ForEach(3...12, id: \.self) { age in
                    Button(action: {
                        minimumAge = age
                        handleMinimumAgeChange(age)
                    }) {
                        if minimumAge == age {
                            Label("\(age)", systemImage: "checkmark")
                        } else {
                            Text("\(age)")
                        }
                    }
                }
            } label: {
                HStack {
                    Text("\(minimumAge)")
                        .font(UITheme.Typography.bodyMedium)
                        .foregroundColor(UITheme.Colors.primary)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(UITheme.Colors.primary)
                }
                .padding(.horizontal, UITheme.Spacing.sm)
                .padding(.vertical, UITheme.Spacing.xs)
                .background(UITheme.Colors.surfaceSecondary)
                .cornerRadius(UITheme.Layout.cornerRadiusSmall)
            }
        }
    }

    private var maximumAgeRow: some View {
        HStack {
            Text("Maximum Age")
                .font(UITheme.Typography.bodyMedium)
                .foregroundColor(UITheme.Colors.textPrimary)
            
            Spacer()
            
            Menu {
                ForEach(minimumAge...15, id: \.self) { age in
                    Button(action: {
                        maximumAge = age
                        updateAgeRange()
                    }) {
                        if maximumAge == age {
                            Label("\(age)", systemImage: "checkmark")
                        } else {
                            Text("\(age)")
                        }
                    }
                }
            } label: {
                HStack {
                    Text("\(maximumAge)")
                        .font(UITheme.Typography.bodyMedium)
                        .foregroundColor(UITheme.Colors.primary)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(UITheme.Colors.primary)
                }
                .padding(.horizontal, UITheme.Spacing.sm)
                .padding(.vertical, UITheme.Spacing.xs)
                .background(UITheme.Colors.surfaceSecondary)
                .cornerRadius(UITheme.Layout.cornerRadiusSmall)
            }
        }
    }

    // MARK: - Allowed Themes Card
    private var allowedThemesCard: some View {
        SettingsCard(title: "Allowed Themes", icon: "tag.fill") {
            VStack(spacing: 0) {
                ForEach(StoryTheme.allCases) { theme in
                    themeRow(theme)
                    
                    if theme != StoryTheme.allCases.last {
                        Divider()
                            .padding(.leading, 32)
                    }
                }
            }
            .onChange(of: selectedThemes) { _, newValue in
                updateAllowedThemes(newValue)
            }
        }
    }

    private func themeRow(_ theme: StoryTheme) -> some View {
        Button(action: {
            toggleTheme(theme)
        }) {
            HStack(spacing: UITheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(UITheme.Colors.primary.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: theme.iconName)
                        .font(.system(size: 16))
                        .foregroundColor(UITheme.Colors.primary)
                }

                Text(theme.title)
                    .font(UITheme.Typography.bodyMedium)
                    .foregroundColor(UITheme.Colors.textPrimary)

                Spacer()

                if selectedThemes.contains(theme) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(UITheme.Colors.primary)
                } else {
                    Circle()
                        .strokeBorder(UITheme.Colors.textSecondary.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, UITheme.Spacing.sm)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helper Methods
    private func handleMinimumAgeChange(_ newValue: Int) {
        if newValue > maximumAge {
            maximumAge = newValue
        }
        updateAgeRange()
    }

    private func updateAllowedThemes(_ newValue: Set<StoryTheme>) {
        var controls = settingsService.parentalControls
        controls.allowedThemes = newValue
        settingsService.updateParentalControls(controls)
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