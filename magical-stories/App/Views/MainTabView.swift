import Foundation
import SwiftData
import SwiftUI

// Import the design system if needed
// Import SparkleAnimationView from DesignSystem/Components if not in same file

struct MainTabView: View {
    @Binding var selectedTab: TabItem
    @EnvironmentObject private var storyService: StoryService
    @EnvironmentObject private var settingsService: SettingsService

    var body: some View {
        ZStack(alignment: .bottom) {
            // Magical sparkle background for tab bar (magical accent)
            SparkleAnimationView(verticalRange: 0.7...1)
                .frame(height: 80)  // Only show at the bottom
                .ignoresSafeArea(.container, edges: .bottom)
            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeView()
                }
                .tabItem {
                    VStack(spacing: 2) {
                        Image(systemName: TabItem.home.icon)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        Text(TabItem.home.title)
                            .font(.headingSmall)
                    }
                    .accessibilityLabel("Home Tab")
                }
                .tag(TabItem.home)

                NavigationStack {
                    LibraryView()
                }
                .tabItem {
                    VStack(spacing: 2) {
                        Image(systemName: TabItem.library.icon)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        Text(TabItem.library.title)
                            .font(.headingSmall)
                    }
                    .accessibilityLabel("Library Tab")
                }
                .tag(TabItem.library)

                NavigationStack {
                    CollectionsListView()
                }
                .tabItem {
                    VStack(spacing: 2) {
                        Image(systemName: TabItem.collections.icon)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        Text(TabItem.collections.title)
                            .font(.headingSmall)
                    }
                    .accessibilityLabel("Collections Tab")
                }
                .tag(TabItem.collections)

                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    VStack(spacing: 2) {
                        Image(systemName: TabItem.settings.icon)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        Text(TabItem.settings.title)
                            .font(.headingSmall)
                    }
                    .accessibilityLabel("Settings Tab")
                }
                .tag(TabItem.settings)
            }
            .accentColor(.magicalPrimary)
            .background(
                // Custom tab bar background with corner radius and shadow
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.surface)
                        .frame(height: 60)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, y: -2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.border, lineWidth: 1)
                        )
                        .ignoresSafeArea(.container, edges: .bottom)
                }
            )
        }
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
                StoryModel.self,
                StoryPage.self,
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
            await storyService.loadStories()
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
                await storyService.loadStories()
            }
        }

        return MainTabView(selectedTab: .constant(.home))
            .modelContainer(container)
            .environmentObject(settingsService)
            .environmentObject(storyService)
            .environmentObject(collectionService)
    }
}

#Preview {
    MainTabView.makePreview()
}
