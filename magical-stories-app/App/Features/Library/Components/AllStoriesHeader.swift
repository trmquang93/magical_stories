import SwiftUI

struct AllStoriesHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("All Stories")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(UITheme.Colors.textPrimary)
                .accessibilityIdentifier("AllStoriesView_Header")
                .accessibilityLabel("AllStoriesView_Header")
            Text("Your complete magical collection")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(UITheme.Colors.textSecondary)
                .accessibilityIdentifier("AllStoriesView_Subtitle")
                .accessibilityLabel("AllStoriesView_Subtitle")
        }
    }
}
