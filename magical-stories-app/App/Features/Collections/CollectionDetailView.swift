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

                // 1. Improved Progress Visualization
                circularProgressView

                // 3. Enhance Achievement Badges Display
                achievementsSection

                Text("Stories")
                    .font(.title2)
                    .bold()
                    .padding(.top)

                ForEach(collection.stories ?? []) { story in
                    // 4. Improve Story List Presentation
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

    // 1. Improved Progress Visualization
    private var circularProgressView: some View {
        ZStack {
            CircularProgressView(progress: collection.completionProgress)
                .frame(width: 100, height: 100)

            Text("\(Int(collection.completionProgress * 100))%")
                .font(.title3)
                .bold()
        }
        .padding(.vertical)
    }

    // 3. Enhance Achievement Badges Display
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
                            // 3. Enhance Achievement Badges Display
                            achievementBadge(achievement)
                                .onAppear {
                                    // 2. Add Animations for Progress Updates
                                    // Add a subtle celebration animation when progress reaches 100%
                                    if collection.completionProgress == 1.0 {
                                        // Trigger celebration animation
                                        print("Celebration animation triggered!")
                                        // 5. Add Haptic Feedback
                                        let generator = UINotificationFeedbackGenerator()
                                        generator.notificationOccurred(.success)
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Achievements section")
    }

    // 3. Enhance Achievement Badges Display
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
        .accessibilityHint(achievement.achievementDescription)
        // 2. Add Animations for Progress Updates
        .scaleEffect(collection.completionProgress == 1.0 ? 1.2 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0), value: collection.completionProgress)
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
            if let storyId = getStoryId(from: story) {
                if let modelContext = getModelContext(from: story) {
                    let repo = AchievementRepository(modelContext: modelContext)
                    if let storyAchievements = try? await repo.fetchAchievements(for: storyId) {
                        all.append(contentsOf: storyAchievements)
                    }
                }
            }
        }
        achievements = all.filter { $0.type == .growthPathProgress }
    }

    private func getStoryId(from story: Story) -> UUID? {
        return story.id
    }

    private func getModelContext(from story: Story) -> ModelContext? {
        if let mirror = Mirror(reflecting: story).children.first(where: { $0.label == "modelContext" }) {
            return mirror.value as? ModelContext
        }
        return nil
    }

    // 4. Improve Story List Presentation
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
                    // 5. Add Haptic Feedback
                        .onAppear {
                            // Trigger haptic feedback when story is completed
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        }
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                        .accessibilityLabel("Not completed")
                }
            }
        }
        .padding(.vertical, 8)
        // 4. Improve Story List Presentation
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .listRowSeparator(.hidden)
        // 5. Add Haptic Feedback
        .onTapGesture {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }
}

// 1. Improved Progress Visualization
struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color(.systemGray5),
                    lineWidth: 8
                )
                .opacity(0.3)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.red, .yellow, .green]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                // 2. Add Animations for Progress Updates
                .animation(.spring(), value: progress)
        }
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
