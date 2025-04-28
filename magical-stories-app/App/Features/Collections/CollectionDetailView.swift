import SwiftData
import SwiftUI

struct CollectionDetailView: View {
    @EnvironmentObject private var collectionService: CollectionService
    @State private var achievements: [AchievementModel] = []
    @State private var isLoadingAchievements = false
    @State private var selectedTab = 0
    @State private var animateElements = false
    @Bindable var collection: StoryCollection  // Use @Bindable for live updates

    init(collection: StoryCollection) {
        self.collection = collection
    }

    // Compute a thematic color based on the collection category
    private var thematicColor: Color {
        switch collection.category {
        case "emotionalIntelligence": return Color.magicalPrimary
        case "socialSkills": return Color.blue
        case "cognitiveDevelopment": return Color.purple
        case "creativityImagination": return Color(hex: "#FF617B")
        case "problemSolving": return Color(hex: "#00B8A9")
        case "resilienceGrit": return Color(hex: "#F9A826")
        case "kindnessEmpathy": return Color(hex: "#7ED957")
        default: return Color.magicalAccent
        }
    }

    // Get a formatted category name
    private var categoryName: String {
        switch collection.category {
        case "emotionalIntelligence": return "Emotional Intelligence"
        case "socialSkills": return "Social Skills"
        case "cognitiveDevelopment": return "Cognitive Development"
        case "creativityImagination": return "Creativity & Imagination"
        case "problemSolving": return "Problem Solving"
        case "resilienceGrit": return "Resilience & Grit"
        case "kindnessEmpathy": return "Kindness & Empathy"
        default:
            return collection.category
                .replacingOccurrences(
                    of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression
                )
                .capitalized
        }
    }

    // Get a category icon
    private var categoryIcon: String {
        switch collection.category {
        case "emotionalIntelligence": return "heart.fill"
        case "socialSkills": return "person.2.fill"
        case "cognitiveDevelopment": return "brain"
        case "creativityImagination": return "sparkles"
        case "problemSolving": return "puzzlepiece.fill"
        case "resilienceGrit": return "figure.walk.motion"
        case "kindnessEmpathy": return "hands.sparkles"
        default: return "book.pages"
        }
    }

