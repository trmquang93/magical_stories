import SwiftUI

struct CollectionsNoSearchResultsView: View {
    let searchText: String

    var body: some View {
        VStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .padding(.bottom, 8)

            Text("No Results Found")
                .font(.title2)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)

            Text("No collections matching '\(searchText)' were found.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 16)
        }
        .accessibilityIdentifier("NoSearchResultsView")
    }
}

#Preview {
    CollectionsNoSearchResultsView(searchText: "NonExistentSearch")
}