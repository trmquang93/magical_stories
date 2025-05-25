import Foundation
import Testing
import SwiftData
@testable import magical_stories

@Suite("Illustration Task Recovery Tests")
struct IllustrationTaskRecoveryTests {
    
    // MARK: - Helper Methods and Mocks
    
    class MockModelContextProvider {
        let modelContext: ModelContext
        
        init() {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let schema = Schema([PendingIllustrationTask.self, Page.self, Story.self])
            let container = try! ModelContainer(for: schema, configurations: config)
            self.modelContext = ModelContext(container)
        }
    }
    
    class MockIllustrationService: IllustrationServiceProtocol {
        var shouldSucceed = true
        var generatedPath = "path/to/test/illustration.png"
        var wasTaskInterrupted = false
        
        func generateIllustration(for pageText: String, theme: String) async throws -> String? {
            if wasTaskInterrupted {
                return nil
            }
            
            // Simulate some processing time
            try await Task.sleep(for: .seconds(0.1))
            
            return shouldSucceed ? generatedPath : nil
        }
        
        func generateIllustration(
            for illustrationDescription: String,
            pageNumber: Int,
            totalPages: Int,
            previousIllustrationPath: String?,
            visualGuide: VisualGuide?,
            globalReferenceImagePath: String?
        ) async throws -> String? {
            if wasTaskInterrupted {
                return nil
            }
            
            // Simulate some processing time
            try await Task.sleep(for: .seconds(0.1))
            
            return shouldSucceed ? generatedPath : nil
        }
    }

    @Test("Tasks stuck in scheduled or generating status should be reset on app restart")
    @MainActor
    func testRecoveryFromIncompleteState() async throws {
        // Arrange: Create our mocks and components
        let contextProvider = MockModelContextProvider()
        let taskManager = IllustrationTaskManager()
        let taskRepository = IllustrationTaskRepository(modelContext: contextProvider.modelContext)
        
        // Create a page with pending illustration status
        let page = Page(
            id: UUID(),
            content: "This is a test page for illustration recovery",
            pageNumber: 1,
            illustrationStatus: .pending
        )
        
        // Create a story with the page
        let storyId = UUID()
        let story = Story(
            id: storyId,
            title: "Test Story for Recovery",
            pages: [page],
            parameters: StoryParameters(childName: "Test", childAge: 7, theme: "Adventure"),
            collections: []
        )
        
        // 1. First, let's simulate the initial state (tasks are created and persisted)
        let task = IllustrationTask(
            pageId: page.id,
            storyId: story.id,
            priority: .high
        )
        
        // Add to task manager (in-memory state)
        taskManager.addTask(task)
        
        // Save to repository (persistent state)
        _ = try taskRepository.saveTask(
            task,
            pageNumber: page.pageNumber,
            totalPages: 1,
            description: page.content
        )
        
        // Update status to 'scheduled' to simulate it being picked up
        let _ = try taskRepository.updateTaskStatus(task.id, status: .scheduled)
        
        // Create some tasks in the 'generating' state too
        let generatingTask = IllustrationTask(
            pageId: UUID(),
            storyId: story.id,
            priority: .medium,
            status: .pending
        )
        _ = try taskRepository.saveTask(
            generatingTask,
            pageNumber: 2,
            totalPages: 5,
            description: "Another test page"
        )
        let _ = try taskRepository.updateTaskStatus(generatingTask.id, status: .generating)
        
        // 2. Verify the initial state
        let tasks = try taskRepository.getAllPendingTasks()
        #expect(tasks.count == 2, "Should have 2 pending tasks")
        #expect(tasks.contains { $0.status == .scheduled }, "Should have a task in scheduled state")
        #expect(tasks.contains { $0.status == .generating }, "Should have a task in generating state")
        
        // 3. Now let's simulate app restart
        // Clear the task manager (app terminated)
        taskManager.clearAllTasks()
        #expect(taskManager.pendingTasks.isEmpty, "Task manager should be empty after app termination")
        
        // Create a new coordinator to handle app restart
        let coordinator = IllustrationCoordinator(
            taskManager: taskManager,
            taskRepository: taskRepository
        )
        
        // Start the coordinator (simulating app restart)
        await coordinator.start()
        
        // 4. Verify that the tasks have been recovered AND their status reset
        // The tasks should be back in the manager
        #expect(taskManager.pendingTasks.count == 2, "Task manager should have restored 2 tasks")
        
        // Check the repository - tasks should now be in pending state instead of scheduled/generating
        let recoveredTasks = try taskRepository.getAllPendingTasks()
        #expect(recoveredTasks.count == 2, "Should have 2 tasks after recovery")
        
        // Verify that all tasks that were in scheduled or generating state have been properly 
        // reset to pending state by the IllustrationTaskRepository's restoreTasksToManager method
        #expect(!recoveredTasks.contains { $0.status == .scheduled }, "Tasks should no longer be in scheduled state")
        #expect(!recoveredTasks.contains { $0.status == .generating }, "Tasks should no longer be in generating state")
        #expect(recoveredTasks.allSatisfy { $0.status == .pending }, "All tasks should be reset to pending status")
        #expect(recoveredTasks.allSatisfy { $0.status == .pending }, "All tasks should be reset to pending status")
    }
}
