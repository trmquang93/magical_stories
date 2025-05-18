import Foundation

/// Represents the types of illustration tasks that can be processed
enum IllustrationTaskType: String, Codable, Equatable {
    case globalReference  // Global reference image containing all key characters and elements
    case pageIllustration  // Regular page-specific illustration
    
    /// Default implementation of Equatable
    static func == (lhs: IllustrationTaskType, rhs: IllustrationTaskType) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}