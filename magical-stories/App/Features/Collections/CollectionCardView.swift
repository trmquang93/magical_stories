/// CollectionCardView displays summary information for a StoryCollection, including title, description, category, age group, and progress.
import SwiftUI

struct CollectionCardView: View {
    let collection: StoryCollection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(collection.title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Text(collection.descriptionText)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .accessibilityLabel("Description: \(collection.descriptionText)")
            HStack {
                Text(collection.category)
                    .font(.caption)
                Spacer()
                Text(collection.ageGroup)
                    .font(.caption)
            }
            ProgressView(value: collection.completionProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                .padding(.vertical, 4)
                .accessibilityLabel("Progress: \(Int(collection.completionProgress * 100)) percent")
            
            if collection.completionProgress >= 1.0 {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
                .padding(.top, 4)
                .accessibilityLabel("Collection completed")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    CollectionCardView(collection: StoryCollection(
        title: "Preview Collection",
        descriptionText: "This is a preview collection",
        category: "emotionalIntelligence",
        ageGroup: "elementary",
        stories: [],
        createdAt: Date(),
        updatedAt: Date()
    ))
    .padding()
}
