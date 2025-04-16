/// CollectionsListView displays a list of StoryCollection items with search and navigation.
/// NOTE: This view is not currently integrated into the main app UI. The collections list is rendered directly in HomeView.
/// This view is intended for future use as a dedicated tab (see plan T6).
import SwiftUI
import SwiftData

struct CollectionsListView: View {
    @Query private var collections: [StoryCollection]
    @State private var searchText = ""
    @EnvironmentObject private var collectionService: CollectionService
    @State private var deletionError: String? = nil
    
    private var filteredCollections: [StoryCollection] {
        if searchText.isEmpty {
            return collections
        } else {
            return collections.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredCollections) { collection in
                    NavigationLink(value: collection.id) {
                        CollectionCardView(collection: collection)
                    }
                }
                .onDelete(perform: deleteCollections)
            }
            .navigationTitle("Collections")
            .searchable(text: $searchText)
            .navigationDestination(for: UUID.self) { collectionId in
                if let collection = collections.first(where: { $0.id == collectionId }) {
                    CollectionDetailView(collection: collection)
                } else {
                    Text("Collection not found")
                }
            }
            .alert("Error Deleting Collection", isPresented: .constant(deletionError != nil), actions: {
                Button("OK", role: .cancel) { deletionError = nil }
            }, message: {
                if let error = deletionError {
                    Text(error)
                }
            })
        }
    }
    
    private func deleteCollections(at offsets: IndexSet) {
        for index in offsets {
            let collection = filteredCollections[index]
            do {
                try collectionService.deleteCollection(id: collection.id)
            } catch {
                deletionError = error.localizedDescription
            }
        }
    }
}

#Preview {
    CollectionsListView()
        .modelContainer(for: StoryCollection.self, inMemory: true)
}
