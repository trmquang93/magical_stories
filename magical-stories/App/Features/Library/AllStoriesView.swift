import SwiftData
import SwiftUI

struct AllStoriesView: View {
    @EnvironmentObject private var storyService: StoryService
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
        NavigationStack {
            ZStack(alignment: .top) {
                UITheme.Colors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("All Stories")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(UITheme.Colors.textPrimary)
                            .accessibilityIdentifier("AllStoriesView_Header")
                            .accessibilityLabel("AllStoriesView_Header")
                        Text("Your complete magical collection")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(UITheme.Colors.textSecondary)
                            .accessibilityIdentifier("AllStoriesView_Subtitle")
                            .accessibilityLabel("AllStoriesView_Subtitle")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 48)
                    .padding(.horizontal, 16)

                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(UITheme.Colors.textSecondary)
                            .padding(.leading, 12)
                        TextField("Search stories", text: $searchText)
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .padding(.vertical, 12)
                            .padding(.horizontal, 4)
                            .accessibilityIdentifier("AllStoriesView_SearchField")
                            .accessibilityLabel("AllStoriesView_SearchField")
                    }
                    .background(UITheme.Colors.surfacePrimary)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(UITheme.Colors.surfaceSecondary, lineWidth: 1)
                    )
                    .padding(.top, 24)
                    .padding(.horizontal, 16)

                    // Sort Options
                    HStack {
                        Text("Sort by:")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(UITheme.Colors.textSecondary)

                        Picker("Sort", selection: $sortOption) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .accessibilityIdentifier("AllStoriesView_SortPicker")

                        Spacer()
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 16)

                    if filteredAndSortedStories.isEmpty {
                        emptyStateView
                    } else {
                        // Stories List
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredAndSortedStories) { story in
                                    NavigationLink(value: story) {
                                        LibraryStoryCard(story: story)
                                            .accessibilityIdentifier(
                                                "AllStoriesView_StoryCard_\(story.id)")
                                    }
                                }
                            }
                            .padding(.top, 16)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                        }
                        .accessibilityIdentifier("AllStoriesView_StoriesList")
                    }
                }
            }
            .navigationDestination(for: Story.self) { story in
                StoryDetailView(story: story)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(UITheme.Colors.textSecondary.opacity(0.5))

            if searchText.isEmpty {
                Text("No stories found")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(UITheme.Colors.textPrimary)

                Text("Create your first magical story to see it here")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(UITheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("No matching stories")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(UITheme.Colors.textPrimary)

                Text("Try adjusting your search to find more stories")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(UITheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(.horizontal, 32)
        .accessibilityIdentifier("AllStoriesView_EmptyState")
    }

    // MARK: - Data Logic
    private var filteredStories: [Story] {
        if searchText.isEmpty {
            return storyService.stories
        } else {
            return storyService.stories.filter { story in
                story.title.localizedCaseInsensitiveContains(searchText)
                    || story.parameters.childName.localizedCaseInsensitiveContains(searchText)
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
        let storyService: StoryService
        do {
            storyService = try StoryService(context: container.mainContext)
        } catch {
            fatalError("Failed to create StoryService: \(error)")
        }
        return NavigationStack {
            AllStoriesView()
                .environment(\.modelContext, container.mainContext)
                .environmentObject(storyService)
        }
    }
}

#Preview {
    AllStoriesView.makePreview()
}
