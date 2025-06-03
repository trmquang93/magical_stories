import Foundation
import SwiftData

/// Protocol defining operations for managing illustration tasks persistence
protocol IllustrationTaskRepositoryProtocol {
    /// Save a runtime task to persistence
    /// - Parameters:
    ///   - task: The runtime task to save
    ///   - pageNumber: The page number in the story
    ///   - totalPages: The total number of pages in the story
    ///   - description: The description for generating the illustration
    ///   - previousIllustrationPath: Path to the previous illustration if available
    /// - Returns: The created persistent task
    @MainActor
    func saveTask(
        _ task: IllustrationTask,
        pageNumber: Int,
        totalPages: Int,
        description: String?,
        previousIllustrationPath: String?
    ) throws -> PendingIllustrationTask
    
    /// Update the status of a persisted task
    /// - Parameters:
    ///   - id: The ID of the task
    ///   - status: The new status
    /// - Returns: The updated task if found, nil otherwise
    @MainActor
    func updateTaskStatus(_ id: UUID, status: IllustrationStatus) throws -> PendingIllustrationTask?
    
    /// Increment the attempt count of a task
    /// - Parameter id: The ID of the task
    /// - Returns: The updated task if found, nil otherwise
    @MainActor
    func incrementTaskAttempt(_ id: UUID) throws -> PendingIllustrationTask?
    
    /// Delete a task by ID
    /// - Parameter id: The ID of the task to delete
    @MainActor
    func deleteTask(_ id: UUID) throws
    
    /// Get all pending tasks (tasks not in terminal state)
    /// - Returns: Array of pending tasks
    @MainActor
    func getAllPendingTasks() throws -> [PendingIllustrationTask]
    
    /// Get a task by its ID
    /// - Parameter id: The ID of the task
    /// - Returns: The task if found, nil otherwise
    @MainActor
    func getTaskById(_ id: UUID) throws -> PendingIllustrationTask?
    
    /// Get tasks for a specific page
    /// - Parameter pageId: The ID of the page
    /// - Returns: Tasks associated with the page
    @MainActor
    func getTasksForPage(_ pageId: UUID) throws -> [PendingIllustrationTask]
    
    /// Get tasks for a specific story
    /// - Parameter storyId: The ID of the story
    /// - Returns: Tasks associated with the story
    @MainActor
    func getTasksForStory(_ storyId: UUID) throws -> [PendingIllustrationTask]
    
    /// Delete all tasks for a specific story
    /// - Parameter storyId: The ID of the story
    @MainActor
    func deleteTasksForStory(_ storyId: UUID) throws
    
    /// Restores tasks from persistent storage into the task manager
    /// - Parameter manager: The IllustrationTaskManager to restore tasks into
    /// - Returns: The number of tasks restored
    @MainActor
    func restoreTasksToManager(_ manager: IllustrationTaskManager) async throws -> Int
    
    /// Get the completed global reference task for a story
    /// - Parameter storyId: The ID of the story
    /// - Returns: The completed global reference task if found, nil otherwise
    @MainActor
    func getCompletedGlobalReferenceTask(for storyId: UUID) throws -> PendingIllustrationTask?
    
    /// Update the illustration path for a completed task
    /// - Parameters:
    ///   - id: The ID of the task
    ///   - illustrationPath: The path to the generated illustration
    /// - Returns: The updated task if found, nil otherwise
    @MainActor
    func updateTaskIllustrationPath(_ id: UUID, illustrationPath: String) throws -> PendingIllustrationTask?
}
