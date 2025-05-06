import Foundation

/// Represents the priority levels for illustration generation tasks
enum IllustrationPriority: Int, Codable, Comparable {
    case critical = 0  // Title page, always visible immediately
    case high = 1      // First content page, visible in preview
    case medium = 2    // Middle pages likely to be viewed soon
    case low = 3       // Later pages or pages rarely viewed
    
    /// Implement Comparable for priority-based sorting
    static func < (lhs: IllustrationPriority, rhs: IllustrationPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// Represents a task for generating an illustration
struct IllustrationTask: Identifiable, Equatable, Codable {
    let id: UUID
    let pageId: UUID
    let storyId: UUID
    let priority: IllustrationPriority
    var status: IllustrationStatus
    let createdAt: Date
    var lastUpdatedAt: Date
    var attemptCount: Int
    
    /// Default initializer with all properties
    init(
        id: UUID = UUID(),
        pageId: UUID,
        storyId: UUID,
        priority: IllustrationPriority,
        status: IllustrationStatus = .pending,
        createdAt: Date = Date(),
        lastUpdatedAt: Date? = nil,
        attemptCount: Int = 0
    ) {
        self.id = id
        self.pageId = pageId
        self.storyId = storyId
        self.priority = priority
        self.status = status
        self.createdAt = createdAt
        self.lastUpdatedAt = lastUpdatedAt ?? createdAt
        self.attemptCount = attemptCount
    }
    
    /// Updates the task status and sets lastUpdatedAt to current time
    mutating func updateStatus(_ newStatus: IllustrationStatus) {
        self.status = newStatus
        self.lastUpdatedAt = Date()
    }
    
    /// Increments the attempt count and updates lastUpdatedAt
    mutating func incrementAttempt() {
        self.attemptCount += 1
        self.lastUpdatedAt = Date()
    }
    
    /// Resets the attempt count to zero and updates lastUpdatedAt
    mutating func resetAttempts() {
        self.attemptCount = 0
        self.lastUpdatedAt = Date()
    }
    
    /// Equatable implementation based on id only
    static func == (lhs: IllustrationTask, rhs: IllustrationTask) -> Bool {
        return lhs.id == rhs.id
    }
}
