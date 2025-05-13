import Foundation
import SwiftData
import OSLog

/// Repository responsible for persisting and retrieving illustration tasks
class IllustrationTaskRepository: IllustrationTaskRepositoryProtocol {
    /// The model context for SwiftData operations
    private let modelContext: ModelContext
    
    /// Logger for the repository
    private let logger = Logger(subsystem: "com.magical-stories.app", category: "IllustrationTaskRepository")
    
    /// Initializes a new repository with the provided model context
    /// - Parameter modelContext: The SwiftData model context
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
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
        pageNumber: Int = 1,
        totalPages: Int = 1,
        description: String? = nil,
        previousIllustrationPath: String? = nil
    ) throws -> PendingIllustrationTask {
        // Check if the task already exists
        if let existingTask = try getTaskById(task.id) {
            logger.debug("Task already exists, updating: \(task.id.uuidString)")
            existingTask.status = task.status
            existingTask.lastUpdatedAt = task.lastUpdatedAt
            existingTask.attemptCount = task.attemptCount
            existingTask.illustrationDescription = description ?? existingTask.illustrationDescription
            existingTask.pageNumber = pageNumber
            existingTask.totalPages = totalPages
            existingTask.previousIllustrationPath = previousIllustrationPath ?? existingTask.previousIllustrationPath
            
            try modelContext.save()
            return existingTask
        }
        
        // Create a new task
        let persistentTask = PendingIllustrationTask.from(
            task: task,
            pageNumber: pageNumber,
            totalPages: totalPages,
            previousIllustrationPath: previousIllustrationPath,
            illustrationDescription: description
        )
        
        modelContext.insert(persistentTask)
        try modelContext.save()
        logger.debug("Saved new task: \(task.id.uuidString), priority: \(task.priority.rawValue), status: \(task.status.rawValue)")
        
        return persistentTask
    }
    
    /// Update the status of a persisted task
    /// - Parameters:
    ///   - id: The ID of the task
    ///   - status: The new status
    /// - Returns: The updated task if found, nil otherwise
    @MainActor
    func updateTaskStatus(_ id: UUID, status: IllustrationStatus) throws -> PendingIllustrationTask? {
        guard let task = try getTaskById(id) else {
            logger.warning("Task not found for status update: \(id.uuidString)")
            return nil
        }
        
        task.status = status
        task.lastUpdatedAt = Date()
        
        try modelContext.save()
        logger.debug("Updated task status: \(id.uuidString) to \(status.rawValue)")
        
        return task
    }
    
    /// Increment the attempt count of a task
    /// - Parameter id: The ID of the task
    /// - Returns: The updated task if found, nil otherwise
    @MainActor
    func incrementTaskAttempt(_ id: UUID) throws -> PendingIllustrationTask? {
        guard let task = try getTaskById(id) else {
            logger.warning("Task not found for attempt increment: \(id.uuidString)")
            return nil
        }
        
        task.attemptCount += 1
        task.lastUpdatedAt = Date()
        
        try modelContext.save()
        logger.debug("Incremented task attempt: \(id.uuidString), new count: \(task.attemptCount)")
        
        return task
    }
    
    /// Delete a task by ID
    /// - Parameter id: The ID of the task to delete
    @MainActor
    func deleteTask(_ id: UUID) throws {
        guard let task = try getTaskById(id) else {
            logger.warning("Task not found for deletion: \(id.uuidString)")
            return
        }
        
        modelContext.delete(task)
        try modelContext.save()
        logger.debug("Deleted task: \(id.uuidString)")
    }
    
    /// Get all pending tasks (tasks not in terminal state)
    /// - Returns: Array of pending tasks
    @MainActor
    func getAllPendingTasks() throws -> [PendingIllustrationTask] {
        let pendingStatus = IllustrationStatus.pending.rawValue
        let generatingStatus = IllustrationStatus.generating.rawValue
        let scheduledStatus = IllustrationStatus.scheduled.rawValue
        
        let descriptor = FetchDescriptor<PendingIllustrationTask>(
            predicate: #Predicate<PendingIllustrationTask> { task in
                task.statusRawValue == pendingStatus || 
                task.statusRawValue == generatingStatus ||
                task.statusRawValue == scheduledStatus
            },
            sortBy: [SortDescriptor(\.priorityRawValue, order: .forward)]
        )
        
        do {
            let tasks = try modelContext.fetch(descriptor)
            logger.debug("Fetched \(tasks.count) pending tasks")
            return tasks
        } catch {
            logger.error("Error fetching pending tasks: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Get a task by its ID
    /// - Parameter id: The ID of the task
    /// - Returns: The task if found, nil otherwise
    @MainActor
    func getTaskById(_ id: UUID) throws -> PendingIllustrationTask? {
        let descriptor = FetchDescriptor<PendingIllustrationTask>(
            predicate: #Predicate<PendingIllustrationTask> { $0.id == id }
        )
        
        do {
            let tasks = try modelContext.fetch(descriptor)
            return tasks.first
        } catch {
            logger.error("Error fetching task by ID \(id.uuidString): \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Get tasks for a specific page
    /// - Parameter pageId: The ID of the page
    /// - Returns: Tasks associated with the page
    @MainActor
    func getTasksForPage(_ pageId: UUID) throws -> [PendingIllustrationTask] {
        let descriptor = FetchDescriptor<PendingIllustrationTask>(
            predicate: #Predicate<PendingIllustrationTask> { $0.pageId == pageId }
        )
        
        do {
            let tasks = try modelContext.fetch(descriptor)
            logger.debug("Fetched \(tasks.count) tasks for page \(pageId.uuidString)")
            return tasks
        } catch {
            logger.error("Error fetching tasks for page \(pageId.uuidString): \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Get tasks for a specific story
    /// - Parameter storyId: The ID of the story
    /// - Returns: Tasks associated with the story
    @MainActor
    func getTasksForStory(_ storyId: UUID) throws -> [PendingIllustrationTask] {
        let descriptor = FetchDescriptor<PendingIllustrationTask>(
            predicate: #Predicate<PendingIllustrationTask> { $0.storyId == storyId },
            sortBy: [SortDescriptor(\.pageNumber)]
        )
        
        do {
            let tasks = try modelContext.fetch(descriptor)
            logger.debug("Fetched \(tasks.count) tasks for story \(storyId.uuidString)")
            return tasks
        } catch {
            logger.error("Error fetching tasks for story \(storyId.uuidString): \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Delete all tasks for a specific story
    /// - Parameter storyId: The ID of the story
    @MainActor
    func deleteTasksForStory(_ storyId: UUID) throws {
        let tasks = try getTasksForStory(storyId)
        
        for task in tasks {
            modelContext.delete(task)
        }
        
        try modelContext.save()
        logger.debug("Deleted \(tasks.count) tasks for story \(storyId.uuidString)")
    }
    
    /// Restores tasks from persistent storage into the task manager
    /// - Parameter manager: The IllustrationTaskManager to restore tasks into
    /// - Returns: The number of tasks restored
    @MainActor
    func restoreTasksToManager(_ manager: IllustrationTaskManager) async throws -> Int {
        let pendingStatus = IllustrationStatus.pending.rawValue
        let scheduledStatus = IllustrationStatus.scheduled.rawValue
        let generatingStatus = IllustrationStatus.generating.rawValue
        
        // Find tasks that are in pending, scheduled or generating status
        let descriptor = FetchDescriptor<PendingIllustrationTask>(
            predicate: #Predicate<PendingIllustrationTask> { task in
                task.statusRawValue == pendingStatus || 
                task.statusRawValue == scheduledStatus ||
                task.statusRawValue == generatingStatus
            },
            sortBy: [SortDescriptor(\.priorityRawValue, order: .forward)]
        )
        
        let tasks = try modelContext.fetch(descriptor)
        var restoredCount = 0
        
        for persistentTask in tasks {
            // Reset any task that was in 'scheduled' or 'generating' state back to 'pending'
            // when app restarts, since these are intermediate states that should not persist
            // across app restarts
            if persistentTask.status == .scheduled || persistentTask.status == .generating {
                let oldStatus = persistentTask.status
                persistentTask.status = .pending
                logger.debug("Reset task \(persistentTask.id.uuidString) from \(oldStatus.rawValue) to pending")
            }
            
            // Create runtime task from the persistent task (which will now be in pending state)
            let runtimeTask = persistentTask.toRuntimeTask()
            manager.addTask(runtimeTask)
            restoredCount += 1
        }
        
        // Save any status changes back to persistent storage
        try modelContext.save()
        
        logger.debug("Restored \(restoredCount) tasks to the task manager")
        return restoredCount
    }
}
