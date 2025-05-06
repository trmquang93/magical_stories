# Illustration Service Improvement Plan - Phase 1

## Overview
Phase 1 focuses on implementing the core background generation system that will decouple illustration generation from story creation, allowing users to access stories immediately while illustrations are generated asynchronously in the background.

## Timeline
**Duration:** 2 weeks (10 working days)
**Start:** [DATE]
**End:** [DATE]

## Core Objectives
1. Move illustration generation from story creation to first story view
2. Implement background task management system
3. Create persistence for illustration tasks across app restarts
4. Develop placeholder UI components with loading states
5. Implement real-time UI updates when illustrations become available

## Detailed Tasks Breakdown

### Week 1: Core Infrastructure

#### Day 1-2: IllustrationTaskManager Implementation
- [x] Create `IllustrationTaskManager` singleton class
- [x] Implement task queue with priority support
- [x] Design and implement the `IllustrationTask` model
- [x] Add status tracking and task lifecycle management
- [ ] Implement connectivity monitoring to pause/resume based on network status

#### Day 3: SwiftData Task Persistence
- [x] Design `PendingIllustrationTask` SwiftData model
- [x] Implement `TaskRepository` for SwiftData persistence
- [x] Add methods to persist, retrieve, and delete tasks
- [x] Create serialization/deserialization between tasks and persistence models
- [ ] Implement task restoration on app startup

#### Day 4-5: StoryDetailView Modifications
- [ ] Modify `StoryDetailView` to check illustration status on appearance
- [ ] Implement first-view detection logic to trigger generation only once
- [ ] Create hooks to initiate illustration generation via `IllustrationTaskManager`
- [ ] Add special handling for first page vs. subsequent pages
- [ ] Implement proper task cancellation when view disappears

### Week 2: UI Components and Integration

#### Day 6-7: Placeholder UI Components
- [ ] Design base `IllustrationPlaceholderView` component
- [ ] Create themed placeholder variations based on story context
- [ ] Implement loading animations and states for placeholders
- [ ] Create blocking loading indicator for first page (critical priority)
- [ ] Develop non-blocking placeholders for subsequent pages

#### Day 8: Real-time UI Updates
- [ ] Implement ObservableObject pattern for illustration status
- [ ] Create binding between illustration status and UI components
- [ ] Add smooth transition animations when illustrations become available
- [ ] Develop proper state handling for all illustration states (pending, generating, failed, ready)
- [ ] Implement error state UI with retry options

#### Day 9: Settings Integration
- [ ] Add background task monitoring view in Settings
- [ ] Create user controls for managing illustration generation
- [ ] Implement background task pause/resume functionality
- [ ] Add basic analytics for task completion rates
- [ ] Create debug tools for developers to monitor task status

#### Day 10: Testing and Documentation
- [x] Create comprehensive unit tests for `IllustrationTaskManager`
- [ ] Implement integration tests for the end-to-end flow
- [ ] Test performance impact on app startup and story viewing
- [ ] Write technical documentation for the background generation system
- [ ] Create user-facing documentation for the new placeholder system

## Technical Requirements

### Models and Data Structures

```swift
// Key data structures needed for Phase 1

enum IllustrationStatus: Codable {
    case pending      // Not yet processed
    case scheduled    // In queue, awaiting generation
    case generating   // API call in progress
    case retrying(Int) // Retrying with attempt count
    case ready        // Successfully generated
    case failed(Error?) // Failed with optional error
}

enum IllustrationPriority {
    case critical  // Title page, always visible immediately
    case high      // First content page, visible in preview
    case medium    // Middle pages likely to be viewed soon
    case low       // Later pages or pages rarely viewed
}

struct IllustrationTask: Identifiable, Equatable {
    let id: UUID
    let pageId: UUID
    let storyId: UUID
    let priority: IllustrationPriority
    var status: IllustrationStatus
    let createdAt: Date
    var lastUpdatedAt: Date
    var attemptCount: Int
}

// SwiftData model for persistence
@Model
final class PendingIllustrationTask {
    var id: UUID
    var pageId: UUID
    var storyId: UUID
    var priority: String
    var status: String
    var createdAt: Date
    var lastUpdatedAt: Date
    var attemptCount: Int
    var errorMessage: String?
    
    init(from task: IllustrationTask) {
        // Implementation details
    }
    
    func toIllustrationTask() -> IllustrationTask {
        // Implementation details
    }
}
```

### Key Components

