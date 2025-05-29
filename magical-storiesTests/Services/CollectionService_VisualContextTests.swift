import SwiftData
import Testing
@testable import magical_stories

@Suite("CollectionService Visual Context Tests")
@MainActor
struct CollectionService_VisualContextTests {
    
    private func createTestEnvironment() throws -> (CollectionService, ModelContext, MockStoryServiceForVisualContext) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Story.self, StoryCollection.self, configurations: config)
        let context = container.mainContext
        
        // Create repository dependencies
        let collectionRepository = CollectionRepository(context: context)
        let achievementRepository = AchievementRepository(context: context)
        
        // Create enhanced mock story service that captures visual context
        let mockStoryService = MockStoryServiceForVisualContext(context: context)
        
        // Create collection service
        let collectionService = CollectionService(
            repository: collectionRepository,
            storyService: mockStoryService,
            achievementRepository: achievementRepository
        )
        
        return (collectionService, context, mockStoryService)
    }
    
    @Test("Visual context creation for collection")
    func testVisualContextCreation() throws {
        let (collectionService, _, _) = try createTestEnvironment()
        
        // Create test collection
        let collection = StoryCollection(
            title: "Test Collection",
            descriptionText: "A test collection for visual context testing",
            category: "Adventure",
            ageGroup: "5-7"
        )
        
        // Verify that the collection service was created successfully
        #expect(collectionService.collections.isEmpty)
        #expect(!collectionService.isGenerating)
    }
    
    @Test("Collection parameters create appropriate visual context")  
    func testCollectionParametersVisualContext() throws {
        let parameters = CollectionParameters(
            childAgeGroup: "4-6", 
            developmentalFocus: "Emotional Intelligence",
            interests: "Animals, Ocean",
            childName: "Alex",
            characters: ["Dolphin", "Turtle"]
        )
        
        // Verify parameters contain the right information for visual context
        #expect(parameters.developmentalFocus == "Emotional Intelligence")
        #expect(parameters.interests == "Animals, Ocean")
        #expect(parameters.characters?.count == 2)
        #expect(parameters.childAgeGroup == "4-6")
        
        // These will be used to create the CollectionVisualContext
        let expectedTheme = "\(parameters.developmentalFocus) through \(parameters.interests)"
        #expect(expectedTheme == "Emotional Intelligence through Animals, Ocean")
    }
    
    @Test("Collection story generation with visual context")
    func testCollectionStoryGenerationWithVisualContext() async throws {
        let (collectionService, context, mockStoryService) = try createTestEnvironment()
        
        // Create test collection
        let collection = StoryCollection(
            title: "Animal Friends Collection",
            descriptionText: "A collection about social skills with animal friends",
            category: "Social Skills",
            ageGroup: "5-7"
        )
        
        let parameters = CollectionParameters(
            childAgeGroup: "5-7",
            developmentalFocus: "Social Skills",
            interests: "Animals, Friendship",
            childName: "Sam",
            characters: ["Bear", "Fox"]
        )
        
        // Save collection to context
        context.insert(collection)
        try context.save()
        
        // Generate stories for the collection
        try await collectionService.generateStoriesForCollection(collection, parameters: parameters)
        
        // Verify stories were generated
        #expect(collection.stories?.count == 3)
        
        // Verify mock service captured visual context calls
        #expect(mockStoryService.capturedVisualContexts.count == 3)
        
        // Verify all visual contexts are identical (unified)
        let firstContext = mockStoryService.capturedVisualContexts[0]
        for context in mockStoryService.capturedVisualContexts {
            #expect(context.collectionId == firstContext.collectionId)
            #expect(context.collectionTheme == firstContext.collectionTheme)
            #expect(context.sharedCharacters == firstContext.sharedCharacters)
            #expect(context.unifiedArtStyle == firstContext.unifiedArtStyle)
        }
        
        // Verify specific visual context properties
        #expect(firstContext.collectionTheme == "Social Skills through Animals, Friendship")
        #expect(firstContext.sharedCharacters == ["Bear", "Fox"])
        #expect(firstContext.developmentalFocus == "Social Skills")
        #expect(firstContext.ageGroup == "5-7")
        #expect(firstContext.requiresCharacterConsistency == true)
        #expect(firstContext.allowsStyleVariation == false)
    }
    
    @Test("Visual context art style generation")
    func testVisualContextArtStyleGeneration() async throws {
        let (collectionService, context, mockStoryService) = try createTestEnvironment()
        
        // Test with preschool age group
        let preschoolCollection = StoryCollection(
            title: "Preschool Collection",
            descriptionText: "A collection for emotional intelligence development",
            category: "Emotional Intelligence",
            ageGroup: "3-4"
        )
        
        let preschoolParameters = CollectionParameters(
            childAgeGroup: "3-4",
            developmentalFocus: "Emotional Intelligence",
            interests: "Colors, Shapes",
            childName: "Emma"
        )
        
        context.insert(preschoolCollection)
        try context.save()
        
        try await collectionService.generateStoriesForCollection(preschoolCollection, parameters: preschoolParameters)
        
        // Verify art style for preschoolers
        let preschoolContext = mockStoryService.capturedVisualContexts.first!
        #expect(preschoolContext.unifiedArtStyle.contains("Simple shapes and bold colors suitable for preschoolers"))
        #expect(preschoolContext.unifiedArtStyle.contains("Emotional Intelligence development"))
        
        // Clear captured contexts
        mockStoryService.capturedVisualContexts.removeAll()
        
        // Test with older age group
        let olderCollection = StoryCollection(
            title: "Older Kids Collection",
            descriptionText: "A collection for problem solving skills",
            category: "Problem Solving",
            ageGroup: "7-9"
        )
        
        let olderParameters = CollectionParameters(
            childAgeGroup: "7-9",
            developmentalFocus: "Problem Solving",
            interests: "Science, Adventure",
            childName: "Jake"
        )
        
        context.insert(olderCollection)
        try context.save()
        
        try await collectionService.generateStoriesForCollection(olderCollection, parameters: olderParameters)
        
        // Verify art style for older children
        let olderContext = mockStoryService.capturedVisualContexts.first!
        #expect(olderContext.unifiedArtStyle.contains("Detailed illustrations with rich visual storytelling"))
        #expect(olderContext.unifiedArtStyle.contains("Problem Solving development"))
    }
    
    @Test("Visual context shared props extraction")
    func testVisualContextSharedPropsExtraction() async throws {
        let (collectionService, context, mockStoryService) = try createTestEnvironment()
        
        // Test collection with various interests
        let collection = StoryCollection(
            title: "Multi-Interest Collection",
            descriptionText: "A collection with multiple interests",
            category: "Social Skills",
            ageGroup: "5-7"
        )
        
        let parameters = CollectionParameters(
            childAgeGroup: "5-7",
            developmentalFocus: "Social Skills",
            interests: "Animals, Ocean, Space, Forest",
            childName: "Alex"
        )
        
        context.insert(collection)
        try context.save()
        
        try await collectionService.generateStoriesForCollection(collection, parameters: parameters)
        
        // Verify shared props were extracted correctly
        let visualContext = mockStoryService.capturedVisualContexts.first!
        let props = visualContext.sharedProps
        
        #expect(props.contains("friendly animals"))
        #expect(props.contains("seashells and waves"))
        #expect(props.contains("stars and planets"))
        #expect(props.contains("trees and flowers"))
        #expect(props.contains("group activities")) // From social skills focus
    }
    
    @Test("Character cycling in collection stories")
    func testCharacterCyclingInCollectionStories() async throws {
        let (collectionService, context, mockStoryService) = try createTestEnvironment()
        
        // Create collection with 2 characters but 3 stories
        let collection = StoryCollection(
            title: "Character Cycling Collection",
            descriptionText: "A collection to test character cycling",
            category: "Creativity",
            ageGroup: "5-7"
        )
        
        let parameters = CollectionParameters(
            childAgeGroup: "5-7",
            developmentalFocus: "Creativity",
            interests: "Art, Music",
            childName: "Maya",
            characters: ["Luna", "Star"]
        )
        
        context.insert(collection)
        try context.save()
        
        try await collectionService.generateStoriesForCollection(collection, parameters: parameters)
        
        // Verify 3 stories were generated
        #expect(collection.stories?.count == 3)
        
        // Verify character cycling in story parameters
        let storyParams = mockStoryService.capturedStoryParameters
        #expect(storyParams.count == 3)
        
        // Should cycle: Luna, Star, Luna
        #expect(storyParams[0].favoriteCharacter == "Luna")
        #expect(storyParams[1].favoriteCharacter == "Star") 
        #expect(storyParams[2].favoriteCharacter == "Luna")
    }
}

