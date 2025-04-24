import SwiftUI

struct LibraryActiveCategoryFilter: View {
    let selectedCategoryName: String
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: UITheme.Spacing.sm) {
            // Find the matching category to get icon and color
            let categoryInfo = libraryCategories.first { $0.name == selectedCategoryName }

            if let info = categoryInfo {
                Image(systemName: info.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(info.color)
            }

            Text("Filtered by: \(selectedCategoryName)")
                .font(UITheme.Typography.bodyMedium)
                .foregroundColor(UITheme.Colors.primary)

            Spacer()

            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    onClear()
                }
            }) {
                HStack(spacing: UITheme.Spacing.xxs) {
                    Text("Clear")
                        .font(UITheme.Typography.bodySmall.weight(.medium))
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                }
                .foregroundColor(UITheme.Colors.primary)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    Capsule()
                        .fill(UITheme.Colors.primary.opacity(0.1))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityIdentifier("LibraryView_ClearFilterButton")
            .accessibilityLabel("Clear category filter")
        }
        .padding(.horizontal, UITheme.Spacing.lg)
        .padding(.bottom, UITheme.Spacing.md)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
