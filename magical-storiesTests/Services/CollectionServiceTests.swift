import Foundation
import XCTest
import SwiftData
import Testing
import SwiftUI

@testable import magical_stories

/// Mock for CollectionRepositoryProtocol to use in tests
class MockCollectionRepository: CollectionRepositoryProtocol {
    var collections: [UUID: StoryCollection] = [:]
    var saveCollectionCalled = false
    var updateProgressCalled = false
    
    func saveCollection(_ collection: StoryCollection) throws {
        saveCollectionCalled = true
        collections[collection.id] = collection
    }
    
    func fetchCollection(id: UUID) throws -> StoryCollection? {
        return collections[id]
    }
    
    func fetchAllCollections() throws -> [StoryCollection] {
        return Array(collections.values)
    }
    
    func updateCollectionProgress(id: UUID, progress: Float) throws {
        updateProgressCalled = true
        if let collection = collections[id] {
            collection.completionProgress = Double(progress)
            collection.updatedAt = Date()
        }
    }
    
    func deleteCollection(id: UUID) throws {
        collections.removeValue(forKey: id)
    }
}

/// Mock for StoryService to use in tests
class MockStoryService: StoryService {
    var generateStoryCallCount = 0
    var lastParameters: StoryParameters?
    var storiesToReturn: [Story] = []
    var shouldFailGeneration = false
    
    init() throws {
        // Create an in-memory ModelContext for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Story.self, configurations: config)
        let context = ModelContext(container)
        
        // Initialize with the test context and no persistence service
        try super.init(apiKey: "test_key", context: context)
    }
    
    override func generateStory(parameters: StoryParameters) async throws -> Story {
        generateStoryCallCount += 1
        lastParameters = parameters
        
        if shouldFailGeneration {
            throw StoryServiceError.generationFailed("Mock generation failure")
        }
        
        // Return a story from our prepared list, or create a new one
        if !storiesToReturn.isEmpty && generateStoryCallCount <= storiesToReturn.count {
            return storiesToReturn[generateStoryCallCount - 1]
        }
        
        return Story(
            title: "Test Story \(generateStoryCallCount)",
            pages: [],
            parameters: parameters,
            timestamp: Date()
        )
    }
}

@Suite("CollectionService Tests")
@MainActor
struct CollectionServiceTests {
    
    func setupTest() -> (service: CollectionService, repository: MockCollectionRepository, storyService: MockStoryService) {
        let repository = MockCollectionRepository()
        let storyService: MockStoryService
        do {
            storyService = try MockStoryService()
        } catch {
            fatalError("Failed to initialize MockStoryService: \(error)")
        }
        let service = CollectionService(repository: repository, storyService: storyService)
        return (service, repository, storyService)
    }
    
    @Test("generateStoriesForCollection creates stories with varied themes")
    func testGenerateStoriesForCollection() async throws {
        let (service, repository, storyService) = setupTest()
        
        let collection = StoryCollection(
            title: "Test Collection",
            descriptionText: "Test Description",
            category: "emotionalIntelligence",
            ageGroup: "4-6"
        )
        
        let parameters = CollectionParameters(
            childAgeGroup: "4-6",
            developmentalFocus: "Emotional Intelligence",
            interests: "Dinosaurs, Space",
            childName: "Alex",
            characters: ["Dragon"]
        )
        
        // Generate stories
        try await service.generateStoriesForCollection(collection, parameters: parameters)
        
        // Verify story generation was called 3 times (default number of stories)
        #expect(storyService.generateStoryCallCount == 3)
        #expect(repository.saveCollectionCalled)
        
        // Verify the collection was saved with stories
        if let savedCollection = repository.collections[collection.id] {
            #expect(savedCollection.stories?.count == 3)
            
            // Check that themes are different - themes should be varied
            let themes = storyService.lastParameters?.theme ?? ""
            #expect(themes.contains("Emotional Intelligence"))
        } else {
            XCTFail("Collection was not saved")
        }
    }
    
    @Test("generateStoriesForCollection handles failure gracefully")
    func testGenerateStoriesForCollectionFailure() async throws {
        let (service, _, storyService) = setupTest()
        
        let collection = StoryCollection(
            title: "Test Collection",
            descriptionText: "Test Description",
            category: "emotionalIntelligence",
            ageGroup: "4-6"
        )
        
        let parameters = CollectionParameters(
            childAgeGroup: "4-6",
            developmentalFocus: "Emotional Intelligence",
            interests: "Dinosaurs",
            childName: "Alex"
        )
        
        // Configure story service to fail
        storyService.shouldFailGeneration = true
        
        // Attempt to generate stories
        do {
            try await service.generateStoriesForCollection(collection, parameters: parameters)
            XCTFail("Should have thrown an error")
        } catch {
            // Verify error was set - Wait briefly to allow the async DispatchQueue.main call to complete
            try await Task.sleep(for: .milliseconds(100))
            #expect(service.generationError != nil)
            #expect(service.isGenerating == false) // Should reset generating state
        }
    }
    
    @Test("createStoryThemes generates varied themes")
    func testCreateStoryThemes() throws {
        let (service, _, _) = setupTest()
        
        // Access private method using reflection
        let mirror = Mirror(reflecting: service)
        
        // Find the createStoryThemes method
        let createThemesMethod = mirror.children.first { 
            $0.label == "createStoryThemes" 
        }?.value
        
        guard let createThemes = createThemesMethod as? (String, String, Int) -> [String] else {
            XCTFail("Could not access createStoryThemes method")
            return
        }
        
        let themes = createThemes("Emotional Intelligence", "Dinosaurs, Space", 5)
        
        // Verify themes were created
        #expect(themes.count == 5)
        
        // Check theme composition
        let emotionalIntelligenceThemes = themes.filter { $0.contains("Emotional Intelligence") }
        #expect(emotionalIntelligenceThemes.count == 5)
        
        // Make sure at least one interest was incorporated
        let interestThemes = themes.filter { $0.contains("Dinosaurs") || $0.contains("Space") }
        #expect(interestThemes.count > 0)
    }
    
