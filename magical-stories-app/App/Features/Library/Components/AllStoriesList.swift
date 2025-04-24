import SwiftUI

struct AllStoriesList: View {
    var stories: [Story]
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(stories) { story in
                    NavigationLink(value: story) {
                        EnhancedStoryCard(story: story)
                            .accessibilityIdentifier("AllStoriesView_StoryCard_\(story.id)")
                    }
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .accessibilityIdentifier("AllStoriesView_StoriesList")
    }
}
