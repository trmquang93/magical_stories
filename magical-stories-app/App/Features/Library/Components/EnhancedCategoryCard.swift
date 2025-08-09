import SwiftUI

// MARK: - EnhancedCategoryCard
struct EnhancedCategoryCard: View {
    var category: LibraryCategory
    var isSelected: Bool = false

    var body: some View {
        ZStack {
            // Card background with gradient
            RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusLarge)
                .fill(UITheme.Colors.surfacePrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusLarge)
                        .stroke(
                            isSelected ? category.color : UITheme.Colors.surfaceSecondary,
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 4
                )

            // Content
            VStack(alignment: .leading, spacing: UITheme.Spacing.sm) {
                // Header with icon and selection indicator
                HStack {
                    ZStack {
                        Circle()
                            .fill(category.color.opacity(0.15))
                            .frame(width: 36, height: 36)

                        Image(systemName: category.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(category.color)
                    }

                    Spacer()

                    if isSelected {
                        ZStack {
                            Circle()
                                .fill(category.color.opacity(0.15))
                                .frame(width: 20, height: 20)

                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(category.color)
                        }
                    }
                }

                Spacer()

                // Category name and count
                Text(category.name)
                    .font(UITheme.Typography.headingSmall)
                    .foregroundColor(UITheme.Colors.textPrimary)

                Text("\(category.storyCount) stories")
                    .font(UITheme.Typography.bodySmall)
                    .foregroundColor(UITheme.Colors.textSecondary)
            }
            .padding(UITheme.Spacing.md)
        }
        .frame(height: 120)
        .contentShape(Rectangle())
    }
}

// Preview for EnhancedCategoryCard
#Preview("Selected") {
    let category = LibraryCategory(
        name: "Fantasy",
        icon: "sparkles",
        color: .magicPurple,
        storyCount: 5
    )
    EnhancedCategoryCard(category: category, isSelected: true)
        .padding()
        .background(Color.gray.opacity(0.1))
}

#Preview("Not Selected") {
    let category = LibraryCategory(
        name: "Adventure",
        icon: "rocket",
        color: .calmBlue,
        storyCount: 3
    )
    EnhancedCategoryCard(category: category, isSelected: false)
        .padding()
        .background(Color.gray.opacity(0.1))
}