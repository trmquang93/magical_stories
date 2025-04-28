import SwiftData
import SwiftUI

struct StoryDetailView: View {
    @EnvironmentObject private var collectionService: CollectionService
    @EnvironmentObject private var persistenceService: PersistenceService
    @EnvironmentObject private var illustrationService: IllustrationService
    @Environment(\.modelContext) private var modelContext

    let story: Story

    @State private var pages: [Page] = []
    @State private var currentPageIndex = 0
    @State private var isLoadingPages = true
    @State private var readingProgress: Double = 0.0
    @State private var illustrationProgress: (ready: Int, total: Int) = (0, 0)

    @State private var showCompletionAlert = false
    @State private var newAchievements: [Achievement] = []

    // Accessibility description of the current reading progress
    private var progressDescription: String {
        "Reading progress: \(Int(readingProgress * 100))%"
    }

    // Status text for illustration generation
    private var illustrationStatusText: String? {
        guard illustrationProgress.total > 0 else { return nil }

        let readyCount = illustrationProgress.ready
        let totalCount = illustrationProgress.total

        if readyCount == totalCount {
            return nil  // Don't show if all illustrations are ready
        }

        return "\(readyCount) of \(totalCount) illustrations ready"
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
                // Illustration Status Header (only shown when illustrations are loading)
                if let statusText = illustrationStatusText {
                    VStack(spacing: 4) {
                        Text(statusText)
                            .font(UITheme.Typography.bodySmall)
                            .foregroundColor(UITheme.Colors.textSecondary)

                        ProgressView(
                            value: Double(illustrationProgress.ready),
                            total: Double(illustrationProgress.total)
                        )
                        .tint(UITheme.Colors.accent)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(UITheme.Colors.surfacePrimary)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        "Illustration progress: \(illustrationProgress.ready) of \(illustrationProgress.total) ready"
                    )
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                }

                // Page Content using TabView for pagination
                TabView(selection: $currentPageIndex) {
                    ForEach(pages.indices, id: \.self) { index in
                        PageView(
                            regenerateAction: {
                                regenerateIllustration(for: pages[index])
                            },
                            page: pages[index]
                        )
                        .tag(index)
                        .accessibilityLabel("Page \(index + 1)")
                        .accessibilityHint("Swipe left or right to navigate between pages")
                        .accessibilityIdentifier("PageView-\(index)")
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))  // Use page style, hide default index dots
                .onChange(of: currentPageIndex) { _, newIndex in
                    updateReadingProgress(newIndex: newIndex)
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Story pages")
                .accessibilityIdentifier("StoryPageTabView")

                // Custom Page Indicator and Progress Bar
                pageIndicatorAndProgress
                    .padding(.bottom, Theme.Spacing.sm)
            }
        }
        .navigationTitle(story.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {  // Use .task for async operations on appear
            await loadPages()

            // Start processing illustrations in background
            processIllustrations()
        }
        .alert(
            "Achievement Unlocked!", isPresented: $showCompletionAlert, presenting: newAchievements
        ) { achievements in
            Button("Awesome!") {}
        } message: { achievements in
            Text("You've earned: \(achievements.map { $0.name }.joined(separator: ", "))")
        }
        .onChange(of: pages) { _, _ in
            updateIllustrationProgress()
        }
    }

    // MARK: - Subviews

    private var pageIndicatorAndProgress: some View {
        VStack(spacing: Theme.Spacing.xs) {
            ProgressView(value: readingProgress)
                .tint(UITheme.Colors.primary)
                .padding(.horizontal, Theme.Spacing.lg)
                .accessibilityLabel(progressDescription)
                .accessibilityValue(progressDescription)

            Text("Page \(currentPageIndex + 1) of \(pages.count)")
                .font(UITheme.Typography.bodySmall)
                .foregroundColor(UITheme.Colors.textSecondary)
                .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                .accessibilityLabel("Page \(currentPageIndex + 1) of \(pages.count)")
                .accessibilityIdentifier("PageIndicator")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Reading progress")
        .accessibilityHint("Shows your current position in the story")
        .accessibilityIdentifier("PageIndicatorAndProgress")
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
            // Also update illustration progress initially
            updateIllustrationProgress()
        } else {
            readingProgress = 0.0
        }

        if !pages.isEmpty {
            UIAccessibility.post(
                notification: .screenChanged,
                argument: "\(pages.count) pages loaded. Page 1 is now displayed")
        }
    }

    private func updateIllustrationProgress() {
        let total = pages.count
        let ready = pages.filter { $0.illustrationStatus == .ready }.count

        illustrationProgress = (ready, total)
    }

    private func processIllustrations() {
        // Start generating illustrations for the story in background
        illustrationService.generateIllustrationsForStory(story, context: modelContext)

        // Set up a timer to periodically update the illustration progress
        // This is a simple approach - in a real app, you might use Combine or another observation mechanism
        Task {
            for _ in 1...20 {  // Check up to 20 times
                try? await Task.sleep(for: .seconds(1))
                if !Task.isCancelled {
                    updateIllustrationProgress()
                }
            }
        }
    }

    private func regenerateIllustration(for page: Page) {
        Task {
            do {
                try await illustrationService.generateIllustration(for: page, context: modelContext)
                updateIllustrationProgress()
            } catch {
                print("Failed to regenerate illustration: \(error)")
            }
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

        // Update readCount and lastReadAt in persistence
        do {
            try await persistenceService.incrementReadCount(for: story.id)
            try await persistenceService.updateLastReadAt(for: story.id, date: Date())
        } catch {
            print("[StoryDetailView] Error updating readCount/lastReadAt: \(error)")
        }

        guard let collectionId = story.collections.first?.id else {
            print("[StoryDetailView] Story \"\(story.title)\" does not belong to a collection.")
            return
        }

        // Mark story as completed and update collection progress
        do {
            try await collectionService.markStoryAsCompleted(
                storyId: story.id, collectionId: collectionId)
        } catch {
            print(
                "[StoryDetailView] Error marking story as completed or updating collection progress: \(error)"
            )
        }
    }
}
