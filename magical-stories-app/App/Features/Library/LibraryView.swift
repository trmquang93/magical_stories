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
                        // Header with animated gradient overlay
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Library")
                                    .font(UITheme.Typography.displayMedium)
                                    .foregroundColor(UITheme.Colors.textPrimary)
                                    .accessibilityIdentifier("LibraryView_Header")

                                Text("Your magical story collection")
                                    .font(UITheme.Typography.bodyMedium)
                                    .foregroundColor(UITheme.Colors.textSecondary)
                                    .accessibilityIdentifier("LibraryView_Subtitle")
                            }

                            Spacer()

                            // Animated sparkle icon
                            Image(systemName: "books.vertical.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.calmBlue, .magicPurple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .symbolEffect(.pulse, options: .repeating, value: true)
                        }
                        .padding(.top, UITheme.Spacing.xxxl)
                        .padding(.horizontal, UITheme.Spacing.lg)
                        .padding(.bottom, UITheme.Spacing.md)

                        // Search Bar with improved visual design
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(
                                    isSearchFocused
                                        ? UITheme.Colors.primary : UITheme.Colors.textSecondary
                                )
                                .font(.system(size: 16, weight: .medium))
                                .padding(.leading, UITheme.Spacing.md)

                            TextField(
                                "Search stories", text: $searchText,
                                onEditingChanged: { focused in
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isSearchFocused = focused
                                    }
                                }
                            )
                            .font(UITheme.Typography.bodyMedium)
                            .padding(.vertical, UITheme.Spacing.sm)
                            .accessibilityIdentifier("LibraryView_SearchField")

                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(UITheme.Colors.textSecondary)
                                        .font(.system(size: 16))
                                }
                                .padding(.trailing, UITheme.Spacing.sm)
                                .transition(.opacity)
                                .animation(.easeInOut, value: searchText)
                            }
                        }
                        .padding(.horizontal, UITheme.Spacing.sm)
                        .frame(height: 48)
                        .background(UITheme.Colors.surfacePrimary)
                        .cornerRadius(UITheme.Layout.cornerRadiusLarge)
                        .overlay(
                            RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusLarge)
                                .stroke(
                                    isSearchFocused
                                        ? UITheme.Colors.primary : UITheme.Colors.surfaceSecondary,
                                    lineWidth: isSearchFocused ? 2 : 1
                                )
                        )
                        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                        .padding(.horizontal, UITheme.Spacing.lg)
                        .padding(.bottom, UITheme.Spacing.md)

                        // Categories Carousel (moved up, horizontal scroll)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: UITheme.Spacing.md) {
                                ForEach(categories) { category in
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            if selectedCategoryName == category.name {
                                                selectedCategoryName = nil
                                            } else {
                                                selectedCategoryName = category.name
                                            }
                                        }
                                    }) {
                                        CategoryCarouselCard(
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
                            .padding(.horizontal, UITheme.Spacing.lg)
                            .padding(.vertical, UITheme.Spacing.sm)
                        }

                        // Active Category Filter with improved visual design
                        if let selectedCategory = selectedCategoryName {
                            HStack(spacing: UITheme.Spacing.sm) {
                                // Find the matching category to get icon and color
                                let categoryInfo = libraryCategories.first {
                                    $0.name == selectedCategory
                                }

                                if let info = categoryInfo {
                                    Image(systemName: info.icon)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(info.color)
                                }

                                Text("Filtered by: \(selectedCategory)")
                                    .font(UITheme.Typography.bodyMedium)
                                    .foregroundColor(UITheme.Colors.primary)

                                Spacer()

                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedCategoryName = nil
                                    }
                                }) {
                                    HStack(spacing: UITheme.Spacing.xxs) {
                                        Text("Clear")
                                            .font(UITheme.Typography.bodySmall.weight(.medium))
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 14))
                                    }
                                    .foregroundColor(UITheme.Colors.primary)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 10)
                                    .background(
                                        Capsule()
                                            .fill(UITheme.Colors.primary.opacity(0.1))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .accessibilityIdentifier("LibraryView_ClearFilterButton")
                                .accessibilityLabel("Clear category filter")
                            }
                            .padding(.horizontal, UITheme.Spacing.lg)
                            .padding(.bottom, UITheme.Spacing.md)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Recent Stories with enhanced visual design
                        if !recentStories.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack {
                                    Text("Recent Stories")
                                        .font(UITheme.Typography.headingMedium)
                                        .foregroundColor(UITheme.Colors.textPrimary)
                                        .accessibilityIdentifier("LibraryView_RecentStoriesSection")

                                    Spacer()

                                    NavigationLink(value: ViewDestination.allStories) {
                                        HStack(spacing: UITheme.Spacing.xxs) {
                                            Text("See All")
                                                .font(
                                                    UITheme.Typography.bodySmall.weight(.semibold))
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12, weight: .bold))
                                        }
                                        .foregroundColor(UITheme.Colors.primary)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(
                                            Capsule()
                                                .fill(UITheme.Colors.primary.opacity(0.1))
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .accessibilityIdentifier("LibraryView_SeeAllButton")
                                    .accessibilityLabel("See All Stories")
                                }
                                .padding(.horizontal, UITheme.Spacing.lg)
                                .padding(.top, UITheme.Spacing.xl)
                                .padding(.bottom, UITheme.Spacing.md)

                                ForEach(recentStories) { story in
                                    NavigationLink(value: story) {
                                        EnhancedStoryCard(story: story)
                                            .accessibilityIdentifier(
                                                "LibraryView_StoryCard_\(story.id)")
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal, UITheme.Spacing.lg)
                                    .padding(.bottom, UITheme.Spacing.md)
                                }
                            }
                        }

                        // Empty state
                        if recentStories.isEmpty && searchText.isEmpty
                            && selectedCategoryName == nil
                        {
                            VStack(spacing: UITheme.Spacing.lg) {
                                Image(systemName: "books.vertical")
                                    .font(.system(size: 50))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [
                                                UITheme.Colors.surfaceSecondary,
                                                UITheme.Colors.textSecondary,
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )

                                Text("Your library is empty")
                                    .font(UITheme.Typography.headingMedium)
                                    .foregroundColor(UITheme.Colors.textPrimary)

                                Text("Create your first magical story on the Home tab")
                                    .font(UITheme.Typography.bodyMedium)
                                    .foregroundColor(UITheme.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                            .padding(.horizontal, UITheme.Spacing.lg)
                        }

                        // No results state
                        if filteredStories.isEmpty
                            && (searchText.isNotEmpty || selectedCategoryName != nil)
                        {
                            VStack(spacing: UITheme.Spacing.lg) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(UITheme.Colors.textSecondary)

                                Text("No stories found")
                                    .font(UITheme.Typography.headingMedium)
                                    .foregroundColor(UITheme.Colors.textPrimary)

                                Text("Try adjusting your search or filters")
                                    .font(UITheme.Typography.bodyMedium)
                                    .foregroundColor(UITheme.Colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                            .padding(.horizontal, UITheme.Spacing.lg)
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

// MARK: - EnhancedCategoryCard
struct EnhancedCategoryCard: View {
    var category: LibraryCategory
    var isSelected: Bool = false

    var body: some View {
        ZStack {
            // Card background with gradient
            RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusLarge)
                .fill(UITheme.Colors.surfacePrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusLarge)
                        .stroke(
                            isSelected ? category.color : UITheme.Colors.surfaceSecondary,
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 4
                )

            // Content
            VStack(alignment: .leading, spacing: UITheme.Spacing.sm) {
                // Header with icon and selection indicator
                HStack {
                    ZStack {
                        Circle()
                            .fill(category.color.opacity(0.15))
                            .frame(width: 36, height: 36)

                        Image(systemName: category.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(category.color)
                    }

                    Spacer()

                    if isSelected {
                        ZStack {
                            Circle()
                                .fill(category.color.opacity(0.15))
                                .frame(width: 20, height: 20)

                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(category.color)
                        }
                    }
                }

                Spacer()

                // Category name and count
                Text(category.name)
                    .font(UITheme.Typography.headingSmall)
                    .foregroundColor(UITheme.Colors.textPrimary)

                Text("\(category.storyCount) stories")
                    .font(UITheme.Typography.bodySmall)
                    .foregroundColor(UITheme.Colors.textSecondary)
            }
            .padding(UITheme.Spacing.md)
        }
        .frame(height: 120)
        .contentShape(Rectangle())
    }
}

// MARK: - EnhancedStoryCard
struct EnhancedStoryCard: View {
    var story: Story

    var body: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusLarge)
                .fill(UITheme.Colors.surfacePrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusLarge)
                        .stroke(UITheme.Colors.surfaceSecondary, lineWidth: 1)
                )
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 6,
                    x: 0,
                    y: 3
                )

            // Content
            HStack(spacing: UITheme.Spacing.md) {
                // Category icon with color
                if let categoryName = story.categoryName,
                    let categoryInfo = libraryCategories.first(where: { $0.name == categoryName })
                {
                    ZStack {
                        Circle()
                            .fill(categoryInfo.color.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: categoryInfo.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(categoryInfo.color)
                    }
                } else {
                    // Fallback icon if no category
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: "book")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color.gray)
                    }
                }

                VStack(alignment: .leading, spacing: UITheme.Spacing.xxs) {
                    // Title with badge for read status
                    HStack(alignment: .center, spacing: UITheme.Spacing.xxs) {
                        Text(story.title)
                            .font(UITheme.Typography.headingSmall)
                            .foregroundColor(UITheme.Colors.textPrimary)
                            .lineLimit(1)

                        if story.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(UITheme.Colors.success)
                        }
                    }

                    // Categories badges
                    HStack(spacing: UITheme.Spacing.xxs) {
                        if let categoryName = story.categoryName {
                            Text(categoryName)
                                .font(UITheme.Typography.bodySmall.weight(.medium))
                                .foregroundColor(UITheme.Colors.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(UITheme.Colors.surfaceSecondary.opacity(0.5))
                                .cornerRadius(UITheme.Layout.cornerRadiusSmall)
                        }

                        // Theme badge if different from category
                        if story.parameters.theme != story.categoryName {
                            Text(story.parameters.theme)
                                .font(UITheme.Typography.bodySmall.weight(.medium))
                                .foregroundColor(UITheme.Colors.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(UITheme.Colors.surfaceSecondary.opacity(0.3))
                                .cornerRadius(UITheme.Layout.cornerRadiusSmall)
                        }
                    }

                    // Child name and creation date
                    HStack {
                        Text("For \(story.parameters.childName)")
                            .font(UITheme.Typography.bodySmall)
                            .foregroundColor(UITheme.Colors.textSecondary)

                        Spacer()

                        // Format relative date
                        Text(relativeDate(from: story.timestamp))
                            .font(UITheme.Typography.bodySmall)
                            .foregroundColor(UITheme.Colors.textSecondary)
                    }
                }

                Spacer()

                // Right chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(UITheme.Colors.textSecondary)
            }
            .padding(UITheme.Spacing.md)
        }
        .frame(height: 100)
        .contentShape(Rectangle())
    }

    // Helper to format dates in a relative manner
    private func relativeDate(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - LibraryCategoryCard (legacy, for compatibility)
struct LibraryCategoryCard: View {
    var category: LibraryCategory
    var isSelected: Bool = false

    var body: some View {
        EnhancedCategoryCard(category: category, isSelected: isSelected)
    }
}

// MARK: - LibraryStoryCard (legacy, for compatibility)
struct LibraryStoryCard: View {
    var story: Story

    var body: some View {
        EnhancedStoryCard(story: story)
    }
}

// MARK: - StoryCard
struct StoryCard: View {
    let story: Story

    var body: some View {
        EnhancedStoryCard(story: story)
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

// Add the new CategoryCarouselCard below:
struct CategoryCarouselCard: View {
    var category: LibraryCategory
    var isSelected: Bool = false
    var body: some View {
        VStack(spacing: UITheme.Spacing.xs) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [category.color.opacity(0.18), category.color.opacity(0.38)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 54, height: 54)
                Image(systemName: category.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(category.color)
            }
            .overlay(
                Circle()
                    .stroke(
                        isSelected ? category.color : Color.clear,
                        lineWidth: isSelected ? 3 : 0
                    )
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            )
            Text(category.name)
                .font(UITheme.Typography.bodyMedium.weight(.semibold))
                .foregroundColor(UITheme.Colors.textPrimary)
                .lineLimit(1)
            Text("\(category.storyCount) stories")
                .font(UITheme.Typography.bodySmall)
                .foregroundColor(UITheme.Colors.textSecondary)
        }
        .padding(.vertical, UITheme.Spacing.sm)
        .padding(.horizontal, UITheme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusMedium)
                .fill(isSelected ? category.color.opacity(0.08) : Color.clear)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        )
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .shadow(
            color: isSelected ? category.color.opacity(0.12) : Color.clear, radius: 8, x: 0, y: 2
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }
}
