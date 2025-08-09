import SwiftUI

struct AllStoriesSortOptions: View {
    @Binding var sortOption: SortOption
    var body: some View {
        HStack {
            Text(R.string.localizable.librarySortBy())
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(UITheme.Colors.textSecondary)
            Picker(R.string.localizable.librarySortBy(), selection: $sortOption) {
                ForEach(SortOption.allCases) { option in
                    Text(option.localizedTitle).tag(option)
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
        
        var localizedTitle: String {
            switch self {
            case .newest:
                return R.string.localizable.librarySortNewest()
            case .oldest:
                return R.string.localizable.librarySortOldest()
            case .alphabetical:
                return R.string.localizable.librarySortAlphabetical()
            case .mostRead:
                return R.string.localizable.librarySortMostRead()
            }
        }
    }

}
