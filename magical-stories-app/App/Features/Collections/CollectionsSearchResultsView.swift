import SwiftUI

/// View displayed when no search results are found in Collections
struct CollectionsNoSearchResultsView: View {
    let searchText: String

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 80)

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 32))
                    .foregroundColor(Color(.systemGray2))
            }

            // Text
            Text("No Collections Found")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)

            Text("We couldn't find any collections matching \"\(searchText)\"")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Tips
            VStack(alignment: .leading, spacing: 16) {
                Text("Search Tips")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.magicalPrimary)

                    Text("Check your spelling")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.magicalPrimary)

                    Text("Try more general keywords")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.magicalPrimary)

                    Text("Try searching by category (e.g., \"emotions\")")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .padding(.top, 8)
        }
        .padding(24)
        .accessibilityIdentifier("NoSearchResultsView")
    }
}

#Preview("No Results") {
    CollectionsNoSearchResultsView(searchText: "dragons")
        .background(Color(.systemGroupedBackground))
}
