import XCTest
@testable import magical_stories
import Foundation

// Use XCTestCase class structure
@MainActor // Mark class as MainActor since StoryService is MainActor
class StoryServiceTests: XCTestCase {

    // Declare instance variables for the class
    var storyService: StoryService!
    var mockPersistenceService: MockPersistenceService!
    var storyProcessor: StoryProcessor!
    var illustrationService: IllustrationService!

    // Use setUpWithError for initialization
    override func setUpWithError() throws {
        try super.setUpWithError() // Call super

        mockPersistenceService = MockPersistenceService()

        // Initialize IllustrationService, handling potential throw
        // Ensure API key setup is appropriate for the test environment
        // Using a placeholder key.
        illustrationService = try IllustrationService(apiKey: "mock_illustration_key_setup")
        storyProcessor = StoryProcessor(illustrationService: illustrationService)

        // Initialize StoryService, handling its throw and injecting dependencies
        // Ensure this call matches the signature in StoryService.swift exactly
        storyService = try StoryService(
            apiKey: "mock_text_gen_key_setup",
            persistenceService: mockPersistenceService,
            model: nil, // Explicitly pass nil if not mocking the text model here
            storyProcessor: storyProcessor // Inject the processor
        )
    }

    // Teardown method (optional but good practice)
    override func tearDownWithError() throws {
        storyService = nil
        mockPersistenceService = nil
        storyProcessor = nil
        illustrationService = nil
        try super.tearDownWithError()
    }

    // --- Test Methods ---

    func testStoryGenerationWithValidParameters() async throws {
        // Given
        let parameters = StoryParameters(
            childName: "Alex",
            childAge: 6,
            theme: "adventure",
            favoriteCharacter: "🦁"
        )

        // When
        let story = try await storyService.generateStory(parameters: parameters)

        // Then
        XCTAssertEqual(story.parameters.childName, "Alex")
        XCTAssertEqual(story.parameters.childAge, 6)
        XCTAssertEqual(story.parameters.favoriteCharacter, "🦁")
        XCTAssertEqual(story.parameters.theme, "adventure")
        XCTAssertFalse(story.title.isEmpty)
        XCTAssertFalse(story.pages.isEmpty, "Generated story should have pages")
    }

    func testStoryGenerationWithEmptyChildName() async throws {
        // Given
        let parameters = StoryParameters(
            childName: "",
            childAge: 6,
            theme: "adventure",
            favoriteCharacter: "🦁"
        )

        // When/Then
        do {
            _ = try await storyService.generateStory(parameters: parameters)
            XCTFail("Expected error for empty child name, but no error was thrown.")
        } catch let error as StoryServiceError {
             XCTAssertEqual(error, .invalidParameters, "Incorrect error type thrown for empty child name.")
        } catch {
            XCTFail("Unexpected error type thrown: \(error)")
        }
    }

    func testLoadStoriesSorting() async throws {
        // Given
        let oldParameters = StoryParameters(childName: "Old Alex", childAge: 5, theme: "old theme", favoriteCharacter: "🦖")
        let oldStory = Story(
            title: "Old Story",
            pages: [Page(content: "Old content page 1", pageNumber: 1)],
            parameters: oldParameters,
            timestamp: Date().addingTimeInterval(-86400) // 1 day ago
        )

        let newParameters = StoryParameters(childName: "New Alex", childAge: 7, theme: "new theme", favoriteCharacter: "🚀")
        let newStory = Story(
            title: "New Story",
            pages: [Page(content: "New content page 1", pageNumber: 1)],
            parameters: newParameters,
            timestamp: Date() // Now
        )

        // Save stories directly to the mock service
        try mockPersistenceService.saveStory(oldStory)
        try mockPersistenceService.saveStory(newStory)

        // When: StoryService loads stories
        await storyService.loadStories()

        // Then: Check the stories loaded and sorted by the StoryService
        let stories = storyService.stories
        XCTAssertEqual(stories.count, 2, "Expected two stories to be loaded.")
        XCTAssertEqual(stories.first?.title, "New Story", "Expected newest story first.")
        XCTAssertEqual(stories.last?.title, "Old Story", "Expected oldest story last.")
    }

    // New test case to verify the decoding fix after generation and saving
    func testGenerateAndLoadStoryFixesDecodingError() async throws {
        // Given: Valid parameters
        let parameters = StoryParameters(
            childName: "Charlie",
            childAge: 7,
            theme: "kindness",
            favoriteCharacter: "🦄"
        )

        // When: Generate a story using the service instance from setUp
        let generatedStory = try await storyService.generateStory(parameters: parameters)
        // This implicitly saves the story to mockPersistenceService

        // And When: Simulate loading stories *as if the app restarted*
        // Create a *new* StoryService instance using the *same* mock persistence service
        let newStoryServiceInstance = try StoryService(
             apiKey: "mock_text_gen_key_reload",
             persistenceService: mockPersistenceService, // Use the SAME mock service
             model: nil, // Explicitly pass nil
             storyProcessor: storyProcessor // Inject the same processor
        )
        // Trigger loading in the new instance
        await newStoryServiceInstance.loadStories()

        // Then: Assert loading didn't throw & the loaded story is correct
        let loadedStories = newStoryServiceInstance.stories
        XCTAssertEqual(loadedStories.count, 1, "Expected one story to be loaded after generation and reload.")
        guard let loadedStory = loadedStories.first else {
            XCTFail("Failed to retrieve the loaded story from the new service instance.")
            return
        }

        // Verify key properties and that pages exist
        XCTAssertEqual(loadedStory.id, generatedStory.id, "Loaded story ID mismatch.")
        XCTAssertEqual(loadedStory.title, generatedStory.title, "Loaded story title mismatch.")
        XCTAssertEqual(loadedStory.parameters, generatedStory.parameters, "Loaded story parameters mismatch.")
        XCTAssertFalse(loadedStory.pages.isEmpty, "Loaded story should have pages after decoding.")

        // Optional: Deeper check on page content
        if let firstPage = loadedStory.pages.first {
             XCTAssertTrue(firstPage.content.contains("Once upon a time"), "Page content mismatch after decoding.")
             XCTAssertTrue(firstPage.content.contains(parameters.childName), "Child name mismatch in page content after decoding.")
             XCTAssertEqual(firstPage.pageNumber, 1, "First page number should be 1.")
        }
    }
} // End of class StoryServiceTests

// MARK: - Mock Persistence Service (Keep this definition in the file)
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
        // Simulate the encoding/decoding cycle to catch the error if it still exists
        // This is crucial for the testGenerateAndLoadStoryFixesDecodingError test
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        do {
            let data = try encoder.encode(stories)
            let decodedStories = try decoder.decode([Story].self, from: data)
            return decodedStories // Return the decoded stories to mimic real loading
        } catch {
            // If encoding/decoding fails here, the test will catch it
            print("MockPersistenceService: Error during encode/decode simulation: \(error)")
            throw PersistenceError.decodingFailed(error) // Propagate as decoding error
        }
    }

    func deleteStory(withId id: UUID) throws {
        stories.removeAll { $0.id == id }
    }

    // Optional: Keep deleteAllStories if needed for tests
    func deleteAllStories() throws {
         stories.removeAll()
    }
}
