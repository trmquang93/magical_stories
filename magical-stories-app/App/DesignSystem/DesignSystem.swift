/// [2025-04-16 Modern Calm Update]
import SwiftUI

// MARK: - Theme
enum UITheme {
    // MARK: - Colors
    enum Colors {
        static let primary = Color("MagicalPrimary")
        static let secondary = Color("MagicalSecondary")
        static let accent = Color("MagicalAccent")

        // Background colors
        static let background = Color("MagicalBackground")
        static let surfacePrimary = Color("MagicalSurfacePrimary")
        static let surfaceSecondary = Color("MagicalSurfaceSecondary")

        // Text colors
        static let textPrimary = Color("MagicalTextPrimary")
        static let textSecondary = Color("MagicalTextSecondary")

        // Status colors
        static let success = Color("MagicalSuccess")
        static let error = Color("MagicalError")
        static let warning = Color("MagicalWarning")


        // Gradients
        static let primaryGradient = LinearGradient(
            gradient: Gradient(colors: [Color(hex: "#7B61FF"), Color(hex: "#FF617B")]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Typography
    enum Typography {
        private static let sfProRounded = "SF Pro Rounded"

        // Display
        static let displayLarge = Font.custom(sfProRounded, size: 34, relativeTo: .largeTitle)
            .weight(.bold)
        static let displayMedium = Font.custom(sfProRounded, size: 28, relativeTo: .title).weight(
            .bold)
        static let displaySmall = Font.custom(sfProRounded, size: 24, relativeTo: .title2).weight(
            .bold)

        // Heading
        static let headingLarge = Font.custom(sfProRounded, size: 22, relativeTo: .title3).weight(
            .semibold)
        static let headingMedium = Font.custom(sfProRounded, size: 20, relativeTo: .headline)
            .weight(.semibold)
        static let headingSmall = Font.custom(sfProRounded, size: 18, relativeTo: .subheadline)
            .weight(.semibold)

        // Body
        static let bodyLarge = Font.custom(sfProRounded, size: 17, relativeTo: .body)
        static let bodyMedium = Font.custom(sfProRounded, size: 15, relativeTo: .callout)
        static let bodySmall = Font.custom(sfProRounded, size: 13, relativeTo: .caption)
        
        // Caption
        static let caption = Font.custom(sfProRounded, size: 12, relativeTo: .caption)
    }

    // MARK: - Spacing
    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 40
        static let xxxl: CGFloat = 48
    }

    // MARK: - Animation
    enum Animation {
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.45)

        // Page turn animation
        static let pageTurn = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.75)

        // Transition timings
        enum Transition {
            static let standard = 0.3
            static let quick = 0.15
            static let slow = 0.45
        }
    }

    // MARK: - Layout
    enum Layout {
        static let cornerRadiusSmall: CGFloat = 8
        static let cornerRadiusMedium: CGFloat = 12
        static let cornerRadiusLarge: CGFloat = 16

        static let maxContentWidth: CGFloat = 640
        static let maxReadingWidth: CGFloat = 720

        static let minTapTarget: CGFloat = 44
    }

    // MARK: - Icons
    enum Icons {
        // Map Font Awesome to SF Symbols
        static let backArrow = "arrow.left"
        static let checkmarkCircle = "checkmark.circle.fill"
        static let friendship = "heart.fill"  // fa-heart
        static let bravery = "shield.lefthalf.filled"  // fa-shield-halved
        static let adventure = "mountain.2.fill"  // fa-mountain
        static let discovery = "lightbulb.fill"  // fa-lightbulb
        static let chevronDown = "chevron.down"
        static let volumeHigh = "speaker.wave.2.fill"  // fa-volume-high
        static let cloudDownload = "cloud.fill"  // fa-cloud-arrow-down (approximation)
        static let generate = "wand.and.stars"  // fa-wand-sparkles
    }
    struct CornerRadius {
        static let standard: CGFloat = 12  // Matches rounded-xl
    }
}

