# SwiftData Schema Documentation

## 1. Overview
This document outlines the data model schema for the Magical Stories app using SwiftData, designed to store user profiles, stories, pages, collections, and achievements.

## 2. Core Models

### 2.1. Story Model
Represents a single generated story, composed of multiple pages.

```swift
import SwiftData
import Foundation

@Model
final class Story {
    // Core Properties
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var lastReadAt: Date?

    // Story Parameters (at time of generation)
    var childName: String?
    var ageGroup: AgeGroup // Enum
    var theme: String
    var mainCharacter: String
    // var isGrowthPathStory: Bool // Consider if needed, or managed by Collection relationship

    // Content (Pages)
    // Cascade delete: If a Story is deleted, its associated Pages are also deleted.
    @Relationship(deleteRule: .cascade, inverse: \Page.story)
    var pages: [Page]? = [] // Ordered list of pages

    // Optional Properties
    var readCount: Int
    var isFavorite: Bool
    var notes: String?

    // Relationships
    // An Achievement might be linked to a specific Story
    @Relationship(deleteRule: .nullify) // If Story deleted, link in Achievement becomes nil
    var achievements: [Achievement]? = []

    // A Story can belong to multiple Collections
    var collections: [StoryCollection]? = [] // Many-to-Many handled by SwiftData

    init(
        id: UUID = UUID(),
        title: String,
        childName: String? = nil,
        ageGroup: AgeGroup,
        theme: String,
        mainCharacter: String,
        // isGrowthPathStory: Bool = false,
        createdAt: Date = Date(),
        pages: [Page] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.childName = childName
        self.ageGroup = ageGroup
        self.theme = theme
        self.mainCharacter = mainCharacter
        // self.isGrowthPathStory = isGrowthPathStory
        self.pages = pages
        self.readCount = 0
        self.isFavorite = false
    }

    // Convenience for sorted pages
    var sortedPages: [Page] {
        (pages ?? []).sorted { $0.pageNumber < $1.pageNumber }
    }
}
```

### 2.2. Page Model
Represents a single page within a Story, containing text and illustration details.

```swift
import SwiftData
import Foundation

@Model
final class Page {
    @Attribute(.unique) var id: UUID
    var pageNumber: Int       // Order within the story
    var text: String          // Text content of the page
    var illustrationRelativePath: String? // Path relative to app support/documents dir
    var illustrationStatus: IllustrationStatus // Enum: notStarted, generating, generated, failed

    // Relationship back to the owning Story
    var story: Story?

    init(
        id: UUID = UUID(),
        pageNumber: Int,
        text: String,
        illustrationRelativePath: String? = nil,
        illustrationStatus: IllustrationStatus = .notStarted,
        story: Story? = nil
    ) {
        self.id = id
        self.pageNumber = pageNumber
        self.text = text
        self.illustrationRelativePath = illustrationRelativePath
        self.illustrationStatus = illustrationStatus
        self.story = story
    }
}
```

### 2.3. StoryCollection Model
Represents a collection of stories, potentially themed (e.g., Growth Collections).

```swift
import SwiftData
import Foundation

@Model
final class StoryCollection {
    // Core Properties
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var descriptionText: String? // Renamed from 'description' to avoid conflict

    // Growth Path Properties (Optional)
    var growthCategory: GrowthCategory? // Enum
    var targetAgeGroup: AgeGroup?       // Enum
    var completionProgress: Double      // Calculated or stored progress (0.0 to 1.0)

    // Relationships
    // A collection can contain multiple stories. If a story is deleted,
    // it's removed from the collection, but the collection remains.
    @Relationship(deleteRule: .nullify)
    var stories: [Story]? = []

    init(
        id: UUID = UUID(),
        name: String,
        descriptionText: String? = nil,
        growthCategory: GrowthCategory? = nil,
        targetAgeGroup: AgeGroup? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.descriptionText = descriptionText
        self.growthCategory = growthCategory
        self.targetAgeGroup = targetAgeGroup
        self.createdAt = createdAt
        self.completionProgress = 0.0
        self.stories = []
    }
}

**Deletion:**
Deleting a collection from the Collections tab (via swipe-to-delete in CollectionsListView) will remove the collection and, due to the cascade delete rule, all associated stories. This ensures data integrity and a clean user experience.

See: `CollectionsListView.swift` and `documents/ui/design-system.md` for UI details.
```

