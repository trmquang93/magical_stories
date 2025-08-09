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
            return R.string.localizable.navigationHome()
        case .library:
            return R.string.localizable.navigationLibrary()
        case .settings:
            return R.string.localizable.navigationSettings()
        case .collections:
            return R.string.localizable.navigationCollections()
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

@MainActor
struct RootView: View {
    @State var selectedTab: TabItem = .home
    @EnvironmentObject var storyService: StoryService
    @EnvironmentObject var settingsService: SettingsService
    @EnvironmentObject var persistenceService: PersistenceService
    @EnvironmentObject var collectionService: CollectionService
    @EnvironmentObject var ratingService: RatingService
    @EnvironmentObject var featureFlagService: FeatureFlagService

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
                // Initialize pre-made content from bundle resources (fast startup)
                let startupLoader = StartupContentLoader(
                    persistenceService: persistenceService,
                    collectionService: collectionService
                )
                await startupLoader.loadContentOnStartup()
                
                // Initialize rating system on app launch (if enabled)
                if featureFlagService.isEnabled(.ratingSystem) {
                    await ratingService.handleAppLaunch()
                }
                
                // Create test collections when running UI tests with CREATE_TEST_COLLECTIONS flag
                await createTestCollectionsIfNeeded()
                
                // Create premium screenshot data
                await createScreenshotDataIfNeeded()
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
                        theme: "Learning and Growth",
                        childAge: 5,
                        childName: "Test Child",
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
    
    /// Creates premium screenshot data if CREATE_SCREENSHOT_DATA launch argument is present
    private func createScreenshotDataIfNeeded() async {
        guard CommandLine.arguments.contains("CREATE_SCREENSHOT_DATA") else {
            return
        }
        
        do {
            // Check if we already have screenshot data
            await storyService.loadStoriesIfNeeded()
            let existingStories = storyService.stories
            let existingCollections = try collectionService.fetchAllCollections()
            
            // Only create if we don't have content already
            if existingStories.isEmpty && existingCollections.isEmpty {
                print("[RootView] Creating premium screenshot data")
                
                await createShowcaseCollectionsWithStories()
                
                print("[RootView] Successfully created premium screenshot data")
            } else {
                print("[RootView] Screenshot data not created - content already exists")
            }
        } catch {
            print("[RootView] Error creating screenshot data: \(error)")
        }
    }
    
