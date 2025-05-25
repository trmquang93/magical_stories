import Foundation
import Testing
import SwiftData
import OSLog
@testable import magical_stories

/// Protocol for network monitoring - copied from IllustrationCoordinator.swift for testing
protocol NetworkMonitorProtocol {
    /// Start monitoring for network changes
    /// - Parameter handler: Closure called when network status changes
    func startMonitoring(handler: @escaping (Bool) -> Void)
    
    /// Stop monitoring for network changes
    func stopMonitoring()
}

/// A mock network monitor for testing connectivity
class MockNetworkMonitor: NetworkMonitorProtocol {
    var isMonitoring = false
    var connectivityHandler: ((Bool) -> Void)?
    var currentConnectivity = true
    
    func startMonitoring(handler: @escaping (Bool) -> Void) {
        isMonitoring = true
        connectivityHandler = handler
        handler(currentConnectivity)
    }
    
    func stopMonitoring() {
        isMonitoring = false
        connectivityHandler = nil
    }
    
    func simulateConnectivityChange(hasConnectivity: Bool) {
        currentConnectivity = hasConnectivity
        connectivityHandler?(hasConnectivity)
    }
}

/// Mock implementation of IllustrationService for the coordinator tests
class MockIllustrationServiceForCoordinator: IllustrationServiceProtocol {
    var shouldSucceed = true
    var generationDelay: TimeInterval = 0.1
    var generatedPath = "path/to/generated/illustration.png"
    
    func generateIllustration(for pageText: String, theme: String) async throws -> String? {
        // Simulate generation delay
        try await Task.sleep(for: .seconds(generationDelay))
        
        if shouldSucceed {
            return generatedPath
        } else {
            return nil
        }
    }
    
    func generateIllustration(
        for illustrationDescription: String,
        pageNumber: Int,
        totalPages: Int,
        previousIllustrationPath: String?,
        visualGuide: VisualGuide?,
        globalReferenceImagePath: String?
    ) async throws -> String? {
        // Simulate generation delay
        try await Task.sleep(for: .seconds(generationDelay))
        
        if shouldSucceed {
            return generatedPath
        } else {
            return nil
        }
    }
    
}

/// Simplified IllustrationCoordinator for testing
@MainActor
class TestableIllustrationCoordinator: ObservableObject {
    var taskManager: IllustrationTaskManager
    var taskRepository: IllustrationTaskRepositoryProtocol
    var networkMonitor: NetworkMonitorProtocol?
    
    @Published var status: CoordinatorStatus = .initializing
    @Published var restoredTaskCount: Int = 0
    @Published var hasNetworkConnectivity: Bool = true
    
    enum CoordinatorStatus {
        case initializing
        case ready
        case restoring
        case error
    }
    
    init(
        taskManager: IllustrationTaskManager,
        taskRepository: IllustrationTaskRepositoryProtocol,
        networkMonitor: NetworkMonitorProtocol? = nil
    ) {
        self.taskManager = taskManager
        self.taskRepository = taskRepository
        self.networkMonitor = networkMonitor
        
        setupNetworkMonitoring()
    }
    
    func start() async {
        status = .restoring
        
        do {
            restoredTaskCount = try await taskRepository.restoreTasksToManager(taskManager)
            
            if restoredTaskCount > 0 && hasNetworkConnectivity {
                await startTaskProcessing()
            }
            
            status = .ready
        } catch {
            status = .error
        }
    }
    
    func startTaskProcessing() async {
        if hasNetworkConnectivity {
            await taskManager.startProcessing { task in
                // Simple implementation for testing
                return task
            }
        }
    }
    
    func stopTaskProcessing() async {
        await taskManager.stopProcessing()
    }
    
    private func setupNetworkMonitoring() {
        guard let networkMonitor = networkMonitor else { return }
        
        networkMonitor.startMonitoring { [weak self] hasConnectivity in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.hasNetworkConnectivity = hasConnectivity
                
                if hasConnectivity {
                    if !self.taskManager.isProcessing && self.taskManager.pendingTasks.count > 0 {
                        await self.startTaskProcessing()
                    }
                } else {
                    if self.taskManager.isProcessing {
                        await self.stopTaskProcessing()
                    }
                }
            }
        }
    }
}

// Test suite for IllustrationCoordinator
@Suite("IllustrationCoordinator Tests")
struct IllustrationCoordinatorTests {
    
    // Helper function to create a testable coordinator with mocks
    @MainActor
    func createCoordinator(
        taskManager: IllustrationTaskManager = IllustrationTaskManager(),
        taskRepository: MockIllustrationTaskRepository = MockIllustrationTaskRepository(),
        networkMonitor: MockNetworkMonitor = MockNetworkMonitor()
    ) -> TestableIllustrationCoordinator {
        return TestableIllustrationCoordinator(
            taskManager: taskManager,
            taskRepository: taskRepository,
            networkMonitor: networkMonitor
        )
    }
    
