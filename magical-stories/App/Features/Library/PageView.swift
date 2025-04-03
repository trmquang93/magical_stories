import SwiftUI

struct PageView: View {
    let page: Page
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                // Placeholder for potential illustration (Phase 2)
                // For now, just the text content
                
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
