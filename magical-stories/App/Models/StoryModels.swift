import Foundation
import SwiftData
import magical_stories

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
struct Page: Identifiable, Hashable, Codable {
    let id: UUID
    let content: String
    let pageNumber: Int
    var illustrationRelativePath: String?  // Relative path to saved image
    var illustrationStatus: IllustrationStatus = IllustrationStatus.pending  // Status of illustration generation
    var imagePrompt: String?   // Stores the prompt used for generation

    init(id: UUID = UUID(), content: String, pageNumber: Int, illustrationRelativePath: String? = nil, illustrationStatus: IllustrationStatus = IllustrationStatus.pending, imagePrompt: String? = nil) {
        self.id = id
        self.content = content
        self.pageNumber = pageNumber
        self.illustrationRelativePath = illustrationRelativePath
        self.illustrationStatus = illustrationStatus
        self.imagePrompt = imagePrompt
    }
}

/// Represents a generated story.
struct Story: Identifiable, Hashable, Codable { // Conform to Codable for potential saving
    /// Unique identifier for the story.
    var id: UUID = UUID()

    /// The title of the generated story.
    var title: String

    /// The full content/text of the generated story.
    /// The individual pages of the story.
    var pages: [Page]

    /// The parameters used to generate this story.
    var parameters: StoryParameters

    /// The date and time when the story was generated or saved.
    var timestamp: Date = Date()

    /// Optional: Identifier of the Growth Collection this story belongs to.
    var collectionId: UUID? = nil

    /// Initializer for creating a new Story instance.
    init(
        id: UUID = UUID(),
        title: String,
        pages: [Page],
        parameters: StoryParameters,
        timestamp: Date = Date(),
        collectionId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.pages = pages
        self.parameters = parameters
        self.timestamp = timestamp
        self.collectionId = collectionId
    }

    /// Compatibility initializer to handle calls expecting content, illustrationURL, and imagePrompt directly.
    /// Note: This initializer is primarily for older usage patterns and might not set collectionId.
    init(id: UUID = UUID(), title: String, content: String, parameters: StoryParameters, timestamp: Date = Date(), illustrationURL: URL? = nil, imagePrompt: String? = nil, collectionId: UUID? = nil) {
        self.id = id
        self.title = title
        // Create a single page from the provided content and illustration details
        let singlePage = Page(content: content, pageNumber: 1, illustrationRelativePath: illustrationURL?.path, illustrationStatus: IllustrationStatus.pending, imagePrompt: imagePrompt)
        self.pages = [singlePage]
        self.parameters = parameters
        self.timestamp = timestamp
        self.collectionId = collectionId // Added collectionId
    }

    /// Hashable conformance (based on id)
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Story, rhs: Story) -> Bool {
        lhs.id == rhs.id
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

// MARK: - Preview Helpers

extension Story {
    static func previewStory(title: String = "The Magical Forest Adventure") -> Story {
        let params = StoryParameters(
            childName: "Alex",
            childAge: 5,
            theme: "Friendship",
            favoriteCharacter: "Brave Bear"
        )
        return Story(
            title: title,
            pages: [
                Page(content: "Once upon a time, Alex and Brave Bear went into the forest.", pageNumber: 1, imagePrompt: "A child and a bear entering a forest"),
                Page(content: "They met a lost squirrel and helped it find its way home.", pageNumber: 2, imagePrompt: "Bear and child helping a squirrel"),
                Page(content: "They learned that helping friends is important. The end.", pageNumber: 3, imagePrompt: "Bear, child, and squirrel waving goodbye")
            ],
            parameters: params
        )
    }
    
    static var preview: Story { previewStory() }
}