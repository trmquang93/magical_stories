import Foundation

/// Represents the visual planning structure for a complete story
public struct StoryStructure: Codable, Equatable {
    public let pages: [PageVisualPlan]
    
    public init(pages: [PageVisualPlan]) {
        self.pages = pages
    }
}

/// Visual planning information for a single story page
public struct PageVisualPlan: Codable, Equatable {
    public let pageNumber: Int
    public let characters: [String]
    public let settings: [String]
    public let props: [String]
    public let visualFocus: String
    public let emotionalTone: String
    
    public init(
        pageNumber: Int,
        characters: [String],
        settings: [String],
        props: [String],
        visualFocus: String,
        emotionalTone: String
    ) {
        self.pageNumber = pageNumber
        self.characters = characters
        self.settings = settings
        self.props = props
        self.visualFocus = visualFocus
        self.emotionalTone = emotionalTone
    }
}