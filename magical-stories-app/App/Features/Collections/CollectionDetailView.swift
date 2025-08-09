import SwiftData
import SwiftUI

// Height reader helper to measure content size
struct HeightPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct HeightReaderView: View {
    @Binding var height: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(key: HeightPreferenceKey.self, value: geometry.frame(in: .local).height)
        }
        .onPreferenceChange(HeightPreferenceKey.self) { height in
            Task { @MainActor in
                self.height = height
            }
        }
    }
}

@MainActor
struct CollectionDetailView: View {
    @EnvironmentObject private var collectionService: CollectionService
    @EnvironmentObject private var appRouter: AppRouter // Inject AppRouter
    // @Environment(\.modelContext) private var modelContext // Uncomment if CollectionService needs it or for direct fetching

    @State private var collection: StoryCollection? // Changed from @Bindable to @State optional
    private let collectionID: UUID // Added to store the ID for fetching

    @State private var achievements: [AchievementModel] = []
    @State private var isLoadingAchievements = false
    @State private var selectedTab = 0
    @State private var animateElements = false
    @State private var storiesTabHeight: CGFloat = 0
    @State private var aboutTabHeight: CGFloat = 0
    @State private var achievementsTabHeight: CGFloat = 0
    // @Bindable var collection: StoryCollection  // Removed

    // Determine the appropriate height based on the selected tab
    private var dynamicTabHeight: CGFloat {
        switch selectedTab {
        case 0:
            return max(storiesTabHeight, 100)  // Use a minimum height if content is empty
        case 1:
            return max(aboutTabHeight, 100)
        case 2:
            return max(achievementsTabHeight, 100)
        default:
            return 100
        }
    }

    // init(collection: StoryCollection) { // This init is replaced or used for previews
    //     self.collection = collection
    // }
    
    // Initializer to accept collectionID (new)
    init(collectionID: UUID) {
        self.collectionID = collectionID
        // _collection State property is initialized to nil by default
    }

    // Convenience initializer for Previews
    // Ensure StoryCollection has an 'id: UUID' property
    // For previews, you might need to create a StoryCollection instance within a ModelContext
    init(previewCollection: StoryCollection) {
        self.collectionID = previewCollection.id // Assuming StoryCollection has a UUID id
        self._collection = State(initialValue: previewCollection)
    }


    // Compute a thematic color based on the collection category
    private func thematicColor(for currentCollection: StoryCollection) -> Color { // Changed to take parameter
        switch currentCollection.category {
        case "emotionalIntelligence": return UITheme.Colors.primary
        case "socialSkills": return Color.blue
        case "cognitiveDevelopment": return Color.purple
        case "creativityImagination": return Color(hex: "#FF617B")
        case "problemSolving": return Color(hex: "#00B8A9")
        case "resilienceGrit": return Color(hex: "#F9A826")
        case "kindnessEmpathy": return Color(hex: "#7ED957")
        default: return UITheme.Colors.accent
        }
    }

    // Get a formatted category name
    private func categoryName(for currentCollection: StoryCollection) -> String { // Changed to take parameter
        switch currentCollection.category {
        case "emotionalIntelligence": return "Emotional Intelligence"
        case "socialSkills": return "Social Skills"
        case "cognitiveDevelopment": return "Cognitive Development"
        case "creativityImagination": return "Creativity & Imagination"
        case "problemSolving": return "Problem Solving"
        case "resilienceGrit": return "Resilience & Grit"
        case "kindnessEmpathy": return "Kindness & Empathy"
        default:
            return currentCollection.category
                .replacingOccurrences(
                    of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression
                )
                .capitalized
        }
    }

