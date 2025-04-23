import SwiftUI

// MARK: - FormField
/// A reusable form field wrapper with icon for Story Form
struct FormField<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Title with icon
            HStack(spacing: Theme.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#7B61FF").opacity(0.2),
                                    Color(hex: "#FF617B").opacity(0.2),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)

                    Image(systemName: systemImage)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#7B61FF"))
                }

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(
                        colorScheme == .light ? Color(hex: "#4A5568") : Color(hex: "#E2E8F0"))
            }

            content
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
}

// MARK: - MagicTextField
/// Enhanced text field with animations for Story Form
struct MagicTextField: View {
    let placeholder: String
    @Binding var text: String
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(Color(hex: "#A0AEC0"))
                    .font(.system(size: 16))
                    .padding(.horizontal, Theme.Spacing.lg)
                    .opacity(isFocused ? 0 : 1)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            }

            TextField("", text: $text)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.lg)
                .font(.system(size: 16))
                .foregroundColor(
                    colorScheme == .light ? Color(hex: "#4A5568") : Color(hex: "#E2E8F0")
                )
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.standard)
                        .fill(colorScheme == .light ? .white : Color(hex: "#1F2937"))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.standard)
                        .stroke(
                            isFocused
                                ? LinearGradient(
                                    colors: [Color(hex: "#7B61FF"), Color(hex: "#FF617B")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [
                                        colorScheme == .light
                                            ? Color(hex: "#E2E8F0") : Color(hex: "#374151"),
                                        colorScheme == .light
                                            ? Color(hex: "#E2E8F0") : Color(hex: "#374151"),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                            lineWidth: isFocused ? 2 : 1
                        )
                )
                .shadow(
                    color: isFocused ? Color(hex: "#7B61FF").opacity(0.2) : Color.clear, radius: 4,
                    x: 0, y: 2
                )
                .focused($isFocused)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}

// MARK: - EnhancedThemeCard
/// Card view for displaying and selecting story themes
struct EnhancedThemeCard: View {
    let theme: StoryTheme
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    private var iconName: String {
        switch theme {
        case .adventure: return "mountain.2.fill"
        case .friendship: return "heart.fill"
        case .learning: return "book.fill"
        case .courage: return "shield.lefthalf.filled"
        case .kindness: return "hand.wave.fill"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.sm) {
                // Icon with animated background
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? LinearGradient(
                                    colors: [Color(hex: "#7B61FF"), Color(hex: "#FF617B")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [
                                        colorScheme == .light ? .white : Color(hex: "#2D3748"),
                                        colorScheme == .light ? .white : Color(hex: "#2D3748"),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: iconName)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .white : Color(hex: "#7B61FF"))
                }

                Text(theme.title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(
                        isSelected
                            ? (colorScheme == .light
                                ? Color(hex: "#4A5568") : Color(hex: "#E2E8F0"))
                            : (colorScheme == .light
                                ? Color(hex: "#718096") : Color(hex: "#A0AEC0"))
                    )
                    .multilineTextAlignment(.center)

                // Description
                Text(themeDescription(for: theme))
                    .font(.system(size: 12))
                    .foregroundColor(
                        isSelected
                            ? (colorScheme == .light
                                ? Color(hex: "#718096") : Color(hex: "#A0AEC0"))
                            : (colorScheme == .light
                                ? Color(hex: "#A0AEC0") : Color(hex: "#718096"))
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 160)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.standard)
                    .fill(colorScheme == .light ? .white : Color(hex: "#1F2937"))
            )
            .overlay(
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.standard)
                        .stroke(
                            isSelected
                                ? LinearGradient(
                                    colors: [Color(hex: "#7B61FF"), Color(hex: "#FF617B")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [
                                        colorScheme == .light
                                            ? Color(hex: "#E2E8F0") : Color(hex: "#374151"),
                                        colorScheme == .light
                                            ? Color(hex: "#E2E8F0") : Color(hex: "#374151"),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                            lineWidth: isSelected ? 2 : 1
                        )

                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#7B61FF"), Color(hex: "#FF617B")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .position(x: 16, y: 16)
                    }
                }
            )
            .shadow(
                color: isSelected
                    ? (colorScheme == .light ? Color(hex: "#7B61FF").opacity(0.2) : Color.clear)
                    : (colorScheme == .light ? Color.black.opacity(0.05) : Color.clear),
                radius: 4, x: 0, y: 2
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(
            minimumDuration: .infinity, maximumDistance: .infinity,
            pressing: { pressing in
                isPressed = pressing
            }, perform: {})
    }

    private func themeDescription(for theme: StoryTheme) -> String {
        switch theme {
        case .adventure: return "Epic journeys and discovery"
        case .friendship: return "Bonds and relationships"
        case .learning: return "Knowledge and wisdom"
        case .courage: return "Bravery and strength"
        case .kindness: return "Compassion and empathy"
        }
    }
}

// MARK: - EnhancedSegmentedButtonStyle
/// Button style for segmented controls in Story Form
struct EnhancedSegmentedButtonStyle: ButtonStyle {
    let isSelected: Bool
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
            .padding(.vertical, Theme.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.standard)
                    .fill(
                        isSelected
                            ? AnyShapeStyle(LinearGradient(
                                colors: [Color(hex: "#7B61FF"), Color(hex: "#FF617B")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              ))
                            : AnyShapeStyle(colorScheme == .light ? Color.white : Color(hex: "#1F2937"))
                    )
            )
            .foregroundColor(
                isSelected
                    ? .white
                    : (colorScheme == .light ? Color(hex: "#718096") : Color(hex: "#A0AEC0"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.standard)
                    .stroke(
                        isSelected
                            ? Color.clear
                            : (colorScheme == .light
                                ? Color(hex: "#E2E8F0") : Color(hex: "#374151")),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isSelected
                    ? (colorScheme == .light ? Color(hex: "#7B61FF").opacity(0.2) : Color.clear)
                    : Color.clear,
                radius: 4, x: 0, y: 2
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - EnhancedLanguagePicker
/// Custom language selector for Story Form
struct EnhancedLanguagePicker: View {
    let languages: [(String, String)]
    @Binding var selection: String
    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded = false

    var selectedLanguageName: String {
        languages.first(where: { $0.0 == selection })?.1 ?? "English"
    }

    var body: some View {
        VStack {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "globe")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#7B61FF"))
                        .padding(.trailing, 4)

                    Text(selectedLanguageName)
                        .font(.system(size: 16))
                        .foregroundColor(
                            colorScheme == .light ? Color(hex: "#4A5568") : Color(hex: "#E2E8F0"))

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(
                            colorScheme == .light ? Color(hex: "#A0AEC0") : Color(hex: "#718096")
                        )
                        .rotationEffect(Angle(degrees: isExpanded ? 180 : 0))
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.standard)
                        .fill(colorScheme == .light ? .white : Color(hex: "#1F2937"))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.standard)
                        .stroke(
                            colorScheme == .light ? Color(hex: "#E2E8F0") : Color(hex: "#374151"),
                            lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(languages, id: \.0) { language in
                            Button {
                                selection = language.0
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isExpanded = false
                                }
                            } label: {
                                HStack {
                                    Text(language.1)
                                        .font(.system(size: 16))
                                        .foregroundColor(
                                            selection == language.0
                                                ? Color(hex: "#7B61FF")
                                                : (colorScheme == .light
                                                    ? Color(hex: "#4A5568") : Color(hex: "#E2E8F0"))
                                        )

                                    Spacer()

                                    if selection == language.0 {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(hex: "#7B61FF"))
                                    }
                                }
                                .padding(.horizontal, Theme.Spacing.lg)
                                .padding(.vertical, Theme.Spacing.md)
                                .background(
                                    selection == language.0
                                        ? (colorScheme == .light
                                            ? Color(hex: "#F0F5FF") : Color(hex: "#283B4F"))
                                        : Color.clear
                                )
                            }
                            .buttonStyle(PlainButtonStyle())

                            if language.0 != languages.last?.0 {
                                Divider()
                                    .padding(.horizontal, Theme.Spacing.md)
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.standard)
                        .fill(colorScheme == .light ? .white : Color(hex: "#1F2937"))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.standard)
                        .stroke(
                            colorScheme == .light ? Color(hex: "#E2E8F0") : Color(hex: "#374151"),
                            lineWidth: 1)
                )
                .shadow(
                    color: colorScheme == .light ? Color.black.opacity(0.1) : Color.clear,
                    radius: 8, x: 0, y: 4
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}



// MARK: - Preview
struct EnhancedFormComponents_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Preview MagicTextField
                MagicTextField(placeholder: "Enter text", text: .constant("Sample text"))
                    .previewLayout(.sizeThatFits)
                    .padding()

                // Preview EnhancedThemeCard
                EnhancedThemeCard(
                    theme: .adventure,
                    isSelected: true,
                    action: {}
                )
                .frame(width: 200)
                .previewLayout(.sizeThatFits)
                .padding()

                // Preview EnhancedLanguagePicker
                EnhancedLanguagePicker(
                    languages: [("en", "English"), ("es", "Español")],
                    selection: .constant("en")
                )
                .previewLayout(.sizeThatFits)
                .padding()

                // Preview shine effect
                ZStack {
                    Color.blue
                        .frame(height: 60)
                        .overlay(EnhancedShineEffect())
                        .cornerRadius(10)
                }
                .frame(height: 100)
                .previewLayout(.sizeThatFits)
                .padding()

                // Stars background in a container
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.05))
                        .frame(height: 200)

                    StarsBackground()
                        .frame(height: 200)
                }
                .previewLayout(.sizeThatFits)
                .padding()
            }
            .padding()
        }
        .previewDisplayName("Light Mode")

        ScrollView {
            VStack(spacing: 30) {
                // Same components for dark mode
                MagicTextField(placeholder: "Enter text", text: .constant("Sample text"))

                EnhancedThemeCard(
                    theme: .adventure,
                    isSelected: true,
                    action: {}
                )
                .frame(width: 200)

                EnhancedLanguagePicker(
                    languages: [("en", "English"), ("es", "Español")],
                    selection: .constant("en")
                )

                ZStack {
                    Color.blue
                        .frame(height: 60)
                        .overlay(EnhancedShineEffect())
                        .cornerRadius(10)
                }
                .frame(height: 100)
            }
            .padding()
        }
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
    }
}
