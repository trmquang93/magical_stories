import Foundation
import SwiftData
import OSLog // For logging

// MARK: - Protocol Definition
@MainActor // Ensure methods interacting with SwiftData/UI are on the main actor
protocol UsageAnalyticsServiceProtocol {
    func getStoryGenerationCount() async -> Int
    func incrementStoryGenerationCount() async
    func updateLastGenerationDate(date: Date?) async
    func getLastGenerationDate() async -> Date?
    func updateLastGeneratedStoryId(id: UUID?) async
    func getLastGeneratedStoryId() async -> UUID?
    // Add other necessary methods as needed
}

// MARK: - Service Implementation
@MainActor
class UsageAnalyticsService: UsageAnalyticsServiceProtocol {

    private var isMigrating = false

    private let userProfileRepository: UserProfileRepository
    private let userDefaults: UserDefaults
    private var cachedUserProfile: UserProfile? // Cache the profile after initial load/migration
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example.magicalstories", category: "UsageAnalyticsService")

    // Define keys consistently
    private enum Keys {
        static let lastGeneratedStoryId = "lastGeneratedStoryId"
        static let storyGenerationCount = "storyGenerationCount"
        static let lastGenerationDate = "lastGenerationDate"
        static let migrationFlag = "usageAnalyticsMigratedToSwiftData"
    }

    init(
        userProfileRepository: UserProfileRepository,
        userDefaults: UserDefaults = .standard,
        startBackgroundMigration: Bool = true
    ) {
        self.userProfileRepository = userProfileRepository
        self.userDefaults = userDefaults

        if startBackgroundMigration {
            Task {
                await migrateAndLoadProfileIfNeeded()
            }
        }
    }

    // Expose explicit migration/load for tests
    @MainActor
    func performMigrationAndLoad() async {
        await migrateAndLoadProfileIfNeeded()
    }


    // MARK: - Migration and Loading

    private func migrateAndLoadProfileIfNeeded() async {
        if isMigrating {
            logger.info("Migration already in progress, skipping duplicate call.")
            return
        }
        isMigrating = true
        defer { isMigrating = false }

        let isMigrated = userDefaults.bool(forKey: Keys.migrationFlag)

        if isMigrated {
            logger.info("Usage analytics already migrated to SwiftData.")
            // Attempt to load the existing profile into cache
            await loadProfileIntoCache()
            return
        }

    }

    private func markMigrationComplete() {
        userDefaults.set(true, forKey: Keys.migrationFlag)
        userDefaults.removeObject(forKey: Keys.lastGeneratedStoryId)
        userDefaults.removeObject(forKey: Keys.storyGenerationCount)
        userDefaults.removeObject(forKey: Keys.lastGenerationDate)
        logger.info("Migration flag set and old UserDefaults keys removed.")
    }

    private func loadProfileIntoCache() async {
         guard cachedUserProfile == nil else { return } // Avoid reloading if already cached
         do {
             // Use fetchOrCreate to ensure a profile exists even if migration failed somehow
             cachedUserProfile = try await userProfileRepository.fetchOrCreateUserProfile()
             logger.info("UserProfile loaded into cache.")
         } catch {
             logger.error("Failed to load UserProfile into cache: \(error.localizedDescription)")
             // cachedUserProfile remains nil, methods might return defaults or handle nil profile
         }
     }

    // MARK: - Public API Methods

    func getStoryGenerationCount() async -> Int {
        await loadProfileIntoCache() // Ensure profile is loaded
        return cachedUserProfile?.storyGenerationCount ?? 0
    }

    func incrementStoryGenerationCount() async {
        await loadProfileIntoCache()
        guard let profile = cachedUserProfile else {
            logger.error("Cannot increment story count: UserProfile not loaded.")
            return
        }
        profile.storyGenerationCount += 1
        do {
            try await userProfileRepository.update(profile) // Saves context
            logger.debug("Incremented story generation count to \(profile.storyGenerationCount)")
        } catch {
            logger.error("Failed to save updated story generation count: \(error.localizedDescription)")
            // Optionally revert the in-memory change?
             profile.storyGenerationCount -= 1
        }
    }

    func updateLastGenerationDate(date: Date?) async {
        await loadProfileIntoCache()
        guard let profile = cachedUserProfile else {
            logger.error("Cannot update last generation date: UserProfile not loaded.")
            return
        }
        profile.lastGenerationDate = date
        do {
            try await userProfileRepository.update(profile)
            logger.debug("Updated last generation date.")
        } catch {
            logger.error("Failed to save updated last generation date: \(error.localizedDescription)")
            // Revert? Depends on desired consistency.
        }
    }

    func getLastGenerationDate() async -> Date? {
        await loadProfileIntoCache()
        return cachedUserProfile?.lastGenerationDate
    }

    func updateLastGeneratedStoryId(id: UUID?) async {
        await loadProfileIntoCache()
        guard let profile = cachedUserProfile else {
            logger.error("Cannot update last generated story ID: UserProfile not loaded.")
            return
        }
        profile.lastGeneratedStoryId = id
        do {
            try await userProfileRepository.update(profile)
            logger.debug("Updated last generated story ID.")
        } catch {
            logger.error("Failed to save updated last generated story ID: \(error.localizedDescription)")
        }
    }

    func getLastGeneratedStoryId() async -> UUID? {
        await loadProfileIntoCache()
        return cachedUserProfile?.lastGeneratedStoryId
    }
}