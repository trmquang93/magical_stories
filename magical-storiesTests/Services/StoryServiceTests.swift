import Testing
import Foundation
import GoogleGenerativeAI // Keep for potential underlying types if needed, though mocks abstract it
import SwiftData
@testable import magical_stories

// MARK: - Mocks

// Mock for local StoryGenerationResponse protocol
struct MockStoryGenerationResponse: StoryGenerationResponse {
    var text: String?
}

// Mock for local GenerativeModelProtocol (defined in StoryService.swift)
class MockGenerativeModel: GenerativeModelProtocol {
    var generateContentCalled = false
    var generateContentPrompt: String?
    var generateContentResult: Result<StoryGenerationResponse, Error>? // Use local protocol

    func generateContent(_ prompt: String) async throws -> StoryGenerationResponse { // Return local protocol type
        generateContentCalled = true
        generateContentPrompt = prompt
        switch generateContentResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        case .none:
            throw StoryServiceError.networkError // Default error for unconfigured mock
        }
    }
}

// Mock for PersistenceServiceProtocol (defined in ServiceProtocols.swift)
class MockPersistenceService: PersistenceServiceProtocol {
    var saveStoryCalled = false
    var loadStoriesCalled = false
    var deleteStoryCalled = false
    var saveStoriesCalled = false // Added

    var storyToSave: Story?
    var storiesToSave: [Story]? // Added
    var storyIdToDelete: UUID? // Added

    var saveStoryError: Error?
    var loadStoriesError: Error?
    var deleteStoryError: Error?
    var saveStoriesError: Error? // Added

    var storiesToLoad: [Story] = []

    // Corrected: synchronous throws
    func saveStory(_ story: Story) throws {
        saveStoryCalled = true
        storyToSave = story
        if let error = saveStoryError {
            throw error
        }
        // Simulate saving by adding to the list used by loadStories
        storiesToLoad.append(story)
    }

    // Corrected: synchronous throws
    func loadStories() throws -> [Story] {
        loadStoriesCalled = true
        if let error = loadStoriesError {
            throw error
        }
        return storiesToLoad
    }

    // Added required method
    func saveStories(_ stories: [Story]) throws {
        saveStoriesCalled = true
        storiesToSave = stories
        if let error = saveStoriesError {
            throw error
        }
    }

    // Added required method
    func deleteStory(withId id: UUID) throws {
        deleteStoryCalled = true
        storyIdToDelete = id
        if let error = deleteStoryError {
            throw error
        }
    }
}

// Mock for IllustrationServiceProtocol is likely defined elsewhere (e.g., IllustrationServiceTests.swift)
// Assuming it's available in the test target, we remove the duplicate definition here.

// Mock for StoryProcessor (inherits from StoryProcessor to access its structure if needed, but overrides the key method)
// Note: If StoryProcessor init is complex or final, this might need adjustment.
// Assuming StoryProcessor has an accessible initializer taking IllustrationServiceProtocol.
class MockStoryProcessor: StoryProcessor {
    var processIntoPagesCalled = false
    var processContent: String?
    var processTheme: String? // Theme is String
    var processResult: Result<[Page], Error>? // Return type is [Page]

    // Keep track of the illustration service passed
    let receivedIllustrationService: IllustrationServiceProtocol

    // Override init to accept the protocol and call super if necessary/possible
    // If StoryProcessor's init is throwing or complex, adjust this.
    // Assuming a simple init for the base class for mocking purposes.
    override init(illustrationService: IllustrationServiceProtocol) { // Added override
         self.receivedIllustrationService = illustrationService
         // Attempt to call super.init. If IllustrationService() throws, this mock setup needs refinement.
         // For isolated unit testing of StoryService, we might not need a fully functional super.init().
         // Let's assume we can bypass the super.init complexity for this mock's purpose,
         // as we only care about overriding processIntoPages.
         // Call the superclass initializer as required.
         super.init(illustrationService: illustrationService)
    }


