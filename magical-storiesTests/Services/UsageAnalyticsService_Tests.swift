import Foundation
import Testing
import SwiftData
@testable import magical_stories
@Suite("UsageAnalyticsService Tests")
struct UsageAnalyticsServiceTests {

    @MainActor
    private func setup() async throws -> (
        modelContainer: ModelContainer,
        userProfileRepository: UserProfileRepository,
        mockUserDefaults: UserDefaults,
        usageAnalyticsService: UsageAnalyticsService
    ) {
        let schema = Schema([UserProfile.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        let userProfileRepository = UserProfileRepository(modelContext: modelContainer.mainContext)

        let mockUserDefaults = MockUserDefaults()

        let usageAnalyticsService = UsageAnalyticsService(
            userProfileRepository: userProfileRepository,
            userDefaults: mockUserDefaults,
            startBackgroundMigration: false
        )
        return (modelContainer, userProfileRepository, mockUserDefaults, usageAnalyticsService)
    }

    @MainActor
    private func waitForInitialization(on service: UsageAnalyticsService) async {
        await service.performMigrationAndLoad()
    }

    private enum Keys {
        static let lastGeneratedStoryId = "lastGeneratedStoryId"
        static let storyGenerationCount = "storyGenerationCount"
        static let lastGenerationDate = "lastGenerationDate"
        static let migrationFlag = "usageAnalyticsMigratedToSwiftData"
    }

    // MARK: - Migration Tests




    // MARK: - Service Method Tests

    @Test("Returns correct story generation count from profile")
    @MainActor
    func testGetStoryGenerationCount_ReturnsCorrectValue() async throws {
        let (_, userProfileRepository, mockUserDefaults, _) = try await setup()

        let profile = UserProfile()
        profile.storyGenerationCount = 3
        try await userProfileRepository.save(profile)
        mockUserDefaults.set(true, forKey: Keys.migrationFlag)

        let usageAnalyticsService = UsageAnalyticsService(
            userProfileRepository: userProfileRepository,
            userDefaults: mockUserDefaults,
            startBackgroundMigration: false
        )
        await waitForInitialization(on: usageAnalyticsService)
        await waitForInitialization(on: usageAnalyticsService)

        let count = await usageAnalyticsService.getStoryGenerationCount()

        #expect(count == 3)
    }

    @Test("Increments story generation count and saves to profile")
    @MainActor
    func testIncrementStoryGenerationCount_IncreasesCountAndSaves() async throws {
        let (_, userProfileRepository, mockUserDefaults, _) = try await setup()

        let profile = UserProfile()
        profile.storyGenerationCount = 2
        try await userProfileRepository.save(profile)
        mockUserDefaults.set(true, forKey: Keys.migrationFlag)

        let usageAnalyticsService = UsageAnalyticsService(
            userProfileRepository: userProfileRepository,
            userDefaults: mockUserDefaults,
            startBackgroundMigration: false
        )
        await waitForInitialization(on: usageAnalyticsService)
        await waitForInitialization(on: usageAnalyticsService)

        await usageAnalyticsService.incrementStoryGenerationCount()

        let newCountService = await usageAnalyticsService.getStoryGenerationCount()
        let profileFromRepo = try await userProfileRepository.fetchUserProfile()

        #expect(newCountService == 3)
        #expect(profileFromRepo?.storyGenerationCount == 3)
    }

    @Test("Updates and retrieves last generation date correctly, including nil reset")
    @MainActor
    func testUpdateAndGetLastGenerationDate() async throws {
        let (_, userProfileRepository, mockUserDefaults, _) = try await setup()

        let profile = UserProfile()
        try await userProfileRepository.save(profile)
        mockUserDefaults.set(true, forKey: Keys.migrationFlag)

        let usageAnalyticsService = UsageAnalyticsService(
            userProfileRepository: userProfileRepository,
            userDefaults: mockUserDefaults,
            startBackgroundMigration: false
        )
        await waitForInitialization(on: usageAnalyticsService)
        await waitForInitialization(on: usageAnalyticsService)

        let testDate = Date().addingTimeInterval(-1000)

        await usageAnalyticsService.updateLastGenerationDate(date: testDate)

        let fetchedDate = await usageAnalyticsService.getLastGenerationDate()
        let profileFromRepo = try await userProfileRepository.fetchUserProfile()

        #expect(fetchedDate == testDate)
        #expect(profileFromRepo?.lastGenerationDate == testDate)

        await usageAnalyticsService.updateLastGenerationDate(date: nil as Date?)
        let fetchedNilDate = await usageAnalyticsService.getLastGenerationDate()
        #expect(fetchedNilDate == nil)
    }

    @Test("Updates and retrieves last generated story ID correctly, including nil reset")
    @MainActor
    func testUpdateAndGetLastGeneratedStoryId() async throws {
        let (_, userProfileRepository, mockUserDefaults, _) = try await setup()

        let profile = UserProfile()
        try await userProfileRepository.save(profile)
        mockUserDefaults.set(true, forKey: Keys.migrationFlag)

        let usageAnalyticsService = UsageAnalyticsService(
            userProfileRepository: userProfileRepository,
            userDefaults: mockUserDefaults,
            startBackgroundMigration: false
        )
        await waitForInitialization(on: usageAnalyticsService)
        await waitForInitialization(on: usageAnalyticsService)

        let testUUID = UUID()

        await usageAnalyticsService.updateLastGeneratedStoryId(id: testUUID)

        let fetchedUUID = await usageAnalyticsService.getLastGeneratedStoryId()
        let profileFromRepo = try await userProfileRepository.fetchUserProfile()

        #expect(fetchedUUID == testUUID)
        #expect(profileFromRepo?.lastGeneratedStoryId == testUUID)

        await usageAnalyticsService.updateLastGeneratedStoryId(id: nil as UUID?)
        let fetchedNilUUID = await usageAnalyticsService.getLastGeneratedStoryId()
        #expect(fetchedNilUUID == nil)
    }
}