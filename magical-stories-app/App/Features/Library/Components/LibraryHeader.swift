import SwiftUI

struct LibraryHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Library")
                    .font(UITheme.Typography.displayMedium)
                    .foregroundColor(UITheme.Colors.textPrimary)
                    .accessibilityIdentifier("LibraryView_Header")
                Text("Your magical story collection")
                    .font(UITheme.Typography.bodyMedium)
                    .foregroundColor(UITheme.Colors.textSecondary)
                    .accessibilityIdentifier("LibraryView_Subtitle")
            }
            Spacer()
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 28))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.calmBlue, .magicPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse, options: .repeating, value: true)
        }
        .padding(.horizontal, UITheme.Spacing.lg)
        .padding(.bottom, UITheme.Spacing.md)
    }
}