    // Corrected signature: async throws -> [Page], theme is String
     override func processIntoPages(_ content: String, theme: String) async throws -> [Page] { // Added override
        processIntoPagesCalled = true
        processContent = content
        processTheme = theme
        switch processResult {
        case .success(let pages):
            return pages
        case .failure(let error):
            throw error
        case .none:
             throw StoryServiceError.generationFailed("MockStoryProcessor not configured") // Default error
        }
    }
}


// MARK: - Test Suite

@Suite("StoryService Tests")
struct StoryServiceTests {

    var storyService: StoryService!
    var mockModel: MockGenerativeModel!
    var mockPersistenceService: MockPersistenceService!
    var mockStoryProcessor: MockStoryProcessor!
    var mockIllustrationService: MockIllustrationService! // Assuming MockIllustrationService is defined elsewhere

    @MainActor // Ensure tests run on the main actor as StoryService is @MainActor
    init() throws { // Mark init as throwing because StoryService init can throw
        mockModel = MockGenerativeModel()
        mockPersistenceService = MockPersistenceService()
        mockIllustrationService = MockIllustrationService() // Instantiate mock
        // Pass mock illustration service to mock story processor
        mockStoryProcessor = MockStoryProcessor(illustrationService: mockIllustrationService)

        // Initialize StoryService correctly, injecting mocks
        // Use the initializer that allows injecting model and storyProcessor
        // We pass empty for apiKey as the mockModel bypasses the actual GenerativeModelWrapper
        // Create an in-memory model context for testing
        let schema = Schema([StoryModel.self, PageModel.self])
        let container = try ModelContainer(for: schema, configurations: [.init(isStoredInMemoryOnly: true)])
        let testContext = ModelContext(container)
        
        storyService = try StoryService(
            apiKey: "", // Not used by mockModel
            context: testContext,
            persistenceService: mockPersistenceService, // Correct injection
            model: mockModel,                          // Correct injection
            storyProcessor: mockStoryProcessor         // Correct injection
        )
        // Initial loadStories happens within StoryService init's Task,
        // so configure mockPersistenceService *before* initializing storyService if needed for init tests.
        // For generateStory tests, configure mocks within each test case.
    }

