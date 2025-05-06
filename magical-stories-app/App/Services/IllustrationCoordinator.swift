import Foundation
import SwiftData
import OSLog
import Network

/// Coordinator that manages the illustration generation system, including task restoration and network monitoring
@MainActor
class IllustrationCoordinator: ObservableObject {
    /// The task manager for handling illustration generation tasks
    private(set) var taskManager: IllustrationTaskManager
    
    /// The repository for persisting tasks
    private let taskRepository: any IllustrationTaskRepositoryProtocol
    
    /// Model context for page lookups
    private let modelContext: ModelContext
    
    /// Logger for the coordinator
    private let logger = Logger(subsystem: "com.magical-stories.app", category: "IllustrationCoordinator")
    
    /// Status of the coordinator
    @Published var status: CoordinatorStatus = .initializing
    
    /// The number of restored tasks from last session
    @Published var restoredTaskCount: Int = 0
    
    /// Network monitoring status
    @Published var hasNetworkConnectivity: Bool = true
    
    /// Network monitor for checking connectivity
    private var networkMonitor: NetworkMonitorProtocol?
    
    /// Coordinator status values
    enum CoordinatorStatus {
        case initializing
        case ready
        case restoring
        case error
    }
    
    /// Initialize the coordinator with dependencies
    /// - Parameters:
    ///   - taskManager: The task manager to use
    ///   - taskRepository: The repository for persisting tasks
    ///   - networkMonitor: Optional network monitor for connectivity
    init(
        taskManager: IllustrationTaskManager,
        taskRepository: IllustrationTaskRepositoryProtocol,
        networkMonitor: NetworkMonitorProtocol? = nil
    ) {
        self.taskManager = taskManager
        self.taskRepository = taskRepository
        self.networkMonitor = networkMonitor
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Story.self, StoryCollection.self, configurations: config)
        self.modelContext = ModelContext(container)
        // Set up network monitoring after all properties are initialized
        setupNetworkMonitoring()
    }

    /// Convenience initializer that creates all required dependencies
    convenience init(modelContext: ModelContext) {
        // Create components
        let taskManager = IllustrationTaskManager()
        let taskRepository = IllustrationTaskRepository(modelContext: modelContext)
        let networkMonitor = NetworkMonitor()
        
        // Initialize with components
        self.init(
            taskManager: taskManager,
            taskRepository: taskRepository,
            networkMonitor: networkMonitor
        )
    }
    
    /// Start the coordinator
    func start() async {
        logger.debug("Starting IllustrationCoordinator")
        status = .restoring
        
        // Restore tasks from previous session
        do {
            restoredTaskCount = try await taskRepository.restoreTasksToManager(taskManager)
            logger.debug("Restored \(self.restoredTaskCount) tasks from persistent storage")
            
            // Start processing tasks if there are any
            if restoredTaskCount > 0 && hasNetworkConnectivity {
                await startTaskProcessing()
            }
            
            status = .ready
        } catch {
            logger.error("Failed to restore tasks: \(error.localizedDescription)")
            status = .error
        }
    }
    
    /// Start processing tasks
    func startTaskProcessing() async {
        // Only start if we have network connectivity
        guard hasNetworkConnectivity else {
            logger.debug("Not starting task processing due to no network connectivity")
            return
        }
        
        // Create the illustration service for processing tasks
        do {
            let illustrationService = try IllustrationService()
            
            // Start processing
            let _ = await taskManager.startProcessing { task in
                // Process each task by generating an illustration
                var updatedTask = task
                
                do {
                    // Get task details from repository
                    guard let persistentTask = try self.taskRepository.getTaskById(task.id) else {
                        self.logger.error("Task not found in repository: \(task.id.uuidString)")
                        updatedTask.updateStatus(.failed)
                        return updatedTask
                    }
                    
                    // Update status to generating
                    updatedTask.updateStatus(.generating)
                    let _ = try self.taskRepository.updateTaskStatus(task.id, status: .generating)
                    
                    // Get description
                    let description = persistentTask.illustrationDescription ?? "A children's story illustration"
                    
                    // Generate the illustration
                    if let relativePath = try await illustrationService.generateIllustration(
                        for: description, 
                        pageNumber: persistentTask.pageNumber, 
                        totalPages: persistentTask.totalPages,
                        previousIllustrationPath: persistentTask.previousIllustrationPath
                    ) {
                        // Successfully generated
                        updatedTask.updateStatus(.ready)
                        _ = try self.taskRepository.updateTaskStatus(task.id, status: .ready)
                        
                        // Update the page if possible
                        self.updatePageWithIllustration(pageId: task.pageId, illustrationPath: relativePath)
                        
                        self.logger.debug("Successfully generated illustration for task: \(task.id.uuidString)")
                    } else {
                        // Failed to generate
                        updatedTask.updateStatus(.failed)
                        _ = try self.taskRepository.updateTaskStatus(task.id, status: .failed)
                        self.logger.error("Failed to generate illustration, received nil path for task: \(task.id.uuidString)")
                    }
                } catch {
                    // Error occurred
                    updatedTask.updateStatus(.failed)
                    _ = try? self.taskRepository.updateTaskStatus(task.id, status: .failed)
                    self.logger.error("Error generating illustration for task \(task.id.uuidString): \(error.localizedDescription)")
                }
                
                return updatedTask
            }
        } catch {
            logger.error("Failed to create IllustrationService: \(error.localizedDescription)")
        }
    }
    
    /// Stop processing tasks
    func stopTaskProcessing() async {
        await taskManager.stopProcessing()
        logger.debug("Stopped task processing")
    }
    
    /// Update page with generated illustration
    /// - Parameters:
    ///   - pageId: ID of the page to update
    ///   - illustrationPath: Path to the generated illustration
    private func updatePageWithIllustration(pageId: UUID, illustrationPath: String) {
        // This is a stub method that would be implemented with actual page lookup logic
        // Typically you would use the ModelContext to find the page and update it
        logger.debug("Updating page \(pageId.uuidString) with illustration at \(illustrationPath)")
        
        // Implementation would look something like:
        // let descriptor = FetchDescriptor<Page>(predicate: #Predicate { $0.id == pageId })
        // if let page = try? modelContext.fetch(descriptor).first {
        //     page.illustrationPath = illustrationPath
        //     page.illustrationStatus = .ready
        //     try? modelContext.save()
        // }
    }
    
    /// Set up network monitoring
    private func setupNetworkMonitoring() {
        guard let networkMonitor = networkMonitor else { return }
        
        // Start monitoring
        networkMonitor.startMonitoring { [weak self] hasConnectivity in
            guard let self = self else { return }
            
            Task { @MainActor in
                // Update current status
                self.hasNetworkConnectivity = hasConnectivity
                
                if hasConnectivity {
                    // Network became available - start processing if needed
                    if !self.taskManager.isProcessing && self.taskManager.pendingTasks.count > 0 {
                        await self.startTaskProcessing()
                        self.logger.debug("Network became available, started processing tasks")
                    }
                } else {
                    // Network lost - stop processing
                    if self.taskManager.isProcessing {
                        await self.stopTaskProcessing()
                        self.logger.debug("Network lost, stopped processing tasks")
                    }
                }
            }
        }
    }
}

/// Protocol for network monitoring
protocol NetworkMonitorProtocol {
    /// Start monitoring for network changes
    /// - Parameter handler: Closure called when network status changes
    func startMonitoring(handler: @escaping (Bool) -> Void)
    
    /// Stop monitoring
    func stopMonitoring()
}

/// Basic implementation of NetworkMonitorProtocol
class NetworkMonitor: NetworkMonitorProtocol {
    private var isMonitoring = false
    
    func startMonitoring(handler: @escaping (Bool) -> Void) {
        isMonitoring = true
        
        // This is a stub implementation that always reports connectivity
        // In a real app, this would use NWPathMonitor to check actual network status
        handler(true)
    }
    
    func stopMonitoring() {
        isMonitoring = false
    }
}
