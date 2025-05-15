import Testing
import SwiftData
@testable import magical_stories
import Foundation

@Suite("Illustration Consistency Integration Tests")
struct IllustrationConsistencyIntegrationTests {
    
    @Test("End-to-end flow with visual guide should pass guide through all components")
    func testEndToEndVisualGuideFlow() async throws {
        // Arrange - Set up the environment
        // Create in-memory database
        let schema = Schema([Story.self, Page.self])
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let modelContext = await modelContainer.mainContext
        
        // Create mock responses for all network calls
        let mockStoryXmlResponse = """
        <title>The Dragon's Quest</title>
        <visual_guide>
            <style_guide>Colorful watercolor style with soft edges and warm lighting</style_guide>
            <character_definitions>
                <character name="Luna">A 6-year-old girl with curly brown hair, bright blue eyes, and freckles. She wears a yellow sunflower dress with red sneakers.</character>
                <character name="Drago">A small friendly dragon with emerald green scales, purple wings, and golden eyes. He has tiny horns and wears a blue crystal pendant.</character>
            </character_definitions>
            <setting_definitions>
                <setting name="Enchanted Forest">A lush green forest with tall oak trees, colorful mushrooms, and a winding dirt path. Rays of golden sunlight filter through the leaves.</setting>
                <setting name="Dragon Cave">A warm cave with crystal formations in various colors. A small waterfall trickles down one wall into a glowing pool of water.</setting>
            </setting_definitions>
        </visual_guide>
        <content>
        Once upon a time, there was a little girl named Luna who loved adventures.
        ---
        One day, Luna discovered a map to a dragon's cave hidden in the Enchanted Forest.
        ---
        In the cave, she met Drago, a friendly dragon who was guarding a magical crystal.
        </content>
        <category>Fantasy</category>
        <illustrations>
            <illustration page="1">Luna holding a map, standing at the edge of the Enchanted Forest. She looks excited, with her curly brown hair blowing in the breeze.</illustration>
            <illustration page="2">Luna walking through the Enchanted Forest, surrounded by tall trees and colorful mushrooms.</illustration>
            <illustration page="3">Luna meeting Drago in the crystal cave. The dragon is small with green scales and purple wings.</illustration>
        </illustrations>
        """
        
        let mockGenerationResponse = createImageGenerationResponse()
        
        // Set up a shared mock URLSession and define responses
        let mockSession = SharedMockURLSession()
        
        // Add response for story generation (from Gemini)
        mockSession.addResponse(
            for: "generativelanguage.googleapis.com",
            statusCode: 200,
            data: prepareGeminiResponse(with: mockStoryXmlResponse)
        )
        
        // Add response for illustration generation
        mockSession.addResponse(
            for: "generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict",
            statusCode: 200,
            data: try JSONEncoder().encode(mockGenerationResponse)
        )
        
        // Create the services with mocked dependencies
        let illustrationService = try TestIllustrationService(
            apiKey: "test-api-key",
            urlSession: mockSession
        )
        
        // Mock the file saving
        let mockFileSaver = MockFileSaver()
        illustrationService.fileSaver = mockFileSaver
        
        let generativeModel = TestGenerativeModel(responseText: mockStoryXmlResponse)
        
        let persistenceService = await TestPersistenceService(context: modelContext)
        let storyProcessor = await StoryProcessor(
            illustrationService: illustrationService,
            generativeModel: generativeModel
        )
        
        let storyService = try await StoryService(
            apiKey: "test-api-key",
            context: modelContext,
            persistenceService: persistenceService,
            model: generativeModel,
            storyProcessor: storyProcessor
        )
        
        // Create test parameters
        let parameters = StoryParameters(
            childName: "Emma",
            childAge: 6,
            theme: "Adventure",
            favoriteCharacter: "Dragon"
        )
        
        // Act - Generate a story which should trigger the visual guide flow
        let story = try await storyService.generateStory(parameters: parameters)
        
        // Assert - Verify the visual guide was extracted and passed through
        // 1. Check if mockSession was called with requests containing visual guide
        let requestsContainingVisualGuide = mockSession.capturedRequests.filter { request in
            if let body = request.httpBody,
               let bodyString = String(data: body, encoding: .utf8) {
                return bodyString.contains("VISUAL GUIDE INFORMATION") &&
                       bodyString.contains("Colorful watercolor style") &&
                       bodyString.contains("Luna: A 6-year-old girl")
            }
            return false
        }
        
        #expect(!requestsContainingVisualGuide.isEmpty, "No requests containing visual guide were made")
        
        // 2. Check if MockFileSaver was called, indicating illustrations were generated
        #expect(mockFileSaver.savedFiles.count > 0, "No files were saved")
        
        // 3. Verify story has the expected pages and structure
        #expect(story.pages.count == 3, "Story should have 3 pages")
        
        // 4. Verify all pages have illustration paths set (indicating successful generation)
        for page in story.pages {
            #expect(page.illustrationPath != nil, "Page \(page.pageNumber) should have an illustration path")
        }
    }
    
    // Helper methods
    private func createImageGenerationResponse() -> ImagenPredictionResponse {
        let base64Image = "SGVsbG8sIHdvcmxkIQ==" // Simple "Hello, world!" in base64
        return ImagenPredictionResponse(
            predictions: [
                ImagenPrediction(
                    bytesBase64Encoded: base64Image,
                    mimeType: "image/png"
                )
            ]
        )
    }
    
