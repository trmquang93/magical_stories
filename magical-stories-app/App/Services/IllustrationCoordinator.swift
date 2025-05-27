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
                    
                    // Get visual guide for the story
                    guard let visualGuide = self.getVisualGuide(for: persistentTask.storyId) else {
                        self.logger.error("No visual guide available for story: \(persistentTask.storyId.uuidString)")
                        updatedTask.updateStatus(.failed)
                        return updatedTask
                    }
                    
                    // Get global reference image path if available
                    let globalReferenceImagePath = self.getGlobalReferenceImagePath(for: persistentTask.storyId)
                    
                    // Generate illustration using the contextual method with all proper parameters
                    if let relativePath = try await illustrationService.generateIllustration(
                        for: description,
                        pageNumber: persistentTask.pageNumber,
                        totalPages: persistentTask.totalPages,
                        previousIllustrationPath: persistentTask.previousIllustrationPath,
                        visualGuide: visualGuide,
                        globalReferenceImagePath: globalReferenceImagePath
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
    
    /// Get visual guide for a story
    /// - Parameter storyId: The story ID
    /// - Returns: Visual guide for the story or a default one
    private func getVisualGuide(for storyId: UUID) -> VisualGuide? {
        // Try to get the story
        let descriptor = FetchDescriptor<Story>(predicate: #Predicate<Story> { $0.id == storyId })
        guard let story = try? modelContext.fetch(descriptor).first else {
            logger.error("Story not found for visual guide lookup: \(storyId.uuidString)")
            return nil
        }
        
        // Create a visual guide for the story (stories don't store visual guides, they're generated dynamically)
        logger.debug("Creating visual guide for story: \(story.title)")
        return createInitialVisualGuide(for: story)
    }
    
    /// Get global reference image path for a story
    /// - Parameter storyId: The story ID
    /// - Returns: Path to global reference image if available
    private func getGlobalReferenceImagePath(for storyId: UUID) -> String? {
        // For now, return nil as global reference lookup is temporarily disabled
        // In the future, this would check for completed global reference tasks
        logger.debug("Global reference lookup temporarily disabled for story: \(storyId.uuidString)")
        return nil
    }
    
    /// Create an initial visual guide for a story
    /// - Parameter story: The story to create a visual guide for
    /// - Returns: A visual guide with style and character information
    private func createInitialVisualGuide(for story: Story) -> VisualGuide {
        // Extract theme from story parameters
        let storyTheme = story.parameters.theme
        
        // Try to extract character names from the story content
        let allContent = story.pages.map { $0.content }.joined(separator: " ")
        var characterDefinitions: [String: String] = [:]
        
        // Simple character extraction (look for capitalized words that appear multiple times)
        let words = allContent.components(separatedBy: .whitespacesAndNewlines)
        let capitalizedWords = words.filter { word in
            guard let first = word.first else { return false }
            return first.isUppercase && word.count > 2 && word.allSatisfy({ $0.isLetter })
        }
        
        // Count occurrences and keep words that appear more than once (likely character names)
        let wordCounts = capitalizedWords.reduce(into: [:]) { counts, word in
            counts[word, default: 0] += 1
        }
        
        for (word, count) in wordCounts where count > 1 && word != "The" && word != "And" {
            characterDefinitions[word] = "A character in the \(storyTheme) story"
        }
        
        // Create a style guide based on the theme and target age
        let styleGuide = createStyleGuide(theme: storyTheme, childAge: story.parameters.childAge)
        
        // Create basic setting definitions
        var settingDefinitions: [String: String] = [:]
        settingDefinitions["main_setting"] = "The primary environment where the \(storyTheme) story takes place"
        
        return VisualGuide(
            styleGuide: styleGuide,
            characterDefinitions: characterDefinitions,
            settingDefinitions: settingDefinitions,
            globalReferenceImageURL: nil
        )
    }
    
    /// Create a style guide string based on theme and child age
    /// - Parameters:
    ///   - theme: The story theme
    ///   - childAge: The target child age
    /// - Returns: A formatted style guide string
    private func createStyleGuide(theme: String, childAge: Int) -> String {
        var styleComponents = [
            "Children's book illustration style",
            "Colorful and engaging artwork suitable for \(childAge)-year-old children",
            "Theme: \(theme)",
            "Warm, friendly, and approachable character designs",
            "Clear, easy-to-read visual storytelling"
        ]
        
        // Add age-appropriate style adjustments
        if childAge <= 5 {
            styleComponents.append("Simple, bold shapes and bright colors")
            styleComponents.append("Large, expressive characters")
        } else if childAge <= 8 {
            styleComponents.append("More detailed illustrations with richer storytelling")
            styleComponents.append("Balanced color palette with good contrast")
        } else {
            styleComponents.append("Sophisticated artwork with detailed backgrounds")
            styleComponents.append("Complex compositions and nuanced character expressions")
        }
        
        return styleComponents.joined(separator: ". ")
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
