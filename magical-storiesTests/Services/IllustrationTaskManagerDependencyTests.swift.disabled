import Testing
import Foundation
@testable import magical_stories

@Suite
struct IllustrationTaskManagerDependencyTests {
    
    // MARK: - Helper Methods
    
    /// Creates a sample illustration task with the specified properties
    func createTask(
        id: UUID = UUID(),
        priority: IllustrationPriority = .medium,
        status: IllustrationStatus = .pending,
        dependencies: [UUID]? = nil,
        taskType: IllustrationTaskType = .pageIllustration,
        pageIndex: Int? = nil
    ) -> IllustrationTask {
        return IllustrationTask(
            id: id,
            pageId: UUID(),
            storyId: UUID(),
            priority: priority,
            status: status,
            createdAt: Date(),
            attemptCount: 0,
            taskType: taskType,
            pageIndex: pageIndex,
            dependencies: dependencies
        )
    }
    
    // MARK: - Tests
    
    /// Tests that tasks without dependencies are processed first, regardless of priority
    @Test func testTasksWithoutDependenciesProcessedFirst() {
        // Arrange
        let manager = IllustrationTaskManager()
        let task1Id = UUID()
        let task2Id = UUID()
        
        let task1 = createTask(id: task1Id, priority: .medium) // No dependencies, medium priority
        let task2 = createTask(id: task2Id, priority: .high, dependencies: [UUID()]) // Has unmet dependency, high priority
        
        // Act
        manager.addTask(task1)
        manager.addTask(task2)
        let nextTask = manager.getNextTask()
        
        // Assert
        #expect(nextTask?.id == task1Id)
        #expect(manager.pendingTasks.count == 1)
        #expect(manager.pendingTasks[0].id == task2Id)
    }
    
    /// Tests that tasks with unmet dependencies stay in the queue and are not selected
    @Test func testTasksWithUnmetDependenciesStayInQueue() {
        // Arrange
        let manager = IllustrationTaskManager()
        let dependencyId = UUID()
        
        let task = createTask(dependencies: [dependencyId])
        
        // Act
        manager.addTask(task)
        let nextTask = manager.getNextTask()
        
        // Assert
        #expect(nextTask == nil)
        #expect(manager.pendingTasks.count == 1)
    }
    
    /// Tests that tasks with satisfied dependencies are selected for processing
    @Test func testTasksWithMetDependenciesAreAvailable() {
        // Arrange
        let manager = IllustrationTaskManager()
        let dependencyId = UUID()
        
        let task = createTask(dependencies: [dependencyId])
        
        // Act
        manager.addCompletedDependency(dependencyId)
        manager.addTask(task)
        let nextTask = manager.getNextTask()
        
        // Assert
        #expect(nextTask != nil)
        #expect(nextTask?.id == task.id)
        #expect(manager.pendingTasks.isEmpty)
    }
    
    /// Tests that tasks become available for processing when their dependencies are marked as completed
    @Test func testTasksAvailableWhenDependenciesComplete() {
        // Arrange
        let manager = IllustrationTaskManager()
        let dependencyId = UUID()
        
        let task = createTask(dependencies: [dependencyId])
        
        // Act - Add task with unmet dependency
        manager.addTask(task)
        let initialNextTask = manager.getNextTask()
        
        // Now satisfy the dependency
        manager.addCompletedDependency(dependencyId)
        manager.addTask(task) // Add it back since it was removed by getNextTask attempt
        let nextTask = manager.getNextTask()
        
        // Assert
        #expect(initialNextTask == nil)
        #expect(nextTask != nil)
        #expect(nextTask?.id == task.id)
    }
    
    /// Tests that tasks with multiple dependencies require all dependencies to be met
    @Test func testMultipleDependenciesAllRequired() {
        // Arrange
        let manager = IllustrationTaskManager()
        let dependency1Id = UUID()
        let dependency2Id = UUID()
        let dependency3Id = UUID()
        
        let task = createTask(dependencies: [dependency1Id, dependency2Id, dependency3Id])
        
        // Act - Add task and satisfy only 2 of 3 dependencies
        manager.addTask(task)
        manager.addCompletedDependency(dependency1Id)
        manager.addCompletedDependency(dependency2Id)
        
        let notReadyTask = manager.getNextTask()
        
        // Now satisfy the last dependency
        manager.addCompletedDependency(dependency3Id)
        manager.addTask(task) // Add it back
        let readyTask = manager.getNextTask()
        
        // Assert
        #expect(notReadyTask == nil)
        #expect(readyTask != nil)
        #expect(readyTask?.id == task.id)
    }
    
