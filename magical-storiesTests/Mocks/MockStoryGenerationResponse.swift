import Foundation
@testable import magical_stories

struct MockStoryGenerationResponse: StoryGenerationResponse {
    let text: String?
    
    init(text: String?) {
        self.text = text
    }
}