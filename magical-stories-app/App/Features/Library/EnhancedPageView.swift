import SwiftUI

/// Enhanced PageView that uses embedded storage for illustrations
@MainActor
struct EnhancedPageView: View {
    let page: Page
    var regenerateAction: (() -> Void)? = nil
    
    @EnvironmentObject private var simpleIllustrationService: SimpleIllustrationService
    @State private var illustrationImage: UIImage?
    @State private var isLoadingIllustration = false
    @State private var loadingError: String?
    
    /// Generate an accessibility description for the illustration
    private var illustrationDescription: String {
        if let prompt = page.imagePrompt, !prompt.isEmpty {
            return "Illustration showing: \(prompt)"
        } else {
            return "Illustration for page \(page.pageNumber)"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UITheme.Spacing.lg) {
                // Enhanced illustration display with embedded storage support
                illustrationView
                
                // Story content
                Text(page.content)
                    .font(UITheme.Typography.bodyLarge)
                    .lineSpacing(8)
                    .foregroundColor(UITheme.Colors.textPrimary)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                    .accessibilityLabel("Story text")
                    .accessibilitySortPriority(2)
                    .accessibilityIdentifier("PageContentText")
                
                Spacer()
            }
            .padding(.horizontal, UITheme.Spacing.lg)
            .padding(.vertical, UITheme.Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Page \(page.pageNumber)")
            .accessibilityIdentifier("EnhancedPageViewContent")
        }
        .accessibilityIdentifier("EnhancedPageViewScrollView")
        .onAppear {
            loadIllustration()
        }
        .onChange(of: page.id) { _, _ in
            loadIllustration()
        }
        .onChange(of: page.illustrationStatus) { _, newStatus in
            // Reload illustration when status changes to ready
            if newStatus == .ready {
                loadIllustration()
            }
        }
        .onChange(of: page.illustrationCacheKey) { _, _ in
            // Reload illustration when cache key changes
            loadIllustration()
        }
    }
    
    @ViewBuilder
    private var illustrationView: some View {
        Group {
            if let image = illustrationImage {
                // Successfully loaded illustration
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(UITheme.Layout.cornerRadiusMedium)
                    .accessibilityLabel(illustrationDescription)
                    .accessibilityAddTraits(.isImage)
                    .transition(.opacity.animation(.easeIn(duration: 0.3)))
                    .contextMenu {
                        if let regenerateAction = regenerateAction {
                            Button("Regenerate Illustration") {
                                regenerateAction()
                            }
                        }
                    }
                
            } else if isLoadingIllustration {
                // Loading state
                IllustrationPlaceholderView(
                    status: .generating,
                    height: 200,
                    onRetry: nil
                )
                
            } else if let error = loadingError {
                // Error state with retry option
                VStack(spacing: UITheme.Spacing.md) {
                    IllustrationPlaceholderView(
                        status: .failed,
                        height: 200,
                        onRetry: regenerateAction
                    )
                    
                    Text("Error: \(error)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
            } else {
                // No illustration available - show appropriate placeholder
                IllustrationPlaceholderView(
                    status: page.illustrationStatus,
                    height: 200,
                    onRetry: page.illustrationStatus == .failed ? regenerateAction : nil
                )
            }
        }
    }
    
    /// Loads illustration using embedded storage
    private func loadIllustration() {
        // Reset state
        illustrationImage = nil
        loadingError = nil
        isLoadingIllustration = true
        
        Task {
            await MainActor.run {
                isLoadingIllustration = true
            }
            
            // Try to get illustration from embedded storage or cache
            if let imageData = simpleIllustrationService.getIllustration(for: page) {
                if let image = UIImage(data: imageData) {
                    await MainActor.run {
                        self.illustrationImage = image
                        self.isLoadingIllustration = false
                    }
                    return
                } else {
                    print("[EnhancedPageView] Failed to create UIImage from data for page \(page.pageNumber)")
                }
            }
            
            // No illustration available
            await MainActor.run {
                self.isLoadingIllustration = false
            }
        }
    }
}

#Preview("Enhanced Page with Embedded Storage") {
    EnhancedPageView(
        page: Page(
            content: "Once upon a time, in a land far, far away, there lived a curious little fox named Finley. This preview shows how the enhanced page view handles embedded illustration storage.",
            pageNumber: 1,
            illustrationStatus: .ready,
            imagePrompt: "A small red fox entering a mystical forest with sunlight filtering through the trees"
        )
    )
    .environmentObject(try! SimpleIllustrationService())
}

#Preview("Enhanced Page Loading State") {
    EnhancedPageView(
        page: Page(
            content: "Finley loved exploring the Whispering Woods behind his cozy den.",
            pageNumber: 2,
            illustrationStatus: .generating,
            imagePrompt: "A small red fox looking at a magical forest"
        )
    )
    .environmentObject(try! SimpleIllustrationService())
}

#Preview("Enhanced Page Error State") {
    EnhancedPageView(
        page: Page(
            content: "One sunny morning, Finley decided to venture deeper into the woods than ever before.",
            pageNumber: 3,
            illustrationStatus: .failed,
            imagePrompt: "A small red fox venturing deeper into a mysterious forest"
        ),
        regenerateAction: {
            print("Regenerate action triggered")
        }
    )
    .environmentObject(try! SimpleIllustrationService())
}

#Preview("Dark Mode") {
    EnhancedPageView(
        page: Page(
            content: "The enhanced page view works beautifully in dark mode too.",
            pageNumber: 1,
            illustrationStatus: .pending,
            imagePrompt: "A small red fox entering a mystical forest"
        )
    )
    .environmentObject(try! SimpleIllustrationService())
    .preferredColorScheme(.dark)
}