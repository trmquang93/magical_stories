/// CollectionCardView displays summary information for a StoryCollection, including title, description, category, age group, and progress.
import SwiftUI

struct CollectionCardView: View {
    let collection: StoryCollection
    
    // Placeholder image - in a real implementation, this would be loaded from the collection's actual thumbnail
    private let defaultImageName = "collection-placeholder"
    
    private var storyCountText: String {
        let count = collection.stories?.count ?? 0
        return "\(count) \(count == 1 ? "story" : "stories")"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image at the top
            Group {
                // In a real implementation, this would load from the collection's thumbnail
                // For now, use a placeholder image or system image
                Image(systemName: "book.pages")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 96) // 24px in Tailwind = 96pt in iOS
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.bottom, 12)
            
            // Title
            Text(collection.title)
                .font(.headline)
                .foregroundStyle(Color.primary)
                .accessibilityAddTraits(.isHeader)
            
            // Story count
            Text(storyCountText)
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
                .padding(.top, 4)
            
            // Progress indicator (shown conditionally)
            if collection.stories?.isEmpty == false {
                ProgressView(value: collection.completionProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                    .padding(.top, 8)
                    .accessibilityLabel("Progress: \(Int(collection.completionProgress * 100)) percent")
            }
            
            // Completed badge (shown conditionally)
            if collection.completionProgress >= 1.0 {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("Completed")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
                .padding(.top, 8)
                .accessibilityLabel("Collection completed")
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(UIColor.separator), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .frame(minWidth: 200)
        .accessibilityIdentifier("CollectionCardView-\(collection.id)")
    }
}

#Preview("Light Mode", traits: .sizeThatFitsLayout) {
    VStack {
        CollectionCardView(collection: StoryCollection(
            title: "Forest Friends",
            descriptionText: "Stories about friendship and nature",
            category: "emotionalIntelligence",
            ageGroup: "elementary",
            stories: Array(repeating: Story.previewStory(), count: 8),
            createdAt: Date(),
            updatedAt: Date()
        ))
        .frame(width: 250)
        
        CollectionCardView(collection: {
            let collection = StoryCollection(
                title: "Problem Solving",
                descriptionText: "Learn to solve problems through stories",
                category: "problemSolving",
                ageGroup: "elementary",
                stories: Array(repeating: Story.previewStory(), count: 3),
                createdAt: Date(),
                updatedAt: Date()
            )
            collection.completionProgress = 1.0
            return collection
        }())
        .frame(width: 250)
    }
    .padding()
    .preferredColorScheme(.light)
}
    
#Preview("Dark Mode", traits: .sizeThatFitsLayout) {
    VStack {
        CollectionCardView(collection: StoryCollection(
            title: "Forest Friends",
            descriptionText: "Stories about friendship and nature",
            category: "emotionalIntelligence",
            ageGroup: "elementary",
            stories: Array(repeating: Story.previewStory(), count: 8),
            createdAt: Date(),
            updatedAt: Date()
        ))
        .frame(width: 250)
        
        CollectionCardView(collection: {
            let collection = StoryCollection(
                title: "Problem Solving",
                descriptionText: "Learn to solve problems through stories",
                category: "problemSolving",
                ageGroup: "elementary",
                stories: Array(repeating: Story.previewStory(), count: 3),
                createdAt: Date(),
                updatedAt: Date()
            )
            collection.completionProgress = 1.0
            return collection
        }())
        .frame(width: 250)
    }
    .padding()
    .preferredColorScheme(.dark)
}
