import SwiftUI
import SwiftData

struct LibraryView: View {
    @EnvironmentObject private var storyService: StoryService
    @State private var searchText = ""
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""
    
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
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Task {
                                            await deleteStory(story)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
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
            .alert("Delete Failed", isPresented: $showDeleteError, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(deleteErrorMessage)
            })
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
        .accessibilityIdentifier("LibraryEmptyState")
    }
    
    // MARK: - Deletion Logic
    private func deleteStory(_ story: Story) async {
        let id = story.id
        let beforeCount = storyService.stories.count
        await storyService.deleteStory(id: id)
        // If the count did not decrease, assume failure (since StoryService swallows errors)
        let afterCount = storyService.stories.count
        if afterCount == beforeCount {
            deleteErrorMessage = "Could not delete the story. Please try again."
            showDeleteError = true
        }
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
