import SwiftData
import SwiftUI

// Import the design system
// If your project uses a module, use: import DesignSystem

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
            Theme.Colors.background.ignoresSafeArea()
            // Optional: SparkleAnimationView() // Placeholder for animated sparkles
            NavigationStack {
                mainContent
                    .navigationDestination(for: Story.self) { story in
                        StoryDetailView(story: story)
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
                growthCollectionsPreview
                if !storyService.stories.isEmpty {
                    libraryPreview
                }
                footerTip
            }
            .padding(.bottom, Spacing.xxl)
            .id("mainContentBottom")
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
            ForEach(storyService.stories.prefix(2)) { story in
                NavigationLink(value: story) {
                    StoryCard(story: story)
                        .padding(.horizontal, Spacing.lg)
                }
            }
            if storyService.stories.count > 2 {
                Button(action: {
                    selectedTabBinding?.wrappedValue = .library
                }) {
                    Text("View All Stories")
                        .font(.headingSmall)
                        .foregroundColor(.magicalPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md).cornerRadius(12)
                }
                .accessibilityIdentifier("ViewAllStoriesButton")
                .frame(width: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)  // Adjust corner radius as needed
                        .stroke(Theme.Colors.primary, lineWidth: 2)  // Set border color and width
                )
                .padding(.trailing, Spacing.lg)
                .padding(.leading, Spacing.lg)
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
