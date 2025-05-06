import Foundation
import Combine
import SwiftData
import OSLog

/// Manager responsible for coordinating background illustration generation tasks
class IllustrationTaskManager: ObservableObject {
    /// The queue of tasks waiting to be processed
    @Published private(set) var pendingTasks: [IllustrationTask] = []
    
    /// Whether the task manager is currently processing tasks
    @Published private(set) var isProcessing: Bool = false
    
    /// The task that handles processing
    private var processingTask: Task<Void, Never>?
    
    /// Flag to track cancellation of the processing loop
    private var isCancelled: Bool = false
    
    /// Logger for the task manager
    private let logger = Logger(subsystem: "com.magical-stories.app", category: "IllustrationTaskManager")
    
    /// Type alias for a function that processes a task and returns the processed task
    typealias TaskProcessor = (IllustrationTask) async throws -> IllustrationTask
    
    /// Initializes a new task manager
    init() {
        logger.debug("IllustrationTaskManager initialized")
    }
    
    /// Adds a task to the queue
    /// - Parameter task: The task to add
    func addTask(_ task: IllustrationTask) {
        // Don't add if task already exists
        if pendingTasks.contains(where: { $0.id == task.id }) {
            logger.debug("Task already in queue, not adding: \(task.id.uuidString)")
            return
        }
        
        // Add the task and sort the queue - do it synchronously for predictable behavior
        pendingTasks.append(task)
        sortTasks()
        logger.debug("Added task to queue: \(task.id.uuidString), priority: \(task.priority.rawValue)")
    }
    
    /// Removes a task from the queue by ID
    /// - Parameter id: The ID of the task to remove
    /// - Returns: True if the task was found and removed, false otherwise
    func removeTask(id: UUID) -> Bool {
        let initialCount = pendingTasks.count
        
        // Remove synchronously for predictable behavior
        pendingTasks.removeAll { $0.id == id }
        
        let wasRemoved = initialCount > pendingTasks.count
        if wasRemoved {
            logger.debug("Removed task from queue: \(id.uuidString)")
        } else {
            logger.debug("Failed to remove task, not found: \(id.uuidString)")
        }
        
        return wasRemoved
    }
    
    /// Gets the next task to process based on priority
    /// - Returns: The next task, or nil if no tasks are available
    func getNextTask() -> IllustrationTask? {
        // Return the first task that's still in pending state
        let nextTask = pendingTasks.first(where: { $0.status == .pending })
        
        if let task = nextTask {
            // Remove it from the queue synchronously
            pendingTasks.removeAll { $0.id == task.id }
        }
        
        return nextTask
    }
    
    /// Sorts the task queue by priority - critical first, then high, medium, low
    private func sortTasks() {
        pendingTasks.sort { 
            // Lower enum raw value means higher priority in our enum
            if $0.priority != $1.priority {
                return $0.priority.rawValue < $1.priority.rawValue
            }
            // Secondary sort by creation time if priority is the same
            return $0.createdAt < $1.createdAt
        }
    }
    
    /// Clears all pending tasks from the queue
    func clearAllTasks() {
        // Clear synchronously for predictable behavior
        pendingTasks.removeAll()
        logger.debug("Cleared all tasks from queue")
    }
    
    /// Starts processing tasks using the provided processor
    /// - Parameter processor: The function to process each task
    /// - Returns: True if processing was started, false if already processing
    @MainActor
    func startProcessing(using processor: @escaping TaskProcessor) async -> Bool {
        guard !isProcessing else {
            logger.debug("Task processing already in progress, not starting")
            return false
        }
        
        isProcessing = true
        isCancelled = false
        logger.debug("Starting task processing")
        
        processingTask = Task {
            await processTasksLoop(using: processor)
        }
        
        return true
    }
    
    /// Stops the task processing loop
    @MainActor
    func stopProcessing() async {
        guard isProcessing else {
            logger.debug("Task processing not active, nothing to stop")
            return
        }
        
        isCancelled = true
        processingTask?.cancel()
        processingTask = nil
        isProcessing = false
        logger.debug("Task processing stopped")
    }
    
    /// The main processing loop that continues until canceled or no tasks remain
    /// - Parameter processor: The function to process each task
    @MainActor
    private func processTasksLoop(using processor: TaskProcessor) async {
        logger.debug("Task processing loop started")
        
        while !isCancelled {
            guard let task = getNextTask() else {
                // No tasks available, wait briefly before checking again
                do {
                    // Use UInt64 explicitly for nanoseconds
                    let sleepTime: UInt64 = 500_000_000
                    try await Task.sleep(nanoseconds: sleepTime) // 500ms in nanoseconds
                } catch {
                    logger.error("Error while sleeping: \(error.localizedDescription)")
                }
                
                // If still no tasks and no tasks in queue, exit the loop
                if getNextTask() == nil && pendingTasks.isEmpty {
                    logger.debug("No tasks in queue, ending processing loop")
                    break
                }
                continue
            }
            
            do {
                logger.debug("Processing task: \(task.id.uuidString), priority: \(task.priority.rawValue)")
                let processedTask = try await processor(task)
                logger.debug("Task completed: \(processedTask.id.uuidString), status: \(String(describing: processedTask.status))")
                
                // If the task failed, we could implement retry logic here
                if processedTask.status == .failed {
                    logger.error("Task processing failed: \(processedTask.id.uuidString)")
                    // Future: implement retry logic
                }
            } catch {
                logger.error("Error processing task: \(error.localizedDescription)")
            }
        }
        
        // Ensure we mark processing as stopped when the loop exits
        if isProcessing {
            isProcessing = false
        }
        
        logger.debug("Task processing loop ended")
    }
    
    /// Returns the count of pending tasks by priority
    func taskCountsByPriority() -> [IllustrationPriority: Int] {
        var counts = [IllustrationPriority: Int]()
        
        for priority in [IllustrationPriority.critical, .high, .medium, .low] {
            let count = pendingTasks.filter { $0.priority == priority }.count
            counts[priority] = count
        }
        
        return counts
    }
}
