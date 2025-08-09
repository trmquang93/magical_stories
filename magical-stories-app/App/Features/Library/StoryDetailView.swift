import SwiftData
import SwiftUI

@MainActor
struct StoryDetailView: View {
    @EnvironmentObject private var collectionService: CollectionService
    @EnvironmentObject private var persistenceService: PersistenceService
    @EnvironmentObject private var readingProgressService: ReadingProgressService
    // New services
    @EnvironmentObject private var simpleIllustrationService: SimpleIllustrationService
    @EnvironmentObject private var characterReferenceService: CharacterReferenceService
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var storyService: StoryService
    @EnvironmentObject private var analyticsService: ClarityAnalyticsService

    // story will be loaded from storyID
    @State private var story: Story?
    private let storyID: UUID // storyID is now the input

    @State private var pages: [Page] = []
    @State private var isFirstAppearance = true
    @State private var currentPageIndex = 0
    @State private var isLoadingPages = true
    @State private var readingProgress: Double = 0.0
    @State private var illustrationProgress: (ready: Int, total: Int) = (0, 0)
    @State private var isGeneratingCharacterReferences = false
    @State private var characterReferenceError: String?

    @State private var showCompletionAlert = false
    @State private var newAchievements: [Achievement] = []
    @State private var isCompletingStory = false

    // Accessibility description of the current reading progress
    private var progressDescription: String {
        "Reading progress: \(Int(readingProgress * 100))%"
    }

