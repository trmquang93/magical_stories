import Foundation

/// Represents a themed collection of stories focused on a specific developmental goal.
struct GrowthCollection: Identifiable, Codable {
    /// Unique identifier for the collection.
    let id: UUID

    /// The title of the collection (e.g., "Learning Kindness", "Building Confidence").
    var title: String

    /// A brief description of the collection's purpose or theme.
    var description: String

    /// The main theme or developmental focus (e.g., "Emotional Intelligence", "Social Skills").
    var theme: String

    /// The intended target age group for this collection (e.g., "3-5", "6-8").
    var targetAgeGroup: String // Consider using an Enum later if predefined groups exist

    /// The stories included in this collection.
    var stories: [Story] // Assumes Story is Codable

    /// User's progress through the collection (e.g., 0.0 to 1.0).
    var progress: Float = 0.0

    /// Identifiers of badges or achievements associated with completing this collection.
    var associatedBadgeIds: [String]? // Using String IDs for simplicity, could be UUIDs

    // Add other relevant properties as needed, e.g., cover image URL/path

    /// Default initializer.
    init(id: UUID = UUID(), title: String, description: String, theme: String, targetAgeGroup: String, stories: [Story], progress: Float = 0.0, associatedBadgeIds: [String]? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.theme = theme
        self.targetAgeGroup = targetAgeGroup
        self.stories = stories
        self.progress = progress
        self.associatedBadgeIds = associatedBadgeIds
    }
}

// MARK: - Example Usage (for previews or testing)
extension GrowthCollection {
    static var example: GrowthCollection {
        GrowthCollection(
            title: "The Forest of Friendship",
            description: "Learn about making friends and being kind.",
            theme: "Social Skills",
            targetAgeGroup: "4-6",
            stories: [Story.example, Story.example] // Using example stories
        )
    }
} 