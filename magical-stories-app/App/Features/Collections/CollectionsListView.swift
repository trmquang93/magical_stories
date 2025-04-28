import SwiftData
import SwiftUI

struct CollectionsListView: View {
    @Query private var collections: [StoryCollection]
    @State private var searchText = ""
    @EnvironmentObject private var collectionService: CollectionService
    @State private var deletionError: String? = nil
    @State private var showingGrowthStoryForm = false

    private var filteredCollections: [StoryCollection] {
        if searchText.isEmpty {
            return collections
        } else {
            return collections.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            if collections.isEmpty && searchText.isEmpty {
                CollectionsEmptyStateView()
                    .navigationTitle("Collections")
                    .toolbar {
                        toolbarAddButton
                    }
            } else if filteredCollections.isEmpty && !searchText.isEmpty {
                CollectionsNoSearchResultsView(searchText: searchText)
                    .navigationTitle("Collections")
                    .toolbar {
                        toolbarAddButton
                    }
            } else {
                List {
                    ForEach(filteredCollections) { collection in
                        NavigationLink(value: collection.id) {
                            CollectionCardView(collection: collection)
                                .padding(.vertical, 4)  // Add vertical padding to list items
                                .contentShape(Rectangle())  // Improve tap target size
                                .accessibilityElement(children: .combine)  // Combine accessibility for the card
                        }
                    }
                    .onDelete(perform: deleteCollections)
                }
                .accessibilityIdentifier("CollectionsList")  // Identifier for the list
                .navigationTitle("Collections")
                .searchable(text: $searchText)
                .refreshable {  // Add pull-to-refresh
                    await collectionService.loadCollections(forceReload: true)
                    // Haptic feedback is typically handled by the system for .refreshable
                }
                .navigationDestination(for: UUID.self) { collectionId in
                    // Find the collection using the ID from the full collections array,
                    // not the filtered one, to ensure navigation works even with search active.
                    if let collection = collections.first(where: { $0.id == collectionId }) {
                        CollectionDetailView(collection: collection)
                    } else {
                        Text("Collection not found")  // Should ideally not happen if ID is valid
                    }
                }
                .alert(
                    "Error Deleting Collection", isPresented: .constant(deletionError != nil),
                    actions: {
                        Button("OK", role: .cancel) { deletionError = nil }
                    },
                    message: {
                        if let error = deletionError {
                            Text(error)
                        }
                    }
                )
                .toolbar {
                    toolbarAddButton
                }
                .animation(.default, value: filteredCollections)  // Animation for list changes
            }
        }
        .sheet(isPresented: $showingGrowthStoryForm) {
            CollectionFormView()
                .environmentObject(collectionService)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: showingGrowthStoryForm)
        .animation(.default, value: collections.isEmpty && searchText.isEmpty)  // Animation for empty state transition
        .animation(.default, value: filteredCollections.isEmpty && !searchText.isEmpty)  // Animation for no search results transition
    }

    private var toolbarAddButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showingGrowthStoryForm = true
            } label: {
                Image(systemName: "wand.and.stars.inverse")  // Thematic icon
                    .foregroundColor(UITheme.Colors.primary)  // Thematic color
                    .padding(5)  // Increase touch target
            }
            .accessibilityLabel("Create New Collection")
            .accessibilityIdentifier("CollectionsListView_AddButton")
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
    let container = try! ModelContainer(
        for: StoryCollection.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let storyService = try! StoryService(context: container.mainContext)
    let collectionRepository = CollectionRepository(modelContext: container.mainContext)
    let achievementRepository = AchievementRepository(modelContext: container.mainContext)
    let collectionService = CollectionService(
        repository: collectionRepository,
        storyService: storyService,
        achievementRepository: achievementRepository
    )
    return CollectionsListView()
        .modelContainer(container)
        .environmentObject(collectionService)
}
