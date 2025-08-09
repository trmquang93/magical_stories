import Foundation

/// Represents the input parameters provided by the user to generate a Growth Collection.
struct CollectionParameters: Codable, Hashable {
    /// The target age group for the collection (e.g., "3-5", "6-8").
    /// Consider using an Enum if predefined, fixed groups are desired.
    var childAgeGroup: String

    /// The primary developmental area the collection should focus on (e.g., "Emotional Intelligence", "Problem Solving").
    var developmentalFocus: String

    /// Specific interests of the child to incorporate into the stories (e.g., "Dinosaurs", "Space Exploration", "Fairy Tales").
    /// Could be a comma-separated string or an array of strings.
    var interests: String  // Or [String]?

    /// Optional: Child's name to personalize stories within the collection.
    var childName: String?

    /// Optional: Specific characters to include.
    var characters: [String]?

    /// Optional: Language code for stories in this collection (e.g., "en", "fr", "es").
    var languageCode: String?

    /// Initializer
    init(
        childAgeGroup: String, developmentalFocus: String, interests: String,
        childName: String? = nil, characters: [String]? = nil, languageCode: String? = nil
    ) {
        self.childAgeGroup = childAgeGroup
        self.developmentalFocus = developmentalFocus
        self.interests = interests
        self.childName = childName
        self.characters = characters
        self.languageCode = languageCode
    }
}

// MARK: - Example Usage
extension CollectionParameters {
    static var example: CollectionParameters {
        CollectionParameters(
            childAgeGroup: "4-6",
            developmentalFocus: "Sharing and Cooperation",
            interests: "Animals, Playground",
            languageCode: "en"
        )
    }
}
