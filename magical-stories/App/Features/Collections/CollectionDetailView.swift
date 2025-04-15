import SwiftUI

struct CollectionDetailView: View {
    let collection: StoryCollection
    
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
                
                // Stories list would go here
            }
            .padding()
        }
        .navigationTitle(collection.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CollectionDetailView(collection: StoryCollection(
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
