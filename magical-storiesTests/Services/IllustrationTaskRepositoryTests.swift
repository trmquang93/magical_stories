import Foundation
import Testing
import SwiftData
@testable import magical_stories

@Suite("IllustrationTaskRepository Tests")
struct IllustrationTaskRepositoryTests {
    
    // Helper to create runtime tasks for testing
    func createRuntimeTask(status: IllustrationStatus = .pending) -> IllustrationTask {
        return IllustrationTask(
            id: UUID(),
            pageId: UUID(),
            storyId: UUID(),
            priority: .medium,
            status: status,
            createdAt: Date(),
            lastUpdatedAt: Date(),
            attemptCount: 0
        )
    }
    
    // Helper to create persistent tasks
    func createPersistentTask(
        id: UUID = UUID(),
        pageId: UUID = UUID(),
        storyId: UUID = UUID(),
        status: IllustrationStatus = .pending
    ) -> PendingIllustrationTask {
        return PendingIllustrationTask(
            id: id,
            pageId: pageId,
            storyId: storyId,
            priority: .medium,
            status: status,
            pageNumber: 1,
            totalPages: 5
        )
    }
    
    @Test("Repository saveTask adds new task correctly")
    @MainActor
    func testSaveTask() throws {
        // Arrange
        let mockRepository = MockIllustrationTaskRepository()
        let task = createRuntimeTask()
        
        // Act
        let savedTask = try mockRepository.saveTask(
            task,
            pageNumber: 2,
            totalPages: 10,
            description: "Test description",
            previousIllustrationPath: "path/to/image.png"
        )
        
        // Assert
        #expect(mockRepository.savedTasks.count == 1)
        #expect(mockRepository.savedTasks[task.id] != nil)
        #expect(savedTask.pageNumber == 2)
        #expect(savedTask.totalPages == 10)
        #expect(savedTask.illustrationDescription == "Test description")
        #expect(savedTask.previousIllustrationPath == "path/to/image.png")
    }
    
    @Test("Repository updateTaskStatus changes task status")
    @MainActor
    func testUpdateTaskStatus() throws {
        // Arrange
        let mockRepository = MockIllustrationTaskRepository()
        let taskId = UUID()
        let task = createPersistentTask(id: taskId, status: .pending)
        mockRepository.taskToReturn = task
        
        // Act
        let updatedTask = try mockRepository.updateTaskStatus(taskId, status: .ready)
        
        // Assert
        #expect(updatedTask != nil)
        #expect(updatedTask?.status == .ready)
        #expect(mockRepository.updatedStatuses[taskId] == .ready)
    }
    
    @Test("Repository incrementTaskAttempt increases attempt count")
    @MainActor
    func testIncrementTaskAttempt() throws {
        // Arrange
        let mockRepository = MockIllustrationTaskRepository()
        let taskId = UUID()
        let task = createPersistentTask(id: taskId)
        task.attemptCount = 1
        mockRepository.taskToReturn = task
        
        // Act
        let updatedTask = try mockRepository.incrementTaskAttempt(taskId)
        
        // Assert
        #expect(updatedTask != nil)
        #expect(updatedTask?.attemptCount == 2)
        #expect(mockRepository.incrementedAttempts.contains(taskId))
    }
    
    @Test("Repository deleteTask removes task by ID")
    @MainActor
    func testDeleteTask() throws {
        // Arrange
        let mockRepository = MockIllustrationTaskRepository()
        let taskId = UUID()
        
        // Act
        try mockRepository.deleteTask(taskId)
        
        // Assert
        #expect(mockRepository.deletedTasks.contains(taskId))
    }
    
    @Test("Repository getAllPendingTasks returns pending tasks")
    @MainActor
    func testGetAllPendingTasks() throws {
        // Arrange
        let mockRepository = MockIllustrationTaskRepository()
        let tasks = [
            createPersistentTask(status: .pending),
            createPersistentTask(status: .generating)
        ]
        mockRepository.tasksToReturn = tasks
        
        // Act
        let pendingTasks = try mockRepository.getAllPendingTasks()
        
        // Assert
        #expect(mockRepository.fetchedAllPending)
        #expect(pendingTasks.count == 2)
    }
    
    @Test("Repository getTaskById finds task by ID")
    @MainActor
    func testGetTaskById() throws {
        // Arrange
        let mockRepository = MockIllustrationTaskRepository()
        let taskId = UUID()
        let task = createPersistentTask(id: taskId)
        mockRepository.taskToReturn = task
        
        // Act
        let retrievedTask = try mockRepository.getTaskById(taskId)
        
        // Assert
        #expect(retrievedTask != nil)
        #expect(retrievedTask?.id == taskId)
        #expect(mockRepository.fetchedById.contains(taskId))
    }
    
    @Test("Repository getTasksForPage retrieves tasks for page")
    @MainActor
    func testGetTasksForPage() throws {
        // Arrange
        let mockRepository = MockIllustrationTaskRepository()
        let pageId = UUID()
        let tasks = [
            createPersistentTask(pageId: pageId),
            createPersistentTask(pageId: pageId)
        ]
        mockRepository.tasksToReturn = tasks
        
        // Act
        let pageTasks = try mockRepository.getTasksForPage(pageId)
        
        // Assert
        #expect(pageTasks.count == 2)
        #expect(mockRepository.fetchedByPage.contains(pageId))
    }
    
    @Test("Repository getTasksForStory retrieves tasks for story")
    @MainActor
    func testGetTasksForStory() throws {
        // Arrange
        let mockRepository = MockIllustrationTaskRepository()
        let storyId = UUID()
        let tasks = [
            createPersistentTask(storyId: storyId),
            createPersistentTask(storyId: storyId)
        ]
        mockRepository.tasksToReturn = tasks
        
        // Act
        let storyTasks = try mockRepository.getTasksForStory(storyId)
        
        // Assert
        #expect(storyTasks.count == 2)
        #expect(mockRepository.fetchedByStory.contains(storyId))
    }
    
    @Test("Repository deleteTasksForStory removes all story tasks")
    @MainActor
    func testDeleteTasksForStory() throws {
        // Arrange
        let mockRepository = MockIllustrationTaskRepository()
        let storyId = UUID()
        
        // Act
        try mockRepository.deleteTasksForStory(storyId)
        
        // Assert
        #expect(mockRepository.deletedTasksForStory.contains(storyId))
    }
    
    @Test("Repository handles errors correctly")
    @MainActor
    func testErrorHandling() throws {
        // Arrange
        let mockRepository = MockIllustrationTaskRepository()
        mockRepository.shouldThrowError = true
        let task = createRuntimeTask()
        
        // Act & Assert
        do {
            _ = try mockRepository.saveTask(task, pageNumber: 1, totalPages: 1, description: nil, previousIllustrationPath: nil)
            #expect(false, "Expected an error to be thrown")
        } catch {
            // Success, we expected an error
            #expect(true)
        }
    }
}
