import Foundation
import SwiftData
import SwiftUI

// Import our components directly
import OSLog

/// Responsible for setting up and initializing the illustration task system on app startup
@MainActor
class IllustrationTaskManagerSetup {
    /// Singleton instance
    static let shared = IllustrationTaskManagerSetup()
    
    /// The coordinator that manages the illustration task system
    private(set) var coordinator: IllustrationCoordinator?
    
    /// The task manager for handling illustration generation tasks
    var taskManager: IllustrationTaskManager? {
        coordinator?.taskManager
    }
    
    private init() {}
    
    /// Initialize the task manager and coordinator
    /// - Parameter modelContext: The SwiftData model context to use
    func initialize(with modelContext: ModelContext) {
        // Create the coordinator with the model context
        let coordinator = IllustrationCoordinator(modelContext: modelContext)
        self.coordinator = coordinator
        
        // Start the coordinator to restore tasks and begin processing
        Task {
            await coordinator.start()
        }
        
        print("[IllustrationTaskManagerSetup] Task system initialized")
    }
    
    /// Shut down the task system
    func shutdown() async {
        // Stop processing tasks
        await coordinator?.stopTaskProcessing()
        coordinator = nil
        
        print("[IllustrationTaskManagerSetup] Task system shut down")
    }
    
    /// Generate illustrations for a story
    /// - Parameters:
    ///   - story: The story to generate illustrations for
    ///   - modelContext: The SwiftData model context
    func generateIllustrationsForStory(_ story: Story, modelContext: ModelContext) async {
        guard let taskManager = taskManager else {
            print("[IllustrationTaskManagerSetup] Task manager not initialized")
            return
        }
        
        print("[IllustrationTaskManagerSetup] Adding illustration tasks for story: \(story.title)")
        
        // Create repository for saving tasks
        let repository = IllustrationTaskRepository(modelContext: modelContext)
        
        // Process each page that needs an illustration
        for page in story.pages where page.illustrationStatus == .pending {
            // Determine priority based on page number
            let priority: IllustrationPriority
            if page.pageNumber == 1 {
                priority = .critical  // First page is critical priority
            } else if page.pageNumber == 2 {
                priority = .high      // Second page is high priority
            } else if page.pageNumber <= 4 {
                priority = .medium    // Pages 3-4 are medium priority
            } else {
                priority = .low       // All other pages are low priority
            }
            
            // Create and add task
            let task = IllustrationTask(
                pageId: page.id,
                storyId: story.id,
                priority: priority
            )
            
            // Get previous illustration path if available
            let previousIllustrationPath: String? = page.pageNumber > 1 ?
                story.pages.first(where: { $0.pageNumber == page.pageNumber - 1 })?.illustrationPath : nil
            
            // Add task to manager
            taskManager.addTask(task)
            
            // Save task to repository
            do {
                _ = try repository.saveTask(
                    task,
                    pageNumber: page.pageNumber,
                    totalPages: story.pages.count,
                    description: page.imagePrompt ?? page.content,
                    previousIllustrationPath: previousIllustrationPath
                )
                
                // Update page status
                page.illustrationStatus = .scheduled
            } catch {
                print("[IllustrationTaskManagerSetup] Failed to save task: \(error)")
            }
        }
        
        // Start processing if not already running
        if !taskManager.isProcessing {
            await coordinator?.startTaskProcessing()
        }
    }
}

extension IllustrationSettingsView {
    /// Factory method to create an illustration settings view
    /// - Returns: The illustration settings view, or nil if the task system is not initialized
    static func create() -> IllustrationSettingsView? {
        guard let coordinator = IllustrationTaskManagerSetup.shared.coordinator,
              let taskManager = IllustrationTaskManagerSetup.shared.taskManager else {
            return nil
        }
        
        let view = IllustrationSettingsView()
            .environmentObject(taskManager)
            .environmentObject(coordinator)
        
        return view as? IllustrationSettingsView
    }
}
