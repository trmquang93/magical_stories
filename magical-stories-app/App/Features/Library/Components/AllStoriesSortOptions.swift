import SwiftUI

struct AllStoriesSortOptions: View {
    @Binding var sortOption: AllStoriesView.SortOption
    var body: some View {
        HStack {
            Text("Sort by:")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(UITheme.Colors.textSecondary)
            Picker("Sort", selection: $sortOption) {
                ForEach(AllStoriesView.SortOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("AllStoriesView_SortPicker")
            Spacer()
        }
    }
}
