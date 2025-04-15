import Foundation
import SwiftData
import Testing

@testable import magical_stories

@Suite("Collection Service Integration Tests")
@MainActor
class CollectionServiceIntegrationTests {

    var collectionService: CollectionService!
    var aiService: MockAIService
    var repository: CollectionRepository!

    init() {
        // Setup for integration test - using new CollectionService API with appropriate mocks
        aiService = MockAIService()
        // Use in-memory ModelContext for repository
        let modelContext: ModelContext = {
            do {
                return try ModelContext(ModelContainer(for: StoryCollection.self))
            } catch {
                fatalError("Failed to create ModelContext/ModelContainer: \(error)")
            }
        }()
        repository = CollectionRepository(context: modelContext)
        collectionService = CollectionService(aiService: aiService, repository: repository)
        // Clean up any existing test data if needed (implementation may be updated in later subtasks)
    }

    // Helper function to clean up test data
    private func cleanupTestData() async {
        // Clean up collections created for testing
        // Implementation will be updated in a later subtask to use the new repository
    }
}