### 2.4. Achievement Model
Represents an achievement earned by the user.

```swift
import SwiftData
import Foundation

@Model
final class Achievement {
    // Core Properties
    @Attribute(.unique) var id: UUID
    var name: String
    var descriptionText: String // Renamed from 'description'
    var earnedAt: Date
    var type: AchievementType // Enum

    // Optional Properties
    var iconName: String? // SF Symbol name or asset name
    var progress: Double? // For multi-step achievements

    // Relationships (Optional: Link achievement to a specific story or profile)
    // If the story is deleted, the achievement link becomes nil, but achievement persists.
    var story: Story?

    // Link to UserProfile if achievements are per-profile
    // var userProfile: UserProfile?

    init(
        id: UUID = UUID(),
        name: String,
        descriptionText: String,
        type: AchievementType,
        earnedAt: Date = Date(),
        iconName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.descriptionText = descriptionText
        self.type = type
        self.earnedAt = earnedAt
        self.iconName = iconName
    }
}
```

### 2.5. UserProfile Model
Represents the user's profile, potentially supporting multiple child profiles in the future. (Currently assumes one primary profile).

```swift
import SwiftData
import Foundation

@Model
final class UserProfile {
    // Core Properties
    @Attribute(.unique) var id: UUID // Could be a stable identifier
    var createdAt: Date

    // Child Information (Consider making this a separate Child model if multi-child support is needed)
    var childName: String
    var dateOfBirth: Date? // Optional?
    var interests: [String]? = []

    // Preferences
    var preferredThemes: [String]? = []
    var favoriteCharacters: [String]? = []

    // Settings (Could also be stored in UserDefaults or a separate Settings model)
    // var useTextToSpeech: Bool
    // var preferredVoiceIdentifier: String?
    // var darkModePreference: DarkModePreference // Enum

    // Statistics (Consider if these belong here or calculated dynamically)
    // var totalStoriesRead: Int
    // var totalReadingTime: TimeInterval
    // var lastReadDate: Date?

    // Relationships (If achievements are per-profile)
    // @Relationship(deleteRule: .cascade)
    // var achievements: [Achievement]? = []

    init(
        id: UUID = UUID(),
        childName: String,
        dateOfBirth: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.childName = childName
        self.dateOfBirth = dateOfBirth
        self.createdAt = createdAt
        self.interests = []
        self.preferredThemes = []
        self.favoriteCharacters = []
        // Initialize other properties
    }
}
```

## 3. Enums and Supporting Types

### 3.1. AgeGroup
```swift
enum AgeGroup: Int, Codable, CaseIterable { // Codable for potential storage/transfer
    case preschool = 0    // 3-5 years
    case elementary = 1   // 6-8 years
    case preteen = 2      // 9-10 years

    var displayName: String {
        switch self {
        case .preschool: return "Preschool (3-5)"
        case .elementary: return "Elementary (6-8)"
        case .preteen: return "Preteen (9-10)"
        }
    }
}
```

### 3.2. GrowthCategory
```swift
enum GrowthCategory: String, Codable, CaseIterable { // Codable for potential storage/transfer
    case emotionalIntelligence
    case cognitiveDevelopment
    case confidenceLeadership
    case socialResponsibility
    // Add more as needed

    var displayName: String {
        switch self {
        case .emotionalIntelligence: return "Emotional Intelligence"
        case .cognitiveDevelopment: return "Cognitive Development"
        case .confidenceLeadership: return "Confidence & Leadership"
        case .socialResponsibility: return "Social Responsibility"
        }
    }
}
```

### 3.3. AchievementType
```swift
enum AchievementType: String, Codable, CaseIterable { // Codable for potential storage/transfer
    case readingStreak
    case storiesCompleted
    case themeMastery
    case collectionCompleted // Renamed from growthPathProgress
    case specialMilestone
}
```

