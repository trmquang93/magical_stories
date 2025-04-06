import Foundation

/// Represents the input parameters provided by the user to generate a story.
struct StoryParameters: Codable, Hashable { // Conform to Codable/Hashable for potential saving/diffing
    /// The name of the child the story is for.
    var childName: String

    /// The age of the child. Kept as Int for MVP simplicity.
    /// Consider Enum for specific age ranges post-MVP (e.g., based on Growth-Path-Stories.md).
    var childAge: Int

    /// The desired theme or moral for the story.
    var theme: String

    /// The favorite character or animal to feature in the story.
    var favoriteCharacter: String
}

/// Represents a generated story.
struct Story: Identifiable, Hashable, Codable { // Conform to Codable for potential saving
    /// Unique identifier for the story.
    let id: UUID

    /// The title of the generated story.
    var title: String

    /// The full content/text of the generated story.
    var content: String

    /// The parameters used to generate this story.
    var parameters: StoryParameters

    /// The date and time when the story was generated or saved.
    var timestamp: Date

    /// Initializer for creating a new Story instance.
    init(id: UUID = UUID(), title: String, content: String, parameters: StoryParameters, timestamp: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.parameters = parameters
        self.timestamp = timestamp
    }
}

/// Represents user-specific settings for the application.
struct UserSettings: Codable { // Conform to Codable for saving
    /// Preference for enabling or disabling Text-to-Speech functionality.
    var isTextToSpeechEnabled: Bool = false // Default value
}

/// Represents errors that can occur during story generation or handling.
enum StoryError: Error, LocalizedError {
    case generationFailed
    case invalidParameters
    case persistenceFailed // Although persistence isn't implemented yet, keep the error case as defined.

    var errorDescription: String? {
        switch self {
        case .generationFailed:
            return NSLocalizedString("Failed to generate the story. Please try again.", comment: "Story Generation Error")
        case .invalidParameters:
            return NSLocalizedString("The provided parameters were invalid.", comment: "Invalid Story Parameters Error")
        case .persistenceFailed:
            return NSLocalizedString("Failed to save or load the story.", comment: "Story Persistence Error")
        }
    }
}