// magical-storiesTests/Services/PersistenceServiceTests.swift
import XCTest
@testable import magical_stories

final class PersistenceServiceTests: XCTestCase {

    var persistenceService: PersistenceService!
    var testUserDefaults: UserDefaults!
    let testSuiteName = "TestPersistenceService"

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Use a specific UserDefaults suite for testing to avoid conflicts
        testUserDefaults = UserDefaults(suiteName: testSuiteName)
        testUserDefaults.removePersistentDomain(forName: testSuiteName) // Clear previous test data
        persistenceService = PersistenceService(userDefaults: testUserDefaults)
    }

    override func tearDownWithError() throws {
        testUserDefaults.removePersistentDomain(forName: testSuiteName) // Clean up
        testUserDefaults = nil
        persistenceService = nil
        try super.tearDownWithError()
    }

    // Helper function to create a sample story with pages
    private func createSampleStory(id: UUID = UUID(), title: String = "Sample Story", includeIllustration: Bool = true) -> Story {
        let page1 = Page(content: "Page 1 content.", pageNumber: 1, illustrationRelativePath: includeIllustration ? "Illustrations/page1.png" : nil, illustrationStatus: includeIllustration ? .success : .failed, imagePrompt: includeIllustration ? "Prompt 1" : nil)
        let page2 = Page(content: "Page 2 content.", pageNumber: 2, illustrationRelativePath: includeIllustration ? "Illustrations/page2.png" : nil, illustrationStatus: includeIllustration ? .success : .failed, imagePrompt: includeIllustration ? "Prompt 2" : nil)
        let params = StoryParameters(childName: "Test", childAge: 5, theme: "Testing", favoriteCharacter: "Bot")
        return Story(id: id, title: title, pages: [page1, page2], parameters: params, timestamp: Date())
    }

    func testSaveAndLoadSingleStory() throws {
        // Given
        let story = createSampleStory()

        // When
        try persistenceService.saveStory(story)
        let loadedStories = try persistenceService.loadStories()

        // Then
        XCTAssertEqual(loadedStories.count, 1)
        let loadedStory = try XCTUnwrap(loadedStories.first) // Ensure one story is loaded
        XCTAssertEqual(loadedStory.id, story.id)
        XCTAssertEqual(loadedStory.title, story.title)
        XCTAssertEqual(loadedStory.pages.count, story.pages.count)
        XCTAssertEqual(loadedStory.pages[0].content, story.pages[0].content)
        XCTAssertEqual(loadedStory.pages[0].illustrationRelativePath, story.pages[0].illustrationRelativePath)
        XCTAssertEqual(loadedStory.pages[0].illustrationStatus, story.pages[0].illustrationStatus)
        XCTAssertEqual(loadedStory.pages[0].imagePrompt, story.pages[0].imagePrompt)
        XCTAssertEqual(loadedStory.pages[1].illustrationRelativePath, story.pages[1].illustrationRelativePath)
        XCTAssertEqual(loadedStory.pages[1].illustrationStatus, story.pages[1].illustrationStatus)
    }

    func testSaveAndLoadMultipleStories() throws {
        // Given
        let story1 = createSampleStory(title: "Story One")
        let story2 = createSampleStory(title: "Story Two", includeIllustration: false) // One with, one without illustration

        // When
        try persistenceService.saveStories([story1, story2])
        let loadedStories = try persistenceService.loadStories()

        // Then
        XCTAssertEqual(loadedStories.count, 2)
        // Stories should be sorted by timestamp (newest first), assuming story2 was created slightly after story1
        let loadedStory1 = try XCTUnwrap(loadedStories.first(where: { $0.id == story1.id }))
        let loadedStory2 = try XCTUnwrap(loadedStories.first(where: { $0.id == story2.id }))

        XCTAssertEqual(loadedStory1.pages.count, 2)
        XCTAssertNotNil(loadedStory1.pages[0].illustrationRelativePath)
        XCTAssertEqual(loadedStory2.pages.count, 2)
        XCTAssertNil(loadedStory2.pages[0].illustrationRelativePath) // Verify nil path is handled
    }

    func testLoadEmptyStories() throws {
        // Given: No stories saved

        // When
        let loadedStories = try persistenceService.loadStories()

        // Then
        XCTAssertTrue(loadedStories.isEmpty)
    }

    func testUpdateExistingStory() throws {
        // Given
        let originalStory = createSampleStory(title: "Original Title")
        try persistenceService.saveStory(originalStory)

        // When
        var modifiedStory = originalStory
        modifiedStory.title = "Updated Title"
        modifiedStory.pages[0].illustrationRelativePath = "Illustrations/updated_image.png"
        modifiedStory.pages[0].illustrationStatus = .success
        try persistenceService.saveStory(modifiedStory) // Save the modified story with the same ID

        // Then
        let loadedStories = try persistenceService.loadStories()
        XCTAssertEqual(loadedStories.count, 1)
        let loadedStory = try XCTUnwrap(loadedStories.first)
        XCTAssertEqual(loadedStory.id, originalStory.id)
        XCTAssertEqual(loadedStory.title, "Updated Title")
        XCTAssertEqual(loadedStory.pages[0].illustrationRelativePath, "Illustrations/updated_image.png")
    }

    func testDeleteStory() throws {
        // Given
        let story1 = createSampleStory(title: "To Keep")
        let storyToDelete = createSampleStory(title: "To Delete")
        try persistenceService.saveStories([story1, storyToDelete])

        // When
        try persistenceService.deleteStory(withId: storyToDelete.id)

        // Then
        let loadedStories = try persistenceService.loadStories()
        XCTAssertEqual(loadedStories.count, 1)
        XCTAssertEqual(loadedStories.first?.id, story1.id)
        XCTAssertEqual(loadedStories.first?.title, "To Keep")
    }

    // Test potential decoding failure (e.g., if data is corrupted)
    func testDecodingFailure() throws {
        // Given: Corrupted data saved under the key
        let corruptedData = Data("this is not valid json".utf8)
        testUserDefaults.set(corruptedData, forKey: "savedStories") // Use the key directly

        // When & Then
        // Use XCTAssertThrowsError for specific error checking
        XCTAssertThrowsError(try persistenceService.loadStories()) { error in
            guard let persistenceError = error as? PersistenceError else {
                XCTFail("Expected PersistenceError but got \(type(of: error))")
                return
            }
            guard case .decodingFailed = persistenceError else {
                XCTFail("Expected .decodingFailed but got \(persistenceError)")
                return
            }
            // Test passed if correct error is thrown
        }
    }
}