// MARK: - Color Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        switch hex.count {
        case 3:  // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)  // Default color
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension Color {
    // Modern Calm
    static let calmBlue = Color(hex: "4F8CFF")
    static let gentleGreen = Color(hex: "6DD6A7")
    static let softGold = Color(hex: "FFD86B")
    static let deepNavy = Color(hex: "222B45")
    static let coolGray = Color(hex: "6B7280")
    static let surface = Color(hex: "FFFFFF")
    static let background = Color(hex: "F7F9FB")
    static let border = Color(hex: "E3E8EF")
    // Magical Accents (Reading/Playful)
    static let magicPurple = Color(hex: "A259FF")
    static let skyBlue = Color(hex: "38BDF8")
    static let fairyPink = Color(hex: "FF7EB9")
    static let sparkleWhite = Color.white
}

// MARK: - Font Extensions
extension Font {
    static let displayLarge = Font.system(size: 34, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)
    static let headingLarge = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let headingMedium = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let headingSmall = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let bodyLarge = Font.system(size: 17, design: .rounded)
    static let bodyMedium = Font.system(size: 15, design: .rounded)
    static let bodySmall = Font.system(size: 13, design: .rounded)
    static let storyTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let storyText = Font.system(size: 20, design: .rounded)
}

// MARK: - Spacing
enum Spacing {
    static let xxxs: CGFloat = 2
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 40
    static let xxxl: CGFloat = 48
}

// MARK: - Container Sizes
enum ContainerSize {
    static let maxWidth: CGFloat = 414  // iPhone Pro Max width
    static let contentPadding: CGFloat = 16
    static let cardPadding: CGFloat = 12
    static let modalPadding: CGFloat = 20
}

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(UITheme.Typography.headingSmall)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, UITheme.Spacing.md)
                .background(UITheme.Colors.primary)
                .cornerRadius(UITheme.Layout.cornerRadiusMedium)
        }
    }
}

// MARK: - Secondary Button
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(UITheme.Typography.headingSmall)
                .foregroundColor(UITheme.Colors.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, UITheme.Spacing.md)
                .background(UITheme.Colors.primary.opacity(0.1))
                .cornerRadius(UITheme.Layout.cornerRadiusMedium)
        }
    }
}

// MARK: - Card Modifier
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(UITheme.Spacing.md)
            .background(UITheme.Colors.surfacePrimary)
            .cornerRadius(UITheme.Layout.cornerRadiusLarge)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}

// MARK: - Input Field Modifier
struct InputFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .font(UITheme.Typography.bodyLarge)
            .padding(.vertical, UITheme.Spacing.xs)
    }
}
extension View {
    func customInputFieldStyle() -> some View {
        modifier(InputFieldModifier())
    }
}

/// [2025-04-16 Modern Calm Update] End of section

#Preview("Primary Button") {
    VStack(spacing: UITheme.Spacing.md) {
        PrimaryButton(title: "Create Story") {
            // Action
        }
        PrimaryButton(title: "Save") {
            // Action
        }
    }
    .padding()
}

// MARK: - Font Scale EnvironmentKey
private struct FontScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1.0
}

extension EnvironmentValues {
    var fontScale: CGFloat {
        get { self[FontScaleKey.self] }
        set { self[FontScaleKey.self] = newValue }
    }
}

struct ActionCard: View {
    let iconName: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let buttonTitle: String
    let buttonAction: () -> Void

    // Colors for gradient
    private let gradientStart = Color(hex: "#7B61FF")
    private let gradientEnd = Color(hex: "#FF617B")

