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

// MARK: - Components
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.headingSmall)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: Theme.Layout.minTapTarget)
                .padding(.horizontal, Theme.Spacing.md)
                .background(Theme.Colors.primary)
                .cornerRadius(Theme.Layout.cornerRadiusMedium)
        }
        .buttonStyle(.plain)
    }
}

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
