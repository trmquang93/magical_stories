import Foundation

struct MockStory {
    var id: String
    var title: String
    var content: String
    var imageURL: String?
}

protocol MockAIServiceProtocol {
    func generateStories(for theme: String, ageGroup: String) async throws -> [MockStory]
}