import SwiftData
// magical-storiesTests/Services/StoryRepositoryTests.swift
import XCTest

@testable import magical_stories

@MainActor
final class StoryRepositoryTests: XCTestCase {

    var storyRepository: StoryRepository!
    var achievementRepository: AchievementRepository!  // Needed for relationship tests
    var modelContext: ModelContext!
    var modelContainer: ModelContainer!  // Keep reference for potential context needs

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Create an in-memory SwiftData model container for testing
        // Include ALL models involved in the tests
        let schema = Schema([Story.self, Page.self, AchievementModel.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)

        storyRepository = StoryRepository(modelContext: modelContext)
        achievementRepository = AchievementRepository(modelContext: modelContext)  // Initialize Achievement repo too
    }

    override func tearDownWithError() throws {
        storyRepository = nil
        achievementRepository = nil
        modelContext = nil
        modelContainer = nil  // Release container
        try super.tearDownWithError()
    }

    // Helper function to create a sample story domain object
    private func createSampleDomainStory(
        id: UUID = UUID(), title: String = "Sample Story", pagesCount: Int = 2
    ) -> Story {
        var pages = [Page]()
        for i in 1...pagesCount {
            pages.append(
                Page(
                    content: "Page \(i) content.", pageNumber: i,
                    illustrationPath: "Illustrations/page\(i).png",
                    illustrationStatus: .ready, imagePrompt: "Prompt \(i)"))
        }
        let params = StoryParameters(
            childName: "Test", childAge: 5, theme: "Testing", favoriteCharacter: "Bot")
        return Story(id: id, title: title, pages: pages, parameters: params, timestamp: Date())
    }

    // Helper function to create a sample achievement model
    private func createSampleAchievementModel(
        name: String = "Test Achievement", type: AchievementType = .storiesCompleted,
        story: Story? = nil
    ) -> AchievementModel {
        return AchievementModel(name: name, type: type, story: story)
    }

    // --- Adapted Tests ---

    func testSaveAndLoadSingleStory() async throws {
        // Given
        let story = createSampleDomainStory()

        // When
        _ = try await storyRepository.saveStory(story)
        let loadedModels = try await storyRepository.fetchAllStories()

        // Then
        XCTAssertEqual(loadedModels.count, 1)
        let loadedModel = try XCTUnwrap(loadedModels.first)
        XCTAssertEqual(loadedModel.id, story.id)
        XCTAssertEqual(loadedModel.title, story.title)
        XCTAssertEqual(loadedModel.pages.count, story.pages.count)
        XCTAssertEqual(
            loadedModel.pages.sorted { $0.pageNumber < $1.pageNumber }[0].content,
            story.pages[0].content)
        XCTAssertEqual(loadedModel.readCount, 0)  // Verify new field default
        XCTAssertFalse(loadedModel.isFavorite)  // Verify new field default
        XCTAssertNil(loadedModel.lastReadAt)  // Verify new field default
        XCTAssertTrue(loadedModel.achievements.isEmpty)  // Verify new relationship default
    }

    func testSaveAndLoadMultipleStories() async throws {
        // Given
        let story1 = createSampleDomainStory(title: "Story One")
        let story2 = createSampleDomainStory(title: "Story Two")

        // When
        _ = try await storyRepository.saveStories([story1, story2])  // Use repository method
        let loadedModels = try await storyRepository.fetchAllStories()

        // Then
        XCTAssertEqual(loadedModels.count, 2)
        let loadedStory1 = try XCTUnwrap(loadedModels.first(where: { $0.id == story1.id }))
        let loadedStory2 = try XCTUnwrap(loadedModels.first(where: { $0.id == story2.id }))

        XCTAssertEqual(loadedStory1.pages.count, 2)
        XCTAssertEqual(loadedStory2.pages.count, 2)
    }

    func testLoadEmptyStories() async throws {
        // Given: No stories saved

        // When
        let loadedModels = try await storyRepository.fetchAllStories()

        // Then
        XCTAssertTrue(loadedModels.isEmpty)
    }

    func testUpdateExistingStory() async throws {
        // Given
        let id = UUID()
        let storyTitle1 = "Original Title"
        let storyTitle2 = "Updated Title"

        // When - Create and save a story
        let originalStory = createSampleDomainStory(id: id, title: storyTitle1)
        _ = try await storyRepository.saveStory(originalStory)

        // Then - Verify it exists
        var loadedModel = try await storyRepository.fetchStory(withId: id)
        XCTAssertNotNil(loadedModel)
        XCTAssertEqual(loadedModel?.title, storyTitle1)
        XCTAssertEqual(loadedModel?.pages.count, 2)  // Check original page count

        // When - Save a new version with the same ID but different page count
        let updatedStory = createSampleDomainStory(id: id, title: storyTitle2, pagesCount: 3)  // Change page count
        _ = try await storyRepository.saveStory(updatedStory)

        // Then - Verify the title and page count are updated
        loadedModel = try await storyRepository.fetchStory(withId: id)
        XCTAssertNotNil(loadedModel)
        XCTAssertEqual(loadedModel?.id, id)
        XCTAssertEqual(loadedModel?.title, storyTitle2)
        XCTAssertEqual(loadedModel?.pages.count, 3)  // Verify page count updated
    }

