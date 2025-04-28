import SwiftUI

/// A premium list item for displaying stories within a collection
struct CollectionStoryListItem: View {
    let story: Story
    let onStoryTapped: (Story) -> Void

    // Animation state
    @State private var isPressed = false

    var body: some View {
        Button {
            // Provide haptic feedback on tap
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

            onStoryTapped(story)
        } label: {
            HStack(spacing: 16) {
                // Story thumbnail with theme color
                thumbnailView

                // Story content
                VStack(alignment: .leading, spacing: 4) {
                    // Title with completion indicator
                    Text(story.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    // Metadata row
                    HStack(spacing: 12) {
                        // Category badge if available
                        if let category = story.categoryName {
                            Text(category)
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.magicalPrimary.opacity(0.1))
                                )
                                .foregroundColor(Color.magicalPrimary)
                        }

                        // Pages count
                        Text("\(story.pages.count) pages")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Completion status
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 1.5)
                        .frame(width: 24, height: 24)

                    if story.isCompleted {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: Color.black.opacity(isPressed ? 0.03 : 0.05),
                        radius: isPressed ? 2 : 4,
                        x: 0,
                        y: isPressed ? 1 : 2
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
        .pressAction {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isPressed = false
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(story.title), \(story.isCompleted ? "Completed" : "Not completed")")
        .accessibilityAddTraits(.isButton)
    }

    // Thumbnail with theme icon
    private var thumbnailView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(
                            colors: [
                                Color.magicalPrimary.opacity(0.7),
                                Color.magicalPrimary.opacity(0.5),
                            ]
                        ),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)

            Image(systemName: story.isCompleted ? "book.closed.fill" : "book.fill")
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
    }
}

#Preview("Story List Items") {
    VStack(spacing: 20) {
        CollectionStoryListItem(
            story: Story.previewStory(title: "Adventure in the Forest"),
            onStoryTapped: { _ in }
        )

        CollectionStoryListItem(
            story: {
                let story = Story.previewStory(title: "The Magic Castle")
                story.isCompleted = true
                return story
            }(),
            onStoryTapped: { _ in }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
