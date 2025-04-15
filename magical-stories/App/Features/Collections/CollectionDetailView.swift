import SwiftUI

struct CollectionDetailView: View {
    @EnvironmentObject private var collectionService: CollectionService
    @State private var collection: StoryCollection

    init(collection: StoryCollection) {
        _collection = State(initialValue: collection)
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
                    HStack {
                        NavigationLink(value: story) {
                            Text(story.title)
                                .font(.headline)
                        }
                        Spacer()
                        Button(action: {
                            toggleStoryCompletion(story)
                        }) {
                            Image(
                                systemName: story.isCompleted ? "checkmark.circle.fill" : "circle"
                            )
                            .foregroundColor(story.isCompleted ? .green : .gray)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding()
        }
        .navigationTitle(collection.title)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: collection) { newValue in
            // Handle collection changes if needed
        }
    }

    private func toggleStoryCompletion(_ story: Story) {
        // Toggle completion state
        story.isCompleted.toggle()

        // Update collection progress based on stories completed
        let stories = collection.stories ?? []
        let completedCount = stories.filter { $0.isCompleted }.count
        let progress = Double(completedCount) / Double(stories.count)

        // Update collection progress in service
        do {
            try collectionService.updateCollectionProgress(
                id: collection.id, progress: Float(progress))
            // Update local state to reflect changes
            collection.completionProgress = progress
        } catch {
            print("Failed to update collection progress: \(error)")
        }
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
