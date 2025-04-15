import Foundation

/// Represents developmental categories for Growth Collections.
enum GrowthCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case emotionalIntelligence = "Emotional Intelligence"
    case cognitiveDevelopment = "Cognitive Development"
    case socialSkills = "Social Skills"
    case creativityImagination = "Creativity & Imagination"
    case problemSolving = "Problem Solving"
    case resilienceGrit = "Resilience & Grit"
    case kindnessEmpathy = "Kindness & Empathy"

    var id: String { self.rawValue }

    // Add other potential properties or methods if required by tests later
}