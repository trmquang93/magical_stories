import Foundation
import SwiftData

/// Concrete implementation of `CollectionRepositoryProtocol` using SwiftData.
final class CollectionRepository: CollectionRepositoryProtocol, Sendable {

    nonisolated(unsafe) private let modelContext: ModelContext

    /// Initializes the repository with a SwiftData model context.
    /// - Parameter modelContext: The `ModelContext` to use for data operations.
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func saveCollection(_ collection: StoryCollection) throws {
        modelContext.insert(collection)
        try modelContext.save()
    }

    func fetchCollection(id: UUID) throws -> StoryCollection? {
        let predicate = #Predicate<StoryCollection> { $0.id == id }
        var fetchDescriptor = FetchDescriptor<StoryCollection>(predicate: predicate)
        fetchDescriptor.fetchLimit = 1
        let results = try modelContext.fetch(fetchDescriptor)
        return results.first
    }

    func fetchAllCollections() throws -> [StoryCollection] {
        let fetchDescriptor = FetchDescriptor<StoryCollection>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(fetchDescriptor)
    }

    func updateCollectionProgress(id: UUID, progress: Float) throws {
        guard let collection = try fetchCollection(id: id) else {
            throw NSError(domain: "CollectionRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Collection with ID \(id) not found for progress update."])
        }
        collection.completionProgress = Double(progress)
        collection.updatedAt = Date()
        try modelContext.save()
    }

    func deleteCollection(id: UUID) throws {
        guard let collection = try fetchCollection(id: id) else {
            throw NSError(domain: "CollectionRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Collection with ID \(id) not found for deletion."])
        }
        modelContext.delete(collection)
        try modelContext.save()
    }
}
