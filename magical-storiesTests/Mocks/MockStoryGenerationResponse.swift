import Foundation
@testable import magical_stories

/// Minimal mock for story generation response used in tests.
struct MockStoryGenerationResponse: StoryGenerationResponse {
    let text: String?
}