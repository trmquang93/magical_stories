import SwiftUI

struct PageView: View {
    var regenerateAction: (() -> Void)? = nil  // Optional regenerate callback
    let page: Page

    private func fullImageURL(for relativePath: String) -> URL? {
        let fileManager = FileManager.default
        do {
            let appSupportURL = try fileManager.url(
                for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil,
                create: false)
            return appSupportURL.appendingPathComponent(relativePath)
        } catch {
            print("Failed to get Application Support directory: \(error)")
            return nil
        }
    }

    /// Generate an accessibility description for the illustration based on the image prompt or create a default one
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
                // Illustration or placeholder based on status
                Group {
                    if page.illustrationStatus == .ready,
                        let relPath = page.illustrationRelativePath,
                        let url = fullImageURL(for: relPath)
                    {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                IllustrationPlaceholderView(
                                    status: .generating,
                                    height: 200,
                                    onRetry: nil
                                )
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                                    .cornerRadius(UITheme.Layout.cornerRadiusMedium)
                                    .accessibilityLabel(illustrationDescription)
                                    .accessibilityAddTraits(.isImage)
                                    .transition(.opacity.animation(.easeIn(duration: 0.3)))
                            case .failure:
                                IllustrationPlaceholderView(
                                    status: .failed,
                                    height: 200,
                                    onRetry: regenerateAction
                                )
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        // Use our placeholder component for all other states
                        IllustrationPlaceholderView(
                            status: page.illustrationStatus,
                            height: 200,
                            onRetry: page.illustrationStatus == .failed ? regenerateAction : nil
                        )
                    }
                }

                Text(page.content)
                    .font(UITheme.Typography.bodyLarge)
                    .lineSpacing(8)  // Consistent line spacing
                    .foregroundColor(UITheme.Colors.textPrimary)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                    .accessibilityLabel("Story text")
                    .accessibilitySortPriority(2)

                Spacer()  // Push content to the top
            }
            .padding(.horizontal, UITheme.Spacing.lg)
            .padding(.vertical, UITheme.Spacing.xl)  // Add vertical padding
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Page \(page.pageNumber)")
        }
    }
}

#Preview("Various States") {
    VStack {
        PageView(
            page: Page(
                content:
                    "Once upon a time, in a land far, far away, there lived a curious little fox named Finley.",
                pageNumber: 1,
                illustrationStatus: .pending,
                imagePrompt:
                    "A small red fox entering a mystical forest with sunlight filtering through the trees"
            )
        )

        PageView(
            page: Page(
                content: "Finley loved exploring the Whispering Woods behind his cozy den.",
                pageNumber: 2,
                illustrationStatus: .generating,
                imagePrompt: "A small red fox looking at a magical forest"
            )
        )

        PageView(
            regenerateAction: {},
            page: Page(
                content:
                    "One sunny morning, Finley decided to venture deeper into the woods than ever before.",
                pageNumber: 3,
                illustrationStatus: .failed,
                imagePrompt: "A small red fox venturing deeper into a mysterious forest"
            )
        )
    }
}

#Preview("Ready State") {
    PageView(
        page: Page(
            content:
                "Once upon a time, in a land far, far away, there lived a curious little fox named Finley. Finley loved exploring the Whispering Woods behind his cozy den. One sunny morning, Finley decided to venture deeper into the woods than ever before.",
            pageNumber: 1,
            illustrationRelativePath: "Illustrations/sample.png",  // This won't load in preview
            illustrationStatus: .ready,
            imagePrompt:
                "A small red fox entering a mystical forest with sunlight filtering through the trees"
        )
    )
}

#Preview("Dark Mode") {
    PageView(
        page: Page(
            content:
                "Once upon a time, in a land far, far away, there lived a curious little fox named Finley.",
            pageNumber: 1,
            illustrationStatus: .pending,
            imagePrompt:
                "A small red fox entering a mystical forest with sunlight filtering through the trees"
        )
    )
    .preferredColorScheme(.dark)
}
