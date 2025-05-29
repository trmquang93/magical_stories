import Foundation

/// Visual context shared across all stories in a collection for consistency
public struct CollectionVisualContext: Codable, Equatable {
    public let collectionId: UUID
    public let collectionTheme: String
    public let sharedCharacters: [String]
    public let unifiedArtStyle: String
    public let developmentalFocus: String
    public let ageGroup: String
    public let requiresCharacterConsistency: Bool
    public let allowsStyleVariation: Bool
    public let sharedProps: [String]
    
    public init(
        collectionId: UUID,
        collectionTheme: String,
        sharedCharacters: [String],
        unifiedArtStyle: String,
        developmentalFocus: String,
        ageGroup: String,
        requiresCharacterConsistency: Bool = true,
        allowsStyleVariation: Bool = false,
        sharedProps: [String] = []
    ) {
        self.collectionId = collectionId
        self.collectionTheme = collectionTheme
        self.sharedCharacters = sharedCharacters
        self.unifiedArtStyle = unifiedArtStyle
        self.developmentalFocus = developmentalFocus
        self.ageGroup = ageGroup
        self.requiresCharacterConsistency = requiresCharacterConsistency
        self.allowsStyleVariation = allowsStyleVariation
        self.sharedProps = sharedProps
    }
}