import SwiftUI

/// View for monitoring and controlling illustration generation tasks
struct IllustrationSettingsView: View {
    @EnvironmentObject var illustrationTaskManager: IllustrationTaskManager
    @EnvironmentObject var illustrationCoordinator: IllustrationCoordinator
    
    @State private var isPaused = false
    
    var body: some View {
        Form {
            Section(header: Text("Background Task Status")) {
                HStack {
                    Text("Status")
                    Spacer()
                    Text(illustrationTaskManager.isProcessing ? "Processing" : "Idle")
                        .foregroundColor(illustrationTaskManager.isProcessing ? .green : .secondary)
                }
                
                HStack {
                    Text("Network Connectivity")
                    Spacer()
                    Text(illustrationCoordinator.hasNetworkConnectivity ? "Connected" : "Offline")
                        .foregroundColor(illustrationCoordinator.hasNetworkConnectivity ? .green : .red)
                }
                
                HStack {
                    Text("Pending Tasks")
                    Spacer()
                    Text("\(illustrationTaskManager.pendingTasks.count)")
                }
                
                Button(action: {
                    isPaused.toggle()
                    Task {
                        if isPaused {
                            await illustrationCoordinator.stopTaskProcessing()
                        } else {
                            await illustrationCoordinator.startTaskProcessing()
                        }
                    }
                }) {
                    Text(isPaused ? "Resume Processing" : "Pause Processing")
                }
            }
            
            Section(header: Text("Task Queue")) {
                if illustrationTaskManager.pendingTasks.isEmpty {
                    Text("No pending tasks")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(illustrationTaskManager.pendingTasks) { task in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Task \(task.id.uuidString.prefix(6))")
                                    .font(.headline)
                                Text("Priority: \(priorityString(for: task.priority))")
                                    .font(.caption)
                            }
                            
                            Spacer()
                            
                            Text(statusString(for: task.status))
                                .foregroundColor(statusColor(for: task.status))
                        }
                    }
                }
            }
        }
        .navigationTitle("Illustration Tasks")
        .onAppear {
            // Refresh status when view appears
            isPaused = !illustrationTaskManager.isProcessing
        }
    }
    
    // Helper functions
    private func priorityString(for priority: IllustrationPriority) -> String {
        switch priority {
        case .critical: return "Critical"
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
    
    private func statusString(for status: IllustrationStatus) -> String {
        switch status {
        case .pending: return "Pending"
        case .scheduled: return "Scheduled"
        case .generating: return "Generating"
        case .ready: return "Ready"
        case .failed: return "Failed"
        }
    }
    
    private func statusColor(for status: IllustrationStatus) -> Color {
        switch status {
        case .pending: return .secondary
        case .scheduled: return .blue
        case .generating: return .orange
        case .ready: return .green
        case .failed: return .red
        }
    }
}

// Preview
#Preview {
    NavigationStack {
        IllustrationSettingsView()
            .environmentObject(IllustrationTaskManager())
            .environmentObject(
                IllustrationCoordinator(
                    taskManager: IllustrationTaskManager(), 
                    taskRepository: PreviewMocks.mockTaskRepository
                )
            )
    }
}

// Preview Mock
private enum PreviewMocks {
    static let mockTaskRepository = MockTaskRepository()
    
    class MockTaskRepository: IllustrationTaskRepositoryProtocol {
        @MainActor
        func saveTask(_ task: IllustrationTask, pageNumber: Int, totalPages: Int, description: String?, previousIllustrationPath: String?) throws -> PendingIllustrationTask {
            // Return a mock task for preview purposes
            return PendingIllustrationTask(
                pageId: task.pageId, 
                storyId: task.storyId, 
                priority: task.priority,
                status: task.status,
                illustrationDescription: description,
                pageNumber: pageNumber,
                totalPages: totalPages
            )
        }
        
        @MainActor
        func updateTaskStatus(_ id: UUID, status: IllustrationStatus) throws -> PendingIllustrationTask? {
            return nil
        }
        
        @MainActor
        func incrementTaskAttempt(_ id: UUID) throws -> PendingIllustrationTask? {
            return nil
        }
        
        @MainActor
        func deleteTask(_ id: UUID) throws {}
        
        @MainActor
        func getAllPendingTasks() throws -> [PendingIllustrationTask] {
            return []
        }
        
        @MainActor
        func getTaskById(_ id: UUID) throws -> PendingIllustrationTask? {
            return nil
        }
        
        @MainActor
        func getTasksForPage(_ pageId: UUID) throws -> [PendingIllustrationTask] {
            return []
        }
        
        @MainActor
        func getTasksForStory(_ storyId: UUID) throws -> [PendingIllustrationTask] {
            return []
        }
        
        @MainActor
        func deleteTasksForStory(_ storyId: UUID) throws {}
        
        @MainActor
        func restoreTasksToManager(_ manager: IllustrationTaskManager) async throws -> Int {
            return 0
        }
        
        @MainActor
        func getCompletedGlobalReferenceTask(for storyId: UUID) throws -> PendingIllustrationTask? {
            return nil
        }
        
        @MainActor
        func updateTaskIllustrationPath(_ id: UUID, illustrationPath: String) throws -> PendingIllustrationTask? {
            return nil
        }
    }
}
