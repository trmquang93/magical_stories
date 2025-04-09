import SwiftUI
import SwiftData

struct LibraryView: View {
    @EnvironmentObject private var storyService: StoryService
    @EnvironmentObject private var collectionService: CollectionService
    
    @State private var searchText = ""
    @State private var showingNewCollectionForm = false
    
    enum LibrarySegment: String, CaseIterable, Identifiable {
        case stories = "Stories"
        case collections = "Collections"
        var id: String { self.rawValue }
    }
    @State private var selectedSegment: LibrarySegment = .stories
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View Type", selection: $selectedSegment) {
                    ForEach(LibrarySegment.allCases) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, Theme.Spacing.sm)
                
                Group {
                    if selectedSegment == .stories {
                        storiesContentView
                    } else {
                        CollectionsListView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Library")
            .navigationDestination(for: Story.self) { story in
                StoryDetailView(story: story)
            }
            .navigationDestination(for: GrowthCollection.self) { collection in
                CollectionDetailView(collection: collection)
            }
            .searchable(text: $searchText, prompt: "Search library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewCollectionForm = true
                    } label: {
                        Label("New Collection", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingNewCollectionForm) {
                CollectionFormView()
                    .environmentObject(collectionService)
            }
            .onAppear {
                Task {
                    await storyService.loadStories()
                    await collectionService.loadCollections()
                }
            }
        }
    }
    
    @ViewBuilder
    private var storiesContentView: some View {
        if filteredStories.isEmpty && searchText.isEmpty {
            MagicalEmptyStateView(
                title: "No Stories Yet",
                message: "Your magical stories will appear here once you create them.",
                buttonTitle: "Create Story"
            ) {
                print("Create Story tapped")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if filteredStories.isEmpty && !searchText.isEmpty {
            Text("No stories found matching '\(searchText)'.")
                .foregroundColor(Theme.Colors.textSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.md) {
                    ForEach(filteredStories) { story in
                        NavigationLink(value: story) {
                            StoryCard(story: story)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
            }
        }
    }
    
    @ViewBuilder
    private var collectionsContentView: some View {
        if collectionService.collections.isEmpty {
            MagicalEmptyStateView(
                title: "No Collections Yet",
                message: "Create a new collection to start a guided learning journey!",
                buttonTitle: "Create Collection"
            ) {
                showingNewCollectionForm = true
            }
             .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(collectionService.collections) { collection in
                VStack(alignment: .leading) {
                    Text(collection.title).font(.headline)
                    Text(collection.description ?? "").font(.subheadline).foregroundColor(.gray)
                }
            }
        }
    }
    
    private var filteredStories: [Story] {
        guard selectedSegment == .stories else { return [] }
        if searchText.isEmpty {
            return storyService.stories
        } else {
            return storyService.stories.filter { story in
                story.title.localizedCaseInsensitiveContains(searchText) ||
                (story.parameters.childName ?? "").localizedCaseInsensitiveContains(searchText) ||
                story.parameters.theme.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

struct StoryCard: View {
    let story: Story
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Image(systemName: "book.closed")
                    .foregroundColor(Theme.Colors.primary)
                Spacer()
                Text(dateFormatter.string(from: story.timestamp))
                    .font(Theme.Typography.bodySmall)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .padding(.bottom, Theme.Spacing.xxs)
            
            Text(story.title)
                .font(Theme.Typography.headingSmall)
                .foregroundColor(Theme.Colors.textPrimary)
                .lineLimit(2)
            
            Text("For: \(story.parameters.childName ?? "Unknown")")
                .font(Theme.Typography.bodySmall)
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
        .background(Theme.Colors.surfacePrimary)
        .cornerRadius(Theme.Layout.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

#Preview {
    let container = try! ModelContainer()
    let collectionService = CollectionService.preview
    Task {
        await collectionService.loadCollections()
        if collectionService.collections.isEmpty {
            let previewCollection = GrowthCollection.previewExample
            try? await collectionService.persistenceService.saveCollection(previewCollection)
            await collectionService.loadCollections()
        }
    }
    return NavigationStack {
        LibraryView()
            .environment(\.modelContext, container.mainContext)
            .environmentObject(try! StoryService(context: container.mainContext, persistenceService: PreviewPersistenceService()))
            .environmentObject(collectionService)
    }
}
