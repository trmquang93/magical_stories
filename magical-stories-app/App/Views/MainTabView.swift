import Foundation
import SwiftData
import SwiftUI

// Import the design system if needed
// Import SparkleAnimationView from DesignSystem/Components if not in same file

struct MainTabView: View {
    @Binding var selectedTab: TabItem // This will be synced with AppRouter.activeTab
    @EnvironmentObject private var appRouter: AppRouter // Inject AppRouter
    @EnvironmentObject private var storyService: StoryService
    @EnvironmentObject private var settingsService: SettingsService
    // @StateObject private var tabSelection = TabSelection() // tabSelection might be redundant now or integrated with AppRouter

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main TabView
            // The TabView's selection is now driven by appRouter.activeTab,
            // which is kept in sync with the selectedTab binding from RootView.
            TabView(selection: $appRouter.activeTab) {
                NavigationStack(path: $appRouter.homePath) {
                    HomeView()
                        .navigationDestination(for: AppDestination.self) { destination in
                            view(for: destination)
                        }
                }
                .tabItem {
                    VStack(spacing: 2) {
                        Image(systemName: TabItem.home.icon)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        Text(TabItem.home.title)
                            .font(.headingSmall)
                    }
                    .accessibilityLabel("Home Tab")
                    .accessibilityIdentifier("HomeTabButton")
                }
                .tag(TabItem.home)

                NavigationStack(path: $appRouter.libraryPath) {
                    LibraryView()
                        .navigationDestination(for: AppDestination.self) { destination in
                            view(for: destination)
                        }
                }
                .tabItem {
                    VStack(spacing: 2) {
                        Image(systemName: TabItem.library.icon)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        Text(TabItem.library.title)
                            .font(.headingSmall)
                    }
                    .accessibilityLabel("Library Tab")
                    .accessibilityIdentifier("LibraryTabButton")
                }
                .tag(TabItem.library)

                NavigationStack(path: $appRouter.collectionsPath) {
                    CollectionsListView()
                        .navigationDestination(for: AppDestination.self) { destination in
                            view(for: destination)
                        }
                }
                .tabItem {
                    VStack(spacing: 2) {
                        Image(systemName: TabItem.collections.icon)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        Text(TabItem.collections.title)
                            .font(.headingSmall)
                    }
                    .accessibilityLabel("Collections Tab")
                    .accessibilityIdentifier("CollectionsTabButton")
                }
                .tag(TabItem.collections)

                NavigationStack(path: $appRouter.settingsPath) {
                    SettingsView()
                        .navigationDestination(for: AppDestination.self) { destination in
                            view(for: destination)
                        }
                }
                .tabItem {
                    VStack(spacing: 2) {
                        Image(systemName: TabItem.settings.icon)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        Text(TabItem.settings.title)
                            .font(.headingSmall)
                    }
                    .accessibilityLabel("Settings Tab")
                    .accessibilityIdentifier("SettingsTabButton")
                }
                .tag(TabItem.settings)
            }
            .accentColor(.magicalPrimary)
            // Sync RootView's selectedTab with AppRouter's activeTab
            .onChange(of: appRouter.activeTab) { _, newRouterTab in
                if selectedTab != newRouterTab {
                    selectedTab = newRouterTab
                }
            }
            .onChange(of: selectedTab) { _, newSelectedTab in
                if appRouter.activeTab != newSelectedTab {
                    appRouter.activeTab = newSelectedTab
                }
            }
            .onAppear {
                // Initialize appRouter's activeTab with the initial selectedTab from RootView
                // This ensures they are in sync when the view first appears.
                // However, if appRouter.activeTab is already set (e.g. deep link),
                // the onChange(of: appRouter.activeTab) will handle updating selectedTab.
                // To avoid potential loops if both are set simultaneously,
                // we can prioritize one source on initial appearance or ensure AppRouter's
                // initial activeTab matches RootView's initial selectedTab.
                // For simplicity, let's assume AppRouter.activeTab is the leading state for TabView selection.
                // If selectedTab from RootView is different, it will be updated by the first onChange.
                // If they are the same, no change.
                // If appRouter.activeTab needs to reflect RootView's initial state:
                if appRouter.activeTab != selectedTab {
                     appRouter.activeTab = selectedTab
                }

                // Set a solid color UITabBar appearance for the entire app
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor.systemBackground

                // Apply the appearance to all tab bars
                UITabBar.appearance().standardAppearance = appearance
                if #available(iOS 15.0, *) {
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                }
            }

            // Optional: Magical sparkle effect behind the tab bar
            // This is now layered properly behind the solid tab bar
            VStack {
                Spacer()
                SparkleAnimationView(verticalRange: 0.7...1)
                    .frame(height: 50)
                    .ignoresSafeArea(.container, edges: .bottom)
            }
        }
        // .environmentObject(tabSelection) // tabSelection might be replaced by appRouter for tab control
    }
}

// SparkleAnimationView is now integrated as a magical accent behind the TabBar.
// TODO: Tune sparkle parameters for best effect in context.
// TODO: If performance issues arise, consider reducing sparkleCount or animation complexity.

extension MainTabView {
    static func makePreview() -> some View {
        let container: ModelContainer = {
            let schema = Schema([
                UserProfile.self,
                AppSettingsModel.self,
                ParentalControlsModel.self,
                Story.self,
                Page.self,
                AchievementModel.self,
            ])
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: config)
            } catch {
                fatalError("Failed to create preview ModelContainer: \(error)")
            }
        }()

        let context = container.mainContext
        let userProfileRepo = UserProfileRepository(modelContext: context)
        let settingsRepo = SettingsRepository(modelContext: context)
        let usageService = UsageAnalyticsService(userProfileRepository: userProfileRepo)
        let settingsService = SettingsService(
            repository: settingsRepo, usageAnalyticsService: usageService)
        let persistenceService = PersistenceService(context: context)
        let previewApiKey = "PREVIEW_API_KEY"
        let illustrationService: IllustrationService
        do {
            illustrationService = try IllustrationService(apiKey: previewApiKey)
        } catch {
            fatalError("Failed to create IllustrationService: \(error)")
        }
        let storyProcessor = StoryProcessor(illustrationService: illustrationService)
        let storyService: StoryService
        do {
            storyService = try StoryService(
                apiKey: previewApiKey,
                context: context,
                persistenceService: persistenceService,
                storyProcessor: storyProcessor
            )
        } catch {
            fatalError("Failed to create StoryService: \(error)")
        }

        // Add CollectionService for HomeView and CollectionsListView
        let collectionRepository = CollectionRepository(modelContext: context)
        let achievementRepository = AchievementRepository(modelContext: context)
        let collectionService = CollectionService(
            repository: collectionRepository,
            storyService: storyService,
            achievementRepository: achievementRepository
        )

        Task {
            await storyService.loadStoriesIfNeeded()
            if storyService.stories.isEmpty {
                // Inject mock stories for preview
                let mockStories = [
                    Story.previewStory(title: "The Magical Forest Adventure"),
                    Story.previewStory(title: "The Lost City of Gold"),
                    Story.previewStory(title: "The Space Explorer's Quest"),
                ]
                for story in mockStories {
                    try? await persistenceService.saveStory(story)
                }
                await storyService.loadStoriesIfNeeded()
            }
        }

        let appRouter = AppRouter()
        
        return MainTabView(selectedTab: .constant(.home))
            .modelContainer(container)
            .environmentObject(settingsService)
            .environmentObject(storyService)
            .environmentObject(collectionService)
            .environmentObject(appRouter)
    }
}

#Preview {
    MainTabView.makePreview()
}
