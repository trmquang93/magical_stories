import Foundation
import SwiftData

/// Generic repository protocol for SwiftData persistence operations
// protocol Repository {
//     associatedtype T: PersistentModel
//
//     /// Fetches entities matching the provided descriptor
//     /// - Parameter descriptor: The fetch descriptor defining what to fetch and how
//     /// - Returns: An array of fetched entities
//     func fetch(_ descriptor: FetchDescriptor<T>) async throws -> [T]
//
//     /// Saves an entity to the persistent store
//     /// - Parameter item: The entity to save
//     func save(_ item: T) async throws
//
//     /// Deletes an entity from the persistent store
//     /// - Parameter item: The entity to delete
//     func delete(_ item: T) async throws
//
//     /// Updates an entity in the persistent store
//     /// - Parameter item: The entity to update
//     func update(_ item: T) async throws
//
//     /// Performs a batch save operation for multiple entities
//     /// - Parameter items: The entities to save
//     func batchSave(_ items: [T]) async throws
// }