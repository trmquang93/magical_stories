// Import new subviews
import Foundation
import SwiftData
import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var storyService: StoryService
    @State private var searchText = ""
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""
    @State private var selectedCategoryName: String? = nil
    @State private var isSearchFocused = false

    // Define an enum for navigation destinations
    enum ViewDestination: Hashable {
        case allStories
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Background
                UITheme.Colors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        LibraryHeader()

                        // Search Bar
                        LibrarySearchBar(searchText: $searchText, isSearchFocused: $isSearchFocused)

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

                        // Recent Stories Section
                        if !recentStories.isEmpty {
                            LibraryRecentStoriesSection(
                                recentStories: recentStories
                            )
                        }

                        // Empty state
                        if recentStories.isEmpty && searchText.isEmpty
                            && selectedCategoryName == nil
                        {
                            LibraryEmptyState(mode: .empty)
                        }

                        // No results state
                        if filteredStories.isEmpty
                            && (searchText.isNotEmpty || selectedCategoryName != nil)
                        {
                            LibraryEmptyState(mode: .noResults)
                        }
                    }
                    .padding(.bottom, 60)  // Space for tab bar
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
            }
            .navigationDestination(for: ViewDestination.self) { destination in
                switch destination {
                case .allStories:
                    AllStoriesView()
                }
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
                    || story.parameters.childName.localizedCaseInsensitiveContains(searchText)
                    || story.parameters.theme.localizedCaseInsensitiveContains(searchText)
            }
        }
        return stories
    }

    private var recentStories: [Story] {
        filteredStories.sorted { $0.timestamp > $1.timestamp }.prefix(2).map { $0 }
    }

    private var categories: [LibraryCategory] {
        libraryCategories.map { def in
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
        let schema = Schema([StoryModel.self, PageModel.self])
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
        return NavigationStack {
            LibraryView()
                .environmentObject(mockStoryService)
                .environmentObject(storyService)
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
