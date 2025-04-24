import SwiftData
import SwiftUI

// MARK: - Category Mapping
/// Maps design categories to icons and colors
struct LibraryCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String  // SF Symbol
    let color: Color
    let storyCount: Int
}

private let libraryCategories:
    [(name: String, icon: String, color: Color, themeKeywords: [String])] = [
        (
            "Fantasy", "sparkles", Color(red: 1.0, green: 0.38, blue: 0.48),
            ["fantasy", "magic", "imagination"]
        ),
        (
            "Animals", "pawprint", Color(red: 0.31, green: 0.55, blue: 1.0),
            ["animal", "animals", "pet", "creature"]
        ),
        (
            "Bedtime", "moon.stars", Color(red: 0.48, green: 0.38, blue: 1.0),
            ["bedtime", "sleep", "night"]
        ),
        (
            "Adventure", "rocket", Color(red: 0.0, green: 0.72, blue: 0.66),
            ["adventure", "explore", "journey"]
        ),
    ]

struct LibraryView: View {
    @EnvironmentObject private var storyService: StoryService
    @State private var searchText = ""
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""
    @State private var selectedCategoryName: String? = nil

    // Define an enum for navigation destinations
    enum ViewDestination: Hashable {
        case allStories
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Library")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(UITheme.Colors.textPrimary)
                                .accessibilityIdentifier("LibraryView_Header")
                                .accessibilityLabel("LibraryView_Header")
                            Text("Your magical story collection")
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundColor(UITheme.Colors.textSecondary)
                                .accessibilityIdentifier("LibraryView_Subtitle")
                                .accessibilityLabel("LibraryView_Subtitle")
                        }
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
                                .accessibilityIdentifier("LibraryView_SearchField")
                                .accessibilityLabel("LibraryView_SearchField")
                        }
                        .background(UITheme.Colors.surfacePrimary)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(UITheme.Colors.surfaceSecondary, lineWidth: 1)
                        )
                        .padding(.top, 24)
                        .padding(.horizontal, 16)

                        // Active Category Filter (if any)
                        if let selectedCategory = selectedCategoryName {
                            HStack {
                                Text("Category: \(selectedCategory)")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(UITheme.Colors.primary)

                                Spacer()

                                Button(action: {
                                    selectedCategoryName = nil
                                }) {
                                    HStack(spacing: 4) {
                                        Text("Clear")
                                            .font(
                                                .system(size: 14, weight: .medium, design: .rounded)
                                            )
                                        Image(systemName: "xmark.circle.fill")
                                    }
                                    .foregroundColor(UITheme.Colors.primary)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .accessibilityIdentifier("LibraryView_ClearFilterButton")
                                .accessibilityLabel("Clear category filter")
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        }

                        // Recent Stories
                        if !recentStories.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Recent Stories")
                                        .font(
                                            .system(size: 20, weight: .semibold, design: .rounded)
                                        )
                                        .foregroundColor(UITheme.Colors.textPrimary)
                                        .accessibilityIdentifier("LibraryView_RecentStoriesSection")
                                        .accessibilityLabel("LibraryView_RecentStoriesSection")

                                    Spacer()

                                    NavigationLink(value: ViewDestination.allStories) {
                                        Text("See All")
                                            .font(
                                                .system(
                                                    size: 15, weight: .semibold, design: .rounded)
                                            )
                                            .foregroundColor(UITheme.Colors.primary)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .accessibilityIdentifier("LibraryView_SeeAllButton")
                                    .accessibilityLabel("See All Stories")
                                    .contentShape(Rectangle())
                                }
                                .padding(.top, 32)
                                .padding(.bottom, 8)
                                .padding(.horizontal, 0)

                                ForEach(recentStories) { story in
                                    NavigationLink(value: story) {
                                        LibraryStoryCard(story: story)
                                            .accessibilityIdentifier(
                                                "LibraryView_StoryCard_\(story.id)")
                                    }
                                }
                            }
                            .padding(.horizontal, 0)
                            .padding(.horizontal, 16)
                        }

                        // Categories
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Categories")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(UITheme.Colors.textPrimary)
                                .padding(.top, 32)
                                .padding(.bottom, 8)
                                .accessibilityIdentifier("LibraryView_CategoriesSection")
                                .accessibilityLabel("LibraryView_CategoriesSection")
                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16
                            ) {
                                ForEach(categories) { category in
                                    Button(action: {
                                        // If category is already selected, clear the filter
                                        // Otherwise, set the selected category
                                        if selectedCategoryName == category.name {
                                            selectedCategoryName = nil
                                        } else {
                                            selectedCategoryName = category.name
                                        }
                                    }) {
                                        LibraryCategoryCard(
                                            category: category,
                                            isSelected: category.name == selectedCategoryName
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .accessibilityIdentifier(
                                        "LibraryView_CategoryCard_\(category.name)"
                                    )
                                    .accessibilityLabel(
                                        "Category: \(category.name), \(category.storyCount) stories"
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                }
                // Tab bar highlight is handled by MainTabView
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

        // First filter by selected category if any
        if let categoryName = selectedCategoryName {
            stories = stories.filter { $0.categoryName == categoryName }
        }

        // Then filter by search text if any
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
            // Count stories for each category based on categoryName
            let count = storyService.stories.filter { story in
                story.categoryName == def.name
            }.count

            return LibraryCategory(
                name: def.name, icon: def.icon, color: def.color, storyCount: count)
        }
    }
}

// MARK: - LibraryCategoryCard
struct LibraryCategoryCard: View {
    var category: LibraryCategory
    var isSelected: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(UITheme.Colors.surfacePrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? category.color : UITheme.Colors.surfaceSecondary,
                            lineWidth: isSelected ? 2 : 1)
                )
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 4
                )

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: category.icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(category.color)

                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(category.color)
                        }
                    }

                    Text(category.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(UITheme.Colors.textPrimary)

                    Text("\(category.storyCount) stories")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(UITheme.Colors.textSecondary)
                }
                .padding(16)

                Spacer()
            }
        }
        .frame(height: 90)
    }
}

