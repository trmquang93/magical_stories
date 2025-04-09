import Testing
@testable import magical_stories
import Foundation

extension Tag {
    @Tag static var integration: Self
}

@Suite("Collection Service Integration Tests")
@MainActor
struct CollectionServiceIntegrationTests {
    
    var collectionService: CollectionService!
    var persistenceService: PersistenceService!
    var storyService: StoryService!
    var generativeModel: GenerativeModelProtocol!
    var aiErrorManager: AIErrorManager!
    
    init() {
        // Setup for integration test - using actual implementations with mocked dependencies
        persistenceService = PersistenceService(useSwiftData: false)
        aiErrorManager = AIErrorManager()
        
        // For StoryService, use a mock generative model
        let mockStoryModel = MockGenerativeModel()
        mockStoryModel.generateContentHandler = { _ in 
            return MockStoryGenerationResponse(text: """
            {
                "title": "Integration Test Story",
                "summary": "A test story for integration testing",
                "targetAgeGroup": "5-7",
                "pages": [
                    {"content": "Page 1 content", "imagePrompt": "A test image with a happy child"},
                    {"content": "Page 2 content", "imagePrompt": "A test image with a rainbow"}
                ]
            }
            """)
        }
        
        // For CollectionService, use a different mock model
        let mockCollectionModel = MockGenerativeModel()
        mockCollectionModel.generateContentHandler = { _ in
            return MockStoryGenerationResponse(text: """
            {
                "title": "Integration Test Collection",
                "description": "A collection for testing the integration flow",
                "achievementIds": ["test_badge_1", "test_badge_2"],
                "storyOutlines": [
                    {"theme": "Learning", "context": "First day at school context"},
                    {"theme": "Friendship", "context": "Making new friends context"},
                    {"theme": "Sharing", "context": "Sharing toys context"},
                    {"theme": "Learning", "context": "Learning to read context"},
                    {"theme": "Adventure", "context": "Going on a trip context"}
                ]
            }
            """)
        }
        
        // For illustration service, use a mock that doesn't call APIs
        let mockIllustrationService = MockIllustrationService()
        mockIllustrationService.generateIllustrationHandler = { _, _ in
            return URL(string: "file:///mockIllustration.jpg")!
        }
        
        // Initialize story service with mocks
        storyService = StoryService(
            model: mockStoryModel, 
            persistenceService: persistenceService,
            illustrationService: mockIllustrationService,
            aiErrorManager: aiErrorManager
        )
        
        // Initialize collection service with real story service but mock generative model
        collectionService = CollectionService(
            storyService: storyService,
            persistenceService: persistenceService,
            aiErrorManager: aiErrorManager,
            model: mockCollectionModel
        )
        
        // Clean up any existing test data
        Task {
            await cleanupTestData()
        }
    }
    
    @Test("Full generation success path", tags: [.integration])
    func testCollectionGenerationFlow_Success() async throws {
        // Arrange
        let parameters = CollectionParameters(
            childAgeGroup: "5-7",
            developmentalFocus: "Learning",
            interests: ["Animals", "School"]
        )
        
        // Act - Generate a collection which should trigger the whole flow
        let collection = try await collectionService.generateCollection(parameters: parameters)
        
        // Assert
        // 1. Collection properties
        #expect(collection.title == "Integration Test Collection")
        #expect(collection.description == "A collection for testing the integration flow")
        #expect(collection.stories.count == 5)
        
        // 2. Stories were generated
        for story in collection.stories {
            #expect(story.title == "Integration Test Story")
            #expect(story.pages.count == 2)
            #expect(story.collectionId == collection.id)
        }
        
        // 3. Collection was saved in persistence
        let savedCollections = await persistenceService.fetchCollections()
        #expect(savedCollections.contains(where: { $0.id == collection.id }))
        
        // 4. Stories were saved in persistence
        for story in collection.stories {
            let savedStory = try await persistenceService.fetchStory(id: story.id)
            #expect(savedStory != nil)
        }
        
        // Clean up after test
        await cleanupTestData()
    }
    
    @Test("Generation with AI error handling", tags: [.integration])
    func testCollectionGenerationFlow_AIErrorHandling() async throws {
        // Arrange
        let parameters = CollectionParameters(
            childAgeGroup: "8-10",
            developmentalFocus: "Social Skills",
            interests: ["Sports", "Music"]
        )
        
        // Replace the mock with one that simulates errors
        var errorCount = 0
        let errorModel = MockGenerativeModel()
        errorModel.generateContentHandler = { _ in
            errorCount += 1
            if errorCount <= 2 {
                // First 2 attempts fail
                throw CollectionError.aiServiceError(NSError(domain: "AITestError", code: 500))
            } else {
                // 3rd attempt succeeds
                return MockStoryGenerationResponse(text: """
                {
                    "title": "Retry Collection",
                    "description": "Collection after retry",
                    "achievementIds": ["retry_badge"],
                    "storyOutlines": [
                        {"theme": "Perseverance", "context": "Trying again context"},
                        {"theme": "Perseverance", "context": "Not giving up context"},
                        {"theme": "Perseverance", "context": "Success after failure context"},
                        {"theme": "Learning", "context": "Learning from mistakes context"},
                        {"theme": "Success", "context": "Achieving goals context"}
                    ]
                }
                """)
            }
        }
        
        // Replace the model in the service
        collectionService = CollectionService(
            storyService: storyService,
            persistenceService: persistenceService,
            aiErrorManager: aiErrorManager,
            model: errorModel
        )
        
        // Act - Generate a collection which should trigger retries
        let collection = try await collectionService.generateCollection(parameters: parameters)
        
        // Assert
        #expect(errorCount == 3) // Two failures + one success
        #expect(collection.title == "Retry Collection")
        #expect(collection.stories.count == 5)
        
        // Clean up after test
        await cleanupTestData()
    }
    
    // Helper function to clean up test data
    private func cleanupTestData() async {
        // Clean up collections and stories created for testing
        let collections = await persistenceService.fetchCollections()
        for collection in collections {
            if collection.title.contains("Integration Test") || collection.title.contains("Retry") {
                try? await persistenceService.deleteCollection(collection.id)
                for story in collection.stories {
                    try? await persistenceService.deleteStory(id: story.id)
                }
            }
        }
    }
}

// MARK: - Mock for Integration Tests
class MockIllustrationService: IllustrationServiceProtocol {
    var generateIllustrationHandler: ((String, String) async throws -> URL)?
    
    func generateIllustration(prompt: String, style: String) async throws -> URL {
        if let handler = generateIllustrationHandler {
            return try await handler(prompt, style)
        }
        throw NSError(domain: "MockError", code: 404)
    }
} 