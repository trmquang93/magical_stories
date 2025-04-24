import Foundation
import SwiftData

/// Repository specifically for managing the UserProfile entity.
/// Assumes a single UserProfile instance exists in the data store.
class UserProfileRepository: BaseRepository<UserProfile> {

    /// Fetches the single UserProfile instance from the data store.
    ///
    /// Since UserProfile is intended as a singleton (enforced by unique ID),
    /// this method fetches the first (and presumably only) UserProfile found.
    ///
    /// - Returns: The UserProfile instance if found, otherwise nil.
    /// - Throws: Errors related to SwiftData fetching operations.
    func fetchUserProfile() async throws -> UserProfile? {
        // Fetch descriptor for any UserProfile, limit 1 as we expect only one.
        var descriptor = FetchDescriptor<UserProfile>() // Initialize descriptor
        descriptor.fetchLimit = 1 // Set fetchLimit property
        let profiles = try await fetch(descriptor)
        return profiles.first
    }

    /// Fetches the UserProfile or creates a default one if none exists.
    ///
    /// This is useful for ensuring a profile always exists when accessed.
    /// Note: The migration logic in UsageAnalyticsService handles the initial
    /// creation based on UserDefaults. This method is more for general access
    /// after migration.
    ///
    /// - Returns: The existing or newly created UserProfile instance.
    /// - Throws: Errors related to SwiftData fetching or saving operations.
    func fetchOrCreateUserProfile() async throws -> UserProfile {
        if let existingProfile = try await fetchUserProfile() {
            return existingProfile
        } else {
            // Create a default profile if none exists
            // Note: Migration logic in UsageAnalyticsService should handle the
            // initial creation based on UserDefaults. This is a fallback.
            print("UserProfileRepository: No existing profile found, creating default.")
            let newProfile = UserProfile() // Uses default initializer
            try await save(newProfile)
            return newProfile
        }
    }
    /// Deletes all UserProfile entities to enforce singleton pattern.
    func deleteAllProfiles() async throws {
        var descriptor = FetchDescriptor<UserProfile>()
        let allProfiles = try await fetch(descriptor)
        for profile in allProfiles {
            try await delete(profile)
        }
        try modelContext.save()
    }
}