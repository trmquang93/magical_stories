# SwiftData Schema Documentation

## Overview
This document outlines the data model schema for the Magical Stories app using SwiftData.

## Core Models

### Story Model
```swift
@Model
final class Story {
    // Core Properties
    var id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var lastReadAt: Date?
    
    // Story Parameters
    var childName: String?
    var ageGroup: AgeGroup
    var theme: String
    var mainCharacter: String
    var isGrowthPathStory: Bool
    
    // Optional Properties
    var audioURL: URL?
    var readCount: Int
    var isFavorite: Bool
    var notes: String?
    
    // Relationships
    @Relationship(deleteRule: .cascade)
    var achievements: [Achievement]?
    
    @Relationship(inverse: \StoryCollection.stories)
    var collections: [StoryCollection]?
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        childName: String? = nil,
        ageGroup: AgeGroup,
        theme: String,
        mainCharacter: String,
        isGrowthPathStory: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.childName = childName
        self.ageGroup = ageGroup
        self.theme = theme
        self.mainCharacter = mainCharacter
        self.isGrowthPathStory = isGrowthPathStory
        self.createdAt = Date()
        self.readCount = 0
        self.isFavorite = false
    }
}
```

### StoryCollection Model
```swift
@Model
final class StoryCollection {
    // Core Properties
    var id: UUID
    var name: String
    var createdAt: Date
    var description: String?
    
    // Growth Path Properties
    var growthCategory: GrowthCategory?
    var targetAgeGroup: AgeGroup?
    var completionProgress: Double
    
    // Relationships
    @Relationship(deleteRule: .nullify)
    var stories: [Story]
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        growthCategory: GrowthCategory? = nil,
        targetAgeGroup: AgeGroup? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.growthCategory = growthCategory
        self.targetAgeGroup = targetAgeGroup
        self.createdAt = Date()
        self.completionProgress = 0.0
        self.stories = []
    }
}
```

### Achievement Model
```swift
@Model
final class Achievement {
    // Core Properties
    var id: UUID
    var name: String
    var description: String
    var earnedAt: Date
    var type: AchievementType
    
    // Optional Properties
    var iconName: String?
    var progress: Double?
    
    // Relationships
    @Relationship(inverse: \Story.achievements)
    var story: Story?
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        type: AchievementType
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.earnedAt = Date()
    }
}
```

### UserProfile Model
```swift
@Model
final class UserProfile {
    // Core Properties
    var id: UUID
    var createdAt: Date
    
    // Child Information
    var childName: String
    var dateOfBirth: Date
    var interests: [String]
    
    // Preferences
    var preferredThemes: [String]
    var favoriteCharacters: [String]
    
    // Settings
    var useTextToSpeech: Bool
    var preferredVoiceIdentifier: String?
    var darkModePreference: DarkModePreference
    
    // Statistics
    var totalStoriesRead: Int
    var totalReadingTime: TimeInterval
    var lastReadDate: Date?
    
    // Relationships
    @Relationship(deleteRule: .cascade)
    var achievements: [Achievement]
    
    init(
        id: UUID = UUID(),
        childName: String,
        dateOfBirth: Date
    ) {
        self.id = id
        self.childName = childName
        self.dateOfBirth = dateOfBirth
        self.createdAt = Date()
        self.interests = []
        self.preferredThemes = []
        self.favoriteCharacters = []
        self.useTextToSpeech = true
        self.darkModePreference = .system
        self.totalStoriesRead = 0
        self.totalReadingTime = 0
        self.achievements = []
    }
}
```

## Enums and Supporting Types

### AgeGroup
```swift
enum AgeGroup: Int, Codable {
    case preschool = 0    // 3-5 years
    case elementary = 1   // 6-8 years
    case preteen = 2      // 9-10 years
    
    var range: ClosedRange<Int> {
        switch self {
        case .preschool: return 3...5
        case .elementary: return 6...8
        case .preteen: return 9...10
        }
    }
}
```

### GrowthCategory
```swift
enum GrowthCategory: String, Codable {
    case emotionalIntelligence
    case cognitiveDevelopment
    case confidenceLeadership
    case socialResponsibility
    
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

### AchievementType
```swift
enum AchievementType: String, Codable {
    case readingStreak
    case storiesCompleted
    case themeMastery
    case growthPathProgress
    case specialMilestone
}
```

### DarkModePreference
```swift
enum DarkModePreference: String, Codable {
    case light
    case dark
    case system
}
```

## Data Migration

### Schema Versioning
```swift
enum SchemaVersion: Int {
    case v1 = 1
    case v2 = 2
    // Add new versions here
}
```

### Migration Example
```swift
class DataMigrator {
    static func migrateToV2(context: ModelContext) {
        // Example migration code
        try? context.fetch(FetchDescriptor<Story>()).forEach { story in
            // Add new properties or modify existing ones
            story.readCount = 0
            story.isFavorite = false
        }
    }
}
```

## Queries and Predicates

### Common Queries
```swift
extension Story {
    static func recentStories() -> FetchDescriptor<Story> {
        var descriptor = FetchDescriptor<Story>()
        descriptor.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]
        descriptor.fetchLimit = 10
        return descriptor
    }
    
    static func favoriteStories() -> FetchDescriptor<Story> {
        var descriptor = FetchDescriptor<Story>()
        descriptor.predicate = #Predicate<Story> { story in
            story.isFavorite == true
        }
        return descriptor
    }
}
```

### Growth Path Queries
```swift
extension StoryCollection {
    static func growthPathCollections(
        category: GrowthCategory
    ) -> FetchDescriptor<StoryCollection> {
        var descriptor = FetchDescriptor<StoryCollection>()
        descriptor.predicate = #Predicate<StoryCollection> { collection in
            collection.growthCategory == category
        }
        return descriptor
    }
}
```

## Best Practices

### 1. Data Access
- Use repository pattern to abstract data access
- Implement CRUD operations through dedicated services
- Handle errors gracefully with proper error types

### 2. Performance
- Use appropriate fetch limits
- Implement pagination for large datasets
- Cache frequently accessed data
- Use indexes for common queries

### 3. Data Integrity
- Validate data before saving
- Use appropriate delete rules
- Maintain referential integrity
- Handle concurrent access

### 4. Testing
- Create mock data for testing
- Test all CRUD operations
- Verify migration paths
- Test edge cases

## Example Usage

### Repository Pattern
```swift
class StoryRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func save(_ story: Story) throws {
        modelContext.insert(story)
        try modelContext.save()
    }
    
    func delete(_ story: Story) throws {
        modelContext.delete(story)
        try modelContext.save()
    }
    
    func fetchStories() throws -> [Story] {
        try modelContext.fetch(Story.recentStories())
    }
}
```

---

This schema should be updated when:
- Adding new models or properties
- Modifying relationships
- Implementing new features
- Performing migrations
