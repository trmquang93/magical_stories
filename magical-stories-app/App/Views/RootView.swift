import SwiftData
import SwiftUI

enum TabItem {
    case home
    case library
    case settings
    case collections

    var title: String {
        switch self {
        case .home:
            return "Home"
        case .library:
            return "Library"
        case .settings:
            return "Settings"
        case .collections:
            return "Collections"
        }
    }

    var icon: String {
        switch self {
        case .home:
            return "house.fill"
        case .library:
            return "books.vertical.fill"
        case .settings:
            return "gear"
        case .collections:
            return "square.grid.2x2.fill"
        }
    }
}

private struct SelectedTabBindingKey: EnvironmentKey {
    static let defaultValue: Binding<TabItem>? = nil
}

extension EnvironmentValues {
    var selectedTabBinding: Binding<TabItem>? {
        get { self[SelectedTabBindingKey.self] }
        set { self[SelectedTabBindingKey.self] = newValue }
    }
}

struct RootView: View {
    @State var selectedTab: TabItem = .home
    @EnvironmentObject var storyService: StoryService
    @EnvironmentObject var settingsService: SettingsService
    @EnvironmentObject var persistenceService: PersistenceService
    @EnvironmentObject var collectionService: CollectionService

    var body: some View {
        MainTabView(selectedTab: $selectedTab)
            .environmentObject(storyService)
            .environmentObject(settingsService)
            .environmentObject(persistenceService)
            .environmentObject(collectionService)
            .preferredColorScheme(settingsService.appSettings.darkModeEnabled ? .dark : .light)
            .environment(\.fontScale, settingsService.appSettings.fontScale)
            .environment(\.selectedTabBinding, $selectedTab)
            .task {
                // Create test collections when running UI tests with CREATE_TEST_COLLECTIONS flag
                await createTestCollectionsIfNeeded()
            }
    }

    /// Creates test collections for UI testing if the CREATE_TEST_COLLECTIONS launch argument is present
    private func createTestCollectionsIfNeeded() async {
        guard CommandLine.arguments.contains("CREATE_TEST_COLLECTIONS") else {
            return
        }

        do {
            // Check if we already have collections
            let existingCollections = try collectionService.fetchAllCollections()

            // Only create test collections if we don't have any
            if existingCollections.isEmpty {
                print("[RootView] Creating test collections for UI testing")

                // Create a test collection
                let testCollection = StoryCollection(
                    title: "Test Collection for UI Tests",
                    descriptionText: "This collection was created automatically for UI testing.",
                    category: "emotionalIntelligence",
                    ageGroup: "4-6 years"
                )

                // Add some stories to the collection
                if testCollection.stories == nil {
                    testCollection.stories = []
                }

                // Create 3 test stories for the collection
                for i in 1...3 {
                    let storyTitle = "Test Story \(i)"

                    // Create test parameters
                    let parameters = StoryParameters(
                        childName: "Test Child",
                        childAge: 5,
                        theme: "Learning and Growth",
                        favoriteCharacter: "Buddy"
                    )

                    // Create pages for the story
                    let page1 = Page(
                        content:
                            "Page 1: Once upon a time in a magical land, there lived a child named Test Child.",
                        pageNumber: 1,
                        imagePrompt: "A magical forest scene with a child"
                    )

                    let page2 = Page(
                        content:
                            "Page 2: Test Child and Buddy went on an adventure to learn about friendship.",
                        pageNumber: 2,
                        imagePrompt: "A child and a buddy character on an adventure"
                    )

                    let page3 = Page(
                        content:
                            "Page 3: They learned valuable lessons and lived happily ever after.",
                        pageNumber: 3,
                        imagePrompt: "A child and a buddy celebrating"
                    )

                    // Create the story with pages
                    let story = Story(
                        title: storyTitle,
                        pages: [page1, page2, page3],
                        parameters: parameters,
                        categoryName: "Testing"
                    )

                    // Add the collection to the story
                    story.collections = [testCollection]

                    // Add the story to the collection
                    testCollection.stories?.append(story)

                    // Save the story
                    try await persistenceService.saveStory(story)
                }

                // Save the collection
                try collectionService.createCollection(testCollection)

                print(
                    "[RootView] Successfully created test collection with \(testCollection.stories?.count ?? 0) stories"
                )
            } else {
                print("[RootView] Test collections not created - collections already exist")
            }
        } catch {
            print("[RootView] Error creating test collections: \(error)")
        }
    }
}
