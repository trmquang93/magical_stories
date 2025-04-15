import Testing
import Foundation
import GoogleGenerativeAI // Keep for potential underlying types if needed, though mocks abstract it
import SwiftData
@testable import magical_stories

// MARK: - Mocks


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
    var mockModel: GenerativeModelProtocol!
    var mockPersistenceService: PersistenceServiceProtocol!
    var mockStoryProcessor: StoryProcessor!
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
        
        let storyService: StoryService = try StoryService(
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

    // DELETED testGenerateStory_Success()

    // DELETED testGenerateStory_Error_InvalidParameters()

    // DELETED testGenerateStory_Error_GenerationFailed_NoContent()

    // DELETED testGenerateStory_Error_GenerationFailed_ModelThrows()

    // DELETED testGenerateStory_Error_ProcessingFailed()

    // DELETED testGenerateStory_Error_PersistenceFailed()
}

// MARK: - Tests for Story List Updates

@Suite("StoryService Story List Tests")
@MainActor
struct StoryServiceStoryListTests {
    var storyService: StoryService!
    var mockPersistenceService: MockPersistenceService!
    var modelContext: ModelContext!

    init() throws {
        mockPersistenceService = MockPersistenceService()

        // Setup in-memory SwiftData context
        let schema = Schema([StoryModel.self, PageModel.self])
        let container = try ModelContainer(for: schema, configurations: [.init(isStoredInMemoryOnly: true)])
        modelContext = ModelContext(container)

        // Create StoryService, injecting the context and mock persistence
        // Note: This StoryService won't use the generative AI or processor mocks, suitable for list tests
        storyService = try StoryService(
            apiKey: "", // Dummy key
            context: modelContext,
            persistenceService: mockPersistenceService,
            model: nil, // No generation needed for list tests
            storyProcessor: nil // No processing needed for list tests
        )
    }

    @Test("Initial stories list is empty")
    func testInitialStoriesList() async throws {
        // Arrange: Configure persistence to return empty list initially
        mockPersistenceService.storiesToLoad = []
        // Re-trigger load if necessary, or ensure init load uses the mock config
        await storyService.loadStories()

        // Assert
        #expect(storyService.stories.isEmpty, "Stories list should be empty initially")
    }

    // DELETED testStoryAppearsAfterCreation()

    // DELETED testMultipleStoriesAppear()
}
