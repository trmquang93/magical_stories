import Foundation

/// Represents age groups for targeting content.
enum AgeGroup: String, CaseIterable, Codable, Identifiable, Sendable {
    case preschool = "3-5 years"  // Preschoolers
    case earlyReader = "6-8 years"  // Early Readers
    case middleGrade = "9-12 years"  // Middle Grade

    var id: String { self.rawValue }

    // Add other potential properties or methods if required by tests later
}