    // Format age group for display
    private var ageGroupDisplay: String {
        switch collection.ageGroup {
        case "preschool": return "3-5 years"
        case "earlyReader": return "6-8 years"
        case "middleGrade": return "9-12 years"
        default: return collection.ageGroup
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero section
                heroSection

                // Tab switcher
                tabSwitcher
                    .padding(.top, 24)

                // Tab content
                TabView(selection: $selectedTab) {
                    // Stories tab
                    storiesTab
                        .tag(0)

                    // About tab
                    aboutTab
                        .tag(1)

                    // Achievements tab
                    achievementsTab
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(minHeight: 600)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(collection.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
        }
        .navigationDestination(for: Story.self) { story in
            StoryDetailView(story: story)
                .environmentObject(collectionService)
        }
        .task {
            await loadAchievements()

            // Delay animations for polish
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                animateElements = true
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            // Top gradient background
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(
                            colors: [
                                thematicColor.opacity(0.3),
                                thematicColor.opacity(0.1),
                                Color(.systemGroupedBackground),
                            ]
                        ),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 260)

            VStack(spacing: 16) {
                // Progress circle
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 10)
                        .frame(width: 120, height: 120)

                    // Progress circle with animation
                    Circle()
                        .trim(
                            from: 0,
                            to: animateElements ? CGFloat(collection.completionProgress) : 0
                        )
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    thematicColor, thematicColor.opacity(0.7),
                                ]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(
                            .spring(response: 1.5, dampingFraction: 0.8), value: animateElements)

                    // Icon in center
                    Image(systemName: categoryIcon)
                        .font(.system(size: 36))
                        .foregroundStyle(thematicColor)

                    // Progress text
                    VStack {
                        Spacer()
                        Text("\(Int(collection.completionProgress * 100))%")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 12)
                    }
                    .frame(width: 120, height: 120)
                }
                .overlay {
                    if collection.completionProgress >= 1.0 {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(thematicColor)
                            .background(
                                Circle()
                                    .fill(Color(.systemBackground))
                                    .frame(width: 30, height: 30)
                            )
                            .offset(x: 45, y: -45)
                            .opacity(animateElements ? 1 : 0)
                            .scaleEffect(animateElements ? 1 : 0.5)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.6).delay(0.8),
                                value: animateElements)
                    }
                }

                // Metadata
                HStack(spacing: 12) {
                    metadataPill(icon: "person.2.crop.square.stack.fill", label: categoryName)

                    metadataPill(icon: "calendar.badge.clock", label: ageGroupDisplay)

                    metadataPill(
                        icon: "book.closed",
                        label: "\(collection.stories?.count ?? 0) Stories"
                    )
                }
                .padding(.top, 8)

                // Description
                Text(collection.descriptionText)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .lineLimit(3)
            }
            .padding(.bottom, 12)
        }
    }

    // Helper for metadata pills
    private func metadataPill(icon: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(thematicColor)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
        )
    }

    // MARK: - Tab Switcher

    private var tabSwitcher: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(["Stories", "About", "Achievements"].indices, id: \.self) { index in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = index
                        }
                    } label: {
                        Text(["Stories", "About", "Achievements"][index])
                            .font(
                                .system(
                                    size: 15, weight: selectedTab == index ? .semibold : .regular)
                            )
                            .foregroundColor(selectedTab == index ? thematicColor : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
            }

            // Active tab indicator
            Rectangle()
                .fill(thematicColor)
                .frame(height: 2)
                .frame(width: UIScreen.main.bounds.width / 3)
                .offset(x: UIScreen.main.bounds.width / 3 * CGFloat(selectedTab - 1))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)

            Divider()
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Stories Tab

    private var storiesTab: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let stories = collection.stories, !stories.isEmpty {
                ForEach(stories.sorted(by: { ($0.isCompleted ? 1 : 0) < ($1.isCompleted ? 1 : 0) }))
                { story in
                    NavigationLink(value: story) {
                        premiumStoryRow(story: story)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } else {
                emptyStateView(
                    icon: "books.vertical",
                    title: "No Stories Yet",
                    message: "Stories will appear here once they are generated."
                )
            }
        }
        .padding(.top, 16)
    }

    // Premium story row design
    private func premiumStoryRow(story: Story) -> some View {
        HStack(spacing: 16) {
            // Story thumbnail/icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(
                                colors: [
                                    thematicColor.opacity(0.6),
                                    thematicColor.opacity(0.4),
                                ]
                            ),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: story.isCompleted ? "book.closed.fill" : "book.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(story.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    // Category badge if available
                    if let category = story.categoryName {
                        Text(category)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(.systemBackground))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(thematicColor.opacity(0.7))
                            )
                    }

                    // Pages count
                    Text("\(story.pages.count) pages")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Completion status
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 1.5)
                    .frame(width: 30, height: 30)

                if story.isCompleted {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 30, height: 30)

                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }

    // MARK: - About Tab

    private var aboutTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            aboutSection(
                title: "About This Collection",
                content: collection.descriptionText
            )

            aboutSection(
                title: "Growth Benefits",
                content: growthBenefitsText()
            )

            aboutSection(
                title: "Recommended Age",
                content:
                    "This collection is designed for children in the \(ageGroupDisplay) age range. The vocabulary and concepts are tailored to be engaging and developmentally appropriate."
            )

            aboutSection(
                title: "Reading Tips",
                content:
                    "Encourage your child to reflect on the stories by asking open-ended questions. Discuss how the themes in these stories might apply to real-life situations."
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private func aboutSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)

            Text(content)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }

    // Helper to generate growth benefits based on category
    private func growthBenefitsText() -> String {
        switch collection.category {
        case "emotionalIntelligence":
            return
                "These stories help children identify, understand and manage emotions in themselves and others. They build empathy and emotional vocabulary."
        case "socialSkills":
            return
                "Children will learn about friendship, cooperation, sharing, and resolving conflicts through engaging scenarios and relatable characters."
        case "cognitiveDevelopment":
            return
                "These stories promote critical thinking, problem-solving, memory, attention, and other cognitive skills through engaging narratives."
        case "creativityImagination":
            return
                "This collection stimulates creative thinking, imagination, and artistic expression through fantastical scenarios and open-ended storytelling."
        case "problemSolving":
            return
                "Children will encounter various challenges and puzzles, learning step-by-step approaches to solving problems and building resilience."
        case "resilienceGrit":
            return
                "These stories feature characters who persevere through challenges, teaching children about determination, patience, and bouncing back from setbacks."
        case "kindnessEmpathy":
            return
                "Children will explore themes of compassion, helping others, and understanding different perspectives to build a foundation for empathy."
        default:
            return
                "This collection offers a variety of stories designed to support your child's development through engaging narratives and relatable characters."
        }
    }

    // MARK: - Achievements Tab

    private var achievementsTab: some View {
        VStack(spacing: 16) {
            if isLoadingAchievements {
                ProgressView()
                    .padding(.top, 32)
            } else if achievements.isEmpty {
                emptyStateView(
                    icon: "trophy",
                    title: "No Achievements Yet",
                    message: "Complete stories in this collection to earn achievements."
                )
            } else {
                achievementsGrid
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var achievementsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ],
            spacing: 16
        ) {
            ForEach(achievements, id: \.id) { achievement in
                achievementCard(achievement)
            }
        }
    }

    private func achievementCard(_ achievement: AchievementModel) -> some View {
        VStack(spacing: 12) {
            // Achievement icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(
                                colors: [Color(hex: "#FFD700"), Color(hex: "#FFA500")]
                            ),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .shadow(color: Color(hex: "#FFD700").opacity(0.3), radius: 10, x: 0, y: 5)

                Image(systemName: achievement.iconName ?? "star.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .symbolEffect(.pulse, options: .repeating, value: animateElements)
            }

            // Achievement title
            Text(achievement.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 40)

            // Earned date
            if let date = achievement.earnedAt {
                Text("Earned \(formattedDate(date))")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(
                            colors: [
                                Color(hex: "#FFD700").opacity(0.7),
                                Color(hex: "#FFA500").opacity(0.5),
                            ]
                        ),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // Helper for formatting dates
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    // MARK: - Empty State View

    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(Color(.systemGray3))
                .padding(.bottom, 8)

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)

            Text(message)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Data Loading

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

        // Filter to only show growth path progress achievements
        achievements = all.filter { $0.type == .growthPathProgress }
    }

    private func getStoryId(from story: Story) -> UUID? {
        return story.id
    }

    private func getModelContext(from story: Story) -> ModelContext? {
        if let mirror = Mirror(reflecting: story).children.first(where: {
            $0.label == "modelContext"
        }) {
            return mirror.value as? ModelContext
        }
        return nil
    }
}

#Preview {
    NavigationStack {
        CollectionDetailView(
            collection: {
                let collection = StoryCollection(
                    title: "Emotional Growth Adventures",
                    descriptionText:
                        "Help your child develop emotional intelligence through engaging stories that teach empathy and understanding.",
                    category: "emotionalIntelligence",
                    ageGroup: "preschool",
                    stories: Array(repeating: Story.previewStory(), count: 5),
                    createdAt: Date(),
                    updatedAt: Date()
                )
                collection.completionProgress = 0.6
                return collection
            }())
    }
}