    @Test("IllustrationCoordinator initializes correctly")
    @MainActor
    func testInitialization() {
        // Arrange
        let taskManager = IllustrationTaskManager()
        let taskRepository = MockIllustrationTaskRepository()
        let networkMonitor = MockNetworkMonitor()
        
        // Act
        let coordinator = TestableIllustrationCoordinator(
            taskManager: taskManager,
            taskRepository: taskRepository,
            networkMonitor: networkMonitor
        )
        
        // Assert
        #expect(coordinator.status == TestableIllustrationCoordinator.CoordinatorStatus.initializing)
        #expect(coordinator.restoredTaskCount == 0)
        #expect(coordinator.hasNetworkConnectivity == true)
        #expect(networkMonitor.isMonitoring == true)
    }
    
    @Test("IllustrationCoordinator starts and restores tasks")
    @MainActor
    func testStartAndRestore() async {
        // Arrange
        let taskManager = IllustrationTaskManager()
        let mockRepository = MockIllustrationTaskRepository()
        let networkMonitor = MockNetworkMonitor()
        
        // Set mock to return 3 tasks
        let tasks = [
            PendingIllustrationTask(pageId: UUID(), storyId: UUID(), priority: .high),
            PendingIllustrationTask(pageId: UUID(), storyId: UUID(), priority: .medium),
            PendingIllustrationTask(pageId: UUID(), storyId: UUID(), priority: .low)
        ]
        mockRepository.tasksToReturn = tasks
        
        let coordinator = createCoordinator(
            taskManager: taskManager,
            taskRepository: mockRepository,
            networkMonitor: networkMonitor
        )
        
        // Act
        await coordinator.start()
        
        // Assert
        #expect(coordinator.status == TestableIllustrationCoordinator.CoordinatorStatus.ready)
        #expect(coordinator.restoredTaskCount == 3)
        #expect(mockRepository.fetchedAllPending == true)
        #expect(taskManager.pendingTasks.count == 3)
    }
    
    @Test("IllustrationCoordinator handles start errors")
    @MainActor
    func testStartErrors() async {
        // Arrange
        let taskManager = IllustrationTaskManager()
        let mockRepository = MockIllustrationTaskRepository()
        mockRepository.shouldThrowError = true
        
        let coordinator = createCoordinator(
            taskManager: taskManager,
            taskRepository: mockRepository
        )
        
        // Act
        await coordinator.start()
        
        // Assert
        #expect(coordinator.status == TestableIllustrationCoordinator.CoordinatorStatus.error)
        #expect(coordinator.restoredTaskCount == 0)
    }
    
    @Test("IllustrationCoordinator responds to network connectivity changes")
    @MainActor
    func testNetworkConnectivityChanges() async {
        // Arrange
        let taskManager = IllustrationTaskManager()
        let mockNetworkMonitor = MockNetworkMonitor()
        
        // Add a test task
        let task = IllustrationTask(pageId: UUID(), storyId: UUID(), priority: .high)
        taskManager.addTask(task)
        
        let coordinator = createCoordinator(
            taskManager: taskManager,
            networkMonitor: mockNetworkMonitor
        )
        
        // Act: Start coordinator with network
        await coordinator.start()
        
        // Wait a moment for processing to start
        try? await Task.sleep(for: .milliseconds(50))
        
        // Assert: Processing should begin
        #expect(taskManager.isProcessing)
        
        // Act: Simulate network loss
        mockNetworkMonitor.simulateConnectivityChange(hasConnectivity: false)
        
        // Wait a moment for processing to stop
        try? await Task.sleep(for: .milliseconds(50))
        
        // Assert: Processing should stop
        #expect(!taskManager.isProcessing)
        #expect(!coordinator.hasNetworkConnectivity)
        
        // Act: Restore network
        mockNetworkMonitor.simulateConnectivityChange(hasConnectivity: true)
        
        // Wait a moment for processing to restart
        try? await Task.sleep(for: .milliseconds(50))
        
        // Assert: Processing should resume
        #expect(taskManager.isProcessing)
        #expect(coordinator.hasNetworkConnectivity)
    }
    
    @Test("IllustrationCoordinator stops task processing")
    @MainActor
    func testStopTaskProcessing() async {
        // Arrange
        let taskManager = IllustrationTaskManager()
        let task = IllustrationTask(pageId: UUID(), storyId: UUID(), priority: .high)
        taskManager.addTask(task)
        
        let coordinator = createCoordinator(taskManager: taskManager)
        
        // Act: Start processing
        await coordinator.startTaskProcessing()
        
        // Assert: Processing should be running
        #expect(taskManager.isProcessing)
        
        // Act: Stop processing
        await coordinator.stopTaskProcessing()
        
        // Assert: Processing should stop
        #expect(!taskManager.isProcessing)
    }
}
