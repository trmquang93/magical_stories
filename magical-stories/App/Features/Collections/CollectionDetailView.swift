import SwiftUI

struct CollectionDetailView: View {
    @EnvironmentObject private var collectionService: CollectionService
    @Bindable var collection: StoryCollection // Use @Bindable for live updates

    init(collection: StoryCollection) {
        self.collection = collection
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(collection.title)
                    .font(.largeTitle)
                    .bold()

                Text(collection.descriptionText)
                    .font(.body)

                HStack {
                    Text("Category: \(collection.category)")
                        .font(.subheadline)
                    Spacer()
                    Text("Age Group: \(collection.ageGroup)")
                        .font(.subheadline)
                }

                ProgressView(value: collection.completionProgress)
                    .padding(.vertical)

                Text("Stories")
                    .font(.title2)
                    .bold()
                    .padding(.top)

                ForEach(collection.stories ?? []) { story in
                    storyRow(story: story)
                }
            }
            .padding()
        }
        .navigationTitle(collection.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Story.self) { story in
            StoryDetailView(story: story)
                .environmentObject(collectionService)
        }
    }

    // Helper function to break down the view complexity
    @ViewBuilder
    private func storyRow(story: Story) -> some View {
        NavigationLink(value: story) {
            HStack {
                Text(story.title)
                    .font(.headline)
                Spacer()
                if story.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .accessibilityLabel("Completed")
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                        .accessibilityLabel("Not completed")
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        CollectionDetailView(
            collection: StoryCollection(
                title: "Preview Collection",
                descriptionText: "This is a detailed preview of a story collection",
                category: "emotionalIntelligence",
                ageGroup: "elementary",
                stories: [],
                createdAt: Date(),
                updatedAt: Date()
            ))
    }
}
