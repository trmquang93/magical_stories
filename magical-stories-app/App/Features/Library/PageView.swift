import SwiftUI

struct PageView: View {
    var regenerateAction: (() -> Void)? = nil  // Optional regenerate callback

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
    let page: Page

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
                // Display illustration if available
                if page.illustrationStatus == .success, let relPath = page.illustrationRelativePath,
                    let url = fullImageURL(for: relPath)
                {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity) // Full width
                                .aspectRatio(16/9, contentMode: .fit) // Maintain aspect ratio while loading
                                .background(UITheme.Colors.surfaceSecondary)
                                .accessibilityLabel("Loading illustration")
                                .accessibilityAddTraits(.updatesFrequently)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit() // Maintain aspect ratio, fit within width
                                .containerRelativeFrame(.horizontal) // Occupy full container width
                                .accessibilityLabel(illustrationDescription)
                                .accessibilityAddTraits(.isImage)
                        case .failure:
                            Image("placeholder-illustration") // Placeholder on load failure
                                .resizable()
                                .scaledToFit()
                                .containerRelativeFrame(.horizontal)
                                .overlay(
                                    Text("Failed to load illustration")
                                        .font(UITheme.Typography.bodySmall)
                                        .padding(6)
                                        .background(UITheme.Colors.surfaceSecondary.opacity(0.8))
                                        .cornerRadius(UITheme.Layout.cornerRadiusSmall)
                                        .padding(8),
                                    alignment: .bottom
                                )
                                .accessibilityLabel("Failed to load illustration")
                                .accessibilityAddTraits(.isImage)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity) // Ensure AsyncImage container takes full width
                } else if page.illustrationStatus == .failed {
                    VStack {
                        Image("placeholder-illustration") // Placeholder on generation failure
                            .resizable()
                            .scaledToFit()
                            .containerRelativeFrame(.horizontal)
                            .overlay(
                                Text("Illustration failed")
                                    .font(UITheme.Typography.bodySmall)
                                    .padding(6)
                                    .background(UITheme.Colors.surfaceSecondary.opacity(0.8))
                                    .cornerRadius(UITheme.Layout.cornerRadiusSmall)
                                    .padding(8),
                                alignment: .bottom
                            )
                            .accessibilityLabel("Failed illustration placeholder")
                            .accessibilityAddTraits(.isImage)

                        Button("Regenerate Illustration") {
                            regenerateAction?()
                        }
                        .padding(.top, 8)
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel("Regenerate illustration button")
                    }
                } else {
                    // Placeholder if no illustration path exists or status is not success/failed
                    Image("placeholder-illustration")
                        .resizable()
                        .scaledToFit()
                        .containerRelativeFrame(.horizontal)
                        .accessibilityLabel("Illustration placeholder")
                        .accessibilityAddTraits(.isImage)
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

#Preview {
    PageView(
        page: Page(
            content:
                "Once upon a time, in a land far, far away, there lived a curious little fox named Finley. Finley loved exploring the Whispering Woods behind his cozy den. One sunny morning, Finley decided to venture deeper into the woods than ever before.",
            pageNumber: 1,
            imagePrompt:
                "A small red fox entering a mystical forest with sunlight filtering through the trees"
        )
    )
}