### 3.4. IllustrationStatus
```swift
enum IllustrationStatus: String, Codable { // Codable for storage
    case notStarted
    case generating
    case generated
    case failed
}
```

### 3.5. DarkModePreference (Example if needed)
```swift
// enum DarkModePreference: String, Codable {
//     case light
//     case dark
//     case system
// }
```

## 4. Data Migration & Schema Versioning
SwiftData handles lightweight migrations automatically. For complex migrations requiring data transformation, use `SchemaMigrationPlan`. Define schema versions for explicit control.

```swift
enum SchemaVersion: Int, SchemaVersionIdentifier {
    case v1 = 1 // Initial schema with UserDefaults-like structure
    case v2 = 2 // Schema with Story/Page separation, Collections etc.
    // Add new versions here
}

// Example Migration Plan (if needed for complex changes)
// struct MyMigrationPlan: SchemaMigrationPlan {
//     static var schemas: [VersionedSchema.Type] {
//         [SchemaV1.self, SchemaV2.self] // Define schema versions
//     }
//
//     static var stages: [MigrationStage] {
//         [migrateV1toV2] // Define migration stages
//     }
//
//     static let migrateV1toV2 = MigrationStage.lightweight(
//         fromVersion: SchemaV1.self,
//         toVersion: SchemaV2.self
//     )
//     // Or use .custom for complex transformations
// }

// The ModelContainer needs to be initialized with the migration plan if used:
// ModelContainer(for: SchemaV2.self, migrationPlan: MyMigrationPlan.self)
```
*Note: The migration from UserDefaults to SwiftData is handled separately by the `MigrationManager` described in `persistence-guide.md`, not via SwiftData's schema migration plan.*

## 5. Queries and Predicates
Use `FetchDescriptor` and `#Predicate` macros for efficient data retrieval.

```swift
// Example Predicates
// Fetch stories favorited by the user
// #Predicate<Story> { $0.isFavorite == true }

// Fetch collections for a specific growth category
// #Predicate<StoryCollection> { $0.growthCategory == .emotionalIntelligence }
```
Define common queries as static methods or properties on the `@Model` classes or within Repositories.

## 6. Relationships & Delete Rules
-   **Story <-> Page:** One-to-Many. Deleting a `Story` cascades to delete its `Pages`.
-   **Story <-> StoryCollection:** Many-to-Many. SwiftData handles this implicitly. Deleting a `Story` or `StoryCollection` nullifies the link in the other.
-   **Story <-> Achievement:** One-to-Many (optional). Deleting a `Story` nullifies the link in `Achievement`.
-   **UserProfile <-> Achievement:** One-to-Many (optional, if achievements are per-profile). Deleting `UserProfile` cascades to delete `Achievements`.

Choose delete rules (`.cascade`, `.nullify`, `.deny`, `.noAction`) carefully based on data integrity requirements.

## 7. Best Practices
-   Keep models focused.
-   Use appropriate data types.
-   Define relationships clearly with correct delete rules.
-   Use `@Attribute(.unique)` for stable identifiers.
-   Consider indexing (`@Attribute(originalName: ..., hashModifier: ...)` or via `FetchDescriptor`) for frequently queried properties.
-   Version your schema for migrations.

---
This schema should be updated when models, properties, or relationships change. Refer to `persistence-guide.md` for implementation details.

# SwiftData Schema: Illustration Generation (2025-04-20)

## Illustration Generation Flow
- **Multimodal Context:**
  - When generating an illustration for a story page, if a previous page's illustration exists, its image data is loaded from persistent storage and sent as `inline_data` in the Gemini 2.0 API request.
  - The request includes both the new page's description (as text) and the previous image (as base64-encoded inline_data) for visual consistency.
  - The relative path to the previous illustration is tracked per page.
- **First Page or Missing Image:**
  - If no previous image is available (first page or error), only the text prompt is sent.
- **Fallback:**
  - Legacy Imagen API is used for single-image mode or as a fallback.

## Data Model Impact
- No schema change required, but the illustration generation logic now loads previous image data from the persistent directory (`Application Support/Illustrations/`).
- The generated image is saved as before, with a new relative path returned for each page.

See `IllustrationService.swift` for implementation details.
