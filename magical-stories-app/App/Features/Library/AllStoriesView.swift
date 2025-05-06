import SwiftData
import SwiftUI

struct AllStoriesView: View {
    @EnvironmentObject private var storyService: StoryService
    @EnvironmentObject private var persistenceService: PersistenceService
    @EnvironmentObject private var collectionService: CollectionService
    @State private var searchText: String
    @State private var sortOption: SortOption = .newest

    // For testing
    init(searchText: String = "") {
        self._searchText = State(initialValue: searchText)
    }

    enum SortOption: String, CaseIterable, Identifiable {
        case newest = "Newest"
        case oldest = "Oldest"
        case alphabetical = "A-Z"
        case mostRead = "Completed"

        var id: String { self.rawValue }
    }

    var body: some View {
        ZStack(alignment: .top) {
            UITheme.Colors.background.ignoresSafeArea()
            VStack(spacing: 0) {
                AllStoriesHeader()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 48)
                    .padding(.horizontal, 16)
                AllStoriesSearchBar(searchText: $searchText)
                    .padding(.top, 24)
                    .padding(.horizontal, 16)
                AllStoriesSortOptions(sortOption: $sortOption)
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
                if filteredAndSortedStories.isEmpty {
                    AllStoriesEmptyState(searchText: searchText)
                } else {
                    AllStoriesList(stories: filteredAndSortedStories)
                }
            }
        }
        .navigationDestination(for: Story.self) { story in
            StoryDetailView(story: story)
                .environmentObject(persistenceService)
                .environmentObject(collectionService)
        }
    }

    // MARK: - Data Logic
    private var filteredStories: [Story] {
        if searchText.isEmpty {
            return storyService.stories
        } else {
            return storyService.stories.filter { story in
                story.title.localizedCaseInsensitiveContains(searchText)
                    || story.parameters.childName?.localizedCaseInsensitiveContains(searchText) == true
                    || story.parameters.theme.localizedCaseInsensitiveContains(searchText)
            }
        }
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
}

extension AllStoriesView {
    static func makePreview() -> some View {
        let container: ModelContainer
        do {
            container = try ModelContainer()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // Initialize services
        let persistenceService = PersistenceService(context: container.mainContext)
        let storyService: StoryService
        do {
            storyService = try StoryService(
                context: container.mainContext, persistenceService: persistenceService)
        } catch {
            fatalError("Failed to create StoryService: \(error)")
        }

        // Initialize repositories for CollectionService
        let collectionRepository = CollectionRepository(modelContext: container.mainContext)
        let achievementRepository = AchievementRepository(modelContext: container.mainContext)

        // Create CollectionService with proper parameters
        let collectionService = CollectionService(
            repository: collectionRepository,
            storyService: storyService,
            achievementRepository: achievementRepository
        )

        // Note: Do not wrap in a NavigationStack - it's already wrapped in a NavigationStack
        // by the parent view (MainTabView > LibraryView)
        return AllStoriesView()
            .environment(\.modelContext, container.mainContext)
            .environmentObject(storyService)
            .environmentObject(persistenceService)
            .environmentObject(collectionService)
    }
}

#Preview {
    AllStoriesView.makePreview()
}
