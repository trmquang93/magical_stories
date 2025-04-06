import SwiftUI

struct PageView: View {
    let page: Page
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                // Display illustration if available
                if let url = page.illustrationURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView() // Placeholder while loading
                                .frame(height: 200) // Consistent height
                                .frame(maxWidth: .infinity)
                                .background(Theme.Colors.surfaceSecondary)
                                .cornerRadius(Theme.Layout.cornerRadiusMedium)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200) // Consistent height
                                .frame(maxWidth: .infinity)
                                .cornerRadius(Theme.Layout.cornerRadiusMedium)
                        case .failure:
                            Image(systemName: "photo.artframe") // Error placeholder
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200) // Consistent height
                                .frame(maxWidth: .infinity)
                                .foregroundColor(Theme.Colors.textSecondary)
                                .background(Theme.Colors.surfaceSecondary)
                                .cornerRadius(Theme.Layout.cornerRadiusMedium)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    // Optional: View to show if illustrationURL is nil
                    Rectangle() // Placeholder if no URL
                        .fill(Theme.Colors.surfaceSecondary)
                        .frame(height: 200) // Consistent height
                        .frame(maxWidth: .infinity)
                        .cornerRadius(Theme.Layout.cornerRadiusMedium)
                        .overlay(
                            Image(systemName: "photo.on.rectangle.angled")
                                .foregroundColor(Theme.Colors.textSecondary)
                                .font(.largeTitle)
                        )
                }

                Text(page.content)
                    .font(Theme.Typography.bodyLarge)
                    .lineSpacing(8) // Consistent line spacing
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Spacer() // Push content to the top
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.xl) // Add vertical padding
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    PageView(
        page: Page(
            content: "Once upon a time, in a land far, far away, there lived a curious little fox named Finley. Finley loved exploring the Whispering Woods behind his cozy den. One sunny morning, Finley decided to venture deeper into the woods than ever before.",
            pageNumber: 1
        )
    )
}
