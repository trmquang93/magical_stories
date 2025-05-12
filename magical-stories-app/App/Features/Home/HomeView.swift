import SwiftData
import SwiftUI

struct HomeView: View {
    @State private var showingStoryForm = false
    @State private var showingGrowthStoryForm = false
    @EnvironmentObject private var storyService: StoryService
    @EnvironmentObject private var collectionService: CollectionService
    @EnvironmentObject private var appRouter: AppRouter // Inject AppRouter
    // @Environment(\.selectedTabBinding) private var selectedTabBinding // Replaced by appRouter
    @State private var childName: String = ""
    @State private var scrollOffset = CGPoint.zero
    @State private var scrollDirection: ScrollViewOffsetPredictor.ScrollDirection = .none
    @State private var showScrollHeader = false
    @State private var headerHeight: CGFloat = 0
    @State private var headerShowing = false

    #if DEBUG
        /// Test-only: If true, scrolls to the bottom of the main ScrollView on appear (for snapshot/UI tests)
        let scrollToBottom: Bool
        init(scrollToBottom: Bool = false) {
            self.scrollToBottom = scrollToBottom
        }
    #endif

    var body: some View {
        ZStack(alignment: .top) {
            UITheme.Colors.background.ignoresSafeArea(.container)

            // Scroll-aware header positioned at top of ZStack
            ScrollAwareHeader(
                title: "Welcome back\(childName.isEmpty ? "!" : ", \(childName)!")",
                subtitle: "What magical story will you create today?",
                isVisible: $showScrollHeader
            ) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.calmBlue, .magicPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .zIndex(1)  // Ensure header is above content
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: HeaderHeightKey.self, value: geo.size.height)
                }
            )
            .onPreferenceChange(HeaderHeightKey.self) { height in
                headerHeight = height
            }

            VStack(spacing: 0) {
                // Spacer to push content down when header is visible
                if showScrollHeader {
                    Spacer()
                        .frame(height: headerHeight)
                }

                // The NavigationStack is now managed by MainTabView
                // Its .navigationDestination is also managed there.
                mainContent
            }
        }
        .fullScreenCover(isPresented: $showingStoryForm) {
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
        .onAppear {
            // Load child name from UserDefaults when the view appears
            childName = UserDefaults.standard.string(forKey: "childName") ?? ""
        }
    }

    // Define an enum for navigation destinations - This local enum is no longer needed, AppDestination is global
    // enum ViewDestination: Hashable {
    //    case collectionDetail(StoryCollection)
    // }

    private var mainContent: some View {
        return scrollView
    }

    private var scrollView: some View {
        ScrollView {
            ScrollViewOffsetPredictor(
                coordinateSpace: "homeScrollView",
                scrollOffset: $scrollOffset,
                scrollDirection: $scrollDirection
            )
            .frame(height: 0)  // Make it invisible

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
        .coordinateSpace(name: "homeScrollView")
        .onChange(of: scrollOffset.y) { _, newValue in
            // Only update header visibility based on scroll direction
            // This avoids the feedback loop that was making scrolling impossible
            if newValue < -50 && scrollDirection == .up {
                if !showScrollHeader {
                    showScrollHeader = true
                }
            } else if scrollDirection == .down && newValue >= -50 {
                if showScrollHeader {
                    showScrollHeader = false
                }
            }
        }
        .accessibilityIdentifier("HomeView_MainScrollView")
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Welcome back\(childName.isEmpty ? "!" : ", \(childName)!")")
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
                        // Use the global AppDestination enum
                        NavigationLink(value: AppDestination.collectionDetail(collectionID: collection.id)) {
                            CollectionCardView(collection: collection)
                                .frame(width: 180)
                        }
                        .buttonStyle(PlainButtonStyle())  // Prevent blue tint on card
                    }

                    // Always show the Add card at the end - use it directly since it already contains a Button
                    AddCollectionCardView(action: { showingGrowthStoryForm = true })
                        .frame(width: 180)  // Reduced from 220 to 180 for consistency
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
                NavigationLink(value: AppDestination.storyDetail(storyID: story.id)) {
                    EnhancedStoryCard(story: story)
                        .padding(.horizontal, Spacing.lg)
                        .accessibilityIdentifier("HomeView_StoryCard_\(story.id)")
                }
            }
            if storyService.stories.count > 2 {
                Button(action: {
                    // Use appRouter to change tabs
                    appRouter.activeTab = .library
                }) {
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
                        .accessibilityLabel("View All Stories")
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityIdentifier("ViewAllStoriesButton")
                .contentShape(Rectangle())
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

// Preference key to track header height
struct HeaderHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
