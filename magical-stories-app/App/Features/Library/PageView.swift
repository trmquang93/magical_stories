import SwiftUI

@MainActor
struct PageView: View {
    var regenerateAction: (() -> Void)? = nil  // Optional regenerate callback
    let page: Page
    
    @EnvironmentObject private var simpleIllustrationService: SimpleIllustrationService

    var body: some View {
        // Always use EnhancedPageView as embedded storage is now the only option
        EnhancedPageView(page: page, regenerateAction: regenerateAction)
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