    @Test("Generate Story - Success")
    @MainActor
    func testGenerateStory_Success() async throws {
        // Arrange
        let parameters = StoryParameters( // Correct parameters
            childName: "Alex",
            childAge: 5,
            theme: "space adventure", // Correct type (String)
            favoriteCharacter: "rocket"
        )
        // let expectedPrompt = "..." // Prompt check is brittle, skip for now

        let generatedText = """
        Title: Alex's Rocket Ride

        Once upon a time, Alex the astronaut... (page 1 content)
        --- Page Break ---
        They flew past the moon... (page 2 content)
        """
        let extractedTitle = "Alex's Rocket Ride"
        let extractedContent = """
        Once upon a time, Alex the astronaut... (page 1 content)
        --- Page Break ---
        They flew past the moon... (page 2 content)
        """
        let processedPages = [ // Use Page model
            Page(content: "Once upon a time, Alex the astronaut... (page 1 content)", pageNumber: 1, imagePrompt: "astronaut"),
            Page(content: "They flew past the moon... (page 2 content)", pageNumber: 2, imagePrompt: "moon")
        ]
        let expectedStory = Story( // Use Page model
            title: extractedTitle,
            pages: processedPages,
            parameters: parameters
        )

        // Configure Mocks for Success
        mockModel.generateContentResult = .success(MockStoryGenerationResponse(text: generatedText))
        mockStoryProcessor.processResult = .success(processedPages)
        // Simulate loadStories returning the newly saved story later
        mockPersistenceService.storiesToLoad = [] // Initially empty
        // When load is called *after* save, it should find the story
        // We can refine this by checking the state *after* the call


        // Act
        #expect(!storyService.isGenerating, "isGenerating should be false initially")
        let generatedStory = try await storyService.generateStory(parameters: parameters) // No theme argument
        #expect(!storyService.isGenerating, "isGenerating should be false after completion")

        // Assert
        #expect(mockModel.generateContentCalled, "generateContent should be called")
        // #expect(mockModel.generateContentPrompt == expectedPrompt) // Optional: check parts of prompt if needed
        #expect(mockStoryProcessor.processIntoPagesCalled, "processIntoPages should be called")
        #expect(mockStoryProcessor.processContent == extractedContent, "processIntoPages content mismatch")
        #expect(mockStoryProcessor.processTheme == parameters.theme, "processIntoPages theme mismatch")
        #expect(mockPersistenceService.saveStoryCalled, "saveStory should be called")
        #expect(mockPersistenceService.storyToSave?.title == expectedStory.title, "Saved story title mismatch")
        #expect(mockPersistenceService.storyToSave?.pages.count == expectedStory.pages.count, "Saved story page count mismatch")
        #expect(mockPersistenceService.loadStoriesCalled, "loadStories should be called after generation") // Verify this happens in generateStory

        #expect(generatedStory.title == expectedStory.title, "Returned story title mismatch")
        #expect(generatedStory.pages.count == expectedStory.pages.count, "Returned story page count mismatch")
        #expect(generatedStory.parameters == parameters, "Returned story parameters mismatch")

        // Verify stories array is updated (assuming loadStories updates it)
        // Need to wait briefly for the Task in loadStories to potentially complete
        try await Task.sleep(nanoseconds: 10_000_000) // Small delay for async load
         #expect(storyService.stories.contains(where: { $0.id == generatedStory.id }), "Generated story should be in the stories array")
    }

    @Test("Generate Story - Error: Invalid Parameters (Empty Name)")
    @MainActor
    func testGenerateStory_Error_InvalidParameters() async throws {
        // Arrange
        let invalidParameters = StoryParameters( // Correct parameters
            childName: "", // Invalid
            childAge: 5,
            theme: "space adventure",
            favoriteCharacter: "rocket"
        )

        // Act & Assert
        // Correct #expect(throws:) syntax for specific error instance
        await #expect(throws: StoryServiceError.invalidParameters) {
            _ = try await storyService.generateStory(parameters: invalidParameters) // No theme argument
        }

