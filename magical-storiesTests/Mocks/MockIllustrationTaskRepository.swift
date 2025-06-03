import Foundation
@testable import magical_stories

/// Mock implementation of the illustration task repository for testing
class MockIllustrationTaskRepository: IllustrationTaskRepositoryProtocol {
    // Track operations for verification
    var savedTasks: [UUID: PendingIllustrationTask] = [:]
    var updatedStatuses: [UUID: IllustrationStatus] = [:]
    var incrementedAttempts: [UUID] = []
    var deletedTasks: [UUID] = []
    var fetchedAllPending = false
    var fetchedById: [UUID] = []
    var fetchedByPage: [UUID] = []
    var fetchedByStory: [UUID] = []
    var deletedTasksForStory: [UUID] = []
    
    // Configure mock behavior
    var taskToReturn: PendingIllustrationTask?
    var tasksToReturn: [PendingIllustrationTask] = []
    var shouldThrowError = false
    var errorToThrow = NSError(domain: "MockError", code: 1, userInfo: nil)
    
    // Helper to reset mock state
    func reset() {
        savedTasks = [:]
        updatedStatuses = [:]
        incrementedAttempts = []
        deletedTasks = []
        fetchedAllPending = false
        fetchedById = []
        fetchedByPage = []
        fetchedByStory = []
        deletedTasksForStory = []
        
        taskToReturn = nil
        tasksToReturn = []
        shouldThrowError = false
    }
    
    // Implementation of the protocol methods
    
    @MainActor
    func saveTask(_ task: IllustrationTask, pageNumber: Int, totalPages: Int, description: String?, previousIllustrationPath: String?) throws -> PendingIllustrationTask {
        if shouldThrowError {
            throw errorToThrow
        }
        
        let persistentTask = PendingIllustrationTask.from(
            task: task,
            pageNumber: pageNumber,
            totalPages: totalPages,
            previousIllustrationPath: previousIllustrationPath,
            illustrationDescription: description
        )
        
        savedTasks[task.id] = persistentTask
        return persistentTask
    }
    
    @MainActor
    func updateTaskStatus(_ id: UUID, status: IllustrationStatus) throws -> PendingIllustrationTask? {
        if shouldThrowError {
            throw errorToThrow
        }
        
        updatedStatuses[id] = status
        
        if let task = taskToReturn {
            var updatedTask = task
            updatedTask.status = status
            return updatedTask
        }
        
        return nil
    }
    
    @MainActor
    func incrementTaskAttempt(_ id: UUID) throws -> PendingIllustrationTask? {
        if shouldThrowError {
            throw errorToThrow
        }
        
        incrementedAttempts.append(id)
        
        if let task = taskToReturn {
            var updatedTask = task
            updatedTask.attemptCount += 1
            return updatedTask
        }
        
        return nil
    }
    
    @MainActor
    func deleteTask(_ id: UUID) throws {
        if shouldThrowError {
            throw errorToThrow
        }
        
        deletedTasks.append(id)
    }
    
    @MainActor
    func getAllPendingTasks() throws -> [PendingIllustrationTask] {
        if shouldThrowError {
            throw errorToThrow
        }
        
        fetchedAllPending = true
        return tasksToReturn
    }
    
    @MainActor
    func getTaskById(_ id: UUID) throws -> PendingIllustrationTask? {
        if shouldThrowError {
            throw errorToThrow
        }
        
        fetchedById.append(id)
        return taskToReturn
    }
    
    @MainActor
    func getTasksForPage(_ pageId: UUID) throws -> [PendingIllustrationTask] {
        if shouldThrowError {
            throw errorToThrow
        }
        
        fetchedByPage.append(pageId)
        return tasksToReturn
    }
    
    @MainActor
    func getTasksForStory(_ storyId: UUID) throws -> [PendingIllustrationTask] {
        if shouldThrowError {
            throw errorToThrow
        }
        
        fetchedByStory.append(storyId)
        return tasksToReturn
    }
    
    @MainActor
    func deleteTasksForStory(_ storyId: UUID) throws {
        if shouldThrowError {
            throw errorToThrow
        }
        
        deletedTasksForStory.append(storyId)
    }
    
    @MainActor
    func restoreTasksToManager(_ manager: IllustrationTaskManager) async throws -> Int {
        if shouldThrowError {
            throw errorToThrow
        }
        
        fetchedAllPending = true
        var restoredCount = 0
        
        for task in tasksToReturn {
            let runtimeTask = task.toRuntimeTask()
            manager.addTask(runtimeTask)
            restoredCount += 1
        }
        
        return restoredCount
    }
    
    @MainActor
    func getCompletedGlobalReferenceTask(for storyId: UUID) throws -> PendingIllustrationTask? {
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Return the first completed global reference task for the story
        for task in tasksToReturn {
            if task.storyId == storyId && 
               task.taskType == .globalReference && 
               task.status == .ready {
                return task
            }
        }
        return nil
    }
    
    @MainActor
    func updateTaskIllustrationPath(_ id: UUID, illustrationPath: String) throws -> PendingIllustrationTask? {
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Track the update operation
        if var task = taskToReturn {
            task.illustrationPath = illustrationPath
            return task
        }
        
        return nil
    }
}
