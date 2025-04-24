import SwiftUI

struct AllStoriesEmptyState: View {
    var searchText: String
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(UITheme.Colors.textSecondary.opacity(0.5))
            if searchText.isEmpty {
                Text("No stories found")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(UITheme.Colors.textPrimary)
                Text("Create your first magical story to see it here")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(UITheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("No matching stories")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(UITheme.Colors.textPrimary)
                Text("Try adjusting your search to find more stories")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(UITheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(.horizontal, 32)
        .accessibilityIdentifier("AllStoriesView_EmptyState")
    }
}
