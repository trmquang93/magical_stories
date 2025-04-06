import SwiftUI

struct StoryDetailView: View {
    let story: Story
    
    @State private var pages: [Page] = []
    @State private var currentPageIndex = 0
    @State private var isLoadingPages = true
    @State private var readingProgress: Double = 0.0
    // StoryProcessor instance removed, calculateReadingProgress is now static
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoadingPages {
                MagicalLoadingView(message: "Preparing your story...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if pages.isEmpty {
                MagicalEmptyStateView(
                    title: "Story Error",
                    message: "Could not load story pages.",
                    buttonTitle: "Go Back"
                ) {
                    // In a real app, use Environment(\.dismiss)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Page Content using TabView for pagination
                TabView(selection: $currentPageIndex) {
                    ForEach(pages.indices, id: \.self) { index in
                        PageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never)) // Use page style, hide default index dots
                .onChange(of: currentPageIndex) { _, newIndex in
                    updateReadingProgress()
                }
                
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
            
            Text("Page \(currentPageIndex + 1) of \(pages.count)")
                .font(Theme.Typography.bodySmall)
                .foregroundColor(Theme.Colors.textSecondary)
        }
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

// MARK: - Preview
#Preview {
    NavigationStack {
        StoryDetailView(
            story: {
                // Create sample parameters matching the Story model
                let sampleParams = StoryParameters(
                    childName: "Alex",
                    childAge: 6, // Using the previous ageGroup value
                    theme: "Courage", // Using a string representation of the theme
                    favoriteCharacter: "🦁"
                )
                // Initialize Story with the correct parameters
                // Create sample pages for the preview
                let samplePages = [
                    Page(content: "Once upon a time, there was a brave lion named Leo who lived in the savanna. Leo was known for his courage and kindness to all animals.", pageNumber: 1),
                    Page(content: "One day, a terrible storm came to the savanna, and all the animals were afraid. But Leo stood tall and helped everyone find shelter.", pageNumber: 2, illustrationURL: URL(string: "https://example.com/placeholder-storm.png")), // Example URL
                    Page(content: "Thanks to Leo's bravery, all the animals were safe. They cheered for Leo, the hero of the savanna!", pageNumber: 3),
                    Page(content: "From that day on, Leo continued to watch over his friends, always ready to lend a paw.", pageNumber: 4)
                ]

                return Story(
                    // id and timestamp will use default values from the initializer
                    title: "The Brave Lion",
                    pages: samplePages, // Use the pages array
                    parameters: sampleParams
                )
            }() // Immediately execute the closure to provide the Story instance
        )
    }
    // TODO: Add SettingsService environment object if needed for previews
    // .environmentObject(SettingsService())
}
