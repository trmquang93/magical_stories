import Foundation
import Testing
@testable import magical_stories

@Suite("PendingIllustrationTask Tests")
struct PendingIllustrationTaskTests {
    
    func createRuntimeTask() -> IllustrationTask {
        return IllustrationTask(
            id: UUID(),
            pageId: UUID(),
            storyId: UUID(),
            priority: .high,
            status: .pending,
            createdAt: Date(),
            lastUpdatedAt: Date(),
            attemptCount: 2
        )
    }
    
    @Test("PendingIllustrationTask initialization sets properties correctly")
    func testInitialization() {
        // Arrange
        let id = UUID()
        let pageId = UUID()
        let storyId = UUID()
        let priority = IllustrationPriority.critical
        let status = IllustrationStatus.generating
        let createdAt = Date()
        let lastUpdatedAt = Date()
        let description = "A magical forest with unicorns"
        
        // Act
        let task = PendingIllustrationTask(
            id: id,
            pageId: pageId,
            storyId: storyId,
            priority: priority,
            status: status,
            createdAt: createdAt,
            lastUpdatedAt: lastUpdatedAt,
            attemptCount: 3,
            illustrationDescription: description,
            pageNumber: 2,
            totalPages: 5,
            previousIllustrationPath: "path/to/previous/image.png"
        )
        
        // Assert
        #expect(task.id == id)
        #expect(task.pageId == pageId)
        #expect(task.storyId == storyId)
        #expect(task.priority == priority)
        #expect(task.status == status)
        #expect(task.createdAt == createdAt)
        #expect(task.lastUpdatedAt == lastUpdatedAt)
        #expect(task.attemptCount == 3)
        #expect(task.illustrationDescription == description)
        #expect(task.pageNumber == 2)
        #expect(task.totalPages == 5)
        #expect(task.previousIllustrationPath == "path/to/previous/image.png")
        #expect(task.priorityRawValue == priority.rawValue)
        #expect(task.statusRawValue == status.rawValue)
    }
    
    @Test("PendingIllustrationTask converts enum values to/from raw values correctly")
    func testEnumConversion() {
        // Arrange
        let task = PendingIllustrationTask(
            pageId: UUID(),
            storyId: UUID(),
            priority: .high
        )
        
        // Initial values
        #expect(task.priorityRawValue == IllustrationPriority.high.rawValue)
        #expect(task.statusRawValue == IllustrationStatus.pending.rawValue)
        
        // Act - change via enum
        task.priority = .low
        task.status = .ready
        
        // Assert - raw values updated
        #expect(task.priorityRawValue == IllustrationPriority.low.rawValue)
        #expect(task.statusRawValue == IllustrationStatus.ready.rawValue)
        
        // Act - change via raw value
        task.priorityRawValue = IllustrationPriority.critical.rawValue
        task.statusRawValue = IllustrationStatus.failed.rawValue
        
        // Assert - enum properties updated
        #expect(task.priority == .critical)
        #expect(task.status == .failed)
    }
    
    @Test("PendingIllustrationTask converts from runtime IllustrationTask correctly")
    func testConversionFromRuntimeTask() {
        // Arrange
        let runtimeTask = createRuntimeTask()
        let description = "A test illustration description"
        
        // Act
        let persistentTask = PendingIllustrationTask.from(
            task: runtimeTask,
            pageNumber: 3,
            totalPages: 10,
            previousIllustrationPath: "path/to/image.png",
            illustrationDescription: description
        )
        
        // Assert
        #expect(persistentTask.id == runtimeTask.id)
        #expect(persistentTask.pageId == runtimeTask.pageId)
        #expect(persistentTask.storyId == runtimeTask.storyId)
        #expect(persistentTask.priority == runtimeTask.priority)
        #expect(persistentTask.status == runtimeTask.status)
        #expect(persistentTask.createdAt == runtimeTask.createdAt)
        #expect(persistentTask.lastUpdatedAt == runtimeTask.lastUpdatedAt)
        #expect(persistentTask.attemptCount == runtimeTask.attemptCount)
        #expect(persistentTask.pageNumber == 3)
        #expect(persistentTask.totalPages == 10)
        #expect(persistentTask.previousIllustrationPath == "path/to/image.png")
        #expect(persistentTask.illustrationDescription == description)
    }
    
    @Test("PendingIllustrationTask converts to runtime IllustrationTask correctly")
    func testConversionToRuntimeTask() {
        // Arrange
        let persistentTask = PendingIllustrationTask(
            id: UUID(),
            pageId: UUID(),
            storyId: UUID(),
            priority: .critical,
            status: .generating,
            createdAt: Date(),
            lastUpdatedAt: Date(),
            attemptCount: 5,
            illustrationDescription: "Sample description",
            pageNumber: 2,
            totalPages: 5,
            previousIllustrationPath: "sample/path.png"
        )
        
        // Act
        let runtimeTask = persistentTask.toRuntimeTask()
        
        // Assert
        #expect(runtimeTask.id == persistentTask.id)
        #expect(runtimeTask.pageId == persistentTask.pageId)
        #expect(runtimeTask.storyId == persistentTask.storyId)
        #expect(runtimeTask.priority == persistentTask.priority)
        #expect(runtimeTask.status == persistentTask.status)
        #expect(runtimeTask.createdAt == persistentTask.createdAt)
        #expect(runtimeTask.lastUpdatedAt == persistentTask.lastUpdatedAt)
        #expect(runtimeTask.attemptCount == persistentTask.attemptCount)
        // Note: Other fields (illustrationDescription, pageNumber, etc.) don't
        // transfer to the runtime model as they're not needed for processing
    }
}
