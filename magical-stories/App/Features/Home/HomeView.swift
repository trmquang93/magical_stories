import SwiftData
import SwiftUI

struct HomeView: View {
    @State private var showingStoryForm = false
    @State private var showingGrowthStoryForm = false
    @EnvironmentObject private var storyService: StoryService
    @EnvironmentObject private var collectionService: CollectionService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Header
                    Text("Create a Magical Story")
                        .font(Theme.Typography.displayLarge)
                        .padding(.top, Theme.Spacing.xl)

                    Text("Let's create a unique bedtime story for your child")
                        .font(Theme.Typography.bodyLarge)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.lg)

                    // Story Creation Card
                    MagicalCard {
                        VStack(spacing: Theme.Spacing.md) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 40))
                                .foregroundColor(Theme.Colors.primary)

                            Text("Single Story")
                                .font(Theme.Typography.headingMedium)

                            Text(
                                "Create a custom bedtime story with your child as the main character"
                            )
                            .font(Theme.Typography.bodyMedium)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)

                            PrimaryButton(title: "Create Story") {
                                showingStoryForm = true
                            }
                        }
                        .padding()
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    // Growth Path Stories Card
                    MagicalCard {
                        VStack(spacing: Theme.Spacing.md) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 40))
                                .foregroundColor(Theme.Colors.accent)

                            Text("Growth Path Stories")
                                .font(Theme.Typography.headingMedium)

                            Text(
                                "Create a personalized collection of stories focused on specific developmental skills"
                            )
                            .font(Theme.Typography.bodyMedium)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)

                            PrimaryButton(title: "Create Collection") {
                                showingGrowthStoryForm = true
                            }
                        }
                        .padding()
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    // List of created Growth Collections
                    Group {
                        if !collectionService.collections.isEmpty {
                            Text("Your Growth Collections")
                                .font(Theme.Typography.headingMedium)
                                .padding(.top, Theme.Spacing.lg)
                                .padding(.horizontal, Theme.Spacing.lg)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            VStack(spacing: Theme.Spacing.md) {
                                ForEach(collectionService.collections, id: \.id) { collection in
                                    NavigationLink(value: collection) {
                                        CollectionCardView(collection: collection)
                                            .padding(.horizontal, Theme.Spacing.lg)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        } else {
                            // Debugging placeholder to confirm UI updates are working
                            Text("No collections yet - Create your first collection!")
                                .font(Theme.Typography.bodyMedium)
                                .foregroundColor(.secondary)
                                .padding(.top, Theme.Spacing.lg)
                                .padding(.horizontal, Theme.Spacing.lg)
                        }
                    }

                    Spacer()
                }
                .padding(.bottom, Theme.Spacing.xxl)
            }
            .navigationTitle("Home")
            .sheet(isPresented: $showingStoryForm) {
                StoryFormView()
            }
            .sheet(
                isPresented: $showingGrowthStoryForm,
                onDismiss: {
                    print("[HomeView] Growth story form dismissed, reloading collections")
                    collectionService.loadCollections(forceReload: true)  // Reload collections when form is dismissed
                }
            ) {
                CollectionFormView()
                    .environmentObject(collectionService)
            }
            .task {
                print("[HomeView] Task loading collections")
                collectionService.loadCollections()
            }
            .navigationDestination(for: StoryCollection.self) { collection in
                CollectionDetailView(collection: collection)
                    .environmentObject(collectionService)
            }
        }
    }
}

extension HomeView {
    static func makePreview() -> some View {
        let container: ModelContainer
        do {
            container = try ModelContainer()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        let storyService: StoryService
        do {
            storyService = try StoryService(context: container.mainContext)
        } catch {
            fatalError("Failed to create StoryService: \(error)")
        }
        let collectionRepository = CollectionRepository(modelContext: container.mainContext)
        let achievementRepository = AchievementRepository(modelContext: container.mainContext)
        let collectionService = CollectionService(
            repository: collectionRepository, storyService: storyService, achievementRepository: achievementRepository)
        collectionService.loadCollections()
        return HomeView()
            .environment(\.modelContext, container.mainContext)
            .environmentObject(storyService)
            .environmentObject(collectionService)
    }
}

#Preview {
    HomeView.makePreview()
}
