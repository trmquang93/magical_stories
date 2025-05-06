import SwiftData
// magical-storiesTests/Services/AchievementRepositoryTests.swift
import XCTest

@testable import magical_stories

@MainActor
final class AchievementRepositoryTests: XCTestCase {

    var achievementRepository: AchievementRepository!
    var storyRepository: StoryRepository!  // Needed for relationship tests
    var modelContext: ModelContext!
    var modelContainer: ModelContainer!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Create an in-memory SwiftData model container for testing
        let schema = Schema([Story.self, Page.self, AchievementModel.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)

        achievementRepository = AchievementRepository(modelContext: modelContext)
        storyRepository = StoryRepository(modelContext: modelContext)  // Init story repo for linking
    }

    override func tearDownWithError() throws {
        achievementRepository = nil
        storyRepository = nil
        modelContext = nil
        modelContainer = nil
        try super.tearDownWithError()
    }

    // Helper function to create a sample story model
    private func createSampleStoryModel(id: UUID = UUID(), title: String = "Sample Story")
        -> Story
    {
        // Use the StoryModel initializer directly for simplicity in these tests
        return Story(
            id: id,
            title: title,
            pages: [],
            parameters: StoryParameters(
                childName: "Test Child",
                childAge: 6,
                theme: "Adventure",
                favoriteCharacter: "Hero"
            ),
            timestamp: Date(),
            isCompleted: false,
            collections: [],
            categoryName: nil,
            readCount: 0,
            lastReadAt: nil,
            isFavorite: false,
            achievements: []
        )
    }

    // Helper function to create a sample achievement model
    private func createSampleAchievementModel(
        id: UUID = UUID(), name: String = "Test Achievement",
        type: AchievementType = .storiesCompleted, story: Story? = nil
    ) -> AchievementModel {
        return AchievementModel(id: id, name: name, type: type, story: story)
    }

    func testSaveAndFetchAchievement() async throws {
        // Given
        let achievement = createSampleAchievementModel(name: "First Save")

        // When
        try await achievementRepository.save(achievement)
        let fetchedAchievement = try await achievementRepository.fetchAchievement(
            withId: achievement.id)

        // Then
        XCTAssertNotNil(fetchedAchievement)
        XCTAssertEqual(fetchedAchievement?.id, achievement.id)
        XCTAssertEqual(fetchedAchievement?.name, "First Save")
        XCTAssertEqual(fetchedAchievement?.type, .storiesCompleted)
    }

    func testFetchAchievementsForStory() async throws {
        // Given
        let story1 = createSampleStoryModel()
        let story2 = createSampleStoryModel()
        try await storyRepository.save(story1)  // Save stories first
        try await storyRepository.save(story2)

        let achievement1 = createSampleAchievementModel(name: "Story 1 Achieve 1", story: story1)
        let achievement2 = createSampleAchievementModel(name: "Story 1 Achieve 2", story: story1)
        let achievement3 = createSampleAchievementModel(name: "Story 2 Achieve 1", story: story2)
        try await achievementRepository.batchSave([achievement1, achievement2, achievement3])

        // When
        let story1Achievements = try await achievementRepository.fetchAchievements(for: story1.id)
        let story2Achievements = try await achievementRepository.fetchAchievements(for: story2.id)

        // Then
        XCTAssertEqual(story1Achievements.count, 2)
        XCTAssertTrue(story1Achievements.contains { $0.id == achievement1.id })
        XCTAssertTrue(story1Achievements.contains { $0.id == achievement2.id })
        XCTAssertEqual(story2Achievements.count, 1)
        XCTAssertEqual(story2Achievements.first?.id, achievement3.id)
    }

    func testFetchAchievementsOfType() async throws {
        // Given
        let achievement1 = createSampleAchievementModel(name: "Complete 1", type: .storiesCompleted)
        let achievement2 = createSampleAchievementModel(name: "Streak 1", type: .readingStreak)
        let achievement3 = createSampleAchievementModel(name: "Complete 2", type: .storiesCompleted)
        try await achievementRepository.batchSave([achievement1, achievement2, achievement3])

        // When
        let completedAchievements = try await achievementRepository.fetchAchievements(
            ofType: .storiesCompleted)
        let streakAchievements = try await achievementRepository.fetchAchievements(
            ofType: .readingStreak)
        let themeAchievements = try await achievementRepository.fetchAchievements(
            ofType: .themeMastery)

        // Then
        XCTAssertEqual(completedAchievements.count, 2)
        XCTAssertTrue(completedAchievements.contains { $0.id == achievement1.id })
        XCTAssertTrue(completedAchievements.contains { $0.id == achievement3.id })
        XCTAssertEqual(streakAchievements.count, 1)
        XCTAssertEqual(streakAchievements.first?.id, achievement2.id)
        XCTAssertTrue(themeAchievements.isEmpty)
    }

    func testUpdateAchievement() async throws {
        // Given
        let achievement = createSampleAchievementModel(name: "Initial Name")
        try await achievementRepository.save(achievement)

        // When
        achievement.name = "Updated Name"
        achievement.progress = 0.5
        try await achievementRepository.update(achievement)

        // Then
        let fetchedAchievement = try await achievementRepository.fetchAchievement(
            withId: achievement.id)
        XCTAssertNotNil(fetchedAchievement)
        XCTAssertEqual(fetchedAchievement?.name, "Updated Name")
        XCTAssertEqual(fetchedAchievement?.progress, 0.5)
    }

    func testDeleteAchievement() async throws {
        // Given
        let achievement1 = createSampleAchievementModel(name: "To Delete")
        let achievement2 = createSampleAchievementModel(name: "To Keep")
        try await achievementRepository.batchSave([achievement1, achievement2])

        // When
        try await achievementRepository.delete(achievement1)

        // Then
        let allAchievements = try await achievementRepository.fetch(
            FetchDescriptor<AchievementModel>())
        XCTAssertEqual(allAchievements.count, 1)
        XCTAssertEqual(allAchievements.first?.id, achievement2.id)
        XCTAssertEqual(allAchievements.first?.name, "To Keep")

        let deletedAchievement = try await achievementRepository.fetchAchievement(
            withId: achievement1.id)
        XCTAssertNil(deletedAchievement)
    }
}
