import Testing
import XCTest
import Foundation
import GoogleGenerativeAI
@testable import magical_stories

// MARK: - Mock GenerativeModel
class MockGenerativeModel: GenerativeModelProtocol {
    func generateContent(_ prompt: String) async throws -> StoryGenerationResponse {
        return MockGenerateContentResponse(text: """
            Title: The Lion's Adventure
            
            Once upon a time, there was a brave lion who loved to explore. The lion made friends with all the animals in the forest and helped them whenever they needed assistance.
            
            One day, the lion discovered a magical cave filled with sparkling gems. Instead of keeping the treasure for himself, he decided to share it with all his forest friends.
            
            The animals were so grateful for the lion's generosity that they threw a big celebration in his honor. From that day on, the forest was known as the happiest place in all the land.
            """)
    }
}

struct MockGenerateContentResponse: StoryGenerationResponse {
    var text: String?
}

struct StoryServiceTests {
    var storyService: StoryService!
    var mockPersistenceService: MockPersistenceService!
    var mockGenerativeModel: MockGenerativeModel!
    
    init() async throws {
        mockPersistenceService = MockPersistenceService()
        mockGenerativeModel = MockGenerativeModel()
        storyService = await StoryService(
            apiKey: "mock_key",
            persistenceService: mockPersistenceService,
            model: mockGenerativeModel
        )
    }
    
    @Test("Story generation with valid parameters should succeed")
    func testStoryGenerationWithValidParameters() async throws {
        // Given
        // Corrected StoryParameters initializer
        let parameters = StoryParameters(
            childName: "Alex",
            childAge: 6, // Use childAge
            theme: "adventure", // Use String for theme
            favoriteCharacter: "🦁"
            // Removed language parameter
        )
        
        // When
        let story = try await storyService.generateStory(parameters: parameters)
        
        // Then
        // Corrected property access via parameters
        #expect(story.parameters.childName == "Alex")
        #expect(story.parameters.childAge == 6)
        #expect(story.parameters.favoriteCharacter == "🦁")
        #expect(story.parameters.theme == "adventure") // Compare with String
        #expect(!story.title.isEmpty)
        #expect(!story.content.isEmpty)
    }
    
    @Test("Story generation with empty child name should fail")
    func testStoryGenerationWithEmptyChildName() async {
        // Given
        // Corrected StoryParameters initializer
        let parameters = StoryParameters(
            childName: "",
            childAge: 6, // Use childAge
            theme: "adventure", // Use String for theme
            favoriteCharacter: "🦁"
            // Removed language parameter
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
        // Corrected Story initializer
        let oldParameters = StoryParameters(childName: "Alex", childAge: 6, theme: "adventure", favoriteCharacter: "🦁")
        let oldStory = Story(
            title: "Old Story",
            content: "Content",
            parameters: oldParameters, // Pass parameters object
            timestamp: Date().addingTimeInterval(-86400) // Use timestamp
        )
        
        // Corrected Story initializer
        let newParameters = StoryParameters(childName: "Alex", childAge: 6, theme: "adventure", favoriteCharacter: "🦁")
        let newStory = Story(
            title: "New Story",
            content: "Content",
            parameters: newParameters, // Pass parameters object
            timestamp: Date() // Use timestamp
        )
        
        // Corrected: Mock methods are not async anymore
        try mockPersistenceService.saveStory(oldStory)
        try mockPersistenceService.saveStory(newStory)
        
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
class MockPersistenceService: PersistenceServiceProtocol {
    private var stories: [Story] = []
    
    func saveStory(_ story: Story) throws {
        // Ensure no duplicate IDs are added, replace if exists
        if let index = stories.firstIndex(where: { $0.id == story.id }) {
            stories[index] = story
        } else {
            stories.append(story)
        }
    }
    
    func saveStories(_ storiesToSave: [Story]) throws {
        self.stories = storiesToSave
    }

    func loadStories() throws -> [Story] {
        // Sorting is handled by StoryService, just return the raw array
        return stories
    }
    
    func deleteStory(withId id: UUID) throws {
        stories.removeAll { $0.id == id }
    }

    // Optional: Keep deleteAllStories if needed for tests, but it's not part of the protocol
    // Also mark this nonisolated if kept, though not required by protocol
    // Removed nonisolated - not needed for class
    func deleteAllStories() throws {
         stories.removeAll()
    }
}
