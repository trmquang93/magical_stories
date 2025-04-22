import SwiftData
import SwiftUI

@testable import magical_stories

// Test-specific mock for StoryService used in UI tests
@MainActor
public class TestMockStoryService: ObservableObject {
    @Published public var stories: [Story] = []

    public init() {}

    public func addMockStories(_ stories: [Story]) async {
        self.stories.append(contentsOf: stories)
    }
}
