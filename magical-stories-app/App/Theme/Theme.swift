import SwiftUI

struct Theme {
    struct Colors {
        // Based on CSS Variables provided in HTML
        // Light Mode Colors
        static let backgroundLight = Color(hex: "#F7F9FB")
        static let textPrimaryLight = Color(hex: "#222B45")
        static let textSecondaryLight = Color(hex: "#6B7280")
        static let borderLight = Color(hex: "#E3E8EF")
        static let primaryLight = Color(hex: "#7B61FF") // Also used for focus ring
        static let white = Color.white

        // Dark Mode Colors (Approximated from CSS vars - may need refinement)
        static let backgroundDark = Color(hex: "#1f2937") // Approximated from --color-base
        static let textPrimaryDark = Color(hex: "#f9fafb") // Approximated from --color-base-content
        static let textSecondaryDark = Color(hex: "#d1d5db") // Approximated from --color-base-600
        static let borderDark = Color(hex: "#4b5563") // Approximated from --color-base-300 dark
        static let primaryDark = Color(hex: "#a78bfa") // Approximated from --color-secondary dark

        // Dynamic Colors
        static let appBackground = Color("AppBackground")
        static let appTextPrimary = Color("AppTextPrimary")
        static let appTextSecondary = Color("AppTextSecondary")
        static let appBorder = Color("AppBorder")
        static let appPrimary = Color("AppPrimary")
        static let appWhite = Color("AppWhite") // For elements always white

        // Gradients
        static let primaryGradient = LinearGradient(
            gradient: Gradient(colors: [Color(hex: "#7B61FF"), Color(hex: "#FF617B")]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    struct Fonts {
        // Assuming system font maps well to Inter
        static let header = Font.system(size: 28, weight: .bold)
        static let bodyMedium = Font.system(size: 16, weight: .medium) // Default label/input font
        static let bodyRegular = Font.system(size: 16)
        static let caption = Font.system(size: 12)
        static let button = Font.system(size: 16, weight: .medium)
    }

    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12 // Common gap/padding
        static let lg: CGFloat = 16 // Input vertical padding, section spacing
        static let xl: CGFloat = 24 // Larger spacing
        static let xxl: CGFloat = 32 // Header top margin
    }

    struct CornerRadius {
        static let standard: CGFloat = 12 // Matches rounded-xl
    }

    struct Icons {
        // Map Font Awesome to SF Symbols
        static let backArrow = "arrow.left"
        static let checkmarkCircle = "checkmark.circle.fill"
        static let friendship = "heart.fill" // fa-heart
        static let bravery = "shield.lefthalf.filled" // fa-shield-halved
        static let adventure = "mountain.2.fill" // fa-mountain
        static let discovery = "lightbulb.fill" // fa-lightbulb
        static let chevronDown = "chevron.down"
        static let volumeHigh = "speaker.wave.2.fill" // fa-volume-high
        static let cloudDownload = "cloud.fill" // fa-cloud-arrow-down (approximation)
        static let generate = "wand.and.stars" // fa-wand-sparkles
    }
}

// Helper for initializing Color from HEX strings
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0) // Default color
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