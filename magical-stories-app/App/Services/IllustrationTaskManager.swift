import Foundation
import Combine
import SwiftData
import OSLog

/// Manager responsible for coordinating background illustration generation tasks
class IllustrationTaskManager: ObservableObject {
    /// The queue of tasks waiting to be processed
    @Published private(set) var pendingTasks: [IllustrationTask] = []
    
    /// Set of completed task IDs that can be used as dependencies
    private var completedDependencies = Set<UUID>()
    
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
        
        // Log detailed information about the task being added
        let taskTypeStr = task.taskType == .globalReference ? "GLOBAL REFERENCE" : "PAGE ILLUSTRATION"
        print("[IllustrationTaskManager] Adding task: \(task.id.uuidString)")
        print("[IllustrationTaskManager] Task type: \(taskTypeStr), Priority: \(task.priority)")
        
        if let deps = task.dependencies, !deps.isEmpty {
            print("[IllustrationTaskManager] Task has \(deps.count) dependencies")
            
            // Check which dependencies are already satisfied
            let satisfiedDeps = deps.filter { completedDependencies.contains($0) }.count
            print("[IllustrationTaskManager] \(satisfiedDeps) of \(deps.count) dependencies are already satisfied")
        } else {
            print("[IllustrationTaskManager] Task has no dependencies - can be processed immediately")
        }
        
        // First add the task to ensure it's part of the graph for dependency checking
        pendingTasks.append(task)
        
        // Now check for circular dependencies
        let currentCircularDeps = detectCircularDependencies()
        
        if !currentCircularDeps.isEmpty {
            print("[IllustrationTaskManager] WARNING: Detected circular dependencies after adding task \(task.id.uuidString)")
            print("[IllustrationTaskManager] Circular dependency involves \(currentCircularDeps.count) tasks")
            logger.warning("Detected circular dependencies after adding task \(task.id.uuidString): \(currentCircularDeps.map { $0.uuidString }.joined(separator: ", "))")
            
            // Find all tasks involved in circular dependencies and fix them
            for id in currentCircularDeps {
                if let index = pendingTasks.firstIndex(where: { $0.id == id }) {
                    var taskToUpdate = pendingTasks[index]
                    
                    // Clear the dependencies for tasks in the circular dependency
                    print("[IllustrationTaskManager] Clearing dependencies for task \(taskToUpdate.id) to break circular dependency")
                    logger.debug("Clearing dependencies for task \(taskToUpdate.id) to break circular dependency")
                    taskToUpdate.dependencies = nil
                    
                    // Update the task
                    pendingTasks[index] = taskToUpdate
                }
            }
            print("[IllustrationTaskManager] Circular dependencies resolved by clearing dependency relations")
        }
        
        // Sort the tasks for correct processing order
        sortTasks()
        logger.debug("Added task to queue: \(task.id.uuidString), priority: \(task.priority.rawValue), dependencies: \(String(describing: task.dependencies?.count ?? 0))")
        
        // Log queue stats after adding
        let readyTasks = pendingTasks.filter { areDependenciesMet(for: $0) }.count
        let blockedTasks = pendingTasks.count - readyTasks
        print("[IllustrationTaskManager] Queue now has \(pendingTasks.count) tasks total")
        print("[IllustrationTaskManager] \(readyTasks) tasks ready for processing, \(blockedTasks) blocked by dependencies")
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
    
    /// Checks if a task has all its dependencies satisfied
    /// - Parameter task: The task to check
    /// - Returns: True if all dependencies are met or no dependencies exist
    func areDependenciesMet(for task: IllustrationTask) -> Bool {
        guard let dependencies = task.dependencies, !dependencies.isEmpty else {
            return true // No dependencies means all are met
        }
        
        return dependencies.allSatisfy { completedDependencies.contains($0) }
    }
    
