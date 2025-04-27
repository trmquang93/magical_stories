import Foundation
import SwiftData

@testable import magical_stories

/// A mock implementation of StoryService for use in previews and tests
class MockStoryService: StoryService {
    // --- Test tracking properties ---
    var generateStoryCallCount = 0
    var lastParameters: StoryParameters?
    var shouldFailGeneration = false
   var storiesToReturn: [Story] = []
   var nextStoryIndex = 0
   var simulateNetworkError = false
    var numberOfStoriesToGenerate: Int = 0

    var shouldSimulateError = false
    var simulatedError: Error?
    var simulatedDelay: UInt64 = 2_000_000_000  // 2 seconds by default

    // Required initializer for tests
    convenience init(context: ModelContext) {
        try! self.init(
            apiKey: "mock-api-key",
            context: context
        )
    }

    override func generateStory(parameters: StoryParameters) async throws -> Story {
        // Simulate network error
        if simulateNetworkError {
            throw NSError(
                domain: "MockStoryService", code: NSURLErrorNotConnectedToInternet,
                userInfo: [
                    NSLocalizedDescriptionKey: "Simulated network error"
                ])
        }

        // Simulate network delay
        try await Task.sleep(nanoseconds: simulatedDelay)

        // Optionally simulate an error
        if shouldSimulateError {
            if let error = simulatedError {
                throw error
            } else {
                throw NSError(
                    domain: "MockStoryService", code: 500,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Simulated story generation error"
                    ])
            }
        }

        print("Mock generating story with params: \(parameters)")

        // Create a mock story with sample pages
        return Story(
            id: UUID(),
            title: "The Magical Adventure of \(parameters.childName)",
            pages: createMockPages(for: parameters),
            parameters: parameters,
            timestamp: Date(),
            categoryName: "Fantasy"
        )
    }

    /// Creates mock pages based on story parameters for preview and testing purposes
    private func createMockPages(for parameters: StoryParameters) -> [Page] {
        let storyLength = parameters.storyLength?.lowercased() ?? "medium"
        let length: Int
        switch storyLength {
        case "short":
            length = 3
        case "long":
            length = 7
        default:  // Medium
            length = 5
        }

        var pages: [Page] = []

        // Introduction page
        pages.append(
            Page(
                id: UUID(),
                content:
                    "Once upon a time, in a magical kingdom far away, there lived a brave child named \(parameters.childName). \(parameters.childName) was \(parameters.childAge) years old and loved going on adventures with their friend, a friendly \(parameters.favoriteCharacter).",
                pageNumber: 1,
                illustrationRelativePath: "placeholder-illustration"
            ))

        // Middle pages based on the theme
        for i in 2..<length {
            let content: String
            switch parameters.theme.lowercased() {
            case "adventure":
                content =
                    "On day \(i) of their journey, \(parameters.childName) and the \(parameters.favoriteCharacter) discovered a hidden cave filled with glowing crystals. \"Look at these treasures!\" exclaimed \(parameters.childName) excitedly."
            case "friendship":
                content =
                    "\(parameters.childName) and the \(parameters.favoriteCharacter) sat by the river, sharing stories and laughing together. They promised to always be there for each other, no matter what challenges they faced."
            case "learning":
                content =
                    "As they explored the ancient library, \(parameters.childName) learned about the history of the magical kingdom. The \(parameters.favoriteCharacter) helped turn the giant pages of the dusty books."
            case "courage":
                content =
                    "A mighty storm approached, but \(parameters.childName) wasn't afraid. \"We can brave this together,\" they told the \(parameters.favoriteCharacter), who nodded in agreement."
            case "kindness":
                content =
                    "\(parameters.childName) noticed a small creature who needed help. Without hesitation, they and the \(parameters.favoriteCharacter) gently rescued it and brought it to safety."
            default:
                content =
                    "The adventure continued as \(parameters.childName) and the \(parameters.favoriteCharacter) explored more of the magical kingdom, making new friends along the way."
            }

            pages.append(
                Page(
                    id: UUID(),
                    content: content,
                    pageNumber: i,
                    illustrationRelativePath: "placeholder-illustration"
                ))
        }

        // Final page with conclusion
        pages.append(
            Page(
                id: UUID(),
                content:
                    "As the sun began to set, \(parameters.childName) and the \(parameters.favoriteCharacter) made their way home, tired but happy after their wonderful adventure. They couldn't wait to see what tomorrow would bring! THE END.",
                pageNumber: length,
                illustrationRelativePath: "placeholder-illustration"
            ))

        return pages
    }
}
