import SwiftData
import SwiftUI

struct HomeView: View {
    @State private var showingStoryForm = false
    @State private var showingGrowthStoryForm = false
    @EnvironmentObject private var storyService: StoryService
    @EnvironmentObject private var collectionService: CollectionService
    @Environment(\.selectedTabBinding) private var selectedTabBinding

    #if DEBUG
        /// Test-only: If true, scrolls to the bottom of the main ScrollView on appear (for snapshot/UI tests)
        let scrollToBottom: Bool
        init(scrollToBottom: Bool = false) {
            self.scrollToBottom = scrollToBottom
        }
    #endif

    var body: some View {
        ZStack {
            UITheme.Colors.background.ignoresSafeArea()
            UITheme.Colors.background.opacity(0.9)
                .ignoresSafeArea(edges: .top)
                .frame(height: 30)
            NavigationStack {
                mainContent
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

    // Define an enum for navigation destinations
    enum ViewDestination: Hashable {
        case allStories
    }

    private var mainContent: some View {
        #if DEBUG
            if scrollToBottom {
                return AnyView(
                    ScrollViewReader { proxy in
                        scrollView
                            .onAppear {
                                proxy.scrollTo("mainContentBottom", anchor: .bottom)
                            }
                    }
                )
            }
        #endif
        return AnyView(
            scrollView
        )
    }

    private var scrollView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.lg) {
                headerSection
                primaryActionCard
                if collectionService.collections.isEmpty {
                    createGrowthCollectionCard
                } else {
                    growthCollectionsPreview
                }
                if !storyService.stories.isEmpty {
                    libraryPreview
                }
                footerTip
            }
            .padding(.bottom, Spacing.xxl)
            .id("mainContentBottom")
        }
        .accessibilityIdentifier("HomeView_MainScrollView")
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Welcome back, [Name]!")
                .font(.displayMedium)
                .foregroundColor(UITheme.Colors.textPrimary)
                .padding(.top, Spacing.xl)
                .accessibilityIdentifier("HomeView_WelcomeHeading")
            Text("What magical story will you create today?")
                .font(.bodyMedium)
                .foregroundColor(UITheme.Colors.textSecondary)
                .accessibilityIdentifier("HomeView_WelcomeSubtitle")
        }
        .padding(.horizontal, Spacing.lg)
        .accessibilityIdentifier("HomeView_HeaderSection")
    }

    private var primaryActionCard: some View {
        ActionCard(
            iconName: "wand.and.stars",
            iconColor: UITheme.Colors.primary,
            title: "Create a New Story",
            subtitle: "Personalize a bedtime adventure",
            buttonTitle: "Start",
            buttonAction: { showingStoryForm = true }
        )
        .accessibilityIdentifier("HomeView_CreateStoryCard")
    }

    private var growthCollectionsPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Growth Path Collections")
                .font(.headingMedium)
                .foregroundColor(UITheme.Colors.textPrimary)
                .padding(.horizontal, Spacing.lg)
                .accessibilityIdentifier("HomeView_CollectionsHeading")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(collectionService.collections) { collection in
                        CollectionCardView(collection: collection)
                            .frame(width: 220)
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
            .accessibilityIdentifier("HomeView_CollectionsScrollView")
        }
        .padding(.top, 16)
        .accessibilityIdentifier("HomeView_CollectionsSection")
    }

    private var createGrowthCollectionCard: some View {
        ActionCard(
            iconName: "plus",
            iconColor: UITheme.Colors.primary,
            title: "Create a Growth Collection",
            subtitle: "Guide your child's growth with themed story sets",
            buttonTitle: "Create Collection",
            buttonAction: { showingGrowthStoryForm = true }
        )
        .accessibilityIdentifier("HomeView_CreateCollectionCard")
    }

    private var libraryPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Story Library")
                .font(.headingMedium)
                .foregroundColor(UITheme.Colors.textPrimary)
                .padding(.horizontal, Spacing.lg)
                .accessibilityIdentifier("HomeView_LibraryHeading")
            ForEach(storyService.stories.prefix(2)) { story in
                NavigationLink(value: story) {
                    StoryCard(story: story)
                        .padding(.horizontal, Spacing.lg)
                        .accessibilityIdentifier("HomeView_StoryCard_\(story.id)")
                }
            }
            if storyService.stories.count > 2 {
                NavigationLink(value: ViewDestination.allStories) {
                    Text("View All Stories")
                        .font(.headingSmall)
                        .foregroundColor(.magicalPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(UITheme.Colors.primary, lineWidth: 2)
                        )
                        .padding(.horizontal, Spacing.lg)
                }
                .accessibilityIdentifier("ViewAllStoriesButton")
            }
        }
        .padding(.top, 24)
        .accessibilityIdentifier("HomeView_LibrarySection")
    }

    private var footerTip: some View {
        Text("Tip: Reading together builds magical memories!")
            .font(.bodySmall)
            .foregroundColor(UITheme.Colors.accent)
            .multilineTextAlignment(.center)
            .padding(.vertical, Spacing.md)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("HomeView_FooterTip")
    }
}
