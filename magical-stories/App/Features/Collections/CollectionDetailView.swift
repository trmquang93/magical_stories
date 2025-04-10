import SwiftUI

struct CollectionDetailView: View {
    let collection: GrowthCollection

    // TODO: Fetch actual Achievement data based on associatedBadgeIds IDs
    // For now, just displaying the IDs

    var body: some View {
        // Fully break up the body for the compiler
        CollectionDetailBodyView(collection: collection)
    }
}

private struct CollectionDetailBodyView: View {
    let collection: GrowthCollection

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                HeaderSection(
                    title: collection.title,
                    description: collection.description,
                    theme: collection.theme,
                    targetAgeGroup: collection.targetAgeGroup
                )
                ProgressSection(progress: Double(collection.progress))
                StoriesSection(stories: collection.stories)
                if let badges = collection.associatedBadgeIds, !badges.isEmpty {
                    BadgesSection(badges: badges)
                }
                Spacer() // Push content to top
            }
            .padding()
        }
        .navigationTitle(collection.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}


// MARK: - Header Section
private struct HeaderSection: View {
    let title: String
    let description: String?
    let theme: String
    let targetAgeGroup: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(Theme.Typography.headingMedium)
                .foregroundColor(Theme.Colors.textPrimary)

            Text(description ?? "")
                .font(.body)
                .foregroundColor(Theme.Colors.textSecondary)

            HStack {
                Label(theme, systemImage: "tag.fill")
                Label(targetAgeGroup, systemImage: "person.fill")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
}

// MARK: - Progress Section
private struct ProgressSection: View {
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            ProgressView(value: progress)
                .tint(Theme.Colors.primary)
            Text(String(format: "%.0f%% Complete", progress * 100))
                .font(Theme.Typography.bodySmall)
                .foregroundColor(Theme.Colors.textSecondary)
        }
    }
}

// MARK: - Stories Section
private struct StoriesSection: View {
    let stories: [Story]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            ForEach(stories) { story in
                NavigationLink(value: story) { // Ensure Story is Hashable
                    StoryRow(story: story)
                }
                .buttonStyle(.plain) // Use plain button style for better appearance
                Divider()
            }
        }
    }
}

// MARK: - Badges Section
private struct BadgesSection: View {
    let badges: [String]

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ForEach(badges, id: \.self) { badgeId in
                VStack {
                    Image(systemName: "seal.fill") // Placeholder icon
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(badgeId.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
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
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle()) // Make the whole HStack tappable
    }
}

#Preview {
    NavigationStack { // Wrap in NavigationStack for title display
        CollectionDetailView(collection: GrowthCollection.previewExample)
            // .environmentObject(StoryService.preview) // Provide StoryService if needed by subviews
    }
} 