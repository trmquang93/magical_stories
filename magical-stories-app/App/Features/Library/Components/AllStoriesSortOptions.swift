import SwiftUI

struct AllStoriesSortOptions: View {
    @Binding var sortOption: SortOption
    var body: some View {
        HStack {
            Text("Sort by:")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(UITheme.Colors.textSecondary)
            Picker("Sort", selection: $sortOption) {
                ForEach(SortOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("AllStoriesView_SortPicker")
            Spacer()
        }
    }
}

extension AllStoriesSortOptions {

    enum SortOption: String, CaseIterable, Identifiable {
        case newest = "Newest"
        case oldest = "Oldest"
        case alphabetical = "A-Z"
        case mostRead = "Completed"

        var id: String { self.rawValue }
    }

}
