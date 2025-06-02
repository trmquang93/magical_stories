import Foundation
import Testing
import SwiftData
@testable import magical_stories

/// A test class for testing the integration between various components
/// of the Illustration Service Phase 1 implementation
@MainActor
struct IllustrationIntegrationTests {
    
    /// Test the flow from scheduled task to completed illustration
    @Test func testIllustrationGenerationFlow() async throws {
        // Arrange - Create the necessary objects
        let taskManager = IllustrationTaskManager()
        let taskRepository = MockIllustrationTaskRepository()
        let mockIllustrationService = MockIllustrationServiceForCoordinator()
        
        // Create a story and page for testing
        let storyId = UUID()
        let pageId = UUID()
        let page = Page(
            id: pageId,
            content: "A test page content",
            pageNumber: 1,
            illustrationStatus: .pending,
            imagePrompt: "A beautiful illustration of a magical forest"
        )
        
        // Configure mocks to simulate successful flow
        taskRepository.tasksToReturn = []
        
        // Act - Simulate the complete flow
        
        // 1. Create an illustration task
        let task = IllustrationTask(
            pageId: pageId,
            storyId: storyId,
            priority: .critical
        )
        
        // 2. Save task to repository (simulating the StoryDetailView's action)
        let pendingTask = try await taskRepository.saveTask(
            task,
            pageNumber: 1,
            totalPages: 5,
            description: page.imagePrompt,
            previousIllustrationPath: nil
        )
        
        // Verify task is saved with correct state
        #expect(taskRepository.savedTasks.count == 1)
        #expect(pendingTask.status == .pending)
        
        // 3. Update status to scheduled (simulating when it's added to queue)
        let scheduledState: IllustrationStatus = IllustrationStatus(rawValue: "scheduled") ?? .pending
        let scheduledTask = try await taskRepository.updateTaskStatus(task.id, status: scheduledState)
        #expect(scheduledTask?.status.rawValue == "scheduled")
        #expect(taskRepository.updatedStatuses[task.id]?.rawValue == "scheduled")
        
        // Add task to the task manager
        taskManager.addTask(task)
        
        // 4. Process the task (simulating coordinator's action)
        mockIllustrationService.shouldSucceed = true
        mockIllustrationService.generatedPath = "illustrations/test_illustration.png"
        
        await taskManager.startProcessing { taskToProcess in
            var updatedTask = taskToProcess
            
            // Simulate task processing
            updatedTask.updateStatus(.generating)
            try? taskRepository.updateTaskStatus(taskToProcess.id, status: .generating)
            
            // Check repository state
            #expect(taskRepository.updatedStatuses[taskToProcess.id] == .generating)
            
            // Simulate successful illustration generation
            if let description = pendingTask.illustrationDescription {
                let path = try? await mockIllustrationService.generateIllustration(
                    for: description,
                    pageNumber: pendingTask.pageNumber,
                    totalPages: pendingTask.totalPages,
                    previousIllustrationPath: nil,
                    visualGuide: nil,
                    globalReferenceImagePath: nil
                )
                
                if path != nil {
                    updatedTask.updateStatus(.ready)
                    try? taskRepository.updateTaskStatus(taskToProcess.id, status: .ready)
                    
                    // Update page (in real app, this would update the SwiftData model)
                    page.illustrationStatus = .ready
                    page.illustrationPath = path
                } else {
                    updatedTask.updateStatus(.failed)
                    try? taskRepository.updateTaskStatus(taskToProcess.id, status: .failed)
                }
            }
            
            return updatedTask
        }
        
        // Wait for task to complete
        for _ in 0..<10 {
            if taskManager.pendingTasks.isEmpty {
                break
            }
            try? await Task.sleep(for: .milliseconds(50))
        }
        
        // Assertions
        #expect(taskManager.pendingTasks.isEmpty, "All tasks should be processed")
        #expect(taskRepository.updatedStatuses[task.id] == .ready, "Task should be marked as ready")
        #expect(page.illustrationStatus == .ready, "Page's illustration status should be ready")
        #expect(page.illustrationPath == "illustrations/test_illustration.png", "Page should have illustration path set")
        
        // Stop processing
        await taskManager.stopProcessing()
    }
    
    /// Test task restoration after app restart
    @Test func testTaskRestorationAfterRestart() async throws {
        // Arrange
        let taskManager = IllustrationTaskManager()
        let taskRepository = MockIllustrationTaskRepository()
        let networkMonitor = MockNetworkMonitor()
        
        // Create some persistent tasks that would exist in storage before "restart"
        let tasks = [
            PendingIllustrationTask(
                id: UUID(),
                pageId: UUID(),
                storyId: UUID(),
                priority: .high,
                status: IllustrationStatus(rawValue: "scheduled") ?? .pending,
                pageNumber: 1,
                totalPages: 5
            ),
            PendingIllustrationTask(
                id: UUID(),
                pageId: UUID(),
                storyId: UUID(),
                priority: .medium,
                status: IllustrationStatus(rawValue: "scheduled") ?? .pending,
                pageNumber: 2,
                totalPages: 5
            )
        ]
        taskRepository.tasksToReturn = tasks
        
        // Create coordinator
        let coordinator = TestableIllustrationCoordinator(
            taskManager: taskManager,
            taskRepository: taskRepository,
            networkMonitor: networkMonitor
        )
        
        // Act - Simulate app restart and task restoration
        await coordinator.start()
        
        // Assert
        #expect(coordinator.restoredTaskCount == 2, "Should restore 2 tasks")
        #expect(taskManager.pendingTasks.count == 2, "Task manager should have 2 tasks")
        #expect(coordinator.status == TestableIllustrationCoordinator.CoordinatorStatus.ready, "Coordinator should be ready")
        #expect(taskRepository.fetchedAllPending, "Should fetch all pending tasks")
    }
    
    /// Test integration with network connectivity changes
    @Test func testNetworkConnectivityIntegration() async throws {
        // Arrange
        let taskManager = IllustrationTaskManager()
        let taskRepository = MockIllustrationTaskRepository()
        let networkMonitor = MockNetworkMonitor()
        
        // Add a task
        let task = IllustrationTask(
            pageId: UUID(),
            storyId: UUID(),
            priority: .high
        )
        taskManager.addTask(task)
        
        // Create coordinator
        let coordinator = TestableIllustrationCoordinator(
            taskManager: taskManager,
            taskRepository: taskRepository,
            networkMonitor: networkMonitor
        )
        
        // Act & Assert - With network
        await coordinator.start()
        try? await Task.sleep(for: .milliseconds(50))
        #expect(taskManager.isProcessing, "Task processing should start with network")
        
        // Lost network
        networkMonitor.simulateConnectivityChange(hasConnectivity: false)
        try? await Task.sleep(for: .milliseconds(50))
        #expect(!taskManager.isProcessing, "Processing should stop when network is lost")
        #expect(!coordinator.hasNetworkConnectivity, "Coordinator should update connectivity status")
        
        // Network restored
        networkMonitor.simulateConnectivityChange(hasConnectivity: true)
        try? await Task.sleep(for: .milliseconds(50))
        #expect(taskManager.isProcessing, "Processing should resume when network is restored")
        #expect(coordinator.hasNetworkConnectivity, "Coordinator should update connectivity status")
    }
    
    // Helper to create an in-memory model context for testing
    private func createModelContext() -> ModelContext {
        let schema = Schema([
            Page.self,
            Story.self
        ])
        let modelContainer = try! ModelContainer(for: schema, configurations: [
            ModelConfiguration(isStoredInMemoryOnly: true)
        ])
        return ModelContext(modelContainer)
    }
}
