import Foundation

// Represents a structured collection of stories, often focused on a specific theme or skill.
struct GrowthCollection: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var description: String?
    var theme: String // e.g., "Bravery", "Sharing", "Problem Solving"
    var targetAgeGroup: String // e.g., "3-5", "6-8"
    var stories: [Story] // Array of generated Story objects
    var progress: Float // 0.0 to 1.0
    var associatedBadges: [String]? // IDs of badges related to this collection
    var timestamp: Date = Date() // Added timestamp

    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Implement Equatable based on ID for Hashable conformance
    static func == (lhs: GrowthCollection, rhs: GrowthCollection) -> Bool {
        lhs.id == rhs.id
    }
    
    // Example for previews
    static var previewExample: GrowthCollection {
        GrowthCollection(
            id: UUID(),
            title: "The Little Explorer's Guide to Courage",
            description: "A collection of stories helping young adventurers find their inner bravery.",
            theme: "Courage",
            targetAgeGroup: "4-6",
            stories: [
                Story.previewStory(title: "Finley Fox Faces the Dark"),
                Story.previewStory(title: "Lily Lamb Tries Something New"),
                Story.previewStory(title: "Sammy Squirrel Climbs High")
            ],
            progress: 0.66,
            associatedBadges: ["courage_badge_1", "explorer_badge"]
        )
    }
} 