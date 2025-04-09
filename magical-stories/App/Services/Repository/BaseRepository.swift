import Foundation
import SwiftData
/**
 Generic repository protocol for SwiftData persistence operations
 */
protocol Repository {
    associatedtype T: PersistentModel
    
    /// Fetches entities matching the provided descriptor
    /// - Parameter descriptor: The fetch descriptor defining what to fetch and how
    /// - Returns: An array of fetched entities
    func fetch(_ descriptor: FetchDescriptor<T>) async throws -> [T]
    
    /// Saves an entity to the persistent store
    /// - Parameter item: The entity to save
    func save(_ item: T) async throws
    
    /// Deletes an entity from the persistent store
    /// - Parameter item: The entity to delete
    func delete(_ item: T) async throws
    
    /// Updates an entity in the persistent store
    /// - Parameter item: The entity to update
    func update(_ item: T) async throws
    
    /// Performs a batch save operation for multiple entities
    /// - Parameter items: The entities to save
    func batchSave(_ items: [T]) async throws
}

/// Generic repository protocol for SwiftData persistence operations


/// Base implementation of the Repository protocol using SwiftData's ModelContext
class BaseRepository<T: PersistentModel>: Repository {
    
    internal let modelContext: ModelContext
    
    /// Initialize with a ModelContext
    /// - Parameter modelContext: The SwiftData model context to use for persistence operations
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Fetch entities matching the descriptor
    /// - Parameter descriptor: The descriptor defining what to fetch
    /// - Returns: An array of fetched entities
    func fetch(_ descriptor: FetchDescriptor<T>) async throws -> [T] {
        // SwiftData context operations are often implicitly async or handled by the framework
        try modelContext.fetch(descriptor)
    }
    
    /// Save an entity to the persistent store
    /// - Parameter item: The entity to save
    func save(_ item: T) async throws {
        modelContext.insert(item)
        try modelContext.save()
    }
    
    /// Delete an entity from the persistent store
    /// - Parameter item: The entity to delete
    func delete(_ item: T) async throws {
        modelContext.delete(item)
        try modelContext.save()
    }
    
    /// Update an entity in the persistent store
    /// - Parameter item: The entity to update
    func update(_ item: T) async throws {
        // In SwiftData, there's no explicit update method
        // Changes to the item are tracked automatically by SwiftData
        // We just need to save the context to persist the changes
        try modelContext.save()
    }
    
    /// Perform a batch save operation for multiple entities
    /// - Parameter items: The entities to save
    func batchSave(_ items: [T]) async throws {
        for item in items {
            modelContext.insert(item)
        }
        try modelContext.save()
    }
}