    /// Adds a completed dependency to the tracker
    /// - Parameter id: The ID of the completed task to add as a satisfied dependency
    func addCompletedDependency(_ id: UUID) {
        completedDependencies.insert(id)
        logger.debug("Added completed dependency: \(id.uuidString)")
        
        // Log for detailed dependency tracking
        print("[IllustrationTaskManager] Marked task as completed: \(id.uuidString)")
        
        // Count tasks that may now be unblocked
        let previouslyBlockedTasks = pendingTasks.filter { task in
            if let deps = task.dependencies, deps.contains(id) {
                return !areDependenciesMet(for: task)
            }
            return false
        }.count
        
        // Re-sort tasks since dependency satisfaction may change priorities
        sortTasks()
        
        // Count now-unblocked tasks after sorting
        let nowUnblockedTasks = pendingTasks.filter { task in
            if let deps = task.dependencies, deps.contains(id) {
                return areDependenciesMet(for: task)
            }
            return false
        }.count
        
        if nowUnblockedTasks > 0 {
            print("[IllustrationTaskManager] Unblocked \(nowUnblockedTasks) tasks by completing dependency \(id.uuidString)")
        }
    }
    
    /// Removes a completed dependency from the tracker
    /// - Parameter id: The ID of the dependency to remove
    func removeCompletedDependency(_ id: UUID) {
        completedDependencies.remove(id)
        logger.debug("Removed completed dependency: \(id.uuidString)")
        
        // Re-sort tasks since dependency satisfaction may change priorities
        sortTasks()
    }
    
    /// Gets the next task to process based on dependencies and priority
    /// - Returns: The next task, or nil if no tasks are available
    func getNextTask() -> IllustrationTask? {
        // Return the first pending task that has all dependencies met
        let nextTask = pendingTasks.first { task in
            return task.status == .pending && areDependenciesMet(for: task)
        }
        
        if let task = nextTask {
            // Log details about the selected task
            var dependencyInfo = "no dependencies"
            if let deps = task.dependencies, !deps.isEmpty {
                dependencyInfo = "\(deps.count) dependencies (all satisfied)"
            }
            
            print("[IllustrationTaskManager] Selected task for processing: \(task.id.uuidString)")
            print("[IllustrationTaskManager] Task type: \(task.taskType), Priority: \(task.priority)")
            print("[IllustrationTaskManager] Dependencies: \(dependencyInfo)")
            
            // Remove it from the queue synchronously
            pendingTasks.removeAll { $0.id == task.id }
        } else if !pendingTasks.isEmpty {
            // Log why no task is selected
            let blockedTasks = pendingTasks.filter { !areDependenciesMet(for: $0) }.count
            print("[IllustrationTaskManager] No eligible tasks found. Queue contains \(pendingTasks.count) tasks")
            print("[IllustrationTaskManager] \(blockedTasks) tasks are blocked by dependencies")
        }
        
        return nextTask
    }
    
    /// Sorts the task queue considering dependencies first, then by priority
    private func sortTasks() {
        pendingTasks.sort { task1, task2 in
            // First prioritize tasks based on dependency status
            let task1DependenciesMet = areDependenciesMet(for: task1)
            let task2DependenciesMet = areDependenciesMet(for: task2)
            
            if task1DependenciesMet != task2DependenciesMet {
                return task1DependenciesMet && !task2DependenciesMet
            }
            
            // If dependency status is equal, sort by priority
            if task1.priority != task2.priority {
                return task1.priority.rawValue < task2.priority.rawValue
            }
            
            // Finally, sort by creation time (older first)
            return task1.createdAt < task2.createdAt
        }
    }
    
