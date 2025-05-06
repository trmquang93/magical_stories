import SwiftData
import SwiftUI

struct StoryDetailView: View {
    @EnvironmentObject private var collectionService: CollectionService
    @EnvironmentObject private var persistenceService: PersistenceService
    @EnvironmentObject private var illustrationService: IllustrationService
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var illustrationTaskManager: IllustrationTaskManager

    let story: Story

    @State private var pages: [Page] = []
    @State private var isFirstAppearance = true
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
        
        // Log the pages before sorting to see their original order
        print("[StoryDetailView] Original page order:")
        for (index, page) in story.pages.enumerated() {
            print("[StoryDetailView] Page \(index): pageNumber=\(page.pageNumber), id=\(page.id)")
        }
        
        // Sort pages by pageNumber to ensure correct order
        pages = story.pages.sorted(by: { $0.pageNumber < $1.pageNumber })
        
        // Log the pages after sorting to confirm correct order
        print("[StoryDetailView] After sorting - page count: \(pages.count)")
        for (index, page) in pages.enumerated() {
            print("[StoryDetailView] Page \(index): pageNumber=\(page.pageNumber), id=\(page.id)")
        }
        
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
        // Only process illustrations once
        guard isFirstAppearance else { return }
        isFirstAppearance = false
        
        // Check if any pages need illustration generation
        let pagesNeedingIllustrations = pages.filter { $0.illustrationStatus == .pending }
        
        // If no pages need illustrations, we're done
        if (pagesNeedingIllustrations.isEmpty) {
            print("[StoryDetailView] All illustrations are already generated")
            return
        }
        
        print("[StoryDetailView] Adding \(pagesNeedingIllustrations.count) illustration tasks for story: \(story.title)")
        
        // Create tasks for each page with appropriate priorities
        for page in pagesNeedingIllustrations {
            // Set first viewed timestamp if not already set
            if page.firstViewedAt == nil {
                page.firstViewedAt = Date()
            }
            
            // Determine priority based on page number
            let priority: IllustrationPriority
            if page.pageNumber == 1 {
                priority = .critical  // First page is critical priority
            } else if page.pageNumber == 2 {
                priority = .high      // Second page is high priority
            } else if page.pageNumber <= 4 {
                priority = .medium    // Pages 3-4 are medium priority
            } else {
                priority = .low       // All other pages are low priority
            }
            
            // Create task
            let task = IllustrationTask(
                pageId: page.id,
                storyId: story.id,
                priority: priority
            )
            
            // Get previous illustration path if available
            let previousIllustrationPath: String? = page.pageNumber > 1 ? 
                pages[page.pageNumber - 2].illustrationPath : nil
                
            // Add task to manager and persist it
            illustrationTaskManager.addTask(task)
            
            // Save the task to the repository for persistence
            Task { @MainActor in
                let repository = IllustrationTaskRepository(modelContext: modelContext)
                do {
                    // Remove the unnecessary await keyword since saveTask might not be async
                    _ = try repository.saveTask(
                        task,
                        pageNumber: page.pageNumber,
                        totalPages: pages.count,
                        description: page.imagePrompt,
                        previousIllustrationPath: previousIllustrationPath
                    )
                } catch {
                    print("[StoryDetailView] Failed to save illustration task: \(error)")
                }
            }
            
            // Update page status to scheduled
            page.illustrationStatus = .scheduled
        }
        
        // Set up a task processor if not already running
        Task {
            await startIllustrationTaskProcessing()
        }
        
        // Set up a timer to periodically update the UI
        Task {
            for _ in 1...40 {  // Check up to 40 times (40 seconds)
                try? await Task.sleep(for: .seconds(1))
                if !Task.isCancelled {
                    updateIllustrationProgress()
                }
            }
        }
    }
    
    private func startIllustrationTaskProcessing() async {
        // Start processing if not already processing
        if !illustrationTaskManager.isProcessing {
            // The result of startProcessing is intentionally ignored here because 
            // the task processing logic is handled via the provided closure.
            _ = await illustrationTaskManager.startProcessing { task in
                // Process the task by generating an illustration
                do {
                    // Find the corresponding page
                    guard let page = pages.first(where: { $0.id == task.pageId }) else {
                        print("[StoryDetailView] Page not found for task: \(task.id)")
                        var failedTask = task
                        failedTask.updateStatus(.failed)
                        return failedTask
                    }
                    
                    // Update page status
                    page.illustrationStatus = .generating
                    
                    // Get illustration description
                    let description = page.imagePrompt ?? page.content
                    
                    // Get previous illustration path if available
                    let previousPage = page.pageNumber > 1 ? 
                        pages.first(where: { $0.pageNumber == page.pageNumber - 1 }) : nil
                    let previousIllustrationPath = previousPage?.illustrationPath
                    
                    // Generate illustration
                    if let relativePath = try await illustrationService.generateIllustration(
                        for: description,
                        pageNumber: page.pageNumber,
                        totalPages: pages.count,
                        previousIllustrationPath: previousIllustrationPath
                    ) {
                        // Update page with generated illustration
                        page.illustrationPath = relativePath
                        page.illustrationStatus = .ready
                        
                        // Update task status
                        var completedTask = task
                        completedTask.updateStatus(.ready)
                        
                        // Update UI immediately on main thread
                        await MainActor.run {
                            updateIllustrationProgress()
                        }
                        
                        return completedTask
                    } else {
                        // Failed to generate illustration
                        page.illustrationStatus = .failed
                        
                        var failedTask = task
                        failedTask.updateStatus(.failed)
                        return failedTask
                    }
                } catch {
                    print("[StoryDetailView] Error generating illustration: \(error)")
                    
                    // Find the page and update its status
                    if let page = pages.first(where: { $0.id == task.pageId }) {
                        page.illustrationStatus = .failed
                    }
                    
                    // Update task status
                    var failedTask = task
                    failedTask.updateStatus(.failed)
                    return failedTask
                }
            }
        }
    }

    private func regenerateIllustration(for page: Page) {
        // Using MainActor for the entire task to safely access modelContext
        Task { @MainActor in
            // Store image prompt and other necessary data before starting illustration generation
            let imagePrompt = page.imagePrompt ?? page.content
            let pageNumber = page.pageNumber
            let totalPages = pages.count
            
            do {
                // Use the image prompt directly instead of passing the modelContext
                if let relativePath = try await illustrationService.generateIllustration(
                    for: imagePrompt,
                    pageNumber: pageNumber,
                    totalPages: totalPages,
                    previousIllustrationPath: nil
                ) {
                    // Update page with the new illustration path
                    page.illustrationPath = relativePath
                    page.illustrationStatus = .ready
                    updateIllustrationProgress()
                }
            } catch {
                print("Failed to regenerate illustration: \(error)")
                page.illustrationStatus = .failed
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
