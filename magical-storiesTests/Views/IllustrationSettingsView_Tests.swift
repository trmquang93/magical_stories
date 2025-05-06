import SwiftUI
import Testing
import SwiftData
@testable import magical_stories

@MainActor
struct IllustrationSettingsView_Tests {
    
    // Test that the tasks are displayed in the UI
    @Test func testTasksDisplayed() async throws {
        // Arrange
        let taskManager = IllustrationTaskManager()
        
        // Create tasks with different states
        let pendingTask = IllustrationTask(
            pageId: UUID(),
            storyId: UUID(),
            priority: .medium
        )
        
        var generatingTask = IllustrationTask(
            pageId: UUID(),
            storyId: UUID(),
            priority: .critical
        )
        generatingTask.updateStatus(.generating)
        
        // Add tasks to manager
        taskManager.addTask(pendingTask)
        taskManager.addTask(generatingTask)
        
        #expect(taskManager.pendingTasks.count == 2, "Task manager should have 2 tasks")
        #expect(taskManager.pendingTasks.contains { $0.status == .pending }, "Should have pending task")
        #expect(taskManager.pendingTasks.contains { $0.status == .generating }, "Should have generating task")
    }
    
    // Test task processing control
    @Test func testTaskProcessingControl() async throws {
        // Arrange
        let taskManager = IllustrationTaskManager()
        let task = IllustrationTask(
            pageId: UUID(),
            storyId: UUID(),
            priority: .high
        )
        taskManager.addTask(task)
        
        // Mock processing
        var processingStarted = await taskManager.startProcessing { task in
            return task
        }
        
        // Assert
        #expect(processingStarted, "Task processing should start successfully")
        #expect(taskManager.isProcessing, "Task processing should be active")
        
        // Act - Stop processing
        await taskManager.stopProcessing()
        
        // Assert
        #expect(!taskManager.isProcessing, "Task processing should be stopped")
        
        // Test that we can restart processing
        processingStarted = await taskManager.startProcessing { task in
            return task
        }
        
        // Assert
        #expect(processingStarted, "Task processing should restart successfully")
        #expect(taskManager.isProcessing, "Task processing should be active after restart")
    }
    
    // Test task priority ordering
    @Test func testTaskPriorityOrdering() throws {
        // Arrange - Create tasks with different priorities
        let taskManager = IllustrationTaskManager()
        
        let lowPriorityTask = IllustrationTask(
            pageId: UUID(),
            storyId: UUID(),
            priority: .low
        )
        
        let mediumPriorityTask = IllustrationTask(
            pageId: UUID(),
            storyId: UUID(),
            priority: .medium
        )
        
        let highPriorityTask = IllustrationTask(
            pageId: UUID(),
            storyId: UUID(),
            priority: .high
        )
        
        let criticalPriorityTask = IllustrationTask(
            pageId: UUID(), 
            storyId: UUID(),
            priority: .critical
        )
        
        // Add tasks to manager in non-priority order
        taskManager.addTask(lowPriorityTask)
        taskManager.addTask(mediumPriorityTask)
        taskManager.addTask(criticalPriorityTask)
        taskManager.addTask(highPriorityTask)
        
        // Act - Get next task
        let nextTask = taskManager.getNextTask()
        
        // Assert - Critical should be first
        #expect(nextTask?.priority == .critical, "Critical priority task should be processed first")
        
        // Act & Assert - Continue getting tasks in priority order
        let secondTask = taskManager.getNextTask()
        #expect(secondTask?.priority == .high, "High priority task should be processed second")
        
        let thirdTask = taskManager.getNextTask()
        #expect(thirdTask?.priority == .medium, "Medium priority task should be processed third")
        
        let fourthTask = taskManager.getNextTask()
        #expect(fourthTask?.priority == .low, "Low priority task should be processed fourth")
    }
}
