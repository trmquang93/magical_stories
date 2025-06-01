import Foundation
import Testing
@testable import magical_stories

@Suite("IllustrationTask Tests")
struct IllustrationTaskTests {
    
    @Test("IllustrationTask initialization sets properties correctly")
    func testInitialization() {
        // Arrange
        let id = UUID()
        let pageId = UUID()
        let storyId = UUID()
        let priority = IllustrationPriority.critical
        let status = IllustrationStatus.pending
        let createdAt = Date()
        
        // Act
        let task = IllustrationTask(
            id: id,
            pageId: pageId,
            storyId: storyId,
            priority: priority,
            status: status,
            createdAt: createdAt,
            lastUpdatedAt: createdAt,
            attemptCount: 0
        )
        
        // Assert
        #expect(task.id == id)
        #expect(task.pageId == pageId)
        #expect(task.storyId == storyId)
        #expect(task.priority == priority)
        #expect(task.status == status)
        #expect(task.createdAt == createdAt)
        #expect(task.lastUpdatedAt == createdAt)
        #expect(task.attemptCount == 0)
    }
    
    @Test("IllustrationTask equality based on id")
    func testEquality() {
        // Arrange
        let id = UUID()
        let pageId1 = UUID()
        let pageId2 = UUID()
        
        // Act
        let task1 = IllustrationTask(
            id: id,
            pageId: pageId1,
            storyId: UUID(),
            priority: .high,
            status: .pending
        )
        
        let task2 = IllustrationTask(
            id: id, // Same ID
            pageId: pageId2, // Different page ID
            storyId: UUID(), // Different story ID
            priority: .medium, // Different priority
            status: .generating // Different status
        )
        
        let task3 = IllustrationTask(
            id: UUID(), // Different ID
            pageId: pageId1,
            storyId: task1.storyId,
            priority: .high,
            status: .pending
        )
        
        // Assert
        #expect(task1 == task2, "Tasks with same ID should be equal")
        #expect(task1 != task3, "Tasks with different IDs should not be equal")
    }
    
    @Test("IllustrationTask updates status and timestamp")
    func testStatusUpdate() {
        // Arrange
        let createdAt = Date().addingTimeInterval(-3600) // 1 hour ago
        var task = IllustrationTask(
            id: UUID(),
            pageId: UUID(),
            storyId: UUID(),
            priority: .medium,
            status: .pending,
            createdAt: createdAt,
            lastUpdatedAt: createdAt,
            attemptCount: 0
        )
        
        // Act
        let beforeUpdate = Date()
        task.updateStatus(.generating)
        let afterUpdate = Date()
        
        // Assert
        #expect(task.status == .generating)
        #expect(task.lastUpdatedAt >= beforeUpdate)
        #expect(task.lastUpdatedAt <= afterUpdate)
    }
    
    @Test("IllustrationTask increments attempt count")
    func testIncrementAttempt() {
        // Arrange
        var task = IllustrationTask(
            id: UUID(),
            pageId: UUID(),
            storyId: UUID(),
            priority: .low,
            status: .pending,
            attemptCount: 0
        )
        
        // Act
        task.incrementAttempt()
        
        // Assert
        #expect(task.attemptCount == 1)
        
        // Act again
        task.incrementAttempt()
        
        // Assert
        #expect(task.attemptCount == 2)
    }
    
    @Test("IllustrationTask reset attempts")
    func testResetAttempts() {
        // Arrange
        var task = IllustrationTask(
            id: UUID(),
            pageId: UUID(),
            storyId: UUID(),
            priority: .high,
            status: .pending,
            attemptCount: 5
        )
        
        // Act
        task.resetAttempts()
        
        // Assert
        #expect(task.attemptCount == 0)
    }
    
    @Test("IllustrationTask creation with minimal parameters")
    func testMinimalInitialization() {
        // Arrange & Act
        let pageId = UUID()
        let storyId = UUID()
        let task = IllustrationTask(
            pageId: pageId,
            storyId: storyId,
            priority: .medium
        )
        
        // Assert
        #expect(task.pageId == pageId)
        #expect(task.storyId == storyId)
        #expect(task.priority == .medium)
        #expect(task.status == .pending)
        #expect(task.attemptCount == 0)
        // Check that id, createdAt and lastUpdatedAt were auto-generated
        #expect(task.id != UUID())
        #expect(task.createdAt <= Date())
        #expect(task.lastUpdatedAt <= Date())
        #expect(task.lastUpdatedAt >= task.createdAt.addingTimeInterval(-1)) // Allow for tiny time differences
    }
}
