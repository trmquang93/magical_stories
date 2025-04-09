import Foundation
import SwiftData

/// Represents the user's profile, including preferences and usage statistics.
/// Assumed to be a single instance for the application.
@Model
final class UserProfile {
    // --- Fields from Schema Document ---
    @Attribute(.unique) var id: UUID // Make ID unique to enforce singleton nature
    var createdAt: Date

    // Child Information
    var childName: String
    var dateOfBirth: Date
    var interests: [String]

    // Preferences
    var preferredThemes: [String]
    var favoriteCharacters: [String]

    // Settings (Consider moving to AppSettingsModel if purely device settings)
    var useTextToSpeech: Bool
    var preferredVoiceIdentifier: String?
    var darkModePreferenceRaw: String // Store raw value for enum

    // Statistics (General Reading)
    var totalStoriesRead: Int
    var totalReadingTime: TimeInterval // Store as Double
    var lastReadDate: Date?

    // Relationships (Achievements might be better linked elsewhere if not user-specific)
    // @Relationship(deleteRule: .cascade)
    // var achievements: [Achievement] // Commented out as per schema, but consider if needed

    // --- Fields for Usage Analytics (Phase 3 Migration) ---
    var storyGenerationCount: Int
    var lastGenerationDate: Date?
    var lastGeneratedStoryId: UUID? // Store UUID directly

    // --- Computed Properties ---
    var darkModePreference: DarkModePreference {
        get { DarkModePreference(rawValue: darkModePreferenceRaw) ?? .system }
        set { darkModePreferenceRaw = newValue.rawValue }
    }

    // --- Initializer ---
    // Provide a default initializer or one based on essential info
    init(
        id: UUID = UUID(), // Default ID
        childName: String = "Adventurer", // Default name
        dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -5, to: Date()) ?? Date() // Default DOB (e.g., 5 years ago)
    ) {
        self.id = id
        self.childName = childName
        self.dateOfBirth = dateOfBirth
        self.createdAt = Date()
        self.interests = []
        self.preferredThemes = []
        self.favoriteCharacters = []
        self.useTextToSpeech = true
        self.darkModePreferenceRaw = DarkModePreference.system.rawValue
        self.totalStoriesRead = 0
        self.totalReadingTime = 0.0
        // self.achievements = [] // If relationship is active

        // Initialize new analytics fields
        self.storyGenerationCount = 0
        self.lastGenerationDate = nil
        self.lastGeneratedStoryId = nil
    }

    // Convenience initializer for migration
    convenience init(
        migratingFromUserDefaults defaults: UserDefaults,
        id: UUID = UUID(),
        childName: String = "Adventurer",
        dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -5, to: Date()) ?? Date()
    ) {
        self.init(id: id, childName: childName, dateOfBirth: dateOfBirth) // Call designated initializer

        // Populate analytics from UserDefaults
        self.storyGenerationCount = defaults.integer(forKey: UserDefaultsKeys.storyGenerationCount)
        self.lastGenerationDate = defaults.object(forKey: UserDefaultsKeys.lastGenerationDate) as? Date
        if let uuidString = defaults.string(forKey: UserDefaultsKeys.lastGeneratedStoryId) {
            self.lastGeneratedStoryId = UUID(uuidString: uuidString)
        } else {
            self.lastGeneratedStoryId = nil
        }
    }
}

// MARK: - Supporting Enums (Copied from Schema for completeness)

enum DarkModePreference: String, Codable, CaseIterable {
    case light
    case dark
    case system
}

// MARK: - UserDefaults Keys (Internal)
// Keep these keys consistent with the ones being removed from PersistenceService
private enum UserDefaultsKeys {
    static let lastGeneratedStoryId = "lastGeneratedStoryId"
    static let storyGenerationCount = "storyGenerationCount"
    static let lastGenerationDate = "lastGenerationDate"
    static let usageAnalyticsMigrated = "usageAnalyticsMigratedToSwiftData" // New migration flag
}