    /// Detects circular dependencies in a task's dependency chain
    /// - Parameter task: The task to check
    /// - Returns: Set of task IDs involved in circular dependencies, or nil if none found
    func detectCircularDependenciesForTask(_ task: IllustrationTask) -> Set<UUID>? {
        guard let dependencies = task.dependencies, !dependencies.isEmpty else {
            return nil // No dependencies means no circular dependencies
        }
        
        var visited = Set<UUID>()
        var recursionStack = Set<UUID>()
        var circularDependencies = Set<UUID>()
        
        // Create a simplified dependency graph for the check
        var dependencyGraph = [UUID: [UUID]]()
        for pendingTask in pendingTasks {
            if let deps = pendingTask.dependencies {
                dependencyGraph[pendingTask.id] = deps
            } else {
                dependencyGraph[pendingTask.id] = []
            }
        }
        
        // Add the task being checked if it's not already in the graph
        if dependencyGraph[task.id] == nil {
            dependencyGraph[task.id] = dependencies
        }
        
        // Use helper function to detect circular dependencies
        findCircularDependencies(task.id, 
                                dependencyGraph: dependencyGraph,
                                visited: &visited, 
                                recursionStack: &recursionStack, 
                                circularDependencies: &circularDependencies)
        
        return circularDependencies.isEmpty ? nil : circularDependencies
    }
    
    /// Detects all circular dependencies in the task queue
    /// - Returns: An array of task IDs involved in circular dependencies
    func detectCircularDependencies() -> [UUID] {
        var circularDependencies = Set<UUID>()
        var visited = Set<UUID>()
        var recursionStack = Set<UUID>()
        
        // Create a dependency graph for all tasks
        var dependencyGraph = [UUID: [UUID]]()
        for task in pendingTasks {
            if let deps = task.dependencies {
                dependencyGraph[task.id] = deps
            } else {
                dependencyGraph[task.id] = []
            }
        }
        
        // Check each task for circular dependencies
        for task in pendingTasks {
            if !visited.contains(task.id) {
                findCircularDependencies(task.id,
                                       dependencyGraph: dependencyGraph,
                                       visited: &visited, 
                                       recursionStack: &recursionStack, 
                                       circularDependencies: &circularDependencies)
            }
        }
        
        return Array(circularDependencies)
    }
    
    /// Helper method to identify circular dependencies using depth-first search
    private func findCircularDependencies(
        _ taskId: UUID,
        dependencyGraph: [UUID: [UUID]],
        visited: inout Set<UUID>,
        recursionStack: inout Set<UUID>,
        circularDependencies: inout Set<UUID>
    ) {
        // Mark the current node as visited and add to recursion stack
        visited.insert(taskId)
        recursionStack.insert(taskId)
        
        // Get the dependencies for this task from the graph
        if let dependencies = dependencyGraph[taskId] {
            for dependencyId in dependencies {
                // If not visited, recur for it
                if !visited.contains(dependencyId) {
                    if dependencyGraph[dependencyId] != nil {
                        findCircularDependencies(dependencyId,
                                             dependencyGraph: dependencyGraph,
                                             visited: &visited, 
                                             recursionStack: &recursionStack, 
                                             circularDependencies: &circularDependencies)
                    }
                } 
                // If already in recursion stack, we found a cycle
                else if recursionStack.contains(dependencyId) {
                    // We found a circular dependency
                    circularDependencies.insert(dependencyId)
                    circularDependencies.insert(taskId)
                    
                    // Also add any nodes in between
                    for node in recursionStack {
                        if node != taskId && node != dependencyId {
                            circularDependencies.insert(node)
                        }
                    }
                }
            }
        }
        
        // Remove current node from recursion stack
        recursionStack.remove(taskId)
    }
    
