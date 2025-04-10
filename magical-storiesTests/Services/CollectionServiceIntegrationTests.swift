import Testing
@testable import magical_stories
import Foundation


@Suite("Collection Service Integration Tests")
@MainActor
struct CollectionServiceIntegrationTests {
    
    var collectionService: CollectionService!
    var aiService: MockAIServiceProtocol!
    var repository: CollectionRepository!
    
    init() {
        // Setup for integration test - using new CollectionService API with appropriate mocks
        aiService = MockAIServiceProtocol()
        repository = MockCollectionRepository()
        collectionService = CollectionService(aiService: aiService, repository: repository)
        // Clean up any existing test data if needed (implementation may be updated in later subtasks)
    }
    
    // FIX: No macro named 'Test' in Swift Testing. Use #Test as a function attribute, not as a statement.
    @Test("Full generation success path")
    func testCollectionGenerationFlow_Success() async throws {
        // Arrange
        let title = "Integration Test Collection"
        let growthCategory = "Learning"
        let targetAgeGroup = "5-7"
        
        // Act - Create a collection using the new API
        let collection = try await collectionService.createCollection(
            title: title,
            growthCategory: growthCategory,
            targetAgeGroup: targetAgeGroup
        )
        
        // Assert
        // 1. Collection properties
        #expect(collection.title == "Integration Test Collection")
        #expect(collection.descriptionText == "A collection for testing the integration flow")
        #expect(collection.stories.count == 5)
        #expect(collection.growthCategory == "Learning")
        #expect(collection.targetAgeGroup == "5-7")
        
        // 2. Stories were generated
        for story in collection.stories {
            #expect(story.title == "Integration Test Story")
            #expect(story.pages.count == 2)
            // collectionId property removed from Story; no assertion needed
        }
        
        // Clean up after test
        await cleanupTestData()
    }
    
    @Test("Generation with AI error handling")
    func testCollectionGenerationFlow_AIErrorHandling() async throws {
        // Arrange
        let title = "Retry Collection"
        let growthCategory = "Social Skills"
        let targetAgeGroup = "8-10"
        
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
                        {"context": "Trying again context"},
                        {"context": "Not giving up context"},
                        {"context": "Success after failure context"},
                        {"context": "Learning from mistakes context"},
                        {"context": "Achieving goals context"}
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
        
        // Act - Create a collection which should trigger retries
        let collection = try await collectionService.createCollection(
            title: title,
            growthCategory: growthCategory,
            targetAgeGroup: targetAgeGroup
        )
        
        // Assert
        #expect(errorCount == 3) // Two failures + one success
        #expect(collection.title == "Retry Collection")
        #expect(collection.descriptionText == "Collection after retry")
        #expect(collection.stories.count == 5)
        #expect(collection.targetAgeGroup == "8-10")
        #expect(collection.growthCategory == "Social Skills")
        
        // Clean up after test
        await cleanupTestData()
    }
    
    // Helper function to clean up test data
    private func cleanupTestData() async {
        // Clean up collections created for testing
        // Implementation will be updated in a later subtask to use the new repository
    }
}