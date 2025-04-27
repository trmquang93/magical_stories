import Foundation
import SwiftData

class MockStoryService: StoryService {
    init(context: ModelContext) {
        try! super.init(apiKey: "", context: context)
    }

    override func generateStory(parameters: StoryParameters) async throws -> Story {
        try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds

        return Story(
            id: UUID(),
            title: "Mock Story: \(parameters.childName)",
            pages: [],
            parameters: parameters,
            timestamp: Date()
        )
    }
}
