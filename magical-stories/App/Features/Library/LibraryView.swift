import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var storyService: StoryService
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Empty state view
                if filteredStories.isEmpty {
                    emptyStateView
                } else {
                    // Stories grid
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
                        .padding(.vertical, Theme.Spacing.lg)
                    }
                }
            }
            .navigationTitle("Library")
            .navigationDestination(for: Story.self) { story in
                StoryDetailView(story: story)
            }
            .searchable(text: $searchText, prompt: "Search stories")
            .onAppear {
                Task {
                    await storyService.loadStories()
                }
            }
        }
    }
    
    private var filteredStories: [Story] {
        if searchText.isEmpty {
            return storyService.stories
        } else {
            return storyService.stories.filter { story in
                story.title.localizedCaseInsensitiveContains(searchText) ||
                story.childName.localizedCaseInsensitiveContains(searchText) ||
                story.theme.title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var emptyStateView: some View {
        MagicalEmptyStateView(
            title: "No Stories Yet",
            message: "Your magical stories will appear here once you create them",
            buttonTitle: "Create Story"
        ) {
            // Navigate to HomeView and show story form
            // In a real implementation, we would have a navigation coordinator to handle this
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

struct StoryCard: View {
    let story: Story
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            // Theme Icon
            HStack {
                Image(systemName: story.theme.iconName)
                    .foregroundColor(Theme.Colors.primary)
                Spacer()
                Text(dateFormatter.string(from: story.createdAt))
                    .font(Theme.Typography.bodySmall)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .padding(.bottom, Theme.Spacing.xxs)
            
            // Title
            Text(story.title)
                .font(Theme.Typography.headingSmall)
                .foregroundColor(Theme.Colors.textPrimary)
                .lineLimit(2)
            
            // Child name
            Text("For: \(story.childName)")
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
    NavigationStack {
        LibraryView()
            .environmentObject(StoryService())
    }
}