    func testDeleteStory() async throws {
        // Given
        let story1 = createSampleDomainStory(title: "To Keep")
        let storyToDelete = createSampleDomainStory(title: "To Delete")
        _ = try await storyRepository.saveStories([story1, storyToDelete])  // Use repository method

        // When
        let modelToDelete = try await storyRepository.fetchStory(withId: storyToDelete.id)
        try await storyRepository.delete(try XCTUnwrap(modelToDelete))  // Use repository method

        // Then
        let loadedModels = try await storyRepository.fetchAllStories()
        XCTAssertEqual(loadedModels.count, 1)
        XCTAssertEqual(loadedModels.first?.id, story1.id)
        XCTAssertEqual(loadedModels.first?.title, "To Keep")
    }

    // --- New Tests for StoryRepository ---

    func testIncrementReadCount() async throws {
        // Given
        let story = createSampleDomainStory()
        let savedModel = try await storyRepository.saveStory(story)
        XCTAssertEqual(savedModel.readCount, 0)
        XCTAssertNil(savedModel.lastReadAt)

        // When
        try await storyRepository.incrementReadCount(for: story.id)

        // Then
        let updatedModel = try await storyRepository.fetchStory(withId: story.id)
        XCTAssertNotNil(updatedModel)
        XCTAssertEqual(updatedModel?.readCount, 1)
        XCTAssertNotNil(updatedModel?.lastReadAt)  // Should be set now
    }

    func testToggleFavorite() async throws {
        // Given
        let story = createSampleDomainStory()
        let savedModel = try await storyRepository.saveStory(story)
        XCTAssertFalse(savedModel.isFavorite)

        // When - Toggle On
        try await storyRepository.toggleFavorite(for: story.id)

        // Then - Verify On
        var updatedModel = try await storyRepository.fetchStory(withId: story.id)
        XCTAssertNotNil(updatedModel)
        XCTAssertTrue(updatedModel?.isFavorite ?? false)

        // When - Toggle Off
        try await storyRepository.toggleFavorite(for: story.id)

        // Then - Verify Off
        updatedModel = try await storyRepository.fetchStory(withId: story.id)
        XCTAssertNotNil(updatedModel)
        XCTAssertFalse(updatedModel?.isFavorite ?? true)
    }

    func testUpdateLastReadAt() async throws {
        // Given
        let story = createSampleDomainStory()
        let savedModel = try await storyRepository.saveStory(story)
        XCTAssertNil(savedModel.lastReadAt)
        let specificDate = Date(timeIntervalSinceNow: -3600)  // 1 hour ago

        // When
        try await storyRepository.updateLastReadAt(for: story.id, date: specificDate)

        // Then
        let updatedModel = try await storyRepository.fetchStory(withId: story.id)
        XCTAssertNotNil(updatedModel)
        XCTAssertEqual(updatedModel?.lastReadAt, specificDate)
    }

    func testAddAndRemoveAchievement() async throws {
        // Given
        let story = createSampleDomainStory()
        let savedStoryModel = try await storyRepository.saveStory(story)
        let achievement = createSampleAchievementModel(name: "First Read")
        try await achievementRepository.save(achievement)  // Save achievement separately

        // When - Add Achievement
        try await storyRepository.addAchievement(achievement, to: savedStoryModel.id)

        // Then - Verify Added
        var updatedStoryModel = try await storyRepository.fetchStory(withId: savedStoryModel.id)
        XCTAssertNotNil(updatedStoryModel)
        XCTAssertEqual(updatedStoryModel?.achievements.count, 1)
        XCTAssertEqual(updatedStoryModel?.achievements.first?.id, achievement.id)
        // Verify inverse relationship is set
        let fetchedAchievement = try await achievementRepository.fetchAchievement(
            withId: achievement.id)
        XCTAssertEqual(fetchedAchievement?.story?.id, savedStoryModel.id)

        // When - Remove Achievement
        try await storyRepository.removeAchievement(achievement, from: savedStoryModel.id)

        // Then - Verify Removed
        updatedStoryModel = try await storyRepository.fetchStory(withId: savedStoryModel.id)
        XCTAssertNotNil(updatedStoryModel)
        XCTAssertTrue(updatedStoryModel?.achievements.isEmpty ?? false)
        // Verify inverse relationship is unset
        let fetchedAchievementAfterRemove = try await achievementRepository.fetchAchievement(
            withId: achievement.id)
        XCTAssertNil(fetchedAchievementAfterRemove?.story)
    }

    func testDeleteStoryCascadesAchievements() async throws {
        // Given
        let story = createSampleDomainStory()
        let savedStoryModel = try await storyRepository.saveStory(story)
        let achievement1 = createSampleAchievementModel(name: "Achieve 1")
        let achievement2 = createSampleAchievementModel(name: "Achieve 2")
        try await achievementRepository.save(achievement1)
        try await achievementRepository.save(achievement2)
        try await storyRepository.addAchievement(achievement1, to: savedStoryModel.id)
        try await storyRepository.addAchievement(achievement2, to: savedStoryModel.id)

        // Verify setup
        var storyCheck = try await storyRepository.fetchStory(withId: savedStoryModel.id)
        XCTAssertEqual(storyCheck?.achievements.count, 2)
        var achievementCheck = try await achievementRepository.fetch(
            FetchDescriptor<AchievementModel>())
        XCTAssertEqual(achievementCheck.count, 2)

        // When
        try await storyRepository.delete(savedStoryModel)

        // Then
        storyCheck = try await storyRepository.fetchStory(withId: savedStoryModel.id)
        XCTAssertNil(storyCheck, "Story should be deleted")

        // Check if achievements were cascade deleted
        achievementCheck = try await achievementRepository.fetch(
            FetchDescriptor<AchievementModel>())
        XCTAssertTrue(achievementCheck.isEmpty, "Achievements should be cascade deleted")
    }
}
