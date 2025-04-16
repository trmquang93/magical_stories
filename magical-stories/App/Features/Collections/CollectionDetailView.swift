import SwiftUI
import SwiftData

struct CollectionDetailView: View {
    @EnvironmentObject private var collectionService: CollectionService
    @State private var achievements: [AchievementModel] = []
    @State private var isLoadingAchievements = false
    @Bindable var collection: StoryCollection // Use @Bindable for live updates

    init(collection: StoryCollection) {
        self.collection = collection
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(collection.title)
                    .font(.largeTitle)
                    .bold()

                Text(collection.descriptionText)
                    .font(.body)

                HStack {
                    Text("Category: \(collection.category)")
                        .font(.subheadline)
                    Spacer()
                    Text("Age Group: \(collection.ageGroup)")
                        .font(.subheadline)
                }

                ProgressView(value: collection.completionProgress)
                    .padding(.vertical)

                achievementsSection

                Text("Stories")
                    .font(.title2)
                    .bold()
                    .padding(.top)

                ForEach(collection.stories ?? []) { story in
                    storyRow(story: story)
                }
            }
            .padding()
        }
        .navigationTitle(collection.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Story.self) { story in
            StoryDetailView(story: story)
                .environmentObject(collectionService)
        }
        .task {
            await loadAchievements()
        }
    }

    @ViewBuilder
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Achievements")
                .font(.title3)
                .bold()
                .padding(.top, 8)
            if isLoadingAchievements {
                ProgressView().padding(.vertical)
            } else if achievements.isEmpty {
                Text("No achievements earned yet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(achievements, id: \ .id) { achievement in
                            achievementBadge(achievement)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Achievements section")
    }

    @ViewBuilder
    private func achievementBadge(_ achievement: AchievementModel) -> some View {
        VStack(spacing: 4) {
            Image(systemName: achievement.iconName ?? "star.fill")
                .resizable()
                .frame(width: 36, height: 36)
                .foregroundColor(.yellow)
                .accessibilityLabel(achievement.name)
            Text(achievement.name)
                .font(.caption)
                .bold()
                .multilineTextAlignment(.center)
            if achievement.achievementDescription.isEmpty {
                let desc = achievement.achievementDescription
                Text(desc)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Achievement: \(achievement.name)")
        .accessibilityHint(achievement.achievementDescription ?? "")
    }

    private func loadAchievements() async {
        isLoadingAchievements = true
        defer { isLoadingAchievements = false }
        guard let stories = collection.stories, !stories.isEmpty else {
            achievements = []
            return
        }
        var all: [AchievementModel] = []
        for story in stories {
            if let storyModel = story as? StoryModel {
                if let modelContext = storyModel.modelContext {
                    let repo = AchievementRepository(modelContext: modelContext)
                    if let storyAchievements = try? await repo.fetchAchievements(for: storyModel.id) {
                        all.append(contentsOf: storyAchievements)
                    }
                }
            }
        }
        achievements = all.filter { $0.type == .growthPathProgress }
    }

    // Helper function to break down the view complexity
    @ViewBuilder
    private func storyRow(story: Story) -> some View {
        NavigationLink(value: story) {
            HStack {
                Text(story.title)
                    .font(.headline)
                Spacer()
                if story.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .accessibilityLabel("Completed")
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                        .accessibilityLabel("Not completed")
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        CollectionDetailView(
            collection: StoryCollection(
                title: "Preview Collection",
                descriptionText: "This is a detailed preview of a story collection",
                category: "emotionalIntelligence",
                ageGroup: "elementary",
                stories: [],
                createdAt: Date(),
                updatedAt: Date()
            ))
    }
}