    @State private var isHovering = false
    @State private var shineOffset: CGFloat = -200
    @Environment(\.colorScheme) private var colorScheme

    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(hex: "#1E222A") : UITheme.Colors.surfacePrimary
    }

    private var cardBorderColor: Color {
        colorScheme == .dark ? Color(hex: "#2D323C") : Color(hex: "#E3E8EF")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Icon and text container
            HStack(spacing: UITheme.Spacing.md) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [gradientStart, gradientEnd]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(
                            color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.2), radius: 4,
                            x: 0, y: 2)

                    Image(systemName: iconName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(isHovering ? 1.1 : 1.0)
                        .animation(
                            UITheme.Animation.standard.repeatForever(autoreverses: true),
                            value: isHovering)
                }
                .scaleEffect(isHovering ? 1.05 : 1.0)
                .animation(UITheme.Animation.quick, value: isHovering)

                // Title and subtitle
                VStack(alignment: .leading, spacing: UITheme.Spacing.xxs) {
                    Text(title)
                        .font(UITheme.Typography.headingMedium)
                        .foregroundColor(UITheme.Colors.textPrimary)

                    Text(subtitle)
                        .font(UITheme.Typography.bodySmall)
                        .foregroundColor(UITheme.Colors.textSecondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // Button with gradient background and shine effect
            Button(action: buttonAction) {
                ZStack {
                    // Gradient background
                    LinearGradient(
                        gradient: Gradient(colors: [gradientStart, gradientEnd]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )

                    // Shine effect overlay
                    GeometryReader { geometry in
                        Color.white.opacity(0.2)
                            .mask(
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(stops: [
                                                .init(color: .clear, location: 0),
                                                .init(color: .white, location: 0.45),
                                                .init(color: .white, location: 0.55),
                                                .init(color: .clear, location: 1),
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .rotationEffect(.degrees(-30))
                                    .offset(x: shineOffset)
                                    .frame(width: geometry.size.width * 2)
                            )
                    }
                    .onAppear {
                        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                            shineOffset = 400
                        }
                    }

                    // Button content with sparkles
                    HStack(spacing: UITheme.Spacing.xs) {
                        Image(systemName: UITheme.Icons.generate)
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#FFE696"))

                        Text(buttonTitle)
                            .font(UITheme.Typography.headingSmall)
                            .foregroundColor(.white)

                        Image(systemName: UITheme.Icons.generate)
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#FFE696"))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .cornerRadius(UITheme.Layout.cornerRadiusLarge)
            .padding(.horizontal, 20)
            .padding(.top, UITheme.Spacing.md)
            .padding(.bottom, 20)
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 8, x: 0, y: 4
            )
        }
        .background(cardBackgroundColor)
        .cornerRadius(UITheme.Layout.cornerRadiusLarge)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.08), radius: 8, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusLarge)
                .stroke(cardBorderColor, lineWidth: 1)
        )
        .padding(.horizontal, UITheme.Spacing.lg)
        .padding(.vertical, UITheme.Spacing.xs)
        .onAppear {
            isHovering = true
        }
    }
}

#Preview("ActionCard Light Mode") {
    VStack(spacing: UITheme.Spacing.lg) {
        ActionCard(
            iconName: UITheme.Icons.generate,
            iconColor: UITheme.Colors.primary,
            title: "Create a New Story",
            subtitle: "Personalize a bedtime adventure",
            buttonTitle: "Create Magic",
            buttonAction: {}
        )

        ActionCard(
            iconName: "plus",
            iconColor: UITheme.Colors.primary,
            title: "Create a Growth Collection",
            subtitle: "Guide your child's growth with themed story sets",
            buttonTitle: "Start Collection",
            buttonAction: {}
        )
    }
    .padding()
    .background(UITheme.Colors.background)
    .environment(\.colorScheme, .light)
}

#Preview("ActionCard Dark Mode") {
    VStack(spacing: UITheme.Spacing.lg) {
        ActionCard(
            iconName: UITheme.Icons.generate,
            iconColor: UITheme.Colors.primary,
            title: "Create a New Story",
            subtitle: "Personalize a bedtime adventure",
            buttonTitle: "Create Magic",
            buttonAction: {}
        )

        ActionCard(
            iconName: "plus",
            iconColor: UITheme.Colors.primary,
            title: "Create a Growth Collection",
            subtitle: "Guide your child's growth with themed story sets",
            buttonTitle: "Start Collection",
            buttonAction: {}
        )
    }
    .padding()
    .background(UITheme.Colors.background)
    .environment(\.colorScheme, .dark)
}