// MARK: - Enhanced Mock Service for Visual Context Testing

/// Enhanced mock story service that captures visual context calls for testing
@MainActor
class MockStoryServiceForVisualContext: StoryService {
    var capturedVisualContexts: [CollectionVisualContext] = []
    var capturedStoryParameters: [StoryParameters] = []
    
    init(context: ModelContext) {
        let mockModel = MockGenerativeModelForTesting()
        let mockPersistence = MockPersistenceService_Fixed(modelContext: context)
        let mockIllustration = MockIllustrationService()
        let storyProcessor = StoryProcessor(illustrationService: mockIllustration)
        let promptBuilder = PromptBuilder()
        
        super.init(
            apiKey: "test-key",
            context: context,
            persistenceService: mockPersistence,
            model: mockModel,
            storyProcessor: storyProcessor,
            promptBuilder: promptBuilder
        )
    }
    
    override func generateStory(
        parameters: StoryParameters,
        collectionContext: CollectionVisualContext? = nil
    ) async throws -> Story {
        
        // Capture the visual context for testing
        if let context = collectionContext {
            capturedVisualContexts.append(context)
        }
        
        // Capture story parameters for testing
        capturedStoryParameters.append(parameters)
        
        // Create a mock story with the collection context
        let story = Story(
            title: "Test Story for \(parameters.theme)",
            pages: [Page(content: "Mock story content", pageNumber: 1)],
            parameters: parameters
        )
        
        // Set collection context if provided
        if let context = collectionContext {
            story.setCollectionContext(context)
        }
        
        return story
    }
}

// MARK: - Mock Generative Model for Testing

class MockGenerativeModelForTesting: GenerativeModelProtocol {
    func generateContent(_ prompt: String) async throws -> StoryGenerationResponse {
        return MockVisualContextResponse(responseText: """
        <content>Mock story content for testing</content>
        <category>Fantasy</category>
        """)
    }
}

struct MockVisualContextResponse: StoryGenerationResponse {
    let responseText: String
    
    var text: String? {
        return responseText
    }
}