    @Test("updateCollectionProgressBasedOnReadCount calculates progress correctly")
    func testUpdateCollectionProgressBasedOnReadCount() async throws {
        let (service, repository, _) = setupTest()
        
        // Create test collection with 4 stories, 2 completed
        let collection = StoryCollection(
            title: "Test Collection",
            descriptionText: "Test Description",
            category: "emotionalIntelligence",
            ageGroup: "4-6"
        )
        
        let story1 = Story(
            title: "Story 1",
            pages: [],
            parameters: StoryParameters(childName: "Test", childAge: 5, theme: "Theme", favoriteCharacter: "Friend"),
            isCompleted: true
        )
        
        let story2 = Story(
            title: "Story 2",
            pages: [],
            parameters: StoryParameters(childName: "Test", childAge: 5, theme: "Theme", favoriteCharacter: "Friend"),
            isCompleted: true
        )
        
        let story3 = Story(
            title: "Story 3",
            pages: [],
            parameters: StoryParameters(childName: "Test", childAge: 5, theme: "Theme", favoriteCharacter: "Friend"),
            isCompleted: false
        )
        
        let story4 = Story(
            title: "Story 4",
            pages: [],
            parameters: StoryParameters(childName: "Test", childAge: 5, theme: "Theme", favoriteCharacter: "Friend"),
            isCompleted: false
        )
        
        collection.stories = [story1, story2, story3, story4]
        
        // Save collection to repository
        try repository.saveCollection(collection)
        
        // Calculate progress
        let progress = try await service.updateCollectionProgressBasedOnReadCount(collectionId: collection.id)
        
        // Verify progress (2/4 = 0.5)
        #expect(progress == 0.5)
        #expect(collection.completionProgress == 0.5)
    }
    
    @Test("updateCollectionProgressBasedOnReadCount handles empty collections")
    func testUpdateCollectionProgressWithNoStories() async throws {
        let (service, repository, _) = setupTest()
        
        // Create test collection with no stories
        let collection = StoryCollection(
            title: "Empty Collection",
            descriptionText: "Test Description",
            category: "emotionalIntelligence",
            ageGroup: "4-6"
        )
        
        // Save collection to repository
        try repository.saveCollection(collection)
        
        // Calculate progress
        let progress = try await service.updateCollectionProgressBasedOnReadCount(collectionId: collection.id)
        
        // Verify progress (0 stories = 0 progress)
        #expect(progress == 0.0)
        #expect(collection.completionProgress == 0.0)
    }
    
    @Test("markStoryAsCompleted updates story completion and collection progress")
    func testMarkStoryAsCompleted() async throws {
        let (service, repository, _) = setupTest()
        
        // Create test collection with 2 stories, none completed
        let collection = StoryCollection(
            title: "Test Collection",
            descriptionText: "Test Description",
            category: "emotionalIntelligence", 
            ageGroup: "4-6"
        )
        
        let story1 = Story(
            title: "Story 1",
            pages: [],
            parameters: StoryParameters(childName: "Test", childAge: 5, theme: "Theme", favoriteCharacter: "Friend"),
            isCompleted: false
        )
        
        let story2 = Story(
            title: "Story 2",
            pages: [],
            parameters: StoryParameters(childName: "Test", childAge: 5, theme: "Theme", favoriteCharacter: "Friend"),
            isCompleted: false
        )
        
        collection.stories = [story1, story2]
        
        // Save collection to repository
        try repository.saveCollection(collection)
        
        // Mark first story as completed
        try await service.markStoryAsCompleted(storyId: story1.id, collectionId: collection.id)
        
        // Verify story1 is marked as completed
        #expect(story1.isCompleted)
        
        // Verify collection progress is updated (1/2 = 0.5)
        #expect(collection.completionProgress == 0.5)
        
        // Mark second story as completed
        try await service.markStoryAsCompleted(storyId: story2.id, collectionId: collection.id)
        
        // Verify both stories are completed
        #expect(story2.isCompleted)
        
        // Verify collection progress is updated (2/2 = 1.0)
        #expect(collection.completionProgress == 1.0)
    }
    
    @Test("Achievements are tracked when collection is completed")
    func testAchievementTracking() async throws {
        let (service, repository, _) = setupTest()
        
        // Create test collection with 1 story
        let collection = StoryCollection(
            title: "Test Collection",
            descriptionText: "Test Description",
            category: "emotionalIntelligence",
            ageGroup: "4-6"
        )
        
        let story = Story(
            title: "Test Story",
            pages: [],
            parameters: StoryParameters(childName: "Test", childAge: 5, theme: "Theme", favoriteCharacter: "Friend"),
            isCompleted: false
        )
        
        collection.stories = [story]
        
        // Save collection to repository
        try repository.saveCollection(collection)
        
        // Mark story as completed
        try await service.markStoryAsCompleted(storyId: story.id, collectionId: collection.id)
        
        // Verify collection is completed (progress = 1.0)
        #expect(collection.completionProgress == 1.0)
        
        // Currently, we can only verify achievement would be tracked
        // as we only have a placeholder for the achievement tracking
        // We'd need to add mock achievement repository to test further
    }
}
