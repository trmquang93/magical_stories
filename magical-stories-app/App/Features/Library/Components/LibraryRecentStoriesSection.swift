import SwiftUI

struct LibraryRecentStoriesSection: View {
    let recentStories: [Story]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Recent Stories")
                    .font(UITheme.Typography.headingMedium)
                    .foregroundColor(UITheme.Colors.textPrimary)
                    .accessibilityIdentifier("LibraryView_RecentStoriesSection")
                Spacer()
                NavigationLink(value: LibraryView.ViewDestination.allStories) {
                    HStack(spacing: UITheme.Spacing.xxs) {
                        Text("See All")
                            .font(UITheme.Typography.bodySmall.weight(.semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(UITheme.Colors.primary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        Capsule()
                            .fill(UITheme.Colors.primary.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityIdentifier("LibraryView_SeeAllButton")
                .accessibilityLabel("See All Stories")
            }
            .padding(.horizontal, UITheme.Spacing.lg)
            .padding(.top, UITheme.Spacing.xl)
            .padding(.bottom, UITheme.Spacing.md)

            ForEach(recentStories) { story in
                NavigationLink(value: story) {
                    EnhancedStoryCard(story: story)
                        .accessibilityIdentifier("LibraryView_StoryCard_\(story.id)")
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, UITheme.Spacing.lg)
                .padding(.bottom, UITheme.Spacing.md)
            }
        }
    }
}
