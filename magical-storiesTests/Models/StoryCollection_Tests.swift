import Foundation
import Testing
import SwiftData
@testable import magical_stories

struct StoryCollectionTests {
    
    @Test("StoryCollection can be initialized with required properties")
    func testInit() throws {
        // Arrange
        let id = UUID()
        let title = "Emotional Growth"
        let descriptionText = "Friendship"
        let targetAgeGroup = "6-8 years"
        let growthCategory = "Emotional Intelligence"
        
        // Act
        let collection = StoryCollection(
            id: id,
            title: title,
            descriptionText: descriptionText,
            growthCategory: growthCategory,
            targetAgeGroup: targetAgeGroup
        )
        
        // Assert
        #expect(collection.id == id)
        #expect(collection.title == title)
        #expect(collection.descriptionText == descriptionText)
        #expect(collection.growthCategory == growthCategory)
        #expect(collection.targetAgeGroup == targetAgeGroup)
        #expect(collection.completionProgress == 0.0)
        #expect(collection.stories.isEmpty)
        #expect(collection.achievements == nil || collection.achievements?.isEmpty == true)
    }

    @Test("StoryCollection title can be updated")
    func testUpdateTitle() throws {
        // Arrange
        let collection = StoryCollection(
            id: UUID(),
            title: "Original Title",
            descriptionText: "Theme",
            growthCategory: "Focus",
            targetAgeGroup: "3-5 years"
        )
        let newTitle = "Updated Title"
        
        // Act
        collection.title = newTitle
        
        // Assert
        #expect(collection.title == newTitle)
    }

    @Test("StoryCollection completionProgress can be updated")
    func testUpdateCompletionProgress() throws {
        // Arrange
        let collection = StoryCollection(
            id: UUID(),
            title: "Title",
            descriptionText: "Description",
            growthCategory: "Focus",
            targetAgeGroup: "3-5 years"
        )
        let newProgress = 0.5
        
        // Act
        collection.completionProgress = newProgress
        
        // Assert
        #expect(collection.completionProgress == newProgress)
    }

    @Test("StoryCollection can add stories")
    func testAddStories() throws {
        // Arrange
        let story = Story(
            id: UUID(),
            title: "Test Story",
            content: "Once upon a time...",
            isCompleted: false
        )
        var collection = StoryCollection(
            id: UUID(),
            title: "Title"
        )
        
        // Act
        collection.stories.append(story)
        
        // Assert
        #expect(collection.stories.count == 1)
        #expect(collection.stories.first?.id == story.id)
    }

    @Test("StoryCollection can add achievements")
    func testAddAchievements() throws {
        // Arrange
        let achievement = Achievement(
            id: UUID(),
            name: "Test Achievement",
            type: .specialMilestone
        )
        var collection = StoryCollection(
            id: UUID(),
            title: "Title"
        )
        collection.achievements = []
        
        // Act
        collection.achievements?.append(achievement)
        
        // Assert
        #expect(collection.achievements?.count == 1)
        #expect(collection.achievements?.first?.name == achievement.name)
    }

    @Test("StoryCollection can calculate progress based on completed stories")
    func testCalculateProgress() throws {
        // Arrange
        let story1 = Story(
            id: UUID(),
            title: "Story 1",
            content: "Content 1",
            isCompleted: true
        )
        let story2 = Story(
            id: UUID(),
            title: "Story 2",
            content: "Content 2",
            isCompleted: false
        )
        var collection = StoryCollection(
            id: UUID(),
            title: "Title"
        )
        collection.stories = [story1, story2]
        
        // Act
        let progress = collection.calculateProgress()
        
        // Assert
        #expect(progress == 0.5)
    }
}