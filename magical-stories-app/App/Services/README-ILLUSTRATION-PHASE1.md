# Illustration Service Phase 1 Implementation

This document provides a guide on the implementation of the Phase 1 Illustration Service improvements.

## Overview of Changes

The primary goal was to decouple illustration generation from story creation, allowing users to access stories immediately while illustrations are generated in the background. The following components have been implemented:

1. **IllustrationTaskManager**: A centralized manager for queuing and processing illustration tasks
2. **IllustrationTask/PendingIllustrationTask**: Data models for representing illustration tasks
3. **IllustrationTaskRepository**: Persistence layer for tasks
4. **IllustrationCoordinator**: Coordinates restoration and processing of tasks
5. **Modified StoryProcessor**: No longer blocks story creation with illustration generation
6. **Modified StoryDetailView**: Now uses the task manager for illustration generation

## Integration Steps

To complete the implementation, follow these steps:

### Step 1: Register IllustrationTaskManager in the App

Update `MagicalStoriesApp.swift` to create and inject the IllustrationTaskManager:

```swift
@main
struct MagicalStoriesApp: App {
    // Other existing code...

    // Create the task manager as a state object
    @StateObject private var illustrationTaskManager = IllustrationTaskManager()
    @StateObject private var illustrationCoordinator: IllustrationCoordinator
    
    init() {
        // Initialize the coordinator with the shared ModelContext
        let modelContainer = try! ModelContainer(for: Story.self, Page.self, PendingIllustrationTask.self)
        let modelContext = ModelContext(modelContainer)
        let coordinator = IllustrationCoordinator(modelContext: modelContext)
        _illustrationCoordinator = StateObject(wrappedValue: coordinator)
        
        // Start the coordinator
        Task {
            await coordinator.start()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                // Add the environment objects
                .environmentObject(illustrationTaskManager)
                // Other environment objects...
        }
        .modelContainer(for: [Story.self, Page.self, PendingIllustrationTask.self])
    }
}
```

### Step 2: Create Placeholder UI Components

Create a new `IllustrationPlaceholderView.swift` file:

```swift
import SwiftUI

struct IllustrationPlaceholderView: View {
    let pageNumber: Int
    let totalPages: Int
    let isLoading: Bool
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(UITheme.Colors.surfaceSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(UITheme.Colors.textSecondary.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(8)
            
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView()
                        .tint(UITheme.Colors.primary)
                        .controlSize(.large)
                    
                    Text("Creating your illustration...")
                        .font(UITheme.Typography.body)
                        .foregroundColor(UITheme.Colors.textSecondary)
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(UITheme.Colors.textSecondary.opacity(0.7))
                    
                    Text("Illustration will appear here")
                        .font(UITheme.Typography.body)
                        .foregroundColor(UITheme.Colors.textSecondary)
                }
            }
            .padding()
        }
        .aspectRatio(9/16, contentMode: .fit)
    }
}

// Preview
#Preview {
    VStack {
        IllustrationPlaceholderView(pageNumber: 1, totalPages: 5, isLoading: true)
            .frame(width: 300)
        
        IllustrationPlaceholderView(pageNumber: 2, totalPages: 5, isLoading: false)
            .frame(width: 300)
    }
    .padding()
}
```

### Step 3: Update PageView to use the Placeholder

Update the existing PageView to use the placeholder when an illustration is not ready:

```swift
// In PageView.swift
var body: some View {
    ScrollView {
        VStack(spacing: 16) {
            // Show illustration or placeholder based on status
            if page.illustrationStatus == .ready, let illustrationPath = page.illustrationPath {
                // Show the actual illustration
                StoryIllustrationView(imagePath: illustrationPath)
            } else {
                // Show placeholder with appropriate loading state
                IllustrationPlaceholderView(
                    pageNumber: page.pageNumber,
                    totalPages: totalPages, // Pass this in from parent
                    isLoading: page.illustrationStatus == .generating || page.illustrationStatus == .scheduled
                )
            }
            
            // Existing content display
            Text(page.content)
                // Existing styling...
        }
        // Existing modifiers...
    }
}
```

### Step 4: Add Settings Integration

Create a new view for monitoring task progress in settings:

```swift
// IllustrationSettingsView.swift
import SwiftUI

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
                
                if illustrationTaskManager.pendingTasks.isEmpty {
                    Text("No pending tasks")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .navigationTitle("Illustration Tasks")
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
```

## Testing

To verify the implementation works correctly:

1. Create a new story and confirm it's available immediately without waiting for illustrations
2. Open the story and confirm that illustrations begin generating in the background
3. Verify that placeholder UI shows appropriate loading states
4. Check that illustrations appear once they're generated
5. Close and reopen the app to verify that pending tasks are properly restored

## Common Issues

- **Ambiguous Type Errors**: Ensure imports are correct and specific when referencing repository types
- **Missing Context Issues**: Pass ModelContext correctly to repository classes
- **UI Not Updating**: Verify that ObservableObject and Published are properly set up

## Future Enhancements (Phase 2)

- Enhanced placeholder designs tailored to content
- More sophisticated prioritization algorithms
- User behavior tracking to predict which pages to prioritize
- Automatic retry logic with exponential backoff
- Bandwidth conservation options
