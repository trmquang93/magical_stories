import SwiftUI

// MARK: - MagicalTextField
struct MagicalTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: UITheme.Spacing.xs) {
            Text(title)
                .font(UITheme.Typography.bodyMedium)
                .foregroundColor(UITheme.Colors.textSecondary)
            
            TextField(placeholder, text: $text)
                .font(UITheme.Typography.bodyLarge)
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
        VStack(alignment: .leading, spacing: UITheme.Spacing.xs) {
            Text(title)
                .font(UITheme.Typography.bodyMedium)
                .foregroundColor(UITheme.Colors.textSecondary)
            
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
        VStack(alignment: .leading, spacing: UITheme.Spacing.xs) {
            Text(title)
                .font(UITheme.Typography.bodyMedium)
                .foregroundColor(UITheme.Colors.textSecondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: UITheme.Spacing.sm) {
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
                .padding(.horizontal, UITheme.Spacing.xs)
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
        VStack(alignment: .leading, spacing: UITheme.Spacing.xs) {
            Text(title)
                .font(UITheme.Typography.bodyMedium)
                .foregroundColor(UITheme.Colors.textSecondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: UITheme.Spacing.sm) {
                    ForEach(StoryTheme.allCases) { theme in
                        ThemeButton(
                            theme: theme,
                            isSelected: selection == theme
                        ) {
                            selection = theme
                        }
                    }
                }
                .padding(.horizontal, UITheme.Spacing.xs)
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
            VStack(spacing: UITheme.Spacing.xxs) {
                Text(emoji)
                    .font(.system(size: 32))
                Text(description)
                    .font(UITheme.Typography.bodySmall)
                    .foregroundColor(UITheme.Colors.textSecondary)
            }
            .frame(width: 64, height: 80)
            .background(
                RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusMedium)
                    .fill(isSelected ? UITheme.Colors.surfaceSecondary : UITheme.Colors.surfacePrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusMedium)
                            .strokeBorder(
                                isSelected ? UITheme.Colors.primary : UITheme.Colors.surfaceSecondary,
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
            VStack(spacing: UITheme.Spacing.xxs) {
                Image(systemName: theme.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? UITheme.Colors.primary : UITheme.Colors.textPrimary)
                Text("UITheme.title")
                    .font(UITheme.Typography.bodySmall)
                    .foregroundColor(UITheme.Colors.textSecondary)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusMedium)
                    .fill(isSelected ? UITheme.Colors.surfaceSecondary : UITheme.Colors.surfacePrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusMedium)
                            .strokeBorder(
                                isSelected ? UITheme.Colors.primary : UITheme.Colors.surfaceSecondary,
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
            .padding(UITheme.Spacing.md)
            .background(UITheme.Colors.surfacePrimary)
            .cornerRadius(UITheme.Layout.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusMedium)
                    .strokeBorder(UITheme.Colors.surfaceSecondary, lineWidth: 1)
            )
    }
}

// MARK: - Preview
struct StoryFormComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: UITheme.Spacing.lg) {
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
enum StoryTheme: String, CaseIterable, Identifiable, Codable, Sendable {
    case adventure
    case friendship
    case learning
    case courage
    case kindness
    case nature
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .adventure: return "Adventure"
        case .friendship: return "Friendship"
        case .learning: return "Learning"
        case .courage: return "Courage"
        case .kindness: return "Kindness"
        case .nature: return "Nature"
        }
    }
    
    var iconName: String {
        switch self {
        case .adventure: return "map"
        case .friendship: return "heart"
        case .learning: return "book"
        case .courage: return "star"
        case .kindness: return "hand.wave"
        case .nature: return "leaf"
        }
    }
}
