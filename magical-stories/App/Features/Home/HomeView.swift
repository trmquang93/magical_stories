import SwiftData
import SwiftUI
// Import the design system
// If your project uses a module, use: import DesignSystem

struct HomeView: View {
    @State private var showingStoryForm = false
    @State private var showingGrowthStoryForm = false
    @EnvironmentObject private var storyService: StoryService
    @EnvironmentObject private var collectionService: CollectionService

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            // Optional: SparkleAnimationView() // Placeholder for animated sparkles
            mainContent
        }
        .sheet(isPresented: $showingStoryForm) {
            StoryFormView()
        }
        .sheet(
            isPresented: $showingGrowthStoryForm,
            onDismiss: {
                print("[HomeView] Growth story form dismissed, reloading collections")
                collectionService.loadCollections(forceReload: true)
            }
        ) {
            CollectionFormView()
                .environmentObject(collectionService)
        }
    }

    private var mainContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.lg) {
                headerSection
                primaryActionCard
                growthCollectionsPreview
                if !storyService.stories.isEmpty {
                    libraryPreview
                }
                footerTip
            }
            .padding(.bottom, Spacing.xxl)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Welcome back, [Name]!")
                .font(.displayMedium)
                .foregroundColor(Theme.Colors.textPrimary)
                .padding(.top, Spacing.xl)
            Text("What magical story will you create today?")
                .font(.bodyMedium)
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .padding(.horizontal, Spacing.lg)
    }

    private var primaryActionCard: some View {
        ActionCard(
            iconName: "wand.and.stars",
            iconColor: Theme.Colors.primary,
            title: "Create a New Story",
            subtitle: "Personalize a bedtime adventure",
            buttonTitle: "Start",
            buttonAction: { showingStoryForm = true }
        )
    }

    private var growthCollectionsPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Growth Path Collections")
                .font(.headingMedium)
                .foregroundColor(Theme.Colors.textPrimary)
                .padding(.horizontal, Spacing.lg)
            if collectionService.collections.isEmpty {
                ActionCard(
                    iconName: "plus",
                    iconColor: Theme.Colors.primary,
                    title: "Create a Growth Collection",
                    subtitle: "Guide your child's growth with themed story sets",
                    buttonTitle: "Create Collection",
                    buttonAction: { showingGrowthStoryForm = true }
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(collectionService.collections) { collection in
                            CollectionCardView(collection: collection)
                                .frame(width: 220)
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                }
            }
        }
        .padding(.top, 16)
    }

    private var libraryPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Story Library")
                .font(.headingMedium)
                .foregroundColor(Theme.Colors.textPrimary)
                .padding(.horizontal, Spacing.lg)
            ForEach(storyService.stories.prefix(3)) { story in
                StoryCard(story: story)
                    .padding(.horizontal, Spacing.lg)
            }
            HStack {
                Spacer()
                SecondaryButton(title: "See All") {
                    // Action
                }
                .frame(width: 120)
                .padding(.trailing, Spacing.lg)
            }
        }
        .padding(.top, 24)
    }

    private var footerTip: some View {
        Text("Tip: Reading together builds magical memories!")
            .font(.bodySmall)
            .foregroundColor(Theme.Colors.accent)
            .multilineTextAlignment(.center)
            .padding(.vertical, Spacing.md)
            .frame(maxWidth: .infinity)
    }
}

// TODO: Review all custom card/section components for dark mode support.
// TODO: If any custom view uses hardcoded colors, refactor to use Theme.Colors tokens.
// TODO: Add dark mode UI tests for HomeView.

extension HomeView {
    /// Creates a robust preview with all required environment objects and context.
    /// If any dependency fails to initialize, a fallback mock is used to prevent preview crashes.
    private class MockStoryService: StoryService {
        init(context: ModelContext) { try! super.init(context: context) }
    }
    static func makePreview() -> some View {
        // Attempt to create a ModelContainer for SwiftData
        let container: ModelContainer
        do {
            container = try ModelContainer()
        } catch {
            // Fallback: Use an empty view with error message if ModelContainer fails
            return Text("Preview Error: Failed to create ModelContainer: \(error.localizedDescription)")
                .foregroundColor(.red)
        }
        // Attempt to create StoryService
        let storyService: StoryService
        do {
            storyService = try StoryService(context: container.mainContext)
        } catch {
            // Fallback: Use a minimal mock StoryService for preview
            storyService = MockStoryService(context: container.mainContext)
        }
        // Create repositories for CollectionService
        let collectionRepository = CollectionRepository(modelContext: container.mainContext)
        let achievementRepository = AchievementRepository(modelContext: container.mainContext)
        // Create CollectionService with all dependencies
        let collectionService = CollectionService(
            repository: collectionRepository,
            storyService: storyService,
            achievementRepository: achievementRepository
        )
        // Preload collections for preview
        collectionService.loadCollections()
        // Return HomeView with all required environment objects
        return HomeView()
            .environment(\.modelContext, container.mainContext)
            .environmentObject(storyService)
            .environmentObject(collectionService)
    }
}

#Preview {
    HomeView.makePreview()
}
