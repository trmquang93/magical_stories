import SwiftUI

struct StoryDetailView: View {
    @EnvironmentObject private var collectionService: CollectionService
    let story: Story

    @State private var pages: [Page] = []
    @State private var currentPageIndex = 0
    @State private var isLoadingPages = true
    @State private var readingProgress: Double = 0.0

    @State private var showCompletionAlert = false
    @State private var newAchievements: [Achievement] = []

    // Accessibility description of the current reading progress
    private var progressDescription: String {
        "Reading progress: \(Int(readingProgress * 100))%"
    }

    var body: some View {
        VStack(spacing: 0) {
            if isLoadingPages {
                MagicalLoadingView(message: "Preparing your story...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel("Loading story")
                    .accessibilityHint("Please wait while your story is being prepared")
                    .accessibilityAddTraits(.updatesFrequently)
            } else if pages.isEmpty {
                MagicalEmptyStateView(
                    title: "Story Error",
                    message: "Could not load story pages.",
                    buttonTitle: "Go Back"
                ) {
                    // In a real app, use Environment(\.dismiss)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("Story Error")
                .accessibilityHint("Could not load story pages")
            } else {
                // Page Content using TabView for pagination
                TabView(selection: $currentPageIndex) {
                    ForEach(pages.indices, id: \.self) { index in
                        PageView(page: pages[index])
                            .tag(index)
                            .accessibilityLabel("Page \(index + 1)")
                            .accessibilityHint("Swipe left or right to navigate between pages")
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))  // Use page style, hide default index dots
                .onChange(of: currentPageIndex) { _, newIndex in
                    updateReadingProgress(newIndex: newIndex)
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Story pages")

                // Custom Page Indicator and Progress Bar
                pageIndicatorAndProgress
                    .padding(.bottom, Theme.Spacing.sm)
            }
        }
        .navigationTitle(story.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {  // Use .task for async operations on appear
            await loadPages()
        }
        .alert(
            "Achievement Unlocked!", isPresented: $showCompletionAlert, presenting: newAchievements
        ) { achievements in
            Button("Awesome!") {}
        } message: { achievements in
            Text("You've earned: \(achievements.map { $0.name }.joined(separator: ", "))")
        }
    }

    // MARK: - Subviews

    private var pageIndicatorAndProgress: some View {
        VStack(spacing: Theme.Spacing.xs) {
            ProgressView(value: readingProgress)
                .tint(Theme.Colors.primary)
                .padding(.horizontal, Theme.Spacing.lg)
                .accessibilityLabel(progressDescription)
                .accessibilityValue(progressDescription)

            Text("Page \(currentPageIndex + 1) of \(pages.count)")
                .font(Theme.Typography.bodySmall)
                .foregroundColor(Theme.Colors.textSecondary)
                .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                .accessibilityLabel("Page \(currentPageIndex + 1) of \(pages.count)")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Reading progress")
        .accessibilityHint("Shows your current position in the story")
    }

    // MARK: - Helper Functions

    private func loadPages() async {
        isLoadingPages = true
        pages = story.pages
        print("StoryDetailView: Loaded \(pages.count) pages directly from story model.")
        isLoadingPages = false
        if !pages.isEmpty {
            readingProgress = StoryProcessor.calculateReadingProgress(
                currentPage: currentPageIndex + 1, totalPages: pages.count)
        } else {
            readingProgress = 0.0
        }

        if !pages.isEmpty {
            UIAccessibility.post(
                notification: .screenChanged,
                argument: "\(pages.count) pages loaded. Page 1 is now displayed")
        }
    }

    private func updateReadingProgress(newIndex: Int) {
        guard !pages.isEmpty else {
            readingProgress = 0.0
            return
        }
        readingProgress = StoryProcessor.calculateReadingProgress(
            currentPage: newIndex + 1, totalPages: pages.count)

        UIAccessibility.post(
            notification: .pageScrolled, argument: "Page \(newIndex + 1) of \(pages.count)")

        if newIndex == pages.count - 1 {
            Task {
                await handleStoryCompletion()
            }
        }
    }

    private func handleStoryCompletion() async {
        print("[StoryDetailView] Story completed: \(story.title)")

        guard let collectionId = story.collections.first?.id else {
            print("[StoryDetailView] Story \"\(story.title)\" does not belong to a collection.")
            return
        }

        // Fetch the collection asynchronously since CollectionService does not expose a collections property
        guard
            let collection = try? await collectionService.fetchAllCollections().first(where: {
                $0.id == collectionId
            })
        else {
            print("[StoryDetailView] Could not find parent collection with ID: \(collectionId)")
            return
        }

        let totalStories = Float(collection.stories?.count ?? 0)
        guard totalStories > 0 else {
            print("[StoryDetailView] Collection has no stories, cannot calculate progress.")
            return
        }
        let progressPerStory = 1.0 / totalStories
        let potentialNewProgress = min(
            collection.completionProgress + Double(progressPerStory), 1.0)

        guard potentialNewProgress > collection.completionProgress else {
            print(
                "[StoryDetailView] Calculated progress (\(potentialNewProgress)) did not increase from current (\(collection.completionProgress)). No update needed."
            )
            return
        }

        let finalProgress = potentialNewProgress

        print(
            "[StoryDetailView] Updating collection \(collectionId) progress from \(collection.completionProgress) to \(finalProgress)"
        )

        do {
            try await collectionService.updateCollectionProgress(
                id: collectionId, progress: Float(finalProgress))

            // TODO: Implement achievement checking if/when CollectionService provides such a method.
            // let earnedAchievements = try await collectionService.checkAchievements(for: collectionId)
            // if !earnedAchievements.isEmpty {
            //     print("[StoryDetailView] New achievements earned: \(earnedAchievements.map { $0.name }.joined(separator: ", "))")
            //     self.newAchievements = earnedAchievements
            //     self.showCompletionAlert = true
            // }
        } catch {
            print(
                "[StoryDetailView] Error updating progress or checking achievements for collection \(collectionId): \(error)"
            )
        }
    }
}