    /// Creates beautiful themed collections with stories for screenshots
    private func createShowcaseCollectionsWithStories() async {
        // Define collections with their stories
        let collectionsData = [
            (
                title: "Bedtime Adventures",
                description: "Magical tales perfect for sleepy time",
                category: "bedtime",
                stories: [
                    (
                        title: "Luna's Sleepy Star",
                        theme: "Peaceful Dreams",
                        content: [
                            "Little Luna couldn't fall asleep until she met a friendly star.",
                            "The star sang gentle lullabies and painted dreams across the sky.",
                            "With her star friend, Luna drifted into the most wonderful dreams."
                        ]
                    ),
                    (
                        title: "The Cozy Bear's Blanket",
                        theme: "Comfort and Security",
                        content: [
                            "Bear had a magical blanket that made everyone feel safe and warm.",
                            "Every night, Bear shared his blanket with friends who needed comfort.",
                            "Together they learned that sharing warmth makes bedtime special."
                        ]
                    )
                ]
            ),
            (
                title: "Learning & Growing",
                description: "Stories that teach valuable life lessons",
                category: "emotionalIntelligence",
                stories: [
                    (
                        title: "Maya's Kindness Garden",
                        theme: "Empathy and Helping Others",
                        content: [
                            "Maya planted seeds of kindness that grew into a magical garden.",
                            "Every act of kindness made beautiful flowers bloom around her.",
                            "Maya learned that kindness grows when you share it with others."
                        ]
                    ),
                    (
                        title: "Charlie's Brave Heart",
                        theme: "Overcoming Fears",
                        content: [
                            "Charlie was scared of the dark until he discovered his brave heart.",
                            "His heart glowed with courage whenever he helped others feel safe.",
                            "Charlie became the bravest friend, showing others their inner light."
                        ]
                    ),
                    (
                        title: "Emma's Patient Adventure",
                        theme: "Learning Patience",
                        content: [
                            "Emma wanted everything right now, until she met the wise old turtle.",
                            "The turtle showed her how wonderful things take time to grow.",
                            "Emma learned that patience makes every achievement more special."
                        ]
                    )
                ]
            ),
            (
                title: "Magical Creatures",
                description: "Meet dragons, unicorns, and friendly monsters",
                category: "fantasy",
                stories: [
                    (
                        title: "The Dragon's Secret Garden",
                        theme: "Friendship and Nature",
                        content: [
                            "Luna discovered a hidden garden where gentle dragon Ember grew magical flowers.",
                            "Together, they learned that the most beautiful gardens are made with friendship.",
                            "Luna and Ember became best friends, sharing their garden with forest creatures."
                        ]
                    ),
                    (
                        title: "Unicorn's Rainbow Bridge",
                        theme: "Hope and Wonder",
                        content: [
                            "Alex met a unicorn who painted rainbow bridges across the sky.",
                            "Every bridge connected children who needed a friend to play with.",
                            "Alex learned that friendship can reach across any distance."
                        ]
                    ),
                    (
                        title: "The Friendly Monster's Party",
                        theme: "Acceptance and Inclusion",
                        content: [
                            "Monster Marshmallow looked scary but threw the best tea parties.",
                            "All the forest animals learned not to judge by appearances.",
                            "Marshmallow taught everyone that differences make friendships special."
                        ]
                    )
                ]
            ),
            (
                title: "Brave Heroes",
                description: "Stories of courage and determination",
                category: "courage",
                stories: [
                    (
                        title: "Captain Courage's Treasure Map",
                        theme: "Bravery and Problem-Solving",
                        content: [
                            "Young Alex found an old treasure map leading to the Island of Friendship.",
                            "With courage and clever thinking, Alex solved each puzzle on the hunt.",
                            "The real treasure was discovering the power of believing in yourself."
                        ]
                    ),
                    (
                        title: "The Little Hero's Big Heart",
                        theme: "Small Acts of Courage",
                        content: [
                            "Sam was the smallest in class but had the biggest heart for helping.",
                            "When others needed help, Sam's courage grew bigger than any fear.",
                            "Sam showed everyone that heroes come in all sizes."
                        ]
                    )
                ]
            )
        ]
        
        // Create each collection with its stories
        for collectionData in collectionsData {
            let collection = StoryCollection(
                title: collectionData.title,
                descriptionText: collectionData.description,
                category: collectionData.category,
                ageGroup: "4-8 years"
            )
            
            // Initialize the stories array
            collection.stories = []
            
            // Create stories for this collection
            for (index, storyData) in collectionData.stories.enumerated() {
                let parameters = StoryParameters(
                    theme: storyData.theme,
                    childAge: 5 + (index % 3), // Ages 5-7
                    childName: ["Luna", "Alex", "Maya", "Charlie", "Emma", "Sam"][index % 6],
                    favoriteCharacter: ["Star", "Dragon", "Unicorn", "Bear", "Turtle", "Captain"][index % 6]
                )
                
                var pages: [Page] = []
                for (pageIndex, content) in storyData.content.enumerated() {
                    let page = Page(
                        content: content,
                        pageNumber: pageIndex + 1,
                        imagePrompt: "Beautiful illustration for: \(content.prefix(50))..."
                    )
                    pages.append(page)
                }
                
                let story = Story(
                    title: storyData.title,
                    pages: pages,
                    parameters: parameters,
                    categoryName: collectionData.category
                )
                
                // Link story to collection
                story.collections = [collection]
                collection.stories?.append(story)
                
                do {
                    try await persistenceService.saveStory(story)
                    print("[RootView] Created showcase story: \(story.title)")
                } catch {
                    print("[RootView] Error creating story \(story.title): \(error)")
                }
            }
            
            // Save the collection with its stories
            do {
                try collectionService.createCollection(collection)
                print("[RootView] Created showcase collection: \(collection.title) with \(collection.stories?.count ?? 0) stories")
            } catch {
                print("[RootView] Error creating collection \(collection.title): \(error)")
            }
        }
    }
}
