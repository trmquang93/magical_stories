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
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                // Display illustration if available
                if page.illustrationStatus == .success, let relPath = page.illustrationRelativePath,
                    let url = fullImageURL(for: relPath)
                {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .background(Theme.Colors.surfaceSecondary)
                                .cornerRadius(Theme.Layout.cornerRadiusMedium)
                                .accessibilityLabel("Loading illustration")
                                .accessibilityAddTraits(.updatesFrequently)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .cornerRadius(Theme.Layout.cornerRadiusMedium)
                                .accessibilityLabel(illustrationDescription)
                                .accessibilityAddTraits(.isImage)
                        case .failure:
                            Image("placeholder-illustration")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .cornerRadius(Theme.Layout.cornerRadiusMedium)
                                .overlay(
                                    Text("Failed to load illustration")
                                        .font(Theme.Typography.bodySmall)
                                        .padding(6)
                                        .background(Theme.Colors.surfaceSecondary.opacity(0.8))
                                        .cornerRadius(Theme.Layout.cornerRadiusSmall)
                                        .padding(8),
                                    alignment: .bottom
                                )
                                .accessibilityLabel("Failed to load illustration")
                                .accessibilityAddTraits(.isImage)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else if page.illustrationStatus == .failed {
                    VStack {
                        Image("placeholder-illustration")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(Theme.Layout.cornerRadiusMedium)
                            .overlay(
                                Text("Illustration failed")
                                    .font(Theme.Typography.bodySmall)
                                    .padding(6)
                                    .background(Theme.Colors.surfaceSecondary.opacity(0.8))
                                    .cornerRadius(Theme.Layout.cornerRadiusSmall)
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
                    Image("placeholder-illustration")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(Theme.Layout.cornerRadiusMedium)
                        .accessibilityLabel("Illustration placeholder")
                        .accessibilityAddTraits(.isImage)
                }
                Text(page.content)
                    .font(Theme.Typography.bodyLarge)
                    .lineSpacing(8)  // Consistent line spacing
                    .foregroundColor(Theme.Colors.textPrimary)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                    .accessibilityLabel("Story text")
                    .accessibilitySortPriority(2)

                Spacer()  // Push content to the top
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.xl)  // Add vertical padding
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
