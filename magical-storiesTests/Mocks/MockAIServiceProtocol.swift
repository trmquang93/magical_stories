import Foundation
@testable import magical_stories

/// Mock implementation of MockAIServiceProtocol for testing CollectionService.
/// Allows returning a controlled [StoryModel] or simulating errors for retry logic.
class MockAIService: MockAIServiceProtocol {
    /// The stories to return on success.
    var storiesToReturn: [StoryModel] = []
    /// The number of times to throw an error before succeeding.
    var errorCountBeforeSuccess: Int = 0
    /// The error to throw (default: generic NSError).
    var errorToThrow: Error = NSError(domain: "MockAIService", code: 1, userInfo: nil)
    /// Internal counter for how many times generateStories has been called.
    private var callCount = 0

    func generateStories(for theme: String, ageGroup: String) async throws -> [StoryModel] {
        if callCount < errorCountBeforeSuccess {
            callCount += 1
            throw errorToThrow
        }
        return storiesToReturn
    }

    /// Reset the call count (for use between tests if needed).
    func reset() {
        callCount = 0
    }
}