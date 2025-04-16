/// [2025-04-16 Modern Calm Update]
import SwiftUI

// MARK: - Theme
enum Theme {
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
    }
    
    // MARK: - Typography
    enum Typography {
        private static let sfProRounded = "SF Pro Rounded"
        
        // Display
        static let displayLarge = Font.custom(sfProRounded, size: 34, relativeTo: .largeTitle).weight(.bold)
        static let displayMedium = Font.custom(sfProRounded, size: 28, relativeTo: .title).weight(.bold)
        static let displaySmall = Font.custom(sfProRounded, size: 24, relativeTo: .title2).weight(.bold)
        
        // Heading
        static let headingLarge = Font.custom(sfProRounded, size: 22, relativeTo: .title3).weight(.semibold)
        static let headingMedium = Font.custom(sfProRounded, size: 20, relativeTo: .headline).weight(.semibold)
        static let headingSmall = Font.custom(sfProRounded, size: 18, relativeTo: .subheadline).weight(.semibold)
        
        // Body
        static let bodyLarge = Font.custom(sfProRounded, size: 17, relativeTo: .body)
        static let bodyMedium = Font.custom(sfProRounded, size: 15, relativeTo: .callout)
        static let bodySmall = Font.custom(sfProRounded, size: 13, relativeTo: .caption)
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
}

// MARK: - Color Extensions
extension Color {
    static let calmBlue = Color(red: 79/255, green: 140/255, blue: 255/255)
    static let gentleGreen = Color(red: 109/255, green: 214/255, blue: 167/255)
    static let softGold = Color(red: 255/255, green: 216/255, blue: 107/255)
    static let deepNavy = Color(red: 34/255, green: 43/255, blue: 69/255)
    static let coolGray = Color(red: 107/255, green: 114/255, blue: 128/255)
    static let surface = Color.white
    static let background = Color(red: 247/255, green: 249/255, blue: 251/255)
    static let border = Color(red: 227/255, green: 232/255, blue: 239/255)
    static let magicPurple = Color(red: 162/255, green: 89/255, blue: 255/255)
    static let skyBlue = Color(red: 56/255, green: 189/255, blue: 248/255)
    static let fairyPink = Color(red: 255/255, green: 126/255, blue: 185/255)
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
    static let maxWidth: CGFloat = 414 // iPhone Pro Max width
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
                .font(.headingSmall)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Color.magicalPrimary)
                .cornerRadius(12)
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
                .font(.headingSmall)
                .foregroundColor(.magicalPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Color.magicalPrimary.opacity(0.1))
                .cornerRadius(12)
        }
    }
}

// MARK: - Card Modifier
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Spacing.md)
            .background(Color.surface)
            .cornerRadius(16)
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
            .font(.bodyLarge)
            .padding(.vertical, Spacing.xs)
    }
}
extension View {
    func inputFieldStyle() -> some View {
        modifier(InputFieldModifier())
    }
}

/// [2025-04-16 Modern Calm Update] End of section

#Preview("Primary Button") {
    VStack(spacing: Theme.Spacing.md) {
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

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor)
                    .frame(width: 48, height: 48)
                Image(systemName: iconName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headingLarge)
                    .foregroundColor(Theme.Colors.textPrimary)
                Text(subtitle)
                    .font(.bodySmall)
                    .foregroundColor(Theme.Colors.textSecondary)
                PrimaryButton(title: buttonTitle, action: buttonAction)
                    .padding(.top, 8)
            }
            Spacer()
        }
        .padding(20)
        .background(Theme.Colors.surfacePrimary)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.border, lineWidth: 1)
        )
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, 8)
    }
}
