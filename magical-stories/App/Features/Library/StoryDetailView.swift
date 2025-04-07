import SwiftUI

struct StoryDetailView: View {
    let story: Story
    
    @State private var pages: [Page] = []
    @State private var currentPageIndex = 0
    @State private var isLoadingPages = true
    @State private var readingProgress: Double = 0.0
    // StoryProcessor instance removed, calculateReadingProgress is now static
    
    // Accessibility description of the current reading progress
    private var progressDescription: String {
        return "Reading progress: \(Int(readingProgress * 100))%"
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
                .tabViewStyle(.page(indexDisplayMode: .never)) // Use page style, hide default index dots
                .onChange(of: currentPageIndex) { _, newIndex in
                    updateReadingProgress()
                    // Announce page change to VoiceOver
                    UIAccessibility.post(notification: .pageScrolled, argument: "Page \(newIndex + 1) of \(pages.count)")
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
        .task { // Use .task for async operations on appear
            await loadPages()
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
        // Use the processor to segment the story content into pages
        // Pages are now directly part of the Story model, no processing needed here.
        self.pages = story.pages
        print("StoryDetailView: Loaded \(pages.count) pages directly from story model.")
        isLoadingPages = false
        updateReadingProgress() // Initial progress update
        
        // Announce when pages are loaded for VoiceOver users
        if !pages.isEmpty {
            UIAccessibility.post(notification: .screenChanged, argument: "\(pages.count) pages loaded. Page 1 is now displayed")
        }
    }
    
    private func updateReadingProgress() {
        // Calculate progress based on current index and total pages
        // Ensure pages is not empty to avoid division by zero
        guard !pages.isEmpty else {
            readingProgress = 0.0
            return
        }
        // Call the static method directly
        readingProgress = StoryProcessor.calculateReadingProgress(currentPage: currentPageIndex + 1, totalPages: pages.count)
    }
}