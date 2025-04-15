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
        }
    }
}

#Preview {
    CollectionsListView()
        .modelContainer(for: StoryCollection.self, inMemory: true)
}