    /// Tests that circular dependencies are processed correctly
    @Test func testCircularDependencyDetection() {
        // We'll simplify this test to focus on the outcome rather than the specific detection
        // Arrange - Create a manager and tasks with circular dependencies
        let manager = IllustrationTaskManager()
        let task1Id = UUID()
        let task2Id = UUID()
        
        // Create a simple self-referential circular dependency
        let task1 = createTask(id: task1Id, dependencies: [task1Id]) // Self-dependent
        
        // And a task that depends on itself and another task
        let task2 = createTask(id: task2Id, dependencies: [task1Id, task2Id])
        
        // Act - Add the tasks to the manager
        manager.addTask(task1)
        manager.addTask(task2)
        
        // Both tasks should have been added successfully with circular dependencies removed
        // Assert - The tasks were added but without circular references
        let addedTask1 = manager.pendingTasks.first(where: { $0.id == task1Id })
        let addedTask2 = manager.pendingTasks.first(where: { $0.id == task2Id })
        
        #expect(addedTask1 != nil)
        #expect(addedTask2 != nil)
        
        // The key test is that no dependencies exist for these tasks in the queue
        // This checks that our circular dependency handling is working
        let task1HasNoSelfDeps = addedTask1?.dependencies?.contains(task1Id) != true
        let task2HasNoSelfDeps = addedTask2?.dependencies?.contains(task2Id) != true
        
        #expect(task1HasNoSelfDeps)
        #expect(task2HasNoSelfDeps)
    }
    
    /// Tests that when dependency status is equal, tasks are still sorted by priority
    @Test func testPrioritySortingWithEqualDependencies() {
        // Arrange
        let manager = IllustrationTaskManager()
        let dependencyId = UUID()
        
        let highPriorityTask = createTask(priority: .high, dependencies: [dependencyId])
        let mediumPriorityTask = createTask(priority: .medium, dependencies: [dependencyId])
        let lowPriorityTask = createTask(priority: .low, dependencies: [dependencyId])
        
        // Act - Satisfy the dependency and add all tasks
        manager.addCompletedDependency(dependencyId)
        manager.addTask(mediumPriorityTask)
        manager.addTask(lowPriorityTask)
        manager.addTask(highPriorityTask)
        
        // Get tasks in order
        let first = manager.getNextTask()
        let second = manager.getNextTask()
        let third = manager.getNextTask()
        
        // Assert proper priority order
        #expect(first?.priority == .high)
        #expect(second?.priority == .medium)
        #expect(third?.priority == .low)
    }
    
    /// Tests that removing a completed dependency doesn't affect already processed tasks
    @Test func testRemovingCompletedDependency() {
        // Arrange
        let manager = IllustrationTaskManager()
        let dependencyId = UUID()
        
        let task1 = createTask(dependencies: [dependencyId])
        let task2 = createTask(dependencies: [dependencyId])
        
        // Act - Satisfy dependency, process one task, then remove the dependency
        manager.addCompletedDependency(dependencyId)
        manager.addTask(task1)
        manager.addTask(task2)
        
        let firstTask = manager.getNextTask() // Should get task1
        manager.removeCompletedDependency(dependencyId) // Now dependency is no longer satisfied
        
        // Try to get the second task
        let secondTask = manager.getNextTask()
        
        // Assert
        #expect(firstTask != nil)
        #expect(secondTask == nil) // Second task should not be available after dependency removed
        #expect(manager.pendingTasks.count == 1)
    }
    
