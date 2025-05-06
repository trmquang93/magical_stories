import Foundation
import SwiftData

/// A persistable model for illustration tasks that allows tracking of illustration generation
/// tasks across app launches
@Model
final class PendingIllustrationTask {
    /// Unique identifier for the task
    @Attribute(.unique) var id: UUID
    
    /// ID of the page that needs an illustration
    var pageId: UUID
    
    /// ID of the story that the page belongs to
    var storyId: UUID
    
    /// Priority level of the task
    var priorityRawValue: Int
    
    /// Current status of the illustration task
    var statusRawValue: String
    
    /// When the task was created
    var createdAt: Date
    
    /// When the task was last updated
    var lastUpdatedAt: Date
    
    /// Number of times the task has been attempted
    var attemptCount: Int
    
    /// The detailed description for generating the illustration
    var illustrationDescription: String?
    
    /// Page number in the story
    var pageNumber: Int
    
    /// Total pages in the story
    var totalPages: Int
    
    /// Path to the previous page's illustration, if available
    var previousIllustrationPath: String?
    
    /// Computed property to convert raw priority value to IllustrationPriority enum
    var priority: IllustrationPriority {
        get {
            return IllustrationPriority(rawValue: priorityRawValue) ?? .medium
        }
        set {
            priorityRawValue = newValue.rawValue
        }
    }
    
    /// Computed property to convert raw status value to IllustrationStatus enum
    var status: IllustrationStatus {
        get {
            return IllustrationStatus(rawValue: statusRawValue) ?? .pending
        }
        set {
            statusRawValue = newValue.rawValue
        }
    }
    
    /// Default initializer
    init(
        id: UUID = UUID(),
        pageId: UUID,
        storyId: UUID,
        priority: IllustrationPriority,
        status: IllustrationStatus = .pending,
        createdAt: Date = Date(),
        lastUpdatedAt: Date? = nil,
        attemptCount: Int = 0,
        illustrationDescription: String? = nil,
        pageNumber: Int = 1,
        totalPages: Int = 1,
        previousIllustrationPath: String? = nil
    ) {
        self.id = id
        self.pageId = pageId
        self.storyId = storyId
        self.priorityRawValue = priority.rawValue
        self.statusRawValue = status.rawValue
        self.createdAt = createdAt
        self.lastUpdatedAt = lastUpdatedAt ?? createdAt
        self.attemptCount = attemptCount
        self.illustrationDescription = illustrationDescription
        self.pageNumber = pageNumber
        self.totalPages = totalPages
        self.previousIllustrationPath = previousIllustrationPath
    }
    
    /// Convert a runtime IllustrationTask to a persistent PendingIllustrationTask
    static func from(task: IllustrationTask, pageNumber: Int = 1, totalPages: Int = 1, previousIllustrationPath: String? = nil, illustrationDescription: String? = nil) -> PendingIllustrationTask {
        return PendingIllustrationTask(
            id: task.id,
            pageId: task.pageId,
            storyId: task.storyId,
            priority: task.priority,
            status: task.status,
            createdAt: task.createdAt,
            lastUpdatedAt: task.lastUpdatedAt,
            attemptCount: task.attemptCount,
            illustrationDescription: illustrationDescription,
            pageNumber: pageNumber,
            totalPages: totalPages,
            previousIllustrationPath: previousIllustrationPath
        )
    }
    
    /// Convert a persistent PendingIllustrationTask to a runtime IllustrationTask
    func toRuntimeTask() -> IllustrationTask {
        return IllustrationTask(
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