1. **IllustrationTaskManager**
   - Central coordinator for background tasks
   - Task queue with priority management
   - Task lifecycle handling
   - Connectivity monitoring

2. **TaskRepository**
   - SwiftData-based persistence
   - Task serialization/deserialization
   - Querying and filtering capabilities

3. **IllustrationPlaceholderView**
   - Themed, animated placeholders
   - Status-based visual rendering
   - Transition animations

4. **StoryDetailView Extensions**
   - First-view detection
   - Task initiation hooks
   - Special first page handling

## Integration Points

1. **StoryDetailView**
   - Modify `.onAppear` or `.task` to check illustration status and trigger generation if needed
   - Integrate placeholder views for pages without ready illustrations
   - Implement binding to illustration status updates

2. **PageView**
   - Update to handle illustration loading states
   - Integrate placeholder component
   - Implement transitions for status changes

3. **Settings Integration**
   - Add new section for illustration generation settings
   - Implement background task monitoring

4. **Story Model**
   - Add first-viewed timestamp to track initial view
   - Consider adding a "has-triggered-generation" flag

## Testing Strategy

1. **Unit Tests**
   - IllustrationTaskManager functionality
   - Task prioritization logic
   - Persistence serialization/deserialization
   - Error handling scenarios

2. **Integration Tests**
   - End-to-end flow from story viewing to illustration completion
   - UI updates when illustrations become available
   - App restart with pending tasks

3. **Performance Testing**
   - Memory usage monitoring
   - Background task impact on UI responsiveness
   - Startup time with pending tasks

## Success Criteria for Phase 1

1. Users can access stories immediately after creation without waiting for illustrations
2. First page illustration loads with minimal delay when a story is viewed
3. Subsequent pages show appropriate placeholders until illustrations are ready
4. Background tasks persist across app restarts
5. UI updates seamlessly when illustrations become available
6. Settings panel shows accurate background task status

## Risks and Mitigations

1. **Risk**: Excessive background tasks could impact battery life
   **Mitigation**: Implement intelligent batching and throttling

2. **Risk**: Poor user experience if first page loads too slowly
   **Mitigation**: Prioritize first page generation with blocking UI only when absolutely necessary

3. **Risk**: SwiftData persistence issues with complex task objects
   **Mitigation**: Use simple serializable structures and thorough testing

4. **Risk**: Network conditions affecting generation reliability
   **Mitigation**: Implement robust retry logic with exponential backoff

## Current Implementation Status (Updated May 5, 2025)

### Completed Components

1. **IllustrationTaskManager**
   - ✅ Core task queue with synchronized operations
   - ✅ Priority-based task ordering with reliable sorting
   - ✅ Task lifecycle management (adding, removing, processing)
   - ✅ Comprehensive unit test coverage
   - ⚠️ Known issues fixed:
     - Fixed asynchronous operations that caused test failures
     - Improved task prioritization algorithm
     - Refined task removal logic for better reliability

   **Key Implementation Details:**
   ```swift
   // Task priority sorting now properly handles both priority and creation time
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
   
   // Synchronous operations for predictable behavior in tests
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
   ```

