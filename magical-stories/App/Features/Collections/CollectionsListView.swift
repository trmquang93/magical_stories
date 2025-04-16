/// CollectionsListView displays a list of StoryCollection items with search and navigation.
/// NOTE: This view is not currently integrated into the main app UI. The collections list is rendered directly in HomeView.
/// This view is intended for future use as a dedicated tab (see plan T6).
import SwiftUI
import SwiftData

struct CollectionsListView: View {
    @Query private var collections: [StoryCollection]
    @State private var searchText = ""
    
    private var filteredCollections: [StoryCollection] {
        if searchText.isEmpty {
            return collections
        } else {
            return collections.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredCollections) { collection in
                NavigationLink(value: collection) {
                    CollectionCardView(collection: collection)
                }
            }
            .navigationTitle("Collections")
            .searchable(text: $searchText)
            .navigationDestination(for: StoryCollection.self) { collection in
                CollectionDetailView(collection: collection)
            }
        }
    }
}

#Preview {
    CollectionsListView()
        .modelContainer(for: StoryCollection.self, inMemory: true)
}
