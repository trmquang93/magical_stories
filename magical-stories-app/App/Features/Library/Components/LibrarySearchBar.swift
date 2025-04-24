import SwiftUI

struct LibrarySearchBar: View {
    @Binding var searchText: String
    @Binding var isSearchFocused: Bool

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(
                    isSearchFocused
                        ? UITheme.Colors.primary : UITheme.Colors.textSecondary
                )
                .font(.system(size: 16, weight: .medium))
                .padding(.leading, UITheme.Spacing.md)

            TextField(
                "Search stories", text: $searchText,
                onEditingChanged: { focused in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSearchFocused = focused
                    }
                }
            )
            .font(UITheme.Typography.bodyMedium)
            .padding(.vertical, UITheme.Spacing.sm)
            .accessibilityIdentifier("LibraryView_SearchField")

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(UITheme.Colors.textSecondary)
                        .font(.system(size: 16))
                }
                .padding(.trailing, UITheme.Spacing.sm)
                .transition(.opacity)
                .animation(.easeInOut, value: searchText)
            }
        }
        .padding(.horizontal, UITheme.Spacing.sm)
        .frame(height: 48)
        .background(UITheme.Colors.surfacePrimary)
        .cornerRadius(UITheme.Layout.cornerRadiusLarge)
        .overlay(
            RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusLarge)
                .stroke(
                    isSearchFocused
                        ? UITheme.Colors.primary : UITheme.Colors.surfaceSecondary,
                    lineWidth: isSearchFocused ? 2 : 1
                )
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
        .padding(.horizontal, UITheme.Spacing.lg)
        .padding(.bottom, UITheme.Spacing.md)
    }
}