// MARK: - LibraryStoryCard
struct LibraryStoryCard: View {
    var story: Story

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(UITheme.Colors.surfacePrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(UITheme.Colors.surfaceSecondary, lineWidth: 1)
                )
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 4
                )

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(story.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(UITheme.Colors.textPrimary)
                        .lineLimit(1)

                    HStack {
                        if let categoryName = story.categoryName {
                            Text(categoryName)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(UITheme.Colors.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(UITheme.Colors.surfaceSecondary.opacity(0.5))
                                .cornerRadius(8)
                        }

                        // Theme is displayed with or without category
                        Text(story.parameters.theme)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(UITheme.Colors.textSecondary)
                    }

                    Text("For \(story.parameters.childName)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(UITheme.Colors.textSecondary)
                }
                .padding(16)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(UITheme.Colors.textSecondary)
                    .padding(.trailing, 16)
            }
        }
        .frame(height: 90)
    }
}

struct StoryCard: View {
    let story: Story

    var body: some View {
        VStack(alignment: .leading, spacing: UITheme.Spacing.xs) {
            // Theme Icon
            HStack {
                Image(systemName: "book.closed")  // TODO: Map theme string to icon
                    .foregroundColor(UITheme.Colors.primary)
                Spacer()
                Text(dateFormatter.string(from: story.timestamp))
                    .font(UITheme.Typography.bodySmall)
                    .foregroundColor(UITheme.Colors.textSecondary)
            }
            .padding(.bottom, UITheme.Spacing.xxs)

            // Title
            Text(story.title)
                .font(UITheme.Typography.headingSmall)
                .foregroundColor(UITheme.Colors.textPrimary)
                .accessibilityIdentifier("StoryTitle_\(story.title)")
                .lineLimit(2)

            // Child name
            Text("For: \(story.parameters.childName)")
                .font(UITheme.Typography.bodySmall)
                .foregroundColor(UITheme.Colors.textSecondary)
        }
        .padding(UITheme.Spacing.md)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
        .background(UITheme.Colors.surfacePrimary)
        .cornerRadius(UITheme.Layout.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

extension LibraryView {
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
            LibraryView()
                .environment(\.modelContext, container.mainContext)
                .environmentObject(storyService)
        }
    }
}

#Preview {
    LibraryView.makePreview()
}
