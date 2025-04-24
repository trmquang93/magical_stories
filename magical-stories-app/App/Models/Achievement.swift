import Foundation

/// Represents a badge or achievement earned by the user.
struct Achievement: Identifiable, Codable, Hashable {
    /// Unique identifier for the achievement (could be a predefined string or UUID).
    /// Using String for potentially predefined achievements (e.g., "completed_first_collection").
    let id: String

    /// The display name of the achievement (e.g., "Friendship Explorer", "Kindness Champion").
    var name: String

    /// A description of what the achievement represents or how it was earned.
    var description: String

    /// The name of the icon representing this achievement (e.g., SF Symbol name).
    var iconName: String

    /// Criteria required to unlock this achievement (could be more complex later).
    /// For now, could just be a descriptive string or linked to a collection ID.
    var unlockCriteriaDescription: String

    /// Timestamp when the achievement was earned by the user.
    var dateEarned: Date?

    /// Initializer
    init(id: String, name: String, description: String, iconName: String, unlockCriteriaDescription: String, dateEarned: Date? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.iconName = iconName
        self.unlockCriteriaDescription = unlockCriteriaDescription
        self.dateEarned = dateEarned
    }
}

// MARK: - Example Usage
extension Achievement {
    static var example: Achievement {
        Achievement(
            id: "completed_friendship_collection",
            name: "Friendship Master",
            description: "Completed the Forest of Friendship collection.",
            iconName: "heart.circle.fill", // Example SF Symbol
            unlockCriteriaDescription: "Finish all stories in 'The Forest of Friendship'"
        )
    }
} 