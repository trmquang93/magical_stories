import Testing
import XCTest
import Foundation
@testable import magical_stories

struct StoryServiceTests {
    var storyService: StoryService!
    var mockPersistenceService: MockPersistenceService!
    
    
    init() async throws {
        mockPersistenceService = MockPersistenceService()
        storyService = await StoryService(apiKey: "mock_key", persistenceService: mockPersistenceService)
    }
    
    @Test("Story generation with valid parameters should succeed")
    func testStoryGenerationWithValidParameters() async throws {
        // Given
        let parameters = StoryParameters(
            childName: "Alex",
            ageGroup: 6,
            favoriteCharacter: "🦁",
            theme: .adventure
        )
        
        // When
        let story = try await storyService.generateStory(parameters: parameters)
        
        // Then
        #expect(story.childName == "Alex")
        #expect(story.ageGroup == 6)
        #expect(story.favoriteCharacter == "🦁")
        #expect(story.theme == .adventure)
        #expect(!story.title.isEmpty)
        #expect(!story.content.isEmpty)
    }
    
    @Test("Story generation with empty child name should fail")
    func testStoryGenerationWithEmptyChildName() async {
        // Given
        let parameters = StoryParameters(
            childName: "",
            ageGroup: 6,
            favoriteCharacter: "🦁",
            theme: .adventure
        )
        
        // When/Then
        do {
            _ = try await storyService.generateStory(parameters: parameters)
            XCTFail("Expected error for empty child name")
        } catch {
            #expect(error is StoryServiceError)
            #expect((error as? StoryServiceError) == .invalidParameters)
        }
    }
    
    @Test("Loading stories should return sorted by creation date")
    func testLoadStoriesSorting() async throws {
        // Given
        let oldStory = Story(
            title: "Old Story",
            content: "Content",
            theme: .adventure,
            childName: "Alex",
            ageGroup: 6,
            favoriteCharacter: "🦁",
            createdAt: Date().addingTimeInterval(-86400) // 1 day ago
        )
        
        let newStory = Story(
            title: "New Story",
            content: "Content",
            theme: .adventure,
            childName: "Alex",
            ageGroup: 6,
            favoriteCharacter: "🦁",
            createdAt: Date()
        )
        
        try await mockPersistenceService.saveStory(oldStory)
        try await mockPersistenceService.saveStory(newStory)
        
        // When
        await storyService.loadStories()
        
        // Then
        let stories = await storyService.stories
        #expect(stories.count == 2)
        #expect(stories[0].title == "New Story")
        #expect(stories[1].title == "Old Story")
    }
}

// MARK: - Mock Persistence Service
actor MockPersistenceService: PersistenceServiceProtocol {
    private var stories: [Story] = []
    
    func saveStory(_ story: Story) async throws {
        stories.append(story)
    }
    
    func loadStories() async throws -> [Story] {
        return stories.sorted { $0.createdAt > $1.createdAt }
    }
    
    func deleteStory(_ story: Story) async throws {
        stories.removeAll { $0.id == story.id }
    }
    
    func deleteAllStories() async throws {
        stories.removeAll()
    }
} 
