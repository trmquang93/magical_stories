import Foundation
import Testing
import SwiftData
@testable import magical_stories

@Suite("IllustrationTaskManager Tests")
struct IllustrationTaskManagerTests {
    
    // Helper function to create tasks with specified priorities
    func createTask(priority: IllustrationPriority = .medium) -> IllustrationTask {
        return IllustrationTask(
            pageId: UUID(),
            storyId: UUID(),
            priority: priority
        )
    }
    
    @Test("IllustrationTaskManager initializes with empty queue")
    func testInitialization() {
        // Act
        let manager = IllustrationTaskManager()
        
        // Assert
        #expect(manager.pendingTasks.isEmpty)
        #expect(!manager.isProcessing)
    }
    
    @Test("IllustrationTaskManager adds tasks to queue")
    func testAddTask() {
        // Arrange
        let manager = IllustrationTaskManager()
        let task = createTask()
        
        // Act
        manager.addTask(task)
        
        // Assert
        #expect(manager.pendingTasks.count == 1)
        #expect(manager.pendingTasks.first?.id == task.id)
    }
    
    @Test("IllustrationTaskManager prioritizes critical tasks first")
    func testTaskPriority() {
        // Arrange
        let manager = IllustrationTaskManager()
        let mediumTask = createTask(priority: .medium)
        let highTask = createTask(priority: .high)
        let lowTask = createTask(priority: .low)
        let criticalTask = createTask(priority: .critical)
        
        // Add tasks in non-priority order
        manager.addTask(mediumTask)
        manager.addTask(lowTask)
        manager.addTask(highTask)
        manager.addTask(criticalTask)
        
        // Act
        let nextTask = manager.getNextTask()
        
        // Assert
        #expect(nextTask?.id == criticalTask.id, "Critical task should be processed first")
        
        // Act & Assert - Continue to check priority ordering
        #expect(manager.getNextTask()?.id == highTask.id, "High task should be processed second")
        #expect(manager.getNextTask()?.id == mediumTask.id, "Medium task should be processed third")
        #expect(manager.getNextTask()?.id == lowTask.id, "Low task should be processed fourth")
        #expect(manager.getNextTask() == nil, "Queue should be empty after processing all tasks")
    }
    
    @Test("IllustrationTaskManager removes task by ID")
    func testRemoveTask() {
        // Arrange
        let manager = IllustrationTaskManager()
        let task1 = createTask()
        let task2 = createTask()
        let task3 = createTask()
        
        manager.addTask(task1)
        manager.addTask(task2)
        manager.addTask(task3)
        
        // Act
        let removed = manager.removeTask(id: task2.id)
        
        // Assert
        #expect(removed, "Task should be successfully removed")
        #expect(manager.pendingTasks.count == 2, "Queue should have 2 remaining tasks")
        #expect(!manager.pendingTasks.contains(where: { $0.id == task2.id }), "Removed task should not be in queue")
        
        // Act & Assert - Try removing a non-existent task
        let nonExistentRemoved = manager.removeTask(id: UUID())
        #expect(!nonExistentRemoved, "Removing non-existent task should return false")
    }
    
    @Test("IllustrationTaskManager processes tasks correctly")
    @MainActor
    func testProcessTasks() async {
        // Arrange
        let manager = IllustrationTaskManager()
        let task1 = createTask(priority: .high)
        let task2 = createTask(priority: .medium)
        
        // Mock task processor that simply marks tasks as completed after a delay
        let mockProcessor: IllustrationTaskManager.TaskProcessor = { task in
            // Simulate processing by updating status
            var processedTask = task
            processedTask.updateStatus(.generating)
            try? await Task.sleep(for: .milliseconds(100))
            processedTask.updateStatus(.ready)
            return processedTask
        }
        
        manager.addTask(task1)
        manager.addTask(task2)
        
        // Act
        let processingStarted = await manager.startProcessing(using: mockProcessor)
        
        // Assert
        #expect(processingStarted, "Processing should start successfully")
        #expect(manager.isProcessing, "Manager should be in processing state")
        
        // Wait for tasks to complete (with timeout)
        for _ in 0..<10 {
            if manager.pendingTasks.isEmpty {
                break
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
        
        // Assert all tasks are processed
        #expect(manager.pendingTasks.isEmpty, "All tasks should be processed")
        
        // Stop processing and check state
        await manager.stopProcessing()
        #expect(!manager.isProcessing, "Manager should no longer be processing")
    }
    
    @Test("IllustrationTaskManager doesn't reprocess in-progress tasks")
    func testNoReprocessingInProgressTasks() {
        // Arrange
        let manager = IllustrationTaskManager()
        var task = createTask()
        task.updateStatus(.generating) // Mark as in progress
        
        // Act
        manager.addTask(task)
        let nextTask = manager.getNextTask()
        
        // Assert
        #expect(nextTask == nil, "In-progress task should not be returned for processing")
    }
    
    @Test("IllustrationTaskManager can clear all pending tasks")
    func testClearAllTasks() {
        // Arrange
        let manager = IllustrationTaskManager()
        manager.addTask(createTask())
        manager.addTask(createTask())
        manager.addTask(createTask())
        
        // Act
        manager.clearAllTasks()
        
        // Assert
        #expect(manager.pendingTasks.isEmpty, "Task queue should be empty after clearing")
    }
}
