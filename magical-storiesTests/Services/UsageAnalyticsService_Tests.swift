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
        let mockUserDefaults = UserDefaults(suiteName: #file)!
        mockUserDefaults.removePersistentDomain(forName: #file)
        let usageAnalyticsService = UsageAnalyticsService(
            userProfileRepository: userProfileRepository,
            userDefaults: mockUserDefaults
        )
        return (modelContainer, userProfileRepository, mockUserDefaults, usageAnalyticsService)
    }

    @MainActor
    private func waitForInitialization() async {
        try? await Task.sleep(nanoseconds: 100_000_000)
    }

    private enum Keys {
        static let lastGeneratedStoryId = "lastGeneratedStoryId"
        static let storyGenerationCount = "storyGenerationCount"
        static let lastGenerationDate = "lastGenerationDate"
        static let migrationFlag = "usageAnalyticsMigratedToSwiftData"
    }

    // MARK: - Migration Tests

    @Test("Migrates UserDefaults to SwiftData when flag not set and no profile exists")
    @MainActor
    func testMigration_WhenFlagNotSetAndNoProfile_CreatesProfileFromUserDefaults() async throws {
        let (_, userProfileRepository, mockUserDefaults, _) = try await setup()

        let testDate = Date()
        let testUUID = UUID()
        mockUserDefaults.set(5, forKey: Keys.storyGenerationCount)
        mockUserDefaults.set(testDate, forKey: Keys.lastGenerationDate)
        mockUserDefaults.set(testUUID.uuidString, forKey: Keys.lastGeneratedStoryId)
        mockUserDefaults.set(false, forKey: Keys.migrationFlag)

        let usageAnalyticsService = UsageAnalyticsService(
            userProfileRepository: userProfileRepository,
            userDefaults: mockUserDefaults
        )
        await waitForInitialization()

        let profile = try await userProfileRepository.fetchUserProfile()

        #expect(profile != nil)
        #expect(profile?.storyGenerationCount == 5)
        #expect(profile?.lastGenerationDate == testDate)
        #expect(profile?.lastGeneratedStoryId == testUUID)

        #expect(mockUserDefaults.bool(forKey: Keys.migrationFlag) == true)
        #expect(mockUserDefaults.object(forKey: Keys.storyGenerationCount) == nil)
        #expect(mockUserDefaults.object(forKey: Keys.lastGenerationDate) == nil)
        #expect(mockUserDefaults.object(forKey: Keys.lastGeneratedStoryId) == nil)
    }

    @Test("Does not overwrite existing profile during migration, just clears UserDefaults and sets flag")
    @MainActor
    func testMigration_WhenFlagNotSetAndProfileExists_SetsFlagAndClearsUserDefaults() async throws {
        let (_, userProfileRepository, mockUserDefaults, _) = try await setup()

        let existingProfile = UserProfile(childName: "Existing", dateOfBirth: Date())
        existingProfile.storyGenerationCount = 99
        try await userProfileRepository.save(existingProfile)

        let testDate = Date()
        let testUUID = UUID()
        mockUserDefaults.set(5, forKey: Keys.storyGenerationCount)
        mockUserDefaults.set(testDate, forKey: Keys.lastGenerationDate)
        mockUserDefaults.set(testUUID.uuidString, forKey: Keys.lastGeneratedStoryId)
        mockUserDefaults.set(false, forKey: Keys.migrationFlag)

        let usageAnalyticsService = UsageAnalyticsService(
            userProfileRepository: userProfileRepository,
            userDefaults: mockUserDefaults
        )
        await waitForInitialization()

        let profile = try await userProfileRepository.fetchUserProfile()

        #expect(profile != nil)
        #expect(profile?.storyGenerationCount == 99)

        #expect(mockUserDefaults.bool(forKey: Keys.migrationFlag) == true)
        #expect(mockUserDefaults.object(forKey: Keys.storyGenerationCount) == nil)
        #expect(mockUserDefaults.object(forKey: Keys.lastGenerationDate) == nil)
        #expect(mockUserDefaults.object(forKey: Keys.lastGeneratedStoryId) == nil)
    }

    @Test("Skips migration when migration flag is already set")
    @MainActor
    func testMigration_WhenFlagIsSet_DoesNotMigrate() async throws {
        let (_, userProfileRepository, mockUserDefaults, _) = try await setup()

        mockUserDefaults.set(true, forKey: Keys.migrationFlag)
        mockUserDefaults.set(5, forKey: Keys.storyGenerationCount)
        mockUserDefaults.set(Date(), forKey: Keys.lastGenerationDate)

        let usageAnalyticsService = UsageAnalyticsService(
            userProfileRepository: userProfileRepository,
            userDefaults: mockUserDefaults
        )
        await waitForInitialization()

        let profile = try await userProfileRepository.fetchUserProfile()

        #expect(profile == nil)
        #expect(mockUserDefaults.integer(forKey: Keys.storyGenerationCount) == 5)
        #expect(mockUserDefaults.object(forKey: Keys.lastGenerationDate) != nil)
    }

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
            userDefaults: mockUserDefaults
        )
        await waitForInitialization()

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
            userDefaults: mockUserDefaults
        )
        await waitForInitialization()

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
            userDefaults: mockUserDefaults
        )
        await waitForInitialization()

        let testDate = Date().addingTimeInterval(-1000)

        await usageAnalyticsService.updateLastGenerationDate(date: testDate)

        let fetchedDate = await usageAnalyticsService.getLastGenerationDate()
        let profileFromRepo = try await userProfileRepository.fetchUserProfile()

        #expect(fetchedDate == testDate)
        #expect(profileFromRepo?.lastGenerationDate == testDate)

        await usageAnalyticsService.updateLastGenerationDate(date: nil)
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
            userDefaults: mockUserDefaults
        )
        await waitForInitialization()

        let testUUID = UUID()

        await usageAnalyticsService.updateLastGeneratedStoryId(id: testUUID)

        let fetchedUUID = await usageAnalyticsService.getLastGeneratedStoryId()
        let profileFromRepo = try await userProfileRepository.fetchUserProfile()

        #expect(fetchedUUID == testUUID)
        #expect(profileFromRepo?.lastGeneratedStoryId == testUUID)

        await usageAnalyticsService.updateLastGeneratedStoryId(id: nil)
        let fetchedNilUUID = await usageAnalyticsService.getLastGeneratedStoryId()
        #expect(fetchedNilUUID == nil)
    }
}