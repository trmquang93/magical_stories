import Foundation

/// Repository implementation for managing Growth Collections using UserDefaults.
/// Note: This is intended as a temporary solution until SwiftData migration.
class UserDefaultsCollectionRepository: CollectionRepositoryProtocol {

    private let userDefaults: UserDefaults
    private let collectionsKey = "growthCollections_v1" // Key for storing the array of collections
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// Initializer.
    /// - Parameter userDefaults: The UserDefaults instance to use (defaults to .standard).
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - CollectionRepositoryProtocol Implementation

    func saveCollection(_ collection: GrowthCollection) throws {
        var collections = try fetchAllCollectionsInternal() // Get current collections

        // Update if exists, otherwise append
        if let index = collections.firstIndex(where: { $0.id == collection.id }) {
            collections[index] = collection
        } else {
            collections.append(collection)
        }

        try saveCollectionsArray(collections)
    }

    func fetchCollection(id: UUID) throws -> GrowthCollection? {
        let collections = try fetchAllCollectionsInternal()
        return collections.first(where: { $0.id == id })
    }

    func fetchAllCollections() throws -> [GrowthCollection] {
        return try fetchAllCollectionsInternal()
    }

    func updateCollectionProgress(id: UUID, progress: Float) throws {
        var collections = try fetchAllCollectionsInternal()

        guard let index = collections.firstIndex(where: { $0.id == id }) else {
            throw PersistenceError.dataNotFound
        }

        // Ensure progress is clamped between 0.0 and 1.0
        collections[index].progress = max(0.0, min(1.0, progress))

        try saveCollectionsArray(collections)
    }

    func deleteCollection(id: UUID) throws {
        var collections = try fetchAllCollectionsInternal()

        collections.removeAll { $0.id == id }

        try saveCollectionsArray(collections)
    }

    // MARK: - Private Helpers

    /// Fetches the raw array of collections from UserDefaults.
    private func fetchAllCollectionsInternal() throws -> [GrowthCollection] {
        guard let data = userDefaults.data(forKey: collectionsKey) else {
            return [] // No data found, return empty array
        }

        do {
            let collections = try decoder.decode([GrowthCollection].self, from: data)
            return collections
        } catch {
            print("Error decoding collections: \(error)")
            throw PersistenceError.decodingFailed(error)
        }
    }

    /// Saves the entire array of collections to UserDefaults.
    private func saveCollectionsArray(_ collections: [GrowthCollection]) throws {
        do {
            let data = try encoder.encode(collections)
            userDefaults.set(data, forKey: collectionsKey)
        } catch {
            print("Error encoding collections: \(error)")
            throw PersistenceError.encodingFailed(error)
        }
    }
} 