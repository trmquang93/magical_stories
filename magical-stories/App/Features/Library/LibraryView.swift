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
                story.parameters.childName.localizedCaseInsensitiveContains(searchText) ||
                story.parameters.theme.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var emptyStateView: some View {
        MagicalEmptyStateView(
            title: "No Stories Yet",
            message: "Your magical stories will appear here once you create them",
            buttonTitle: "Create Story"
        ) {
            // TODO: Implement proper navigation to HomeView/StoryForm
            // This likely requires a shared state or coordinator to switch tabs
            // and potentially present the form modally or navigate within the Home tab's stack.
            print("Navigate to Create Story tapped - requires coordinator/state management")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100) // Adjust padding as needed
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

#Preview {
    NavigationStack {
        LibraryView()
            .environmentObject(StoryService())
    }
}
