import SwiftUI

enum LibraryEmptyStateMode {
    case empty
    case noResults
}

struct LibraryEmptyState: View {
    let mode: LibraryEmptyStateMode
    var body: some View {
        VStack(spacing: UITheme.Spacing.lg) {
            Image(systemName: mode == .empty ? "books.vertical" : "magnifyingglass")
                .font(.system(size: mode == .empty ? 50 : 40))
                .foregroundStyle(
                    mode == .empty
                        ? LinearGradient(
                            colors: [
                                UITheme.Colors.surfaceSecondary, UITheme.Colors.textSecondary,
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        : LinearGradient(
                            colors: [UITheme.Colors.textSecondary, UITheme.Colors.textSecondary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                )
            Text(mode == .empty ? "Your library is empty" : "No stories found")
                .font(UITheme.Typography.headingMedium)
                .foregroundColor(UITheme.Colors.textPrimary)
            Text(
                mode == .empty
                    ? "Create your first magical story on the Home tab"
                    : "Try adjusting your search or filters"
            )
            .font(UITheme.Typography.bodyMedium)
            .foregroundColor(UITheme.Colors.textSecondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
        .padding(.horizontal, UITheme.Spacing.lg)
    }
}