    // Status text for illustration generation
    private var illustrationStatusText: String? {
        // Show character reference generation status first
        if isGeneratingCharacterReferences {
            return "Preparing character references..."
        }
        
        // Show character reference error if any
        if let error = characterReferenceError {
            return "Character reference error: \(error)"
        }
        
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
                        MagicalLoadingView(
                            message: isGeneratingCharacterReferences ? 
                                "Preparing character references..." : 
                                "Preparing your story..."
                        )
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
                        // Illustration Status Header (shown during character reference or illustration generation)
                        if let statusText = illustrationStatusText {
                            VStack(spacing: 4) {
                                Text(statusText)
                                    .font(UITheme.Typography.bodySmall)
                                    .foregroundColor(UITheme.Colors.textSecondary)

                                if isGeneratingCharacterReferences {
                                    // Show indeterminate progress for character reference generation
                                    ProgressView()
                                        .tint(UITheme.Colors.accent)
                                        .frame(maxWidth: .infinity)
                                } else {
                                    // Show deterministic progress for illustration generation
                                    ProgressView(
                                        value: Double(illustrationProgress.ready),
                                        total: Double(illustrationProgress.total)
                                    )
                                    .tint(UITheme.Colors.accent)
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal, UITheme.Spacing.lg)
                            .padding(.vertical, UITheme.Spacing.sm)
                            .background(UITheme.Colors.surfacePrimary)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(
                                isGeneratingCharacterReferences ? 
                                "Preparing character references for consistent illustrations" :
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
                MagicalLoadingView(
                    message: isGeneratingCharacterReferences ? 
                        "Preparing character references..." : 
                        "Loading story details..."
                )
            }
        }
        .task {
            if Task.isCancelled { return }
            await loadStoryDetails() // New method to load story by ID
            
            // Track story detail view
            analyticsService.trackScreenView(ClarityConfiguration.ScreenNames.storyDetail)
            
            // Track story viewed with parameters
            if let currentStory = story {
                analyticsService.trackUserAction("story_viewed", parameters: [
                    "story_id": currentStory.id.uuidString,
                    "story_title": currentStory.title,
                    "age_group": String(currentStory.parameters.childAge),
                    "category": currentStory.parameters.theme,
                    "timestamp": Date().timeIntervalSince1970
                ])
            }
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
            // Generate character references asynchronously (for already loaded stories)
            Task {
                await generateCharacterReferencesIfNeeded(for: currentStory)
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
                // Generate character references FIRST before illustrations
                await generateCharacterReferencesIfNeeded(for: currentStory)
                
                // THEN process illustrations after character references are ready
                processIllustrations()
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
    
    // MARK: - Character Reference Generation
    
    /// Checks if a story is a pre-made story with bundle resources (illustrations already included)
    private func isPreMadeStoryWithBundleResources(_ story: Story) -> Bool {
        // Pre-made stories have illustrationFileName in their pages instead of illustrationCacheKey
        return story.pages.contains { page in
            page.illustrationFileName != nil && page.illustrationStatus == .ready
        }
    }
    
    /// Generates character references for a story if they don't already exist
    /// This ensures characters are ready for consistent illustration generation
    private func generateCharacterReferencesIfNeeded(for story: Story) async {
        // Skip character reference generation for pre-made stories with bundle resources
        if isPreMadeStoryWithBundleResources(story) {
            print("[StoryDetailView] Skipping character reference generation for pre-made story: \(story.title)")
            return
        }
        
        // Check if character references already exist
        if hasCharacterReferences(for: story) {
            print("[StoryDetailView] Character references already exist for story: \(story.title)")
            return
        }
        
        // Check if story has visual guide and character names (required for character references)
        guard getVisualGuide(for: story) != nil else {
            print("[StoryDetailView] No visual guide data found in story")
            return
        }
        
        guard let characterNames = story.characterNames, !characterNames.isEmpty else {
            print("[StoryDetailView] Story has no character names - skipping character reference generation")
            return
        }
        
        print("[StoryDetailView] Generating character references for story: \(story.title) with \(characterNames.count) characters")
        print("[StoryDetailView] Character names: \(characterNames.joined(separator: ", "))")
        
        await MainActor.run {
            isGeneratingCharacterReferences = true
            characterReferenceError = nil
        }
        
        do {
            // Use the CharacterReferenceService to generate complete character references
            try await storyService.generateCharacterReferences(for: story)
            
            print("[StoryDetailView] Successfully generated character references for \(characterNames.count) characters")
            
            await MainActor.run {
                isGeneratingCharacterReferences = false
                characterReferenceError = nil
            }
            
        } catch {
            print("[StoryDetailView] Failed to generate character references: \(error.localizedDescription)")
            print("[StoryDetailView] Character reference generation error details: \(error)")
            
            await MainActor.run {
                isGeneratingCharacterReferences = false
                characterReferenceError = "Character preparation incomplete"
            }
            
            // Clear error after a delay to not permanently show error state
            // This ensures the UI doesn't stay in an error state permanently
            Task {
                try? await Task.sleep(for: .seconds(3))
                await MainActor.run {
                    characterReferenceError = nil
                }
            }
            
            // Character reference generation failure should not block illustration generation
            // Illustrations can still be generated without character references, just with less consistency
            print("[StoryDetailView] Continuing with illustration generation despite character reference failure")
        }
    }
    
    /// Checks if a story has character references available
    private func hasCharacterReferences(for story: Story) -> Bool {
        return characterReferenceService.hasCharacterReferences(for: story)
    }
    
    /// Regenerates illustrations that were created without character references
    private func regenerateIllustrationsWithCharacterReferences() async {
        guard let currentStory = story else { return }
        
        // Check if character references are now available
        if characterReferenceService.hasCharacterReferences(for: currentStory) {
            print("[StoryDetailView] Character references now available, checking for illustrations to regenerate")
            
            // Find pages that might have been generated without character references
            let pendingPages = pages.filter { page in
                page.illustrationStatus == .pending || 
                (page.illustrationStatus == .ready && !page.hasEmbeddedIllustration)
            }
            
            if !pendingPages.isEmpty {
                print("[StoryDetailView] Regenerating \(pendingPages.count) illustrations with character references")
                await generateIllustrationsWithSimpleService(pendingPages)
            }
        }
    }
    private func processIllustrations() {
        guard let currentStory = story else { return } // Ensure story is loaded
        // Only process illustrations once
        guard isFirstAppearance else { return }
        isFirstAppearance = false
        
        // Check if any pages need illustration generation
        let pagesNeedingIllustrations = pages.filter { $0.illustrationStatus == .pending }
        
        // If no pages need illustrations, we're done
        if (pagesNeedingIllustrations.isEmpty) {
            print("[StoryDetailView] All illustrations are already generated for story: \(currentStory.title)")
            return
        }
        
        print("[StoryDetailView] Generating \(pagesNeedingIllustrations.count) illustrations for story: \(currentStory.title)")
        
        // Generate illustrations using the simple service
        Task {
            await generateIllustrationsWithSimpleService(pagesNeedingIllustrations)
        }
    }
    
    /// Generates illustrations using SimpleIllustrationService
    private func generateIllustrationsWithSimpleService(_ pagesNeedingIllustrations: [Page]) async {
        for page in pagesNeedingIllustrations {
            // Set first viewed timestamp if not already set
            if page.firstViewedAt == nil {
                page.firstViewedAt = Date()
            }
            
            do {
                await MainActor.run {
                    page.illustrationStatus = .generating
                    updateIllustrationProgress()
                }
                
                // Generate and store illustration using embedded storage with explicit story context
                try await simpleIllustrationService.generateAndStoreIllustration(for: page, in: story)
                
                await MainActor.run {
                    page.illustrationStatus = .ready
                    // Save the model context to persist changes
                    do {
                        try modelContext.save()
                    } catch {
                        print("[StoryDetailView] Failed to save context after illustration generation: \(error)")
                    }
                    updateIllustrationProgress()
                }
                
                print("[StoryDetailView] Successfully generated illustration for page \(page.pageNumber)")
                
            } catch {
                print("[StoryDetailView] Failed to generate illustration for page \(page.pageNumber): \(error)")
                await MainActor.run {
                    page.illustrationStatus = .failed
                    updateIllustrationProgress()
                }
            }
        }
    }

    // MARK: - Helper Methods for Story Data
    
    /// Get the VisualGuide from existing story data
    private func getVisualGuide(for story: Story) -> VisualGuide? {
        guard let visualGuideData = story.visualGuideData else {
            print("[StoryDetailView] No visual guide data found in story: \(story.title)")
            return nil
        }
        
        do {
            let visualGuide = try JSONDecoder().decode(VisualGuide.self, from: visualGuideData)
            print("[StoryDetailView] Successfully decoded visual guide for story: \(story.title)")
            print("[StoryDetailView] Characters: \(story.characterNames?.joined(separator: ", ") ?? "None")")
            return visualGuide
        } catch {
            print("[StoryDetailView] Failed to decode visual guide for story \(story.title): \(error)")
            return nil
        }
    }
    
    /// Get the CollectionVisualContext from existing story data
    private func getCollectionContext(for story: Story) -> CollectionVisualContext? {
        guard let collectionContextData = story.collectionContextData else {
            print("[StoryDetailView] No collection context data found in story: \(story.title)")
            return nil
        }
        
        do {
            let collectionContext = try JSONDecoder().decode(CollectionVisualContext.self, from: collectionContextData)
            print("[StoryDetailView] Successfully decoded collection context for story: \(story.title)")
            return collectionContext
        } catch {
            print("[StoryDetailView] Failed to decode collection context for story \(story.title): \(error)")
            return nil
        }
    }

    private func regenerateIllustration(for page: Page) {
        // Task inherits @MainActor from the view context
        Task {
            do {
                // Use new simple illustration service with embedded storage
                print("[StoryDetailView] Regenerating illustration using SimpleIllustrationService for page \(page.pageNumber)")
                
                // Clear existing illustration data first
                page.clearIllustration()
                page.illustrationStatus = .generating
                
                // Generate and store new illustration using embedded storage
                try await simpleIllustrationService.generateAndStoreIllustration(for: page)
                page.illustrationStatus = .ready
                
                // Save the model context to persist changes
                do {
                    try modelContext.save()
                } catch {
                    print("[StoryDetailView] Failed to save context after illustration regeneration: \(error)")
                }
                
                print("[StoryDetailView] Successfully regenerated illustration for page \(page.pageNumber)")
                
                // Update illustration progress after any changes
                updateIllustrationProgress()
                
            } catch {
                print("[StoryDetailView] Failed to regenerate illustration: \(error)")
                page.illustrationStatus = .failed
                updateIllustrationProgress()
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

        // Only trigger completion if we're actually on the last page and haven't already started completion
        if newIndex == pages.count - 1 && !isCompletingStory {
            isCompletingStory = true
            Task {
                await handleStoryCompletion()
            }
        }
    }

    private func handleStoryCompletion() async {
        // Ensure we have a valid story and haven't already completed this operation
        guard let currentStory = story else { 
            await MainActor.run {
                isCompletingStory = false
            }
            return 
        }
        
        print("[StoryDetailView] Story completed: \(currentStory.title)")

        // Use the new ReadingProgressService for non-blocking progress updates
        // This prevents UI hanging by performing all database operations in background
        await MainActor.run {
            readingProgressService.handleStoryCompletion(for: currentStory)
        }
        
        // Reset the completion flag immediately since progress update is now non-blocking
        await MainActor.run {
            isCompletingStory = false
        }
    }
}
