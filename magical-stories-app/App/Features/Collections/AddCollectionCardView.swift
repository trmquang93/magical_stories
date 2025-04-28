import SwiftUI

/// A visually distinct card used for creating new collections
/// It features a gradient background, thematic icon, and clear call-to-action text
struct AddCollectionCardView: View {
    let action: () -> Void

    // Gradient colors - using UITheme semantic colors for consistent theming
    private var gradientColors: [Color] {
        [UITheme.Colors.primary, UITheme.Colors.accent]
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .center, spacing: UITheme.Spacing.md) {
                // Thematic icon
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .padding(.top, UITheme.Spacing.lg)

                // Call-to-action text
                Text("Create New Collection")
                    .font(UITheme.Typography.headingMedium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // Additional description
                Text("Add a new themed story collection")
                    .font(UITheme.Typography.bodyMedium)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, UITheme.Spacing.lg)
            }
            .frame(maxWidth: .infinity, minHeight: 180)  // Match approximate height of CollectionCardView
            .background(
                LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(UITheme.Layout.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusMedium)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [.white.opacity(0.4), .white.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            // Add a subtle shadow for depth
            .shadow(color: UITheme.Colors.primary.opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())  // Prevent default button styling
        .accessibilityLabel("Create a new Growth Collection")
        .accessibilityIdentifier("HomeView_AddCollectionCard")
    }
}

#Preview("Light Mode") {
    VStack {
        AddCollectionCardView(action: {})
            .frame(width: 220)
    }
    .padding()
    .background(UITheme.Colors.background)
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    VStack {
        AddCollectionCardView(action: {})
            .frame(width: 220)
    }
    .padding()
    .background(UITheme.Colors.background)
    .preferredColorScheme(.dark)
}
