import SwiftUI

// MARK: - Form Styling
struct FormFieldStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .light ? .white : Color(hex: "#1F2937"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#E2E8F0"), lineWidth: 1)
            )
    }
}

struct FormSectionLabelStyle: ViewModifier {
    let iconName: String

    func body(content: Content) -> some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(Color(hex: "#7B61FF"))
            content
                .font(.headline)
        }
    }
}

struct CharacterSuggestionStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let isSelected: Bool

    func body(content: Content) -> some View {
        content
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected
                            ? AnyShapeStyle(UITheme.Colors.primary)
                            : AnyShapeStyle(
                                colorScheme == .light
                                    ? Color(hex: "#F0F4F8")
                                    : Color(hex: "#2D3748")
                            )
                    )
            )
            .foregroundColor(
                isSelected
                    ? .white
                    : (colorScheme == .light
                        ? Color(hex: "#4A5568")
                        : Color(hex: "#CBD5E0")))
    }
}

// MARK: - Form Field Container
struct FormFieldContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            content
        }
        .padding(.horizontal, UITheme.Spacing.lg)
    }
}

// MARK: - ThemeStyle
struct ThemeItemStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let isSelected: Bool

    func body(content: Content) -> some View {
        content
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        colorScheme == .light
                            ? .white : Color(hex: "#1F2937")
                    )
                    .shadow(
                        color: Color.black.opacity(0.05), radius: 4,
                        x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color(hex: "#7B61FF") : .clear,
                        lineWidth: 2)
            )
    }
}

// MARK: - View Extensions
extension View {
    func formFieldStyle() -> some View {
        modifier(FormFieldStyle())
    }

    func formSectionLabel(iconName: String) -> some View {
        modifier(FormSectionLabelStyle(iconName: iconName))
    }

    func characterSuggestionStyle(isSelected: Bool) -> some View {
        modifier(CharacterSuggestionStyle(isSelected: isSelected))
    }

    func themeItemStyle(isSelected: Bool) -> some View {
        modifier(ThemeItemStyle(isSelected: isSelected))
    }
}

// MARK: - Theme Helper Functions
func getIconName(for theme: StoryTheme) -> String {
    switch theme {
    case .friendship: return "heart.fill"
    case .adventure: return "map.fill"
    case .learning: return "book.fill"
    case .courage: return "shield.fill"
    default: return "star.fill"
    }
}