2. **Data Layer**
   - ✅ `IllustrationTask` model with status tracking
   - ✅ `PendingIllustrationTask` SwiftData model
   - ✅ Conversion methods between runtime and persistence models
   - ✅ Repository pattern implementation with all CRUD operations
   - ✅ Query capabilities for filtering tasks by status, page, or story

   **Key Implementation Details:**
   ```swift
   // PendingIllustrationTask model with SwiftData compatibility
   @Model
   final class PendingIllustrationTask {
       @Attribute(.unique) var id: UUID
       var pageId: UUID
       var storyId: UUID
       var priorityRawValue: Int
       var statusRawValue: String
       var createdAt: Date
       var lastUpdatedAt: Date
       var attemptCount: Int
       var illustrationDescription: String?
       var pageNumber: Int
       var totalPages: Int
       var previousIllustrationPath: String?
       
       // Computed properties to handle enum conversions
       var priority: IllustrationPriority {
           get { IllustrationPriority(rawValue: priorityRawValue) ?? .medium }
           set { priorityRawValue = newValue.rawValue }
       }
       
       var status: IllustrationStatus {
           get { IllustrationStatus(rawValue: statusRawValue) ?? .pending }
           set { statusRawValue = newValue.rawValue }
       }
       
       // Conversion from runtime to persistence model
       static func from(task: IllustrationTask, 
                       pageNumber: Int,
                       totalPages: Int,
                       previousIllustrationPath: String? = nil,
                       illustrationDescription: String? = nil) -> PendingIllustrationTask {
           // Implementation details
       }
       
       // Conversion from persistence to runtime model
       func toRuntimeTask() -> IllustrationTask {
           IllustrationTask(
               id: id,
               pageId: pageId,
               storyId: storyId,
               priority: priority,
               status: status,
               createdAt: createdAt,
               lastUpdatedAt: lastUpdatedAt,
               attemptCount: attemptCount
           )
       }
   }
   
   // Repository implementation utilizing SwiftData
   @MainActor
   class IllustrationTaskRepository: IllustrationTaskRepositoryProtocol {
       private let modelContainer: ModelContainer
       private let modelContext: ModelContext
       
       func saveTask(_ task: IllustrationTask, 
                    pageNumber: Int,
                    totalPages: Int,
                    description: String?,
                    previousIllustrationPath: String?) throws -> PendingIllustrationTask {
           let persistentTask = PendingIllustrationTask.from(
               task: task,
               pageNumber: pageNumber,
               totalPages: totalPages,
               previousIllustrationPath: previousIllustrationPath,
               illustrationDescription: description
           )
           
           modelContext.insert(persistentTask)
           try modelContext.save()
           return persistentTask
       }
       
       // Other repository methods for retrieving, updating and deleting tasks
   }
   ```

3. **Testing**
   - ✅ Unit tests for IllustrationTaskManager
   - ✅ Tests for task prioritization logic
   - ✅ Tests for PendingIllustrationTask model
   - ✅ Tests for repository operations

   **Key Implementation Details:**
   ```swift
   // IllustrationTaskManagerTests using Swift Testing framework
   @Suite("IllustrationTaskManager Tests")
   struct IllustrationTaskManagerTests {
       // Helper function to create tasks with specified priorities
       func createTask(priority: IllustrationPriority = .medium) -> IllustrationTask {
           return IllustrationTask(
               pageId: UUID(),
               storyId: UUID(),
               priority: priority
           )
       }
       
       @Test("IllustrationTaskManager adds tasks to queue")
       func testAddTask() {
           // Arrange
           let manager = IllustrationTaskManager()
           let task = createTask()
           
           // Act
           manager.addTask(task)
           
           // Assert
           #expect(manager.pendingTasks.count == 1)
           #expect(manager.pendingTasks.first?.id == task.id)
       }
       
       @Test("IllustrationTaskManager prioritizes critical tasks first")
       func testTaskPriority() {
           // Arrange
           let manager = IllustrationTaskManager()
           let mediumTask = createTask(priority: .medium)
           let highTask = createTask(priority: .high)
           let lowTask = createTask(priority: .low)
           let criticalTask = createTask(priority: .critical)
           
           // Add tasks in non-priority order
           manager.addTask(mediumTask)
           manager.addTask(lowTask)
           manager.addTask(highTask)
           manager.addTask(criticalTask)
           
           // Act & Assert - Verify priority ordering
           #expect(manager.getNextTask()?.id == criticalTask.id)
           #expect(manager.getNextTask()?.id == highTask.id)
           #expect(manager.getNextTask()?.id == mediumTask.id)
           #expect(manager.getNextTask()?.id == lowTask.id)
           #expect(manager.getNextTask() == nil)
       }
       
       // Additional tests for removal, processing, etc.
   }
   
   // Repository tests with mock SwiftData context
   @Suite("IllustrationTaskRepository Tests")
   struct IllustrationTaskRepositoryTests {
       @Test("Repository saveTask adds new task correctly")
       func testSaveTask() {
           // Test implementation
       }
       
       @Test("Repository getAllPendingTasks returns pending tasks")
       func testGetAllPendingTasks() {
           // Test implementation
       }
       
       // Additional repository test cases
   }
   ```

### Next Steps

1. **Immediate Focus (Week 1 remaining tasks)**
   - Implement task restoration on app startup
   - Integrate network connectivity monitoring
   - Begin StoryDetailView modifications

2. **For Week 2**
   - Continue with UI components as planned
   - Implement real-time updates and status binding

## Next Steps After Phase 1

Upon successful completion of Phase 1, the team will proceed to Phase 2, focusing on:
- Enhanced placeholder designs
- Sophisticated prioritization algorithms
- User behavior tracking and analysis
- Visibility-based loading optimizations
