import Foundation

 // Represents a structured collection of stories, often focused on a specific theme or skill.

/// Represents the AI's response for generating a collection and its stories.
public struct CollectionGenerationResponse: Codable, Sendable {
    public struct StoryOutline: Codable, Sendable {
        public let context: String
        public init(context: String) {
            self.context = context
        }
    }
    public let title: String
    public let description: String
    public let achievementIds: [String]?
    public let storyOutlines: [StoryOutline]
    public init(
        title: String,
        description: String,
        achievementIds: [String]? = nil,
        storyOutlines: [StoryOutline]
    ) {
        self.title = title
        self.description = description
        self.achievementIds = achievementIds
        self.storyOutlines = storyOutlines
    }
}