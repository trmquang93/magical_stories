import SwiftUI

struct StoryDetailView: View {
    let story: Story
    
    @EnvironmentObject private var textToSpeechService: TextToSpeechService
    @State private var isPlaying = false
    @State private var highlightedRange: NSRange?
    @State private var pages: [Page] = []
    @State private var currentPageIndex = 0
    @State private var isLoadingPages = true
    @State private var readingProgress: Double = 0.0
    
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
                            // Apply highlighting only to the current page's content
                            .modifier(
                                TextHighlightModifier(
                                    text: pages[index].content,
                                    highlightRange: currentPageIndex == index ? highlightedRange : nil,
                                    highlightColor: Theme.Colors.accent
                                )
                            )
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never)) // Use page style, hide default index dots
                .onChange(of: currentPageIndex) { _, newIndex in
                    // Stop speech when page changes
                    textToSpeechService.stopSpeaking()
                    updateReadingProgress()
                }
                
                // Custom Page Indicator and Progress Bar
                pageIndicatorAndProgress
                    .padding(.bottom, Theme.Spacing.sm)
            }
        }
        .navigationTitle(story.title)
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            if !isLoadingPages && !pages.isEmpty {
                audioControls
                    .padding(.bottom, Theme.Spacing.md)
            }
        }
        .task { // Use .task for async operations on appear
            await loadPages()
        }
        .onReceive(textToSpeechService.$currentWordRange) { range in
            // Only update highlight range if it's for the current page
            // (TTS service might still hold range from previous page briefly)
            highlightedRange = range
        }
        .onReceive(textToSpeechService.$isPlaying) { playing in
            isPlaying = playing
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
    
    private var audioControls: some View {
        HStack(spacing: Theme.Spacing.lg) {
            // Previous Page Button
            Button {
                if currentPageIndex > 0 {
                    currentPageIndex -= 1
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(Theme.Typography.bodyLarge)
                    .foregroundColor(currentPageIndex > 0 ? Theme.Colors.primary : Theme.Colors.textSecondary.opacity(0.5))
                    .frame(width: 50, height: 50)
                    .background(Theme.Colors.surfaceSecondary.opacity(0.8))
                    .clipShape(Circle())
            }
            .disabled(currentPageIndex <= 0)
            
            // Play/Pause Button
            Button {
                togglePlayPause()
            } label: {
                Label(isPlaying ? "Pause" : "Play", systemImage: isPlaying ? "pause.fill" : "play.fill")
                    .font(Theme.Typography.bodyLarge)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Theme.Colors.primary)
                    .cornerRadius(Theme.Layout.cornerRadiusMedium)
            }
            
            // Next Page Button
            Button {
                if currentPageIndex < pages.count - 1 {
                    currentPageIndex += 1
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(Theme.Typography.bodyLarge)
                    .foregroundColor(currentPageIndex < pages.count - 1 ? Theme.Colors.primary : Theme.Colors.textSecondary.opacity(0.5))
                    .frame(width: 50, height: 50)
                    .background(Theme.Colors.surfaceSecondary.opacity(0.8))
                    .clipShape(Circle())
            }
            .disabled(currentPageIndex >= pages.count - 1)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.sm) // Add vertical padding
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .edgesIgnoringSafeArea(.bottom)
        )
    }
    
    // MARK: - Helper Functions
    
    private func loadPages() async {
        isLoadingPages = true
        pages = await story.pages // Use the async property from Story extension
        isLoadingPages = false
        updateReadingProgress() // Initial progress update
    }
    
    private func updateReadingProgress() {
        Task {
            readingProgress = await story.readingProgress(currentPage: currentPageIndex + 1)
        }
    }
    
    private func togglePlayPause() {
        guard currentPageIndex < pages.count else { return }
        let currentPageContent = pages[currentPageIndex].content
        
        if isPlaying {
            textToSpeechService.pauseSpeaking()
        } else {
            // If TTS was paused on this page, continue; otherwise, start fresh
            if textToSpeechService.isPlaying { // Should be false if paused, but check just in case
                 textToSpeechService.continueSpeaking()
            } else {
                 // Check if the synthesizer has state from a previous page read
                 // A more robust solution might involve tracking if the *current* utterance is paused
                 // For simplicity now, we restart if not actively playing.
                 textToSpeechService.speak(currentPageContent)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        StoryDetailView(
            story: Story(
                title: "The Brave Lion",
                content: """
                Once upon a time, there was a brave lion named Leo who lived in the savanna. Leo was known for his courage and kindness to all animals.
                
                One day, a terrible storm came to the savanna, and all the animals were afraid. But Leo stood tall and helped everyone find shelter.
                
                Thanks to Leo's bravery, all the animals were safe. They cheered for Leo, the hero of the savanna!
                
                From that day on, Leo continued to watch over his friends, always ready to lend a paw.
                """,
                theme: .courage,
                childName: "Alex",
                ageGroup: 6,
                favoriteCharacter: "🦁"
            )
        )
    }
    .environmentObject(TextToSpeechService(settingsService: SettingsService()))
}
