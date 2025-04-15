import Combine  // Add Combine import
import Foundation
import SwiftData

/// Concrete implementation of `CollectionServiceProtocol` using SwiftData.
final class CollectionService: ObservableObject, CollectionServiceProtocol {  // Conform to ObservableObject
    private let repository: CollectionRepositoryProtocol

    // Consider adding @Published properties here if views need to react to changes
    // e.g., @Published var collections: [StoryCollection] = []

    init(repository: CollectionRepositoryProtocol) {
        self.repository = repository
    }

    func createCollection(_ collection: StoryCollection) throws {
        try repository.saveCollection(collection)
    }

    func fetchCollection(id: UUID) throws -> StoryCollection? {
        try repository.fetchCollection(id: id)
    }

    func fetchAllCollections() throws -> [StoryCollection] {
        try repository.fetchAllCollections()
    }

    func updateCollectionProgress(id: UUID, progress: Float) throws {
        try repository.updateCollectionProgress(id: id, progress: Float(progress))
    }

    func deleteCollection(id: UUID) throws {
        try repository.deleteCollection(id: id)
    }
}
