import SwiftUI

struct CollectionsListView: View {
    @EnvironmentObject private var collectionService: CollectionService
    // Optional search text binding if search needs to apply here
    // @Binding var searchText: String
    
    // TODO: Add filtering logic based on searchText if needed
    private var filteredCollections: [GrowthCollection] {
        // For now, just return all collections
        collectionService.collections
    }
    
    var body: some View {
        // Use a List or ScrollView with LazyVGrid/LazyVStack
        // Using List for simplicity initially
        List(filteredCollections) { collection in
            // Add navigation link now that GrowthCollection is Hashable
            NavigationLink(value: collection) { 
                CollectionCardView(collection: collection)
            }
        }
        .listStyle(.plain) // Use plain list style
    }
}

#Preview {
    CollectionsListView()
        .environmentObject(CollectionService.preview) // Use preview service
} 