    // Get a category icon
    private func categoryIcon(for currentCollection: StoryCollection) -> String { // Changed to take parameter
        switch currentCollection.category {
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
    private func ageGroupDisplay(for currentCollection: StoryCollection) -> String { // Changed to take parameter
        switch currentCollection.ageGroup {
        case "preschool": return "3-5 years"
        case "earlyReader": return "6-8 years"
        case "middleGrade": return "9-12 years"
        default: return currentCollection.ageGroup
        }
    }

    var body: some View {
        Group { // Added Group to switch between loading and content
            if let currentCollection = collection { // Use the @State collection
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero section
                        heroSection(for: currentCollection) // Pass currentCollection

                        // Tab switcher
                        tabSwitcher // Assuming this doesn't directly depend on collection data for its structure
                            .padding(.top, 24)

                        // Tab content
                        TabView(selection: $selectedTab) {
                            // Stories tab
                            storiesTab(for: currentCollection) // Pass currentCollection
                                .background(
                                    HeightReaderView(height: $storiesTabHeight)
                                )
                                .tag(0)

                            // About tab
                            aboutTab(for: currentCollection) // Pass currentCollection
                                .background(
                                    HeightReaderView(height: $aboutTabHeight)
                                )
                                .tag(1)

                            // Achievements tab
                            achievementsTab(for: currentCollection) // Pass currentCollection
                                .background(
                                    HeightReaderView(height: $achievementsTabHeight)
                                )
                                .tag(2)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(height: dynamicTabHeight) // dynamicTabHeight might need to check collection != nil
                    }
                }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(currentCollection.title) // Use currentCollection
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                }
                // .navigationDestination is now managed by MainTabView
                .task { // Task for collection-specific actions like loading achievements
                    await loadAchievements(for: currentCollection) // Pass currentCollection

                    // Delay animations for polish
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                        animateElements = true
                    }
                }
            } else {
                ProgressView("Loading Collection...")
            }
        }
        .task(id: collectionID) { // Task to load the collection itself, reacting to collectionID changes
            await loadCollectionData()
        }
    }

    private func loadCollectionData() async {
        // Use the correct parameter name for fetchCollection and handle potential errors
        let fetchedCollection: StoryCollection?
        do {
            fetchedCollection = try collectionService.fetchCollection(id: collectionID)
        } catch {
            print("Error: Could not load collection with ID \(collectionID): \(error.localizedDescription)")
            fetchedCollection = nil
            // Optionally, handle error state e.g., appRouter.pop() or show error message
        }
        
        if fetchedCollection == nil {
            print("Error: Collection with ID \(collectionID) not found")
            // Optionally, handle error state e.g., appRouter.pop() or show error message
        }
        // This assignment will trigger UI update if collection was nil or changed
        self.collection = fetchedCollection
        
        // If collection is successfully loaded (or even if not, to reset),
        // reset dependent state here if not handled elsewhere
        if fetchedCollection != nil {
            self.achievements = [] // Reset achievements
            self.selectedTab = 0   // Reset selected tab
            self.animateElements = false // Reset animation state
            // Achievements will be loaded by the inner .task when currentCollection is set
        }
    }

    // MARK: - Hero Section

    private func heroSection(for currentCollection: StoryCollection) -> some View { // Changed to take parameter
        ZStack(alignment: .bottom) {
            // Top gradient background
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(
                            colors: [
                                thematicColor(for: currentCollection).opacity(0.3), // Use parameter
                                thematicColor(for: currentCollection).opacity(0.1), // Use parameter
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
                            to: animateElements ? CGFloat(currentCollection.completionProgress) : 0 // Use parameter
                        )
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    thematicColor(for: currentCollection), // Use parameter
                                    thematicColor(for: currentCollection).opacity(0.7), // Use parameter
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
                    Image(systemName: categoryIcon(for: currentCollection)) // Use parameter
                        .font(.system(size: 36))
                        .foregroundStyle(thematicColor(for: currentCollection)) // Use parameter

                    // Progress text
                    VStack {
                        Spacer()
                        Text("\(Int(currentCollection.completionProgress * 100))%") // Use parameter
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 12)
                    }
                    .frame(width: 120, height: 120)
                }
                .overlay {
                    if currentCollection.completionProgress >= 1.0 {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(thematicColor(for: currentCollection))
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
                    metadataPill(icon: "person.2.crop.square.stack.fill", label: categoryName(for: currentCollection))

                    metadataPill(icon: "calendar.badge.clock", label: ageGroupDisplay(for: currentCollection))

                    metadataPill(
                        icon: "book.closed",
                        label: "\(currentCollection.stories?.count ?? 0) Stories"
                    )
                }
                .padding(.top, 8)

                // Description
                Text(currentCollection.descriptionText)
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
                .foregroundColor(thematicColor(for: collection!))

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
                            .foregroundColor(selectedTab == index ? thematicColor(for: collection!) : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
            }

            // Active tab indicator
            Rectangle()
                .fill(thematicColor(for: collection!))
                .frame(height: 2)
                .frame(width: UIScreen.main.bounds.width / 3)
                .offset(x: UIScreen.main.bounds.width / 3 * CGFloat(selectedTab - 1))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)

            Divider()
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Stories Tab

    private func storiesTab(for currentCollection: StoryCollection) -> some View { // Changed to take parameter
        VStack(alignment: .leading, spacing: 8) {
            if let stories = currentCollection.stories, !stories.isEmpty {
                ForEach(stories.sorted(by: { ($0.isCompleted ? 1 : 0) < ($1.isCompleted ? 1 : 0) }))
                { story in
                    NavigationLink(value: AppDestination.storyDetail(storyID: story.id)) { // Use AppDestination
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
                                    thematicColor(for: collection!).opacity(0.6),
                                    thematicColor(for: collection!).opacity(0.4),
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
                                    .fill(thematicColor(for: collection!).opacity(0.7))
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
                        .accessibilityIdentifier("checkmark")
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
        .accessibilityIdentifier("StoryRow-\(story.id)")
    }

    // MARK: - About Tab

    private func aboutTab(for currentCollection: StoryCollection) -> some View { // Changed to take parameter
        VStack(alignment: .leading, spacing: 16) {
            aboutSection(
                title: "Description",
                content: currentCollection.descriptionText
            )

            aboutSection(
                title: "Growth Benefits",
                content: growthBenefitsText(for: currentCollection)
            )

            aboutSection(
                title: "Recommended Age",
                content:
                    "This collection is designed for children in the \(ageGroupDisplay(for: currentCollection)) age range. The vocabulary and concepts are tailored to be engaging and developmentally appropriate."
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
                .accessibilityIdentifier(title)

            Text(content)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineSpacing(4)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
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
    private func growthBenefitsText(for currentCollection: StoryCollection) -> String {
        switch currentCollection.category {
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

    private func achievementsTab(for currentCollection: StoryCollection) -> some View { // Changed to take parameter
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

    private func loadAchievements(for currentCollection: StoryCollection) async { // Changed to take parameter
        guard !isLoadingAchievements else { return }
        isLoadingAchievements = true
        // Replace with actual achievement fetching logic based on currentCollection.id or similar
        // Example: self.achievements = await achievementService.fetchAchievements(forCollectionID: currentCollection.id)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network
        let mockAchievements = [
            AchievementModel(
                id: UUID(),
                name: "First Steps in \(currentCollection.title)",
                achievementDescription: "Completed 1 story.",
                type: .storiesCompleted,
                earnedAt: Date(),
                iconName: "figure.walk"
            ),
            AchievementModel(
                id: UUID(),
                name: "Explorer of \(currentCollection.title)",
                achievementDescription: "Completed 3 stories.",
                type: .storiesCompleted,
                earnedAt: nil,
                iconName: "map.fill"
            ),
        ]
        self.achievements = mockAchievements
        isLoadingAchievements = false
    }
}

#Preview {
    // For preview, we need to provide AppRouter and other necessary environment objects
    let previewCollection: StoryCollection = {
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
    }()

    // Mock services for preview
    let mockCollectionService: CollectionService = {
        let modelContext: ModelContext = {
            do {
                let schema = Schema([StoryCollection.self, Story.self, Page.self, AchievementModel.self])
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                return try ModelContext(ModelContainer(for: schema, configurations: [config]))
            } catch {
                fatalError("Failed to create ModelContext/ModelContainer: \(error)")
            }
        }()
        let repository = CollectionRepository(modelContext: modelContext)
        do {
            try repository.saveCollection(previewCollection)
        } catch {
            fatalError("Failed to save preview collection: \(error)")
        }
        
        let storyService: MockStoryService
        do {
            storyService = try MockStoryService(context: modelContext)
        } catch {
            fatalError("Failed to initialize MockStoryService: \(error)")
        }
        let achievementRepository = AchievementRepository(modelContext: modelContext)
        return CollectionService(
            repository: repository, storyService: storyService,
            achievementRepository: achievementRepository)
    }()
    
    let appRouter = AppRouter()

    NavigationStack { // Preview still needs a NavStack if the view itself doesn't provide one
        CollectionDetailView(previewCollection: previewCollection)
            .environmentObject(mockCollectionService)
            .environmentObject(appRouter)
    }
}
