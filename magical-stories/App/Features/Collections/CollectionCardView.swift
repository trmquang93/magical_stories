import SwiftUI

struct CollectionCardView: View {
    let collection: StoryCollection
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(collection.title)
                .font(.headline)
            Text(collection.descriptionText)
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack {
                Text(collection.category)
                    .font(.caption)
                Spacer()
                Text(collection.ageGroup)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
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
