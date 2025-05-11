// Import new subviews
import Foundation
import SwiftData
import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var storyService: StoryService
    @EnvironmentObject private var persistenceService: PersistenceService
    @EnvironmentObject private var collectionService: CollectionService
    @State private var searchText = ""
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""
    @State private var selectedCategoryName: String? = nil
    @State private var isSearchFocused = false
    @State private var sortOption: AllStoriesSortOptions.SortOption = .newest
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Background
                UITheme.Colors.background.ignoresSafeArea()
                VStack {
                    // Header
                    LibraryHeader()

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            // Search Bar
                            LibrarySearchBar(
                                searchText: $searchText, isSearchFocused: $isSearchFocused)

                            // Categories Carousel
                            LibraryCategoryCarousel(
                                categories: categories,
                                selectedCategoryName: selectedCategoryName,
                                onSelect: { selected in selectedCategoryName = selected }
                            )

                            // Active Category Filter
                            if let selectedCategory = selectedCategoryName {
                                LibraryActiveCategoryFilter(
                                    selectedCategoryName: selectedCategory,
                                    onClear: { selectedCategoryName = nil }
                                )
                            }

                            // Sort Options
                            HStack {
                                Text("Sort by:")
                                    .font(UITheme.Typography.bodyMedium)
                                    .foregroundColor(UITheme.Colors.textSecondary)

                                Picker("Sort", selection: $sortOption) {
                                    ForEach(AllStoriesSortOptions.SortOption.allCases) { option in
                                        Text(option.rawValue).tag(option)
                                    }
                                }
                                .pickerStyle(.menu)
                                .accentColor(UITheme.Colors.accent)

                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)

                            // All Stories Section
                            if filteredAndSortedStories.isEmpty {
                                LibraryEmptyState(
                                    mode: selectedCategoryName != nil || !searchText.isEmpty
                                        ? .noResults : .empty)
                            } else {
                                LazyVStack(spacing: 16) {
                                    ForEach(filteredAndSortedStories) { story in
                                        NavigationLink(value: story) {
                                            EnhancedStoryCard(story: story)
                                                .padding(.horizontal, 16)
                                                .accessibilityIdentifier(
                                                    "LibraryView_StoryCard_\(story.id)")
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 60)  // Space for tab bar
                    }
                }
            }
            .background(UITheme.Colors.background.ignoresSafeArea())
            .alert(
                "Delete Failed", isPresented: $showDeleteError,
                actions: {
                    Button("OK", role: .cancel) {}
                },
                message: {
                    Text(deleteErrorMessage)
                }
            )
            .navigationDestination(for: Story.self) { story in
                StoryDetailView(story: story)
                    .environmentObject(persistenceService)
                    .environmentObject(collectionService)
            }
        }
    }

    // MARK: - Data Logic
    var filteredStories: [Story] {
        var stories = storyService.stories
        if let categoryName = selectedCategoryName {
            stories = stories.filter { $0.categoryName == categoryName }
        }
        if !searchText.isEmpty {
            stories = stories.filter { story in
                story.title.localizedCaseInsensitiveContains(searchText)
                    || story.parameters.childName?.localizedCaseInsensitiveContains(searchText)
                        == true
                    || story.parameters.theme.localizedCaseInsensitiveContains(searchText)
            }
        }
        return stories
    }

    private var filteredAndSortedStories: [Story] {
        switch sortOption {
        case .newest:
            return filteredStories.sorted(by: { story1, story2 in
                story1.timestamp > story2.timestamp
            })
        case .oldest:
            return filteredStories.sorted(by: { story1, story2 in
                story1.timestamp < story2.timestamp
            })
        case .alphabetical:
            return filteredStories.sorted(by: { story1, story2 in
                story1.title < story2.title
            })
        case .mostRead:
            return filteredStories.sorted(by: { story1, story2 in
                story1.isCompleted && !story2.isCompleted
            })
        }
    }

    private var categories: [LibraryCategory] {
        LibraryCategory.all.map { def in
            let count = storyService.stories.filter { story in
                story.categoryName == def.name
            }.count
            return LibraryCategory(
                name: def.name, icon: def.icon, color: def.color, storyCount: count)
        }
    }
}

// MARK: - Helper Extensions
extension String {
    var isNotEmpty: Bool { !self.isEmpty }
}

// MARK: - Preview Helpers
extension LibraryView {
    static func makePreview() -> some View {
        // Use a fully mocked preview environment
        let mockStoryService = StoryServiceMock()
        let schema = Schema([Story.self, Page.self])
        let container = try! ModelContainer(
            for: schema, configurations: [.init(isStoredInMemoryOnly: true)])
        let context = ModelContext(container)
        let mockPersistence = MockPersistenceService()
        let now = Date()
        mockPersistence.storiesToLoad = (0..<2).map { i in
            let story = Story.previewStory(title: "Story #\(i+1)")
            story.timestamp = now.addingTimeInterval(TimeInterval(-i * 60))  // Unique timestamp
            return story
        }
        let storyService = try! StoryService(
            apiKey: "",
            context: context,
            persistenceService: mockPersistence
        )

        // Initialize repositories for CollectionService (needed for preview)
        let collectionRepository = CollectionRepository(modelContext: context)
        let achievementRepository = AchievementRepository(modelContext: context)

        // Create CollectionService with proper parameters
        let collectionService = CollectionService(
            repository: collectionRepository,
            storyService: storyService,
            achievementRepository: achievementRepository
        )

        return NavigationStack {
            LibraryView()
                .environmentObject(mockStoryService)
                .environmentObject(storyService)
                .environmentObject(mockPersistence)
                .environmentObject(collectionService)
        }
    }
}

// Fully standalone mock for preview only
private class StoryServiceMock: ObservableObject {
    @Published var stories: [Story] = [
        createMockStory(title: "The Magic Dragon", categoryName: "Fantasy", childName: "Emma"),
        createMockStory(
            title: "Adventures in the Forest", categoryName: "Adventure", childName: "Noah"),
        createMockStory(title: "Bedtime for Teddy", categoryName: "Bedtime", childName: "Sophia"),
        createMockStory(title: "Jungle Safari", categoryName: "Animals", childName: "Oliver"),
    ]

    private static func createMockStory(title: String, categoryName: String, childName: String)
        -> Story
    {
        let params = StoryParameters(
            childName: childName,
            childAge: 5,
            theme: categoryName,
            favoriteCharacter: "Dragon"
        )

        let page = Page(
            content: "Once upon a time...",
            pageNumber: 1
        )

        return Story(
            title: title,
            pages: [page],
            parameters: params,
            categoryName: categoryName
        )
    }
}

#Preview {
    LibraryView.makePreview()
}