    /// Creates a new task with circular dependencies removed
    /// - Parameters:
    ///   - task: The original task
    ///   - circularDependencies: The set of task IDs in circular dependencies
    /// - Returns: A new task with circular dependencies removed
    private func removeCircularDependencies(_ task: IllustrationTask, circularDependencies: Set<UUID>) -> IllustrationTask {
        var cleanedTask = task
        
        // Remove any dependencies that are in the circular dependency set
        if var dependencies = task.dependencies {
            dependencies.removeAll(where: { circularDependencies.contains($0) })
            // If removing circular deps, update the task with cleaned dependencies
            var mutableTask = task
            if dependencies.isEmpty {
                mutableTask.dependencies = nil // No dependencies left
            } else {
                mutableTask.dependencies = dependencies // Keep non-circular dependencies
            }
            cleanedTask = mutableTask
        }
        
        return cleanedTask
    }
    
    /// Clears all pending tasks from the queue
    func clearAllTasks() {
        // Clear synchronously for predictable behavior
        pendingTasks.removeAll()
        completedDependencies.removeAll()
        logger.debug("Cleared all tasks from queue and dependencies")
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
        print("[IllustrationTaskManager] Starting task processing loop")
        print("[IllustrationTaskManager] Initial queue contains \(pendingTasks.count) tasks")
        
        var completedTasks = 0
        var failedTasks = 0
        
        while !isCancelled {
            guard let task = getNextTask() else {
                // No tasks available, wait briefly before checking again
                print("[IllustrationTaskManager] No eligible tasks available, waiting...")
                
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
                    print("[IllustrationTaskManager] No tasks remaining in queue, ending processing loop")
                    print("[IllustrationTaskManager] Final stats - Completed: \(completedTasks), Failed: \(failedTasks)")
                    break
                }
                continue
            }
            
            do {
                // Log task processing start with detailed info
                let taskTypeStr = task.taskType == .globalReference ? "GLOBAL REFERENCE" : "PAGE ILLUSTRATION"
                print("[IllustrationTaskManager] Processing \(taskTypeStr) task: \(task.id.uuidString)")
                print("[IllustrationTaskManager] Task priority: \(task.priority.rawValue), attempts: \(task.attemptCount)")
                
                if let deps = task.dependencies, !deps.isEmpty {
                    print("[IllustrationTaskManager] Task depends on \(deps.count) tasks (all dependencies met)")
                }
                
                logger.debug("Processing task: \(task.id.uuidString), priority: \(task.priority.rawValue)")
                let processedTask = try await processor(task)
                logger.debug("Task completed: \(processedTask.id.uuidString), status: \(String(describing: processedTask.status))")
                
                // If the task completed successfully, mark it as a satisfied dependency
                if processedTask.status == .ready {
                    print("[IllustrationTaskManager] Task \(processedTask.id.uuidString) completed successfully")
                    completedTasks += 1
                    
                    addCompletedDependency(processedTask.id)
                    // Re-sort tasks to prioritize those that now have satisfied dependencies
                    sortTasks()
                    
                    // Log remaining queue status
                    let readyTasks = pendingTasks.filter { areDependenciesMet(for: $0) }.count
                    let blockedTasks = pendingTasks.count - readyTasks
                    print("[IllustrationTaskManager] Queue status: \(readyTasks) ready, \(blockedTasks) blocked, \(pendingTasks.count) total")
                }
                
                // If the task failed, we could implement retry logic here
                if processedTask.status == .failed {
                    logger.error("Task processing failed: \(processedTask.id.uuidString)")
                    print("[IllustrationTaskManager] ERROR: Task \(processedTask.id.uuidString) failed")
                    failedTasks += 1
                    
                    // Log more details about failed task
                    let taskTypeStr = processedTask.taskType == .globalReference ? "GLOBAL REFERENCE" : "PAGE ILLUSTRATION"
                    print("[IllustrationTaskManager] Failed task type: \(taskTypeStr), attempts: \(processedTask.attemptCount)")
                    
                    // Future: implement retry logic
                    print("[IllustrationTaskManager] No automatic retry logic implemented yet")
                }
            } catch {
                logger.error("Error processing task: \(error.localizedDescription)")
                print("[IllustrationTaskManager] ERROR processing task: \(error.localizedDescription)")
                failedTasks += 1
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
