import SwiftUI

struct CollectionDetailView: View {
    let collection: GrowthCollection
    
    // TODO: Fetch actual Achievement data based on associatedBadges IDs
    // For now, just displaying the IDs
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                // Header Section
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(collection.title)
                        .font(Theme.Typography.headingMedium)
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text(collection.description ?? "")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    HStack {
                        Label(collection.theme, systemImage: "tag.fill")
                        Label(collection.targetAgeGroup, systemImage: "person.fill")
                    }
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.textTertiary)
                }
                
                // Progress Section
                Section(header: Text("Progress").font(Theme.Typography.label)) {
                    ProgressView(value: collection.progress)
                        .tint(Theme.Colors.primary)
                    Text(String(format: "%.0f%% Complete", collection.progress * 100))
                        .font(Theme.Typography.bodySmall)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                
                // Stories Section
                Section(header: Text("Stories").font(Theme.Typography.label)) {
                    // Use a VStack instead of List to avoid nested scrolling issues
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        ForEach(collection.stories) { story in
                            NavigationLink(value: story) { // Ensure Story is Hashable
                                StoryRow(story: story)
                            }
                            .buttonStyle(.plain) // Use plain button style for better appearance
                            Divider()
                        }
                    }
                }
                
                // Badges Section (Placeholder)
                if let badges = collection.associatedBadges, !badges.isEmpty {
                    Section(header: Text("Badges").font(Theme.Typography.label)) {
                        // TODO: Implement Badge Display View
                        HStack(spacing: Theme.Spacing.md) {
                            ForEach(badges, id: \.self) { badgeId in
                                VStack {
                                    Image(systemName: "seal.fill") // Placeholder icon
                                        .font(.largeTitle)
                                        .foregroundColor(.orange)
                                    Text(badgeId.replacingOccurred(of: "_", with: " ").capitalized)
                                        .font(Theme.Typography.caption)
                                }
                            }
                        }
                        .padding(.vertical, Theme.Spacing.sm)
                    }
                }
                
                Spacer() // Push content to top
            }
            .padding()
        }
        .navigationTitle(collection.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Simple row view for displaying a story in the list
struct StoryRow: View {
    let story: Story
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(story.title)
                    .font(Theme.Typography.bodyLarge)
                    .foregroundColor(Theme.Colors.textPrimary)
                Text("Theme: \(story.parameters.theme)")
                    .font(Theme.Typography.bodySmall)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(Theme.Colors.textTertiary)
        }
        .contentShape(Rectangle()) // Make the whole HStack tappable
    }
}

#Preview {
    NavigationStack { // Wrap in NavigationStack for title display
        CollectionDetailView(collection: GrowthCollection.previewExample)
            .environmentObject(StoryService.preview) // Provide StoryService if needed by subviews
    }
} 