import SwiftData
import SwiftUI

struct StoryDetailView: View {
    @EnvironmentObject private var collectionService: CollectionService
    @EnvironmentObject private var persistenceService: PersistenceService
    @EnvironmentObject private var illustrationService: IllustrationService
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var illustrationTaskManager: IllustrationTaskManager
    @EnvironmentObject private var storyService: StoryService // Added

    // story will be loaded from storyID
    @State private var story: Story?
    private let storyID: UUID // storyID is now the input

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
        // Ensure story is not nil before accessing its properties indirectly via illustrationProgress
        guard story != nil, illustrationProgress.total > 0 else { return nil }

        let readyCount = illustrationProgress.ready
        let totalCount = illustrationProgress.total

        if readyCount == totalCount {
            return nil  // Don't show if all illustrations are ready
        }

        return "\(readyCount) of \(totalCount) illustrations ready"
    }

    var body: some View {
        Group { // Use Group to handle conditional display of story content or loading state
            if let currentStory = story {
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
                            .padding(.horizontal, UITheme.Spacing.lg)
                            .padding(.vertical, UITheme.Spacing.sm)
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
                            .padding(.bottom, UITheme.Spacing.sm)
                    }
                }
                .navigationTitle(currentStory.title)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                // Show loading view while story is being fetched
                MagicalLoadingView(message: "Loading story details...")
            }
        }
        .task {
            if Task.isCancelled { return }
            await loadStoryDetails() // New method to load story by ID
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
        VStack(spacing: UITheme.Spacing.xs) {
            ProgressView(value: readingProgress)
                .tint(UITheme.Colors.primary)
                .padding(.horizontal, UITheme.Spacing.lg)
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

    // MARK: - Initializer
    init(storyID: UUID) {
        self.storyID = storyID
    }

    // MARK: - Helper Functions
    
    private func loadStoryDetails() async {
        // If story is already set, just process it and don't fetch
        if let currentStory = story {
            pages = currentStory.pages.sorted(by: { $0.pageNumber < $1.pageNumber })
            isLoadingPages = false
            if !pages.isEmpty {
                readingProgress = StoryProcessor.calculateReadingProgress(
                    currentPage: currentPageIndex + 1, totalPages: pages.count)
                updateIllustrationProgress()
            }
            processIllustrations()
            return
        }

        // Otherwise fetch the story by ID
        isLoadingPages = true
        do {
            // Use the environment object to fetch the story
            let fetchedStory = try await persistenceService.fetchStory(withId: storyID)
            self.story = fetchedStory
            
            if let currentStory = fetchedStory {
                // Log the pages before sorting to see their original order
                print("[StoryDetailView] Original page order for story \(currentStory.id):")
                for (index, page) in currentStory.pages.enumerated() {
                    print("[StoryDetailView] Page \(index): pageNumber=\(page.pageNumber), id=\(page.id)")
                }
                pages = currentStory.pages.sorted(by: { $0.pageNumber < $1.pageNumber })
                // Log the pages after sorting to confirm correct order
                print("[StoryDetailView] After sorting - page count: \(pages.count) for story \(currentStory.id)")
                for (index, page) in pages.enumerated() {
                    print("[StoryDetailView] Page \(index): pageNumber=\(page.pageNumber), id=\(page.id)")
                }
                // This is where the main logic for setting up after pages are sorted should be.
                // The isLoadingPages = false and subsequent UI updates will be handled after this block.
                 if !pages.isEmpty {
                     readingProgress = StoryProcessor.calculateReadingProgress(
                         currentPage: currentPageIndex + 1, totalPages: pages.count)
                     updateIllustrationProgress() // Ensure this is called after pages are set
                 } else {
                     readingProgress = 0.0
                 }
                processIllustrations() // Call processIllustrations after story is loaded and pages are set
            } else {
                print("[StoryDetailView] Failed to fetch story with ID: \(storyID)")
                // Handle error, e.g., show an error message to the user
            }
        } catch {
            print("[StoryDetailView] Error fetching story \(storyID): \(error)")
            // Handle error
        }
        isLoadingPages = false // Set isLoadingPages to false after all loading logic
        if !pages.isEmpty && story != nil { // Check story != nil as well
            UIAccessibility.post(
                notification: .screenChanged,
                argument: "\(pages.count) pages loaded. Page 1 is now displayed")
        }
    }

    // loadPages() is now part of loadStoryDetails() or assumes story is already loaded
    // private func loadPages() async { ... } // Removed as its logic is integrated

    // This is the correct single instance of updateIllustrationProgress
    private func updateIllustrationProgress() {
        guard story != nil else { return } // Ensure story is loaded
        let total = pages.count
        let ready = pages.filter { $0.illustrationStatus == .ready }.count
        illustrationProgress = (ready, total)
    }
    
    // MARK: - Global Reference Task Helpers
    
    private func createGlobalReferenceTask(for story: Story) -> IllustrationTask {
        return IllustrationTask(
            pageId: UUID(), // Placeholder ID for global reference tasks
            storyId: story.id,
            priority: .high,
            taskType: .globalReference,
            pageIndex: 0, // Global reference uses pageIndex 0
            globalReferenceURL: nil,
            dependencies: nil
        )
    }
    
    private func needsGlobalReferenceTask(for storyId: UUID) -> Bool {
        // Check if any task in the manager is a global reference for this story
        return !illustrationTaskManager.pendingTasks.contains { task in
            task.storyId == storyId && task.taskType == .globalReference
        }
    }
    
    private func getGlobalReferenceTask(for storyId: UUID) -> IllustrationTask? {
        // Check pending tasks first
        if let pendingTask = illustrationTaskManager.pendingTasks.first(where: { task in
            task.storyId == storyId && task.taskType == .globalReference
        }) {
            return pendingTask
        }
        
        // Check completed tasks through task manager's completed dependencies
        // For now, we'll need to track this through the task manager
        return nil
    }
    
    @MainActor
    private func getGlobalReferenceImagePath(for storyId: UUID) -> String? {
        print("[StoryDetailView] Global reference lookup temporarily disabled for testing")
        return nil
    }
    
    /// Ensure the story has a visual guide for character consistency
    private func ensureVisualGuideExists(for story: Story) async {
        // Check if story already has a visual guide
        if story.visualGuide != nil {
            print("[StoryDetailView] Story '\(story.title)' already has visual guide")
            return
        }
        
        print("[StoryDetailView] Generating visual guide for existing story: '\(story.title)'")
        
        do {
            // Generate visual guide for the existing story
            let visualGuide = try await storyService.generateVisualGuideForExistingStory(story)
            
            // Save the visual guide to the story
            await MainActor.run {
                story.setVisualGuide(visualGuide)
                // Save the story with the new visual guide
                try? modelContext.save()
                print("[StoryDetailView] Visual guide saved for story: '\(story.title)'")
                print("[StoryDetailView] Characters: \(visualGuide.characterDefinitions.keys.joined(separator: ", "))")
            }
        } catch {
            print("[StoryDetailView] Failed to generate visual guide for story '\(story.title)': \(error.localizedDescription)")
            
            // Create a basic fallback visual guide
            await MainActor.run {
                let fallbackGuide = VisualGuide(
                    styleGuide: "Colorful, child-friendly illustration style with warm colors",
                    characterDefinitions: [:],
                    settingDefinitions: ["Main Setting": "A warm, inviting environment suitable for children"]
                )
                story.setVisualGuide(fallbackGuide)
                try? modelContext.save()
                print("[StoryDetailView] Fallback visual guide created for story: '\(story.title)'")
            }
        }
    }

    private func processIllustrations() {
        guard let currentStory = story else { return } // Ensure story is loaded
        // Only process illustrations once
        guard isFirstAppearance else { return }
        isFirstAppearance = false
        
        // Ensure the story has a visual guide for character consistency
        Task {
            await ensureVisualGuideExists(for: currentStory)
        }
        
        // Check if any pages need illustration generation
        let pagesNeedingIllustrations = pages.filter { $0.illustrationStatus == .pending }
        
        // If no pages need illustrations, we're done
        if (pagesNeedingIllustrations.isEmpty) {
            print("[StoryDetailView] All illustrations are already generated for story: \(currentStory.title)")
            return
        }
        
        print("[StoryDetailView] Adding \(pagesNeedingIllustrations.count) illustration tasks for story: \(currentStory.title)")
        
        // Create global reference task first if needed and store its ID
        var globalReferenceTaskId: UUID? = nil
        if needsGlobalReferenceTask(for: currentStory.id) {
            let globalReferenceTask = createGlobalReferenceTask(for: currentStory)
            globalReferenceTaskId = globalReferenceTask.id
            illustrationTaskManager.addTask(globalReferenceTask)
            print("[StoryDetailView] Added global reference task for story: \(currentStory.title)")
        } else {
            // Check if there's already a global reference task for this story
            globalReferenceTaskId = getGlobalReferenceTask(for: currentStory.id)?.id
        }
        
        // Create tasks for each page with appropriate priorities and dependencies
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
            
            // Build dependencies for this page task
            var dependencies: [UUID] = []
            
            // Add global reference dependency if available
            if let globalRefId = globalReferenceTaskId {
                dependencies.append(globalRefId)
            }
            
            // Add previous page dependency for sequential illustration
            if page.pageNumber > 1 {
                // Previous page dependencies will be handled by task manager's enforceDependencyPatterns
                // which automatically creates sequential page dependencies
            }
            
            // Create task with enhanced parameters
            let task = IllustrationTask(
                pageId: page.id,
                storyId: currentStory.id,
                priority: priority,
                taskType: .pageIllustration,
                pageIndex: page.pageNumber,
                dependencies: dependencies.isEmpty ? nil : dependencies
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
                    // Handle global reference tasks differently
                    if task.taskType == .globalReference {
                        return await processGlobalReferenceTask(task)
                    }
                    
                    // Find the corresponding page for regular page tasks
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
                    
                    // Get global reference path for visual consistency
                    let globalReferenceImagePath = await MainActor.run {
                        return getGlobalReferenceImagePath(for: task.storyId)
                    }
                    
                    print("[StoryDetailView] Generating page \(page.pageNumber) with global reference: \(globalReferenceImagePath != nil ? "YES" : "NO")")
                    if let globalPath = globalReferenceImagePath {
                        print("[StoryDetailView] Global reference path: \(globalPath)")
                    }
                    
                    // Create VisualGuide for page illustration
                    guard let currentStory = story else {
                        print("[StoryDetailView] No story available for page task: \(task.id)")
                        var failedTask = task
                        failedTask.updateStatus(.failed)
                        return failedTask
                    }
                    let visualGuide = createInitialVisualGuide(for: currentStory)
                    
                    // Generate illustration using the enhanced method
                    if let relativePath = try await illustrationService.generateIllustration(
                        for: description,
                        pageNumber: page.pageNumber,
                        totalPages: pages.count,
                        previousIllustrationPath: previousIllustrationPath,
                        visualGuide: visualGuide,
                        globalReferenceImagePath: globalReferenceImagePath
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
    
    // MARK: - Global Reference Task Processing
    
    private func processGlobalReferenceTask(_ task: IllustrationTask) async -> IllustrationTask {
        guard let currentStory = story else {
            print("[StoryDetailView] No story available for global reference task: \(task.id)")
            var failedTask = task
            failedTask.updateStatus(.failed)
            return failedTask
        }
        
        do {
            print("[StoryDetailView] Processing global reference task for story: \(currentStory.title)")
            
            // Create a description for the global reference image
            // This should include all characters and key elements from the story
            let globalDescription = createGlobalReferenceDescription(for: currentStory)
            
            // Create a basic VisualGuide for global reference generation
            let visualGuide = createInitialVisualGuide(for: currentStory)
            
            // Generate global reference illustration using the enhanced IllustrationService method
            if let relativePath = try await illustrationService.generateIllustration(
                for: globalDescription,
                pageNumber: 0, // Special page number for global reference
                totalPages: pages.count,
                previousIllustrationPath: nil,
                visualGuide: visualGuide,
                globalReferenceImagePath: nil // No global reference for the global reference itself
            ) {
                // Update task status to ready
                var completedTask = task
                completedTask.updateStatus(.ready)
                
                // Save the completed task to repository for persistence
                await MainActor.run {
                    let repository = IllustrationTaskRepository(modelContext: modelContext)
                    do {
                        _ = try repository.saveTask(
                            completedTask,
                            pageNumber: 0, // Global reference is page 0
                            totalPages: pages.count,
                            description: globalDescription,
                            previousIllustrationPath: nil
                        )
                        print("[StoryDetailView] Global reference task saved to repository")
                    } catch {
                        print("[StoryDetailView] Failed to save global reference task: \(error)")
                    }
                }
                
                print("[StoryDetailView] Global reference task completed successfully: \(relativePath)")
                return completedTask
            } else {
                // Failed to generate global reference
                print("[StoryDetailView] Failed to generate global reference illustration")
                var failedTask = task
                failedTask.updateStatus(.failed)
                return failedTask
            }
        } catch {
            print("[StoryDetailView] Error generating global reference illustration: \(error)")
            var failedTask = task
            failedTask.updateStatus(.failed)
            return failedTask
        }
    }
    
    private func createGlobalReferenceDescription(for story: Story) -> String {
        // Extract key elements from the story to create a comprehensive description
        let storyTheme = story.parameters.theme
        let childName = story.parameters.childName ?? "the main character"
        let favoriteCharacter = story.parameters.favoriteCharacter ?? ""
        
        // Create a description that includes all main characters and key visual elements
        var description = "Create a comprehensive reference illustration for a \(storyTheme) story featuring \(childName)"
        
        if !favoriteCharacter.isEmpty {
            description += " and \(favoriteCharacter)"
        }
        
        description += ". This illustration should show all the main characters in a neutral, reference-style composition that can be used as a visual guide for consistency across multiple story pages. Include key visual elements, character designs, and the overall art style that will be maintained throughout the story."
        
        return description
    }
    
    private func createInitialVisualGuide(for story: Story) -> VisualGuide {
        // Extract basic character information from story parameters
        let storyTheme = story.parameters.theme
        let childName = story.parameters.childName ?? "the main character"
        let favoriteCharacter = story.parameters.favoriteCharacter ?? ""
        
        // Create character definitions
        var characterDefinitions: [String: String] = [:]
        
        // Add the main character (child)
        characterDefinitions[childName] = "A cheerful child who is the main protagonist of this \(storyTheme) story"
        
        // Add favorite character if specified
        if !favoriteCharacter.isEmpty {
            characterDefinitions[favoriteCharacter] = "An important character in the story, beloved by the main character"
        }
        
        // Create a style guide based on the theme and target age
        let styleGuide = createStyleGuide(theme: storyTheme, childAge: story.parameters.childAge)
        
        // Create basic setting definitions
        var settingDefinitions: [String: String] = [:]
        settingDefinitions["main_setting"] = "The primary environment where the \(storyTheme) story takes place"
        
        return VisualGuide(
            styleGuide: styleGuide,
            characterDefinitions: characterDefinitions,
            settingDefinitions: settingDefinitions,
            globalReferenceImageURL: nil
        )
    }
    
    private func createStyleGuide(theme: String, childAge: Int) -> String {
        var styleComponents = [
            "Children's book illustration style",
            "Colorful and engaging artwork suitable for \(childAge)-year-old children",
            "Theme: \(theme)",
            "Warm, friendly, and approachable character designs",
            "Clear, easy-to-read visual storytelling"
        ]
        
        // Add age-appropriate style adjustments
        if childAge <= 5 {
            styleComponents.append("Simple, bold shapes and bright colors")
            styleComponents.append("Large, expressive characters")
        } else if childAge <= 8 {
            styleComponents.append("More detailed illustrations with richer storytelling")
            styleComponents.append("Balanced color palette with good contrast")
        } else {
            styleComponents.append("Sophisticated artwork with detailed backgrounds")
            styleComponents.append("Complex compositions and nuanced character expressions")
        }
        
        return styleComponents.joined(separator: ". ")
    }

    private func regenerateIllustration(for page: Page) {
        // Using MainActor for the entire task to safely access modelContext
        Task { @MainActor in
            // Store image prompt and other necessary data before starting illustration generation
            let imagePrompt = page.imagePrompt ?? page.content
            let pageNumber = page.pageNumber
            let totalPages = pages.count
            
            do {
                // Get previous illustration path for visual continuity
                let previousPage = pageNumber > 1 ? 
                    pages.first(where: { $0.pageNumber == pageNumber - 1 }) : nil
                let previousIllustrationPath = previousPage?.illustrationPath
                
                // Get global reference path for visual consistency
                let globalReferenceImagePath = getGlobalReferenceImagePath(for: story?.id ?? UUID())
                
                // Create visual guide for regeneration
                guard let currentStory = story else {
                    throw NSError(domain: "StoryDetailView", code: 1, userInfo: [NSLocalizedDescriptionKey: "No story available"])
                }
                let visualGuide = createInitialVisualGuide(for: currentStory)
                
                // Use the contextual generation method with all proper parameters
                if let relativePath = try await illustrationService.generateIllustration(
                    for: imagePrompt,
                    pageNumber: pageNumber,
                    totalPages: totalPages,
                    previousIllustrationPath: previousIllustrationPath,
                    visualGuide: visualGuide,
                    globalReferenceImagePath: globalReferenceImagePath
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
        guard let currentStory = story else { return } // Ensure story is loaded
        print("[StoryDetailView] Story completed: \(currentStory.title)")

        // Update readCount and lastReadAt in persistence
        do {
            try await persistenceService.incrementReadCount(for: currentStory.id)
            try await persistenceService.updateLastReadAt(for: currentStory.id, date: Date())
        } catch {
            print("[StoryDetailView] Error updating readCount/lastReadAt for story \(currentStory.id): \(error)")
        }

        guard let collectionId = currentStory.collections.first?.id else {
            print("[StoryDetailView] Story \"\(currentStory.title)\" does not belong to a collection.")
            return
        }

        // Mark story as completed and update collection progress
        do {
            try await collectionService.markStoryAsCompleted(
                storyId: currentStory.id, collectionId: collectionId)
        } catch {
            print(
                "[StoryDetailView] Error marking story \(currentStory.id) as completed or updating collection progress: \(error)"
            )
        }
    }
}
