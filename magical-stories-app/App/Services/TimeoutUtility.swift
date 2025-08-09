import Foundation

/// Timeout error thrown when operations exceed their time limit
struct TimeoutError: Error, Equatable {
    let message: String
    
    init(_ message: String = "Operation timed out") {
        self.message = message
    }
}

/// Utility function to wrap async operations with timeout handling
/// This prevents operations from hanging indefinitely and provides better error handling
/// 
/// - Parameters:
///   - timeout: Maximum time to wait for operation completion in seconds
///   - operation: The async operation to execute with timeout
/// - Returns: The result of the operation if completed within timeout
/// - Throws: TimeoutError if operation exceeds timeout, or original operation errors
@MainActor
func withTimeout<T: Sendable>(_ timeout: TimeInterval, operation: @escaping @MainActor @Sendable () async throws -> T) async throws -> T {
    return try await withThrowingTaskGroup(of: T.self) { group in
        // Add the actual operation task
        group.addTask {
            try await operation()
        }
        
        // Add timeout task
        group.addTask {
            try await Task.sleep(for: .seconds(timeout))
            throw TimeoutError("Operation timed out after \(timeout) seconds")
        }
        
        // Wait for first task to complete (either operation or timeout)
        guard let result = try await group.next() else {
            throw TimeoutError("No result from task group")
        }
        
        // Cancel remaining tasks
        group.cancelAll()
        return result
    }
}

/// Extension to provide convenience timeout methods for common operations
extension TimeoutUtility {
    
    /// Standard timeout for database operations (10 seconds)
    static let databaseTimeout: TimeInterval = 10.0
    
    /// Short timeout for quick operations (2 seconds)
    static let quickTimeout: TimeInterval = 2.0
    
    /// Long timeout for complex operations (30 seconds)
    static let longTimeout: TimeInterval = 30.0
    
    /// Wrap database operations with standard timeout
    @MainActor
    static func withDatabaseTimeout<T: Sendable>(_ operation: @escaping @MainActor @Sendable () async throws -> T) async throws -> T {
        return try await withTimeout(databaseTimeout, operation: operation)
    }
    
    /// Wrap quick operations with short timeout
    @MainActor
    static func withQuickTimeout<T: Sendable>(_ operation: @escaping @MainActor @Sendable () async throws -> T) async throws -> T {
        return try await withTimeout(quickTimeout, operation: operation)
    }
    
    /// Wrap complex operations with long timeout
    @MainActor
    static func withLongTimeout<T: Sendable>(_ operation: @escaping @MainActor @Sendable () async throws -> T) async throws -> T {
        return try await withTimeout(longTimeout, operation: operation)
    }
}

/// Utility class for timeout operations
enum TimeoutUtility {
    // Empty enum to act as namespace for static methods
}

/// Extension for Task to support timeout operations
extension Task where Success == Never, Failure == Never {
    /// Create a task that sleeps for specified duration and then throws timeout error
    static func timeout(after duration: TimeInterval) -> Task<Void, any Error> {
        Task<Void, any Error> {
            try await Task.sleep(for: .seconds(duration))
            throw TimeoutError("Timeout after \(duration) seconds")
        }
    }
}