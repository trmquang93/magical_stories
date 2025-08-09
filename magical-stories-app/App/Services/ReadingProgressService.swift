import Foundation
import SwiftData

/// Service responsible for handling reading progress updates in a non-blocking manner
/// This service uses Swift 6 concurrency patterns to prevent UI freezing during database operations
@MainActor
final class ReadingProgressService: ObservableObject, Sendable {
    
    private let persistenceService: PersistenceService
    private let collectionService: CollectionService
    private weak var ratingService: RatingService?
    
    /// Track ongoing progress operations to prevent duplicate work
    private var ongoingProgressUpdates: Set<UUID> = []
    
    init(persistenceService: PersistenceService, collectionService: CollectionService) {
        self.persistenceService = persistenceService
        self.collectionService = collectionService
    }
    
    /// Updates reading progress for a story in a non-blocking manner
    /// This method immediately returns to prevent UI blocking while database operations continue in background
    /// 
    /// - Parameters:
    ///   - storyId: ID of the story that was completed
    ///   - collectionId: ID of the collection containing the story (optional)
    func updateReadingProgress(for storyId: UUID, in collectionId: UUID? = nil) {
        // Prevent duplicate progress updates for the same story
        guard !ongoingProgressUpdates.contains(storyId) else {
            print("[ReadingProgressService] Progress update already in progress for story: \(storyId)")
            return
        }
        
        ongoingProgressUpdates.insert(storyId)
        
        // Perform all database operations on a detached task to avoid blocking UI
        Task.detached(priority: .userInitiated) { [weak self] in
            await self?.performProgressUpdate(storyId: storyId, collectionId: collectionId)
        }
    }
    
    /// Performs the actual progress update operations in background
    /// Uses timeouts and proper error handling to prevent hanging
    @Sendable
    private func performProgressUpdate(storyId: UUID, collectionId: UUID?) async {
        defer {
            Task { @MainActor in
                self.ongoingProgressUpdates.remove(storyId)
            }
        }
        
        do {
            // Step 1: Update story read count and timestamp with timeout
            try await withTimeoutDetached(TimeoutUtility.databaseTimeout) {
                try await self.updateStoryReadingData(storyId: storyId)
            }
            
            // Step 2: Update collection progress if collection is specified
            if let collectionId = collectionId {
                try await withTimeoutDetached(TimeoutUtility.databaseTimeout) {
                    try await self.updateCollectionProgress(storyId: storyId, collectionId: collectionId)
                }
            }
            
            print("[ReadingProgressService] Successfully updated reading progress for story: \(storyId)")
        
        // Record story completion for rating system (non-blocking)
        Task { @MainActor [weak self] in
            await self?.ratingService?.handleStoryCompleted()
        }
            
        } catch {
            // Log error but don't crash - reading progress is not critical for app functionality
            print("[ReadingProgressService] Error updating reading progress for story \(storyId): \(error)")
            
            // Handle specific error types to help with debugging
            if error is TimeoutError {
                print("[ReadingProgressService] Progress update timed out - this may indicate database performance issues")
            } else if let repositoryError = error as? StoryRepositoryError {
                switch repositoryError {
                case .storyNotFound(let id):
                    print("[ReadingProgressService] CRITICAL: Story \(id) not found during progress update - possible data corruption")
                    // This is a critical issue that indicates the story may have been corrupted or deleted
                    // The story should exist since the user just finished reading it
                case .updateFailed(let id, let underlying):
                    print("[ReadingProgressService] Failed to update story \(id) progress: \(underlying.localizedDescription)")
                default:
                    print("[ReadingProgressService] Repository error: \(repositoryError.localizedDescription)")
                }
            }
        }
    }
    
    /// Updates story reading data (read count and last read timestamp)
    /// This method is isolated to main actor to ensure SwiftData context safety
    @MainActor
    private func updateStoryReadingData(storyId: UUID) async throws {
        print("[ReadingProgressService] Updating reading data for story: \(storyId)")
        
        // Update read count
        try await persistenceService.incrementReadCount(for: storyId)
        
        // Update last read timestamp
        try await persistenceService.updateLastReadAt(for: storyId, date: Date())
        
        print("[ReadingProgressService] Successfully updated story reading data")
    }
    
    /// Updates collection progress and handles achievement tracking
    /// This method runs on main actor to ensure proper SwiftData context usage
    @MainActor
    private func updateCollectionProgress(storyId: UUID, collectionId: UUID) async throws {
        print("[ReadingProgressService] Updating collection progress for story: \(storyId), collection: \(collectionId)")
        
        // Mark story as completed in collection
        try await collectionService.markStoryAsCompleted(storyId: storyId, collectionId: collectionId)
        
        print("[ReadingProgressService] Successfully updated collection progress")
    }
    
    /// Sets the rating service dependency
    /// - Parameter ratingService: The rating service for tracking user engagement
    func setRatingService(_ ratingService: RatingService) {
        self.ratingService = ratingService
    }
}

/// Extension providing convenience methods for common progress update scenarios
extension ReadingProgressService {
    
    /// Updates reading progress when a story is completed from story detail view
    /// - Parameters:
    ///   - story: The completed story
    func handleStoryCompletion(for story: Story) {
        // Extract collection ID if story belongs to a collection
        let collectionId = story.collections.first?.id
        
        // Update progress asynchronously
        updateReadingProgress(for: story.id, in: collectionId)
    }
    
    /// Updates reading progress for multiple stories (batch operation)
    /// Useful for marking multiple stories as read
    /// - Parameter stories: Array of stories to mark as completed
    func handleBatchCompletion(for stories: [Story]) {
        for story in stories {
            handleStoryCompletion(for: story)
        }
    }
}

/// Timeout utility function that works from detached tasks
/// Unlike the MainActor timeout functions, this can be called from any context
@Sendable
private func withTimeoutDetached<T: Sendable>(_ timeout: TimeInterval, operation: @escaping @Sendable () async throws -> T) async throws -> T {
    return try await withThrowingTaskGroup(of: T.self) { group in
        // Add the actual operation task
        group.addTask {
            try await operation()
        }
        
        // Add timeout task
        group.addTask {
            try await Task.sleep(for: .seconds(timeout))
            throw TimeoutError("Operation timed out after \(timeout) seconds")
        }
        
        // Wait for first task to complete (either operation or timeout)
        guard let result = try await group.next() else {
            throw TimeoutError("No result from task group")
        }
        
        // Cancel remaining tasks
        group.cancelAll()
        return result
    }
}

/// Error types specific to reading progress operations
enum ReadingProgressError: Error, LocalizedError {
    case storyNotFound(UUID)
    case collectionNotFound(UUID)
    case progressUpdateFailed(underlying: any Error)
    
    var errorDescription: String? {
        switch self {
        case .storyNotFound(let id):
            return "Story with ID \(id) not found"
        case .collectionNotFound(let id):
            return "Collection with ID \(id) not found"
        case .progressUpdateFailed(let error):
            return "Failed to update reading progress: \(error.localizedDescription)"
        }
    }
}