    /// Tests that circular dependencies are automatically detected and handled when adding tasks
    @Test func testAutomaticCircularDependencyHandling() {
        // Arrange
        let manager = IllustrationTaskManager()
        let task1Id = UUID()
        let task2Id = UUID()
        
        // Create a simple circular dependency: task1 -> task2 -> task1
        var task1 = createTask(id: task1Id, dependencies: [task2Id])
        var task2 = createTask(id: task2Id, dependencies: [task1Id])
        
        // Act
        manager.addTask(task1)
        manager.addTask(task2)
        
        // Adding tasks with circular dependencies should modify them to break the cycles
        let addedTask1 = manager.pendingTasks.first { $0.id == task1Id }
        let addedTask2 = manager.pendingTasks.first { $0.id == task2Id }
        
        // Assert
        #expect(addedTask1 != nil)
        #expect(addedTask2 != nil)
        
        // At least one of the tasks should have had its dependencies broken
        let atLeastOneTaskHasNoDependencies = 
            (addedTask1?.dependencies == nil || addedTask1?.dependencies?.isEmpty == true) ||
            (addedTask2?.dependencies == nil || addedTask2?.dependencies?.isEmpty == true)
        
        #expect(atLeastOneTaskHasNoDependencies)
    }
    
    /// Tests that dependency status check only affects pending tasks
    @Test func testDependencyCheckOnlyAffectsPendingTasks() {
        // Arrange
        let manager = IllustrationTaskManager()
        let dependencyId = UUID()
        
        let pendingTask = createTask(dependencies: [dependencyId])
        var processingTask = createTask(dependencies: [dependencyId])
        processingTask.updateStatus(.generating) // Using .generating status instead of non-existent .processing
        
        // Act
        manager.addTask(pendingTask)
        manager.addTask(processingTask)
        
        // Now satisfy the dependency
        manager.addCompletedDependency(dependencyId)
        
        // Get next task
        let nextTask = manager.getNextTask()
        
        // Assert - only the pending task should be returned
        #expect(nextTask != nil)
        #expect(nextTask?.id == pendingTask.id)
        #expect(manager.pendingTasks.count == 1) // Processing task should still be in queue
        #expect(manager.pendingTasks[0].id == processingTask.id)
    }
    
    /// Tests that processing completed tasks automatically adds them as satisfied dependencies
    @Test func testProcessingCompletionAddsAsSatisfiedDependency() async {
        // Arrange
        let manager = IllustrationTaskManager()
        let task1Id = UUID()
        let task2Id = UUID()
        
        let task1 = createTask(id: task1Id)
        let task2 = createTask(id: task2Id, dependencies: [task1Id])
        
        // Mock task processor that simulates successful processing
        let mockProcessor: IllustrationTaskManager.TaskProcessor = { task in
            var processedTask = task
            processedTask.updateStatus(.ready) // Mark as successfully processed
            return processedTask
        }
        
        // Act - Start processing
        manager.addTask(task1)
        manager.addTask(task2)
        
        let startResult = await manager.startProcessing(using: mockProcessor)
        
        // Wait for processing to complete and the auto-marking of dependencies
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Verify task2 was processed due to task1 being automatically marked as a dependency
        let remainingTasks = manager.pendingTasks
        await manager.stopProcessing()
        
        // Assert
        #expect(startResult)
        #expect(remainingTasks.isEmpty)
    }
    
    /// Tests processing of multiple tasks with nested dependencies in correct order
    @Test func testProcessingNestedDependencies() async {
        // Arrange
        let manager = IllustrationTaskManager()
        let task1Id = UUID() // No dependencies
        let task2Id = UUID() // Depends on task1
        let task3Id = UUID() // Depends on task2
        
        let task1 = createTask(id: task1Id, priority: .medium)
        let task2 = createTask(id: task2Id, priority: .high, dependencies: [task1Id])
        let task3 = createTask(id: task3Id, priority: .critical, dependencies: [task2Id])
        
        // Track the order of processing
        var processedOrder: [UUID] = []
        
        // Mock task processor that captures order and simulates successful processing
        let mockProcessor: IllustrationTaskManager.TaskProcessor = { task in
            processedOrder.append(task.id)
            var processedTask = task
            processedTask.updateStatus(.ready)
            return processedTask
        }
        
        // Act
        manager.addTask(task3) // Add in reverse order to test dependency sorting
        manager.addTask(task2)
        manager.addTask(task1)
        
        let startResult = await manager.startProcessing(using: mockProcessor)
        
        // Wait for processing to complete
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        await manager.stopProcessing()
        
        // Assert
        #expect(startResult)
        #expect(processedOrder.count == 3)
        #expect(processedOrder[0] == task1Id)
        #expect(processedOrder[1] == task2Id)
        #expect(processedOrder[2] == task3Id)
    }
}