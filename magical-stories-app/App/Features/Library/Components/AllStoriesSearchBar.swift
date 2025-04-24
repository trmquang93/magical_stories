import SwiftUI

struct AllStoriesSearchBar: View {
    @Binding var searchText: String
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(UITheme.Colors.textSecondary)
                .padding(.leading, 12)
            TextField("Search stories", text: $searchText)
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .padding(.vertical, 12)
                .padding(.horizontal, 4)
                .accessibilityIdentifier("AllStoriesView_SearchField")
                .accessibilityLabel("AllStoriesView_SearchField")
        }
        .background(UITheme.Colors.surfacePrimary)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(UITheme.Colors.surfaceSecondary, lineWidth: 1)
        )
    }
}
