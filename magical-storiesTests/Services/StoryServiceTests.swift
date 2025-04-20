import SwiftData
import Testing
import XCTest

@testable import magical_stories

// MARK: - Mocks

class MockStoryProcessor: StoryProcessor {
    override func processIntoPages(
        _ content: String,
        theme _: String
    ) async throws -> [Page] {
        return [Page(content: content, pageNumber: 1)]
    }
}

// MARK: - Tests

struct StoryServiceTests {
    var storyService: StoryService!
    var mockModel: MockGenerativeModel!
    var mockProcessor: MockStoryProcessor!
    var context: ModelContext!

    @Test("Test generate story for young child")
    func testGenerateStoryForYoungChild() async throws {
        // Given
        let parameters = StoryParameters(
            childName: "Emma",
            childAge: 4,
            theme: "Friendship",
            favoriteCharacter: "Bunny"
        )

        mockModel.generatedText = """
            Title: Emma and Bunny's Special Day
            Once upon a time, Emma met a fluffy bunny in the garden...
            """

        // When
        let story = try await storyService.generateStory(parameters: parameters)

        // Then
        let prompt = mockModel.lastPrompt!
        #expect(prompt.contains("Use simple, concrete words"))
        #expect(prompt.contains("Create a linear story"))
        #expect(story.title == "Emma and Bunny's Special Day")
        #expect(story.pages.count == 1)
        #expect(story.parameters.childAge == 4)
    }

    @Test("Test generate story for intermediate child")
    func testGenerateStoryForIntermediateChild() async throws {
        // Given
        let parameters = StoryParameters(
            childName: "Alex",
            childAge: 6,
            theme: "Adventure",
            favoriteCharacter: "Dragon",
            developmentalFocus: [.kindnessEmpathy]
        )

        mockModel.generatedText = """
            Title: Alex's Dragon Adventure
            Alex and their brave dragon friend soared through the clouds...
            """

        // When
        let story = try await storyService.generateStory(parameters: parameters)

        // Then
        let prompt = mockModel.lastPrompt!
        #expect(prompt.contains("Use a mix of familiar and new vocabulary"))
        #expect(prompt.contains("Include minor subplots"))
        #expect(story.title == "Alex's Dragon Adventure")
        #expect(
            story.parameters.developmentalFocus?
                .contains(.kindnessEmpathy) == true)
    }

    @Test("Test generate story for advanced child")
    func testGenerateStoryForAdvancedChild() async throws {
        // Given
        let parameters = StoryParameters(
            childName: "Maya",
            childAge: 8,
            theme: "Mystery",
            favoriteCharacter: "Detective Cat",
            emotionalThemes: ["curiosity"]
        )

        mockModel.generatedText = """
            Title: Maya and Detective Cat's Mystery
            The old clock tower held many secrets...
            """

        // When
        let story = try await storyService.generateStory(parameters: parameters)

        // Then
        let prompt = mockModel.lastPrompt!
        #expect(prompt.contains("Use rich vocabulary"))
        #expect(prompt.contains("Develop multiple story layers"))
        #expect(story.title == "Maya and Detective Cat's Mystery")
        #expect(story.parameters.emotionalThemes?.contains("curiosity") == true)
    }

    @Test("Test generate story with invalid parameters")
    func testGenerateStoryWithInvalidParameters() async {
        // Given
        let parameters = StoryParameters(
            childName: "",  // Empty name should trigger error
            childAge: 5,
            theme: "Adventure",
            favoriteCharacter: "Dragon"
        )

        // When/Then
        do {
            _ = try await storyService.generateStory(parameters: parameters)
            XCTFail("Should have thrown invalid parameters error")
        } catch {
            guard let storyError = error as? StoryServiceError else {
                XCTFail("Unexpected error type")
                return
            }
            #expect(storyError == .invalidParameters)
        }
    }

    @Test("Test generate story with network error")
    func testGenerateStoryWithNetworkError() async {
        // Given
        let parameters = StoryParameters(
            childName: "Pat",
            childAge: 7,
            theme: "Space",
            favoriteCharacter: "Star"
        )

        mockModel.error = NSError(domain: "NetworkError", code: -1)

        // When/Then
        do {
            _ = try await storyService.generateStory(parameters: parameters)
            XCTFail("Should have thrown network error")
        } catch {
            guard let storyError = error as? StoryServiceError else {
                XCTFail("Unexpected error type")
                return
            }
            #expect(storyError == .networkError)
        }
    }

    @Test("Test load stories")
    func testLoadStories() async throws {
        // Given
        let parameters = StoryParameters(
            childName: "Test",
            childAge: 5,
            theme: "Test",
            favoriteCharacter: "Test"
        )

        mockModel.generatedText = "Title: Test Story\nTest content"

        // When
        let story = try await storyService.generateStory(parameters: parameters)
        await storyService.loadStories()

        // Then
        await #expect(!storyService.stories.isEmpty)
        await #expect(storyService.stories.contains { $0.id == story.id })
    }
}
