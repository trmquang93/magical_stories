import SwiftUI

struct CategoryCarouselCard: View {
    var category: LibraryCategory
    var isSelected: Bool = false

    var body: some View {
        VStack(spacing: UITheme.Spacing.xs) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [category.color.opacity(0.18), category.color.opacity(0.38)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 54, height: 54)
                Image(systemName: category.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(category.color)
            }
            .overlay(
                Circle()
                    .stroke(
                        isSelected ? category.color : Color.clear,
                        lineWidth: isSelected ? 3 : 0
                    )
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            )
            Text(category.name)
                .font(UITheme.Typography.bodyMedium.weight(.semibold))
                .foregroundColor(UITheme.Colors.textPrimary)
                .lineLimit(1)
            Text("\(category.storyCount) stories")
                .font(UITheme.Typography.bodySmall)
                .foregroundColor(UITheme.Colors.textSecondary)
        }
        .padding(.vertical, UITheme.Spacing.sm)
        .padding(.horizontal, UITheme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusMedium)
                .fill(isSelected ? category.color.opacity(0.08) : Color.clear)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        )
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .shadow(
            color: isSelected ? category.color.opacity(0.12) : Color.clear,
            radius: 8, x: 0, y: 2
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }
}