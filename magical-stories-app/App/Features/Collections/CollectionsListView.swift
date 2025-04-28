import SwiftData
import SwiftUI

struct CollectionsListView: View {
    @Query private var collections: [StoryCollection]
    @State private var searchText = ""
    @EnvironmentObject private var collectionService: CollectionService
    @State private var deletionError: String? = nil
    @State private var showingGrowthStoryForm = false
    @State private var scrollOffset: CGFloat = 0
    @State private var selectedFilter: CollectionFilter = .all

    // Animation states
    @State private var isLoading = true
    @Namespace private var animation

    private var filteredCollections: [StoryCollection] {
        let filtered = collections.filter {
            if !searchText.isEmpty {
                return $0.title.localizedCaseInsensitiveContains(searchText)
            }

            switch selectedFilter {
            case .all:
                return true
            case .completed:
                return $0.completionProgress >= 1.0
            case .inProgress:
                return $0.completionProgress > 0 && $0.completionProgress < 1.0
            case .notStarted:
                return $0.completionProgress == 0
            case .category(let category):
                return $0.category == category
            }
        }

        // Sort by name, but prioritize collections in progress
        return filtered.sorted {
            // First, sort by completion status (in progress first, then not started, then completed)
            if $0.completionProgress > 0 && $0.completionProgress < 1.0
                && ($1.completionProgress == 0 || $1.completionProgress == 1.0)
            {
                return true
            } else if $1.completionProgress > 0 && $1.completionProgress < 1.0
                && ($0.completionProgress == 0 || $0.completionProgress == 1.0)
            {
                return false
            }

            // Then by title alphabetically
            return $0.title < $1.title
        }
    }

    // Get all available categories from collections
    private var availableCategories: [String] {
        var categories = Set<String>()
        for collection in collections {
            categories.insert(collection.category)
        }
        return Array(categories).sorted()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Collection filters
                    collectionFilters

                    if isLoading {
                        loadingView
                    } else if collections.isEmpty && searchText.isEmpty {
                        CollectionsEmptyStateView()
                    } else if filteredCollections.isEmpty && !searchText.isEmpty {
                        CollectionsNoSearchResultsView(searchText: searchText)
                    } else {
                        // Main content with grid layout
                        ScrollView {
                            collectionGrid
                                .padding(.horizontal)
                                .padding(.top, 16)
                        }
                        .refreshable {
                            // Smooth loading animation with feedback
                            withAnimation {
                                isLoading = true
                            }

                            await collectionService.loadCollections(forceReload: true)

                            // Haptic feedback for refresh completion
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)

                            withAnimation {
                                isLoading = false
                            }
                        }
                    }
                }
            }
            .navigationTitle("Growth Collections")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search collections...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    createButton
                }
            }
            .navigationDestination(for: UUID.self) { collectionId in
                if let collection = collections.first(where: { $0.id == collectionId }) {
                    CollectionDetailView(collection: collection)
                } else {
                    Text("Collection not found")
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
            .onAppear {
                // Simulate loading for smoother transitions
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        isLoading = false
                    }
                }
            }
        }
        .sheet(isPresented: $showingGrowthStoryForm) {
            CollectionFormView()
                .environmentObject(collectionService)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: showingGrowthStoryForm)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: filteredCollections)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: searchText)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedFilter)
    }

    // Loading view with animated shimmers
    private var loadingView: some View {
        VStack(spacing: 20) {
            ForEach(0..<3) { _ in
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray5))
                                .frame(width: 100, height: 20)

                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray5))
                                .frame(width: 140, height: 16)
                        }
                    )
                    .padding(.horizontal)
                    .shimmer()
            }
        }
        .padding(.vertical)
    }

    // Collection filters row
    private var collectionFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All filter
                filterButton(for: .all, title: "All")

                // Status filters
                filterButton(for: .inProgress, title: "In Progress")
                filterButton(for: .completed, title: "Completed")

                // Category filters
                ForEach(availableCategories, id: \.self) { category in
                    filterButton(for: .category(category), title: formatCategoryName(category))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(
            Color(UIColor.secondarySystemGroupedBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        )
    }

    // Helper to format category names for display
    private func formatCategoryName(_ category: String) -> String {
        switch category {
        case "emotionalIntelligence": return "Emotional"
        case "socialSkills": return "Social"
        case "cognitiveDevelopment": return "Cognitive"
        case "creativityImagination": return "Creative"
        case "problemSolving": return "Problem Solving"
        case "resilienceGrit": return "Resilience"
        case "kindnessEmpathy": return "Kindness"
        default:
            // Split camelCase and capitalize
            return category.replacingOccurrences(
                of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression
            )
            .capitalized
        }
    }

    // Filter button with animations
    private func filterButton(for filter: CollectionFilter, title: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedFilter = filter
            }
        } label: {
            Text(title)
                .font(.system(size: 14, weight: selectedFilter == filter ? .bold : .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    ZStack {
                        if selectedFilter == filter {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.magicalPrimary)
                                .matchedGeometryEffect(id: "filterBackground", in: animation)
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                        }
                    }
                )
                .foregroundColor(selectedFilter == filter ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // Collection grid layout
    private var collectionGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)
            ],
            spacing: 20
        ) {
            ForEach(filteredCollections) { collection in
                NavigationLink(value: collection.id) {
                    CollectionCardView(collection: collection)
                        .contentShape(Rectangle())
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
                .buttonStyle(PlainButtonStyle())
                .contextMenu {
                    Button {
                        try? collectionService.deleteCollection(id: collection.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .padding(.bottom, 24)
    }

    // Create new collection button
    private var createButton: some View {
        Button {
            showingGrowthStoryForm = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.magicalPrimary)
            }
            .frame(width: 40, height: 40)
            .background(
                Circle()
                    .fill(Color.magicalPrimary.opacity(0.1))
            )
        }
        .accessibilityLabel("Create New Collection")
        .accessibilityIdentifier("CollectionsListView_AddButton")
        .sensoryFeedback(.impact(weight: .light), trigger: showingGrowthStoryForm)
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

// Collection filtering types
enum CollectionFilter: Equatable {
    case all
    case completed
    case inProgress
    case notStarted
    case category(String)

    static func == (lhs: CollectionFilter, rhs: CollectionFilter) -> Bool {
        switch (lhs, rhs) {
        case (.all, .all), (.completed, .completed), (.inProgress, .inProgress),
            (.notStarted, .notStarted):
            return true
        case (.category(let a), .category(let b)):
            return a == b
        default:
            return false
        }
    }
}