    private func prepareGeminiResponse(with text: String) -> Data {
        // Create a mock Gemini response with our test XML
        let response = """
        {
            "candidates": [
                {
                    "content": {
                        "parts": [
                            {
                                "text": "\(text)"
                            }
                        ],
                        "role": "model"
                    },
                    "finishReason": "STOP",
                    "safetyRatings": []
                }
            ],
            "promptFeedback": {
                "safetyRatings": []
            }
        }
        """
        return response.data(using: .utf8)!
    }
}

// Mock file saver for testing
class MockFileSaver {
    var savedFiles: [(data: Data, mimeType: String, path: String)] = []
    
    func saveFile(data: Data, mimeType: String, toPath path: String) -> String {
        savedFiles.append((data: data, mimeType: mimeType, path: path))
        return "mock/path/\(UUID().uuidString).png"
    }
}

/// A mock response for story generation testing specific to these tests
struct TestStoryGenerationResponse: StoryGenerationResponse {
    let text: String?
    
    init(text: String?) {
        self.text = text
    }
}

/// A mock generative model implementation specific to these tests
class TestGenerativeModel: GenerativeModelProtocol {
    let responseText: String
    let shouldThrow: Bool
    let error: Error?
    
    init(responseText: String, shouldThrow: Bool = false, error: Error? = nil) {
        self.responseText = responseText
        self.shouldThrow = shouldThrow
        self.error = error
    }
    
    func generateContent(_ prompt: String) async throws -> StoryGenerationResponse {
        if shouldThrow {
            throw error ?? NSError(domain: "TestGenerativeModel", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        return TestStoryGenerationResponse(text: responseText)
    }
}

/// A mock implementation of the PersistenceServiceProtocol specific to these tests
class TestPersistenceService: PersistenceServiceProtocol {
    private let context: ModelContext
    private var stories: [Story] = []
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func saveStories(_ stories: [Story]) async throws {
        for story in stories {
            try await saveStory(story)
        }
    }
    
    func saveStory(_ story: Story) async throws {
        if !stories.contains(where: { $0.id == story.id }) {
            stories.append(story)
            context.insert(story)
            try context.save()
        }
    }
    
    func loadStories() async throws -> [Story] {
        return stories
    }
    
    func fetchStory(withId id: UUID) async throws -> Story? {
        return stories.first(where: { $0.id == id })
    }
    
    func deleteStory(withId id: UUID) async throws {
        if let index = stories.firstIndex(where: { $0.id == id }) {
            let story = stories[index]
            stories.remove(at: index)
            context.delete(story)
            try context.save()
        }
    }
    
    func incrementReadCount(for storyId: UUID) async throws {
        if let story = stories.first(where: { $0.id == storyId }) {
            story.readCount += 1
        }
    }
    
    func toggleFavorite(for storyId: UUID) async throws {
        if let story = stories.first(where: { $0.id == storyId }) {
            story.isFavorite.toggle()
        }
    }
    
    func updateLastReadAt(for storyId: UUID, date: Date) async throws {
        if let story = stories.first(where: { $0.id == storyId }) {
            story.lastReadAt = date
        }
    }
    
    // Achievement Management
    func saveAchievement(_ achievement: Achievement) async throws {
        // No-op for testing
    }
    
    func fetchAchievement(id: UUID) async throws -> Achievement? {
        return nil
    }
    
    func fetchAllAchievements() async throws -> [Achievement] {
        return []
    }
    
    func fetchEarnedAchievements() async throws -> [Achievement] {
        return []
    }
    
    func fetchAchievements(forCollection collectionId: UUID) async throws -> [Achievement] {
        return []
    }
    
    func updateAchievementStatus(id: UUID, isEarned: Bool, earnedDate: Date?) async throws {
        // No-op for testing
    }
    
    func deleteAchievement(withId id: UUID) async throws {
        // No-op for testing
    }
    
    func associateAchievement(_ achievementId: String, withCollection collectionId: UUID) async throws {
        // No-op for testing
    }
    
    func removeAchievementAssociation(_ achievementId: String, fromCollection collectionId: UUID) async throws {
        // No-op for testing
    }
}

// Custom IllustrationService subclass that doesn't try to override private methods
class TestIllustrationService: IllustrationService {
    var fileSaver: MockFileSaver? = nil
    
    // Hook into the public methods instead of trying to override private methods
    override public func generateIllustration(
        for illustrationDescription: String,
        pageNumber: Int,
        totalPages: Int,
        previousIllustrationPath: String?,
        visualGuide: VisualGuide?
    ) async throws -> String? {
        if let fileSaver = fileSaver {
            // Mock image data for testing
            let mockImageData = "SGVsbG8sIHdvcmxkIQ==".data(using: .utf8)!
            return fileSaver.saveFile(data: mockImageData, mimeType: "image/png", toPath: "mock/path")
        }
        return try await super.generateIllustration(
            for: illustrationDescription,
            pageNumber: pageNumber,
            totalPages: totalPages,
            previousIllustrationPath: previousIllustrationPath,
            visualGuide: visualGuide
        )
    }
}