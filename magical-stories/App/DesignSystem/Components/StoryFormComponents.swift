import SwiftUI

// MARK: - MagicalTextField
struct MagicalTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(Theme.Typography.bodyMedium)
                .foregroundColor(Theme.Colors.textSecondary)
            
            TextField(placeholder, text: $text)
                .font(Theme.Typography.bodyLarge)
                .textFieldStyle(MagicalTextFieldStyle())
                .autocapitalization(.words)
        }
    }
}

// MARK: - MagicalSegmentedPicker
struct MagicalSegmentedPicker<T: Hashable>: View {
    let title: String
    let options: [(T, String)]
    @Binding var selection: T
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(Theme.Typography.bodyMedium)
                .foregroundColor(Theme.Colors.textSecondary)
            
            Picker(title, selection: $selection) {
                ForEach(options, id: \.0) { option in
                    Text(option.1)
                        .tag(option.0)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - MagicalEmojiPicker
struct MagicalEmojiPicker: View {
    let title: String
    @Binding var selection: String
    let emojis: [(String, String)] // (emoji, description)
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(Theme.Typography.bodyMedium)
                .foregroundColor(Theme.Colors.textSecondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(emojis, id: \.0) { emoji in
                        EmojiButton(
                            emoji: emoji.0,
                            description: emoji.1,
                            isSelected: selection == emoji.0
                        ) {
                            selection = emoji.0
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.xs)
            }
        }
    }
}

// MARK: - MagicalThemePicker
struct MagicalThemePicker: View {
    let title: String
    @Binding var selection: StoryTheme
    let themes: [StoryTheme]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(Theme.Typography.bodyMedium)
                .foregroundColor(Theme.Colors.textSecondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(themes) { theme in
                        ThemeButton(
                            theme: theme,
                            isSelected: selection == theme
                        ) {
                            selection = theme
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.xs)
            }
        }
    }
}

// MARK: - Supporting Views
private struct EmojiButton: View {
    let emoji: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.xxs) {
                Text(emoji)
                    .font(.system(size: 32))
                Text(description)
                    .font(Theme.Typography.bodySmall)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .frame(width: 64, height: 80)
            .background(
                RoundedRectangle(cornerRadius: Theme.Layout.cornerRadiusMedium)
                    .fill(isSelected ? Theme.Colors.surfaceSecondary : Theme.Colors.surfacePrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Layout.cornerRadiusMedium)
                            .strokeBorder(
                                isSelected ? Theme.Colors.primary : Theme.Colors.surfaceSecondary,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ThemeButton: View {
    let theme: StoryTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: theme.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.textPrimary)
                Text(theme.title)
                    .font(Theme.Typography.bodySmall)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: Theme.Layout.cornerRadiusMedium)
                    .fill(isSelected ? Theme.Colors.surfaceSecondary : Theme.Colors.surfacePrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Layout.cornerRadiusMedium)
                            .strokeBorder(
                                isSelected ? Theme.Colors.primary : Theme.Colors.surfaceSecondary,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Custom Styles
struct MagicalTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surfacePrimary)
            .cornerRadius(Theme.Layout.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Layout.cornerRadiusMedium)
                    .strokeBorder(Theme.Colors.surfaceSecondary, lineWidth: 1)
            )
    }
}

// MARK: - Preview
struct StoryFormComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Theme.Spacing.lg) {
            MagicalTextField(
                title: "Child's Name",
                placeholder: "Enter name",
                text: .constant("Alex")
            )
            
            MagicalSegmentedPicker(
                title: "Age Group",
                options: [(3, "3-5"), (6, "6-8"), (9, "9-10")],
                selection: .constant(6)
            )
            
            MagicalEmojiPicker(
                title: "Favorite Character",
                selection: .constant("🦁"),
                emojis: [
                    ("🦁", "Lion"),
                    ("🐯", "Tiger"),
                    ("🐘", "Elephant"),
                    ("🦊", "Fox"),
                    ("🐼", "Panda")
                ]
            )
            
            MagicalThemePicker(
                title: "Story Theme",
                selection: .constant(StoryTheme.adventure),
                themes: StoryTheme.allCases
            )
        }
        .padding()
    }
}

// MARK: - Models
enum StoryTheme: String, CaseIterable, Identifiable, Codable {
    case adventure
    case friendship
    case learning
    case courage
    case kindness
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .adventure: return "Adventure"
        case .friendship: return "Friendship"
        case .learning: return "Learning"
        case .courage: return "Courage"
        case .kindness: return "Kindness"
        }
    }
    
    var iconName: String {
        switch self {
        case .adventure: return "map"
        case .friendship: return "heart"
        case .learning: return "book"
        case .courage: return "star"
        case .kindness: return "hand.wave"
        }
    }
} 
