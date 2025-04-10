import SwiftUI

struct CollectionCardView: View {
    let collection: GrowthCollection
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                // Theme Icon (Placeholder - Needs mapping from theme)
                Image(systemName: "books.vertical.fill") 
                    .foregroundColor(Theme.Colors.primary)
                    .font(.title3)
                
                Text(collection.title)
                    .font(Theme.Typography.headingSmall)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(2)
                
                Spacer()
                
                // Optional: Display badge icon if relevant
                if (collection.associatedBadgeIds?.first) != nil {
                    // TODO: Map badge ID to an actual icon/image
                    Image(systemName: "seal.fill")
                        .foregroundColor(.orange) // Example color
                }
            }
            
            Text(collection.description)
                .font(.body)
                .foregroundColor(Theme.Colors.textSecondary)
                .lineLimit(3)
            
            // Progress Bar
            if collection.progress > 0 {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    ProgressView(value: collection.progress)
                        .tint(Theme.Colors.primary) // Use theme color
                        
                    Text(String(format: "%.0f%% Complete", collection.progress * 100))
                        .font(.caption)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding(.top, Theme.Spacing.xs)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surfacePrimary)
        .cornerRadius(Theme.Layout.cornerRadiusMedium)
        // Add shadow similar to StoryCard if desired
        // .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    // Use the preview example from GrowthCollection
    CollectionCardView(collection: GrowthCollection.previewExample)
        .padding()
} 