import SwiftUI
import SwiftData

// MARK: - Category Mapping
/// Maps design categories to icons and colors
struct LibraryCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String // SF Symbol
    let color: Color
    let storyCount: Int
}

private let libraryCategories: [(name: String, icon: String, color: Color, themeKeywords: [String])] = [
    ("Fantasy", "sparkles", Color(red: 1.0, green: 0.38, blue: 0.48), ["fantasy", "magic", "imagination"]),
    ("Animals", "pawprint", Color(red: 0.31, green: 0.55, blue: 1.0), ["animal", "animals", "pet", "creature"]),
    ("Bedtime", "moon.stars", Color(red: 0.48, green: 0.38, blue: 1.0), ["bedtime", "sleep", "night"]),
    ("Adventure", "rocket", Color(red: 0.0, green: 0.72, blue: 0.66), ["adventure", "explore", "journey"])
]

struct LibraryView: View {
    @EnvironmentObject private var storyService: StoryService
    @State private var searchText = ""
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Library")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.textPrimary)
                            .accessibilityIdentifier("LibraryView_Header")
                            .accessibilityLabel("LibraryView_Header")
                        Text("Your magical story collection")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(Theme.Colors.textSecondary)
                            .accessibilityIdentifier("LibraryView_Subtitle")
                            .accessibilityLabel("LibraryView_Subtitle")
                    }
                    .padding(.top, 48)
                    .padding(.horizontal, 16)

                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Theme.Colors.textSecondary)
                            .padding(.leading, 12)
                        TextField("Search stories", text: $searchText)
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .padding(.vertical, 12)
                            .padding(.horizontal, 4)
                            .accessibilityIdentifier("LibraryView_SearchField")
                            .accessibilityLabel("LibraryView_SearchField")
                    }
                    .background(Theme.Colors.surfacePrimary)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Theme.Colors.surfaceSecondary, lineWidth: 1)
                    )
                    .padding(.top, 24)
                    .padding(.horizontal, 16)

                    // Recent Stories
                    if !recentStories.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recent Stories")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(Theme.Colors.textPrimary)
                                .padding(.top, 32)
                                .padding(.bottom, 8)
                                .padding(.horizontal, 0)
                                .accessibilityIdentifier("LibraryView_RecentStoriesSection")
                                .accessibilityLabel("LibraryView_RecentStoriesSection")
                            ForEach(recentStories) { story in
                                LibraryStoryCard(story: story)
                            }
                        }
                        .padding(.horizontal, 0)
                        .padding(.horizontal, 16)
                    }

                    // Categories
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Categories")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(Theme.Colors.textPrimary)
                            .padding(.top, 32)
                            .padding(.bottom, 8)
                            .accessibilityIdentifier("LibraryView_CategoriesSection")
                            .accessibilityLabel("LibraryView_CategoriesSection")
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(categories) { category in
                                LibraryCategoryCard(category: category)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            // Tab bar highlight is handled by MainTabView
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        .alert("Delete Failed", isPresented: $showDeleteError, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            Text(deleteErrorMessage)
        })
    }
    
    // MARK: - Data Logic
    private var filteredStories: [Story] {
        if searchText.isEmpty {
            return storyService.stories
        } else {
            return storyService.stories.filter { story in
                story.title.localizedCaseInsensitiveContains(searchText) ||
                story.parameters.childName.localizedCaseInsensitiveContains(searchText) ||
                story.parameters.theme.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    private var recentStories: [Story] {
        filteredStories.sorted { $0.timestamp > $1.timestamp }.prefix(2).map { $0 }
    }

    private var categories: [LibraryCategory] {
        libraryCategories.map { def in
            let count = storyService.stories.filter { story in
                def.themeKeywords.contains(where: { story.parameters.theme.lowercased().contains($0) })
            }.count
            return LibraryCategory(name: def.name, icon: def.icon, color: def.color, storyCount: count)
        }
    }
}

// MARK: - Story Card (Recent Stories)
struct LibraryStoryCard: View {
    let story: Story
    var icon: String {
        // Map theme to icon
        let theme = story.parameters.theme.lowercased()
        if theme.contains("adventure") { return "rocket" }
        if theme.contains("animal") { return "pawprint" }
        if theme.contains("bedtime") || theme.contains("sleep") { return "moon.stars" }
        if theme.contains("fantasy") || theme.contains("magic") { return "sparkles" }
        return "book" // fallback
    }
    var iconColor: Color {
        let theme = story.parameters.theme.lowercased()
        if theme.contains("adventure") { return Color(red: 0.0, green: 0.72, blue: 0.66) }
        if theme.contains("animal") { return Color(red: 0.31, green: 0.55, blue: 1.0) }
        if theme.contains("bedtime") || theme.contains("sleep") { return Color(red: 0.48, green: 0.38, blue: 1.0) }
        if theme.contains("fantasy") || theme.contains("magic") { return Color(red: 1.0, green: 0.38, blue: 0.48) }
        return Color(red: 0.48, green: 0.38, blue: 1.0)
    }
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(story.title)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.Colors.textPrimary)
                Text("Read \(relativeDateString(from: story.timestamp)) • \(storyDurationString(story: story))")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            Spacer()
            Image(systemName: "ellipsis")
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .padding(16)
        .background(Theme.Colors.surfacePrimary)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.Colors.surfaceSecondary, lineWidth: 1)
        )
    }
    // Helper for relative date
    private func relativeDateString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    // Helper for duration (estimate: 200 words/minute)
    private func storyDurationString(story: Story) -> String {
        let wordCount = story.pages.map { $0.content.split(separator: " ").count }.reduce(0, +)
        let minutes = max(1, Int(round(Double(wordCount) / 200.0)))
        return "\(minutes) min read"
    }
}

// MARK: - Category Card
struct LibraryCategoryCard: View {
    let category: LibraryCategory
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(category.color.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: category.icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(category.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.Colors.textPrimary)
                Text("\(category.storyCount) stories")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Theme.Colors.surfacePrimary)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.Colors.surfaceSecondary, lineWidth: 1)
        )
    }
}

struct StoryCard: View {
    let story: Story
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            // Theme Icon
            HStack {
                Image(systemName: "book.closed") // TODO: Map theme string to icon
                    .foregroundColor(Theme.Colors.primary)
                Spacer()
                Text(dateFormatter.string(from: story.timestamp))
                    .font(Theme.Typography.bodySmall)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .padding(.bottom, Theme.Spacing.xxs)
            
            // Title
            Text(story.title)
                .font(Theme.Typography.headingSmall)
                .foregroundColor(Theme.Colors.textPrimary)
                .accessibilityIdentifier("StoryTitle_\(story.title)")
                .lineLimit(2)
            
            // Child name
            Text("For: \(story.parameters.childName)")
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
