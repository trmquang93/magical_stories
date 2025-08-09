import Foundation
import SwiftUI

// MARK: - EnhancedStoryCard
struct EnhancedStoryCard: View {
    var story: Story

    var body: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusLarge)
                .fill(UITheme.Colors.surfacePrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusLarge)
                        .stroke(UITheme.Colors.surfaceSecondary, lineWidth: 1)
                )
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 6,
                    x: 0,
                    y: 3
                )

            // Content
            HStack(spacing: UITheme.Spacing.md) {
                // Category icon with color
                if let categoryName = story.categoryName,
                    let categoryInfo = LibraryCategory.all.first(where: { $0.name == categoryName })
                {
                    ZStack {
                        Circle()
                            .fill(categoryInfo.color.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: categoryInfo.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(categoryInfo.color)
                    }
                } else {
                    // Fallback icon if no category
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: "book")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color.gray)
                    }
                }

                VStack(alignment: .leading, spacing: UITheme.Spacing.xxs) {
                    // Title with badge for read status
                    HStack(alignment: .center, spacing: UITheme.Spacing.xxs) {
                        Text(story.title)
                            .font(UITheme.Typography.headingSmall)
                            .foregroundColor(UITheme.Colors.textPrimary)
                            .lineLimit(1)

                        if story.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(UITheme.Colors.success)
                        }
                    }

                    // Categories badges
                    HStack(spacing: UITheme.Spacing.xxs) {
                        if let categoryName = story.categoryName {
                            Text(categoryName)
                                .font(UITheme.Typography.bodySmall.weight(.medium))
                                .foregroundColor(UITheme.Colors.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(UITheme.Colors.surfaceSecondary.opacity(0.5))
                                .cornerRadius(UITheme.Layout.cornerRadiusSmall)
                        }

                        // Theme badge if different from category
                        if story.parameters.theme != story.categoryName {
                            Text(story.parameters.theme)
                                .font(UITheme.Typography.bodySmall.weight(.medium))
                                .foregroundColor(UITheme.Colors.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(UITheme.Colors.surfaceSecondary.opacity(0.3))
                                .cornerRadius(UITheme.Layout.cornerRadiusSmall)
                        }
                    }

                    // Child name and creation date
                    HStack {
                        if let childName = story.parameters.childName {
                            Text("For \(childName)")
                                .font(UITheme.Typography.bodySmall)
                                .foregroundColor(UITheme.Colors.textSecondary)
                            Spacer()
                        }

                        // Format relative date
                        Text(relativeDate(from: story.timestamp))
                            .font(UITheme.Typography.bodySmall)
                            .foregroundColor(UITheme.Colors.textSecondary)
                    }
                }

                Spacer()

                // Right chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(UITheme.Colors.textSecondary)
            }
            .padding(UITheme.Spacing.md)
        }
        .frame(height: 100)
        .contentShape(Rectangle())
    }

    // Helper to format dates in a relative manner
    private func relativeDate(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Preview for EnhancedStoryCard
#Preview {
    // Need a mock Story for the preview
    let mockStory = Story(
        title: "The Whispering Woods",
        pages: [Page(content: "Once upon a time...", pageNumber: 1)],
        parameters: StoryParameters(
            theme: "Mystery",
            childAge: 6,
            childName: "Alex",
            favoriteCharacter: "Owl"
        ),
        categoryName: "Adventure"  // Example category
    )

    // Need mock libraryCategories data accessible for the preview
    // This preview might fail until LibraryCategoryData is created and accessible
    // and the placeholder `libraryCategories` computed property above is updated.
    return EnhancedStoryCard(story: mockStory)
        .padding()
        .background(Color.gray.opacity(0.1))
    // Add necessary environment objects if the card depends on them
    // .environmentObject(MockSomeService())
}
