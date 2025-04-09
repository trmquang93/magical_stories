import Foundation

/// A UserDefaults-based implementation of the AchievementRepositoryProtocol.
final class UserDefaultsAchievementRepository: AchievementRepositoryProtocol {
    // MARK: - Constants
    private enum Keys {
        static let achievements = "achievements"
        static let achievementCollectionMap = "achievement_collection_map"
    }

    // MARK: - Properties
    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    // MARK: - Initialization
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    // MARK: - Private Helpers
    private func loadAllAchievements() throws -> [Achievement] {
        guard let data = userDefaults.data(forKey: Keys.achievements) else {
            return []
        }
        return try decoder.decode([Achievement].self, from: data)
    }

    private func saveAllAchievements(_ achievements: [Achievement]) throws {
        let data = try encoder.encode(achievements)
        userDefaults.set(data, forKey: Keys.achievements)
    }

    private func loadCollectionMap() throws -> [UUID: [String]] {
        guard let data = userDefaults.data(forKey: Keys.achievementCollectionMap) else {
            return [:]
        }
        return try decoder.decode([UUID: [String]].self, from: data)
    }

    private func saveCollectionMap(_ map: [UUID: [String]]) throws {
        let data = try encoder.encode(map)
        userDefaults.set(data, forKey: Keys.achievementCollectionMap)
    }

    // MARK: - AchievementRepositoryProtocol Implementation
    func saveAchievement(_ achievement: Achievement) throws {
        var achievements = try loadAllAchievements()
        if let index = achievements.firstIndex(where: { $0.id == achievement.id }) {
            achievements[index] = achievement
        } else {
            achievements.append(achievement)
        }
        try saveAllAchievements(achievements)
    }

    func fetchAchievement(id: UUID) throws -> Achievement? {
        let achievements = try loadAllAchievements()
        return achievements.first { $0.id == id.uuidString }
    }

    func fetchAllAchievements() throws -> [Achievement] {
        return try loadAllAchievements()
    }

    func fetchEarnedAchievements() throws -> [Achievement] {
        let achievements = try loadAllAchievements()
        return achievements.filter { $0.dateEarned != nil }
    }

    func fetchAchievements(forCollection collectionId: UUID) throws -> [Achievement] {
        let map = try loadCollectionMap()
        guard let achievementIds = map[collectionId] else {
            return []
        }
        
        let allAchievements = try loadAllAchievements()
        return allAchievements.filter { achievementIds.contains($0.id) }
    }

    func updateAchievementStatus(id: UUID, isEarned: Bool, earnedDate: Date?) throws {
        var achievements = try loadAllAchievements()
        guard let index = achievements.firstIndex(where: { $0.id == id.uuidString }) else {
            throw PersistenceError.itemNotFound
        }
        
        var achievement = achievements[index]
        achievement.dateEarned = isEarned ? (earnedDate ?? Date()) : nil
        achievements[index] = achievement
        
        try saveAllAchievements(achievements)
    }

    func deleteAchievement(id: UUID) throws {
        var achievements = try loadAllAchievements()
        achievements.removeAll { $0.id == id.uuidString }
        try saveAllAchievements(achievements)
        
        // Also remove from collection mappings
        var map = try loadCollectionMap()
        for (collectionId, achievementIds) in map {
            map[collectionId] = achievementIds.filter { $0 != id.uuidString }
        }
        try saveCollectionMap(map)
    }

    // MARK: - Additional Helper Methods
    /// Associates an achievement with a collection
    /// - Parameters:
    ///   - achievementId: The ID of the achievement
    ///   - collectionId: The ID of the collection
    func associateAchievement(_ achievementId: String, withCollection collectionId: UUID) throws {
        var map = try loadCollectionMap()
        var achievementIds = map[collectionId] ?? []
        if !achievementIds.contains(achievementId) {
            achievementIds.append(achievementId)
            map[collectionId] = achievementIds
            try saveCollectionMap(map)
        }
    }

    /// Removes an achievement's association with a collection
    /// - Parameters:
    ///   - achievementId: The ID of the achievement
    ///   - collectionId: The ID of the collection
    func removeAchievementAssociation(_ achievementId: String, fromCollection collectionId: UUID) throws {
        var map = try loadCollectionMap()
        if var achievementIds = map[collectionId] {
            achievementIds.removeAll { $0 == achievementId }
            map[collectionId] = achievementIds
            try saveCollectionMap(map)
        }
    }
} 