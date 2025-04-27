import SwiftUI

// MARK: - Form Field Components
struct FormHeader: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var animateBackground: Bool

    private var primaryGradient: LinearGradient {
        Theme.Colors.primaryGradient
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Create Magic")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(
                        colorScheme == .light
                            ? Color(hex: "#7B61FF") : Color(hex: "#a78bfa"))

                Text("Personalize your magical story")
                    .font(.system(size: 16))
                    .foregroundColor(
                        Color(colorScheme == .light ? .black : .white).opacity(0.6))
            }

            Spacer()

            // Animated magic wand icon
            Image(systemName: "wand.and.stars")
                .font(.system(size: 32))
                .foregroundStyle(primaryGradient)
                .rotationEffect(Angle(degrees: animateBackground ? 5 : -5))
                .animation(
                    Animation.easeInOut(duration: 2).repeatForever(
                        autoreverses: true),
                    value: animateBackground
                )
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }
}

struct ChildNameField: View {
    @Binding var childName: String

    var body: some View {
        FormFieldContainer {
            Text("Child's Name")
                .formSectionLabel(iconName: "person.fill")

            TextField("Enter child's name", text: $childName)
                .formFieldStyle()
        }
    }
}

struct CharacterField: View {
    @Binding var favoriteCharacter: String
    let characterSuggestions: [String]

    var body: some View {
        FormFieldContainer {
            Text("Favorite Character")
                .formSectionLabel(iconName: "heart.fill")

            TextField("Enter a character (dragon, princess...)", text: $favoriteCharacter)
                .formFieldStyle()

            // Character suggestions
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(characterSuggestions, id: \.self) { character in
                        Button {
                            favoriteCharacter = character
                        } label: {
                            Text(character)
                                .characterSuggestionStyle(
                                    isSelected: favoriteCharacter == character)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

struct AgeRangeField: View {
    @Binding var selectedAgeRange: String
    let ageRanges: [String]

    var body: some View {
        FormFieldContainer {
            Text("Age Range")
                .formSectionLabel(iconName: "person.2.fill")

            Picker("Age Range", selection: $selectedAgeRange) {
                ForEach(ageRanges, id: \.self) { range in
                    Text(range).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.vertical, 8)
        }
    }
}

struct ThemeField: View {
    @Binding var selectedTheme: StoryTheme
    let storyThemes: [StoryTheme]

    var body: some View {
        FormFieldContainer {
            Text("Story Theme")
                .formSectionLabel(iconName: "book.fill")

            themeGrid
        }
    }

    private var themeGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: Theme.Spacing.md
        ) {
            ForEach(storyThemes) { theme in
                Button {
                    selectedTheme = theme
                } label: {
                    themeGridItem(theme: theme)
                }
            }
        }
    }

    private func themeGridItem(theme: StoryTheme) -> some View {
        VStack {
            Image(systemName: getIconName(for: theme))
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(
                            selectedTheme == theme
                                ? AnyShapeStyle(Theme.Colors.primaryGradient)
                                : AnyShapeStyle(Color(hex: "#A3AED0")))
                )
            Text(theme.rawValue.capitalized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(
                    selectedTheme == theme
                        ? Color(hex: "#7B61FF")
                        : Color(hex: "#4A5568"))
        }
        .themeItemStyle(isSelected: selectedTheme == theme)
    }
}

struct StoryLengthField: View {
    @Binding var storyLength: Double
    let storyLengthLabels: [String]

    var body: some View {
        FormFieldContainer {
            Text("Story Length")
                .formSectionLabel(iconName: "text.book.closed.fill")

            storyLengthSlider
        }
    }

    private var storyLengthSlider: some View {
        VStack(spacing: 12) {
            Slider(value: $storyLength, in: 1...3, step: 1)
                .accentColor(Color(hex: "#7B61FF"))

            // Labels
            HStack {
                ForEach(0..<storyLengthLabels.count, id: \.self) { index in
                    Text(storyLengthLabels[index])
                        .font(
                            .system(
                                size: 14,
                                weight: Int(storyLength) == index + 1
                                    ? .semibold : .regular)
                        )
                        .foregroundColor(
                            Int(storyLength) == index + 1
                                ? Color(hex: "#7B61FF")
                                : Color(hex: "#6B7280")
                        )
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .formFieldStyle()
    }
}

struct LanguageField: View {
    @Binding var selectedLanguage: String
    let languages: [(String, String)]

    var body: some View {
        FormFieldContainer {
            Text("Story Language")
                .formSectionLabel(iconName: "globe")

            Picker("Language", selection: $selectedLanguage) {
                ForEach(languages, id: \.0) { code, name in
                    Text(name).tag(code)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .formFieldStyle()
        }
    }
}

struct GenerateButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let isGenerating: Bool
    let childName: String
    let action: () -> Void

    private var primaryGradient: LinearGradient {
        Theme.Colors.primaryGradient
    }

    var body: some View {
        VStack(spacing: 12) {
            Button {
                action()
            } label: {
                ZStack {
                    // Gradient background
                    RoundedRectangle(cornerRadius: 28)
                        .fill(primaryGradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )

                    // Button content
                    HStack(spacing: 16) {
                        if isGenerating {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 36, height: 36)

                                Image(systemName: "wand.and.stars.inverse")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }

                        Text(
                            isGenerating
                                ? "Creating Magic..." : "Generate Magical Story"
                        )
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .shadow(
                    color: Color(hex: "#7B61FF").opacity(0.4), radius: 15, x: 0,
                    y: 8)
            }
            .disabled(isGenerating || childName.isEmpty)
            .scaleEffect(childName.isEmpty ? 0.98 : 1.0)
            .animation(
                .spring(response: 0.3, dampingFraction: 0.7),
                value: childName.isEmpty)

            if childName.isEmpty {
                Text("Please enter the child's name to continue")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#FF617B"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.xxl)
    }
}

// Add proper struct if needed
#if DEBUG
    struct StoryFormViewComponents_Previews: PreviewProvider {
        static var previews: some View {
            VStack {
                FormHeader(animateBackground: .constant(true))
                ChildNameField(childName: .constant("Alex"))
                // Add other preview components as needed
            }
            .padding()
            .previewLayout(.sizeThatFits)
        }
    }
#endif