        #expect(!mockModel.generateContentCalled, "generateContent should not be called on invalid params")
        #expect(!mockStoryProcessor.processIntoPagesCalled, "processIntoPages should not be called on invalid params")
        #expect(!mockPersistenceService.saveStoryCalled, "saveStory should not be called on invalid params")
    }

    @Test("Generate Story - Error: Generation Failed (No Content)")
    @MainActor
    func testGenerateStory_Error_GenerationFailed_NoContent() async throws {
        // Arrange
        let parameters = StoryParameters(childName: "Alex", childAge: 5, theme: "topic", favoriteCharacter: "char")
        mockModel.generateContentResult = .success(MockStoryGenerationResponse(text: nil)) // Simulate no text

        // Act & Assert
        #expect(storyService.isGenerating == false)
        // Correct #expect(throws:) syntax with performing and throws closures
        await #expect(
            performing: { // Code that throws
                _ = try await storyService.generateStory(parameters: parameters)
            },
            throws: { error in // Closure to validate the error
                guard case .generationFailed(let message) = error as? StoryServiceError else {
                    // Error type mismatch, test should fail here naturally.
                    return false
                }
                #expect(message.contains("No content generated")) // Check the associated message
                return true // Error matches expectations
            }
        )
        #expect(storyService.isGenerating == false)

        #expect(mockModel.generateContentCalled)
        #expect(!mockStoryProcessor.processIntoPagesCalled)
        #expect(!mockPersistenceService.saveStoryCalled)
    }

    @Test("Generate Story - Error: Generation Failed (Model Throws Network Error)")
    @MainActor
    func testGenerateStory_Error_GenerationFailed_ModelThrows() async throws {
        // Arrange
        let parameters = StoryParameters(childName: "Alex", childAge: 5, theme: "topic", favoriteCharacter: "char")
        mockModel.generateContentResult = .failure(StoryServiceError.networkError) // Simulate network error

        // Act & Assert
        #expect(storyService.isGenerating == false)
        // Correct #expect(throws:) syntax for specific error instance
        await #expect(throws: StoryServiceError.networkError) {
            _ = try await storyService.generateStory(parameters: parameters)
        }
        #expect(storyService.isGenerating == false)

        #expect(mockModel.generateContentCalled)
        #expect(!mockStoryProcessor.processIntoPagesCalled)
        #expect(!mockPersistenceService.saveStoryCalled)
    }

     @Test("Generate Story - Error: Processing Failed")
     @MainActor
     func testGenerateStory_Error_ProcessingFailed() async throws {
         // Arrange
         let parameters = StoryParameters(childName: "Alex", childAge: 5, theme: "topic", favoriteCharacter: "char")
         let generatedText = """
         Title: Test Title

         Some content
         """
         mockModel.generateContentResult = .success(MockStoryGenerationResponse(text: generatedText))
         // Simulate processing error (using generationFailed as per StoryService logic)
         let processingError = StoryServiceError.generationFailed("Processing mock error")
         mockStoryProcessor.processResult = .failure(processingError)

         // Act & Assert
         #expect(storyService.isGenerating == false)
         // Correct #expect(throws:) syntax with performing and throws closures
         await #expect(
             performing: { // Code that throws
                 _ = try await storyService.generateStory(parameters: parameters)
             },
             throws: { error in // Closure to validate the error
                 guard case .generationFailed(let message) = error as? StoryServiceError else {
                     // Error type mismatch, test should fail here naturally.
                     return false
                 }
                 #expect(message == "Processing mock error") // Check it's the error from the processor
                 return true // Error matches expectations
             }
         )
         #expect(storyService.isGenerating == false)

         #expect(mockModel.generateContentCalled)
         #expect(mockStoryProcessor.processIntoPagesCalled)
         #expect(!mockPersistenceService.saveStoryCalled)
     }

     @Test("Generate Story - Error: Persistence Failed")
     @MainActor
     func testGenerateStory_Error_PersistenceFailed() async throws {
         // Arrange
         let parameters = StoryParameters(childName: "Alex", childAge: 5, theme: "topic", favoriteCharacter: "char")
         let generatedText = """
         Title: Test Title

         Content page 1
         """
         let processedPages = [Page(content: "Content page 1", pageNumber: 1)]
         mockModel.generateContentResult = .success(MockStoryGenerationResponse(text: generatedText))
         mockStoryProcessor.processResult = .success(processedPages)
         mockPersistenceService.saveStoryError = StoryServiceError.persistenceFailed // Simulate persistence error

         // Act & Assert
         mockPersistenceService.loadStoriesCalled = false // Reset flag to ignore init load
         #expect(storyService.isGenerating == false)
         // Correct #expect(throws:) syntax for specific error instance
         await #expect(throws: StoryServiceError.persistenceFailed) {
             _ = try await storyService.generateStory(parameters: parameters)
         }
         #expect(storyService.isGenerating == false)

         #expect(mockModel.generateContentCalled)
         #expect(mockStoryProcessor.processIntoPagesCalled)
         #expect(mockPersistenceService.saveStoryCalled)
         // loadStories is called within generateStory *after* saveStory. If saveStory throws,
         // the catch block in generateStory is hit, and loadStories might not be reached.
         #expect(!mockPersistenceService.loadStoriesCalled, "loadStories should not be called if save fails")
     }
}
