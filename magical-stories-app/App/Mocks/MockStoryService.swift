import Foundation
import SwiftData

class MockStoryService: StoryService {
    private let sleepDuration: UInt64 = 2_000_000_000  // 2 seconds

    init(context: ModelContext) {
        try! super.init(apiKey: "", context: context)
    }

    override func generateStory(parameters: StoryParameters) async throws -> Story {
        try await Task.sleep(nanoseconds: sleepDuration)

        return Story(
            id: UUID(),
            title: "Mock Story: \(parameters.childName)",
            pages: [],
            parameters: parameters,
            timestamp: Date()
        )
    }
}
