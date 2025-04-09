import Foundation
import SwiftUI
import GoogleGenerativeAI

@MainActor
final class CollectionService: CollectionServiceProtocol {
    // MARK: - Published Properties
    
    @Published private(set) var collections: [GrowthCollection] = []
    @Published private(set) var isGenerating: Bool = false
    
    // MARK: - Dependencies
    
    private let storyService: StoryServiceProtocol
    private let persistenceService: PersistenceServiceProtocol
    private let aiErrorManager: AIErrorManager
    private let model: GenerativeModelProtocol
    
    // MARK: - Constants
    
    private enum Constants {
        static let storiesPerCollection = 5
        static let maxRetries = 3
        static let progressThresholds: [Float: String] = [
            0.25: "quarter_complete",
            0.5: "half_complete",
            0.75: "almost_complete",
            1.0: "collection_complete"
        ]
    }
    
    // MARK: - Initialization
    
    init(
        storyService: StoryServiceProtocol,
        persistenceService: PersistenceServiceProtocol,
        aiErrorManager: AIErrorManager,
        model: GenerativeModelProtocol
    ) {
        self.storyService = storyService
        self.persistenceService = persistenceService
        self.aiErrorManager = aiErrorManager
        self.model = model
    }
    
    // MARK: - CollectionServiceProtocol Implementation
    
    func generateCollection(parameters: CollectionParameters) async throws -> GrowthCollection {
        guard !isGenerating else {
            throw CollectionError.generationFailed(NSError(domain: "Collection generation already in progress", code: -1))
        }
        
        isGenerating = true
        defer { isGenerating = false }
        
        do {
            // 1. Generate collection outline using AI
            let collectionOutline = try await generateCollectionOutline(parameters: parameters)
            
            // 2. Create the collection object
            var collection = GrowthCollection(
                id: UUID(),
                title: collectionOutline.title,
                description: collectionOutline.description,
                theme: parameters.theme,
                targetAgeGroup: parameters.childAgeGroup,
                stories: [],
                progress: 0.0,
                associatedBadges: collectionOutline.achievementIds
            )
            
            // 3. Generate stories for the collection
            var generatedStories: [Story] = []
            for storyOutline in collectionOutline.storyOutlines {
                let storyParameters = StoryParameters(
                    childName: parameters.childName ?? "Friend",
                    childAge: parameters.childAge ?? 5,
                    theme: storyOutline.theme,
                    favoriteCharacter: parameters.characters?.first ?? "a magical creature",
                    additionalContext: storyOutline.context
                )
                
                var story = try await storyService.generateStory(parameters: storyParameters)
                
                story.collectionId = collection.id
                
                generatedStories.append(story)
            }
            
            // 4. Update collection with generated stories
            collection.stories = generatedStories
            
            // 5. Save the collection
            try await saveCollection(collection)
            
            // 6. Update local state
            if let index = collections.firstIndex(where: { $0.id == collection.id }) {
                collections[index] = collection
            } else {
                collections.append(collection)
            }
            
            return collection
            
        } catch {
            throw await aiErrorManager.handle(error: error, context: "Collection generation")
        }
    }
    
    func loadCollections() async {
        do {
            let loadedCollections = try await persistenceService.fetchAllCollections()
            collections = loadedCollections.sorted { $0.timestamp > $1.timestamp }
        } catch {
            print("Failed to load collections: \(error)")
            // Consider showing an error to the user via a dedicated error handling system
        }
    }
    
    func updateProgress(for collectionId: UUID, progress: Float) async throws {
        guard progress >= 0 && progress <= 1 else {
            throw CollectionError.invalidProgress
        }
        
        guard let index = collections.firstIndex(where: { $0.id == collectionId }) else {
            throw CollectionError.collectionNotFound
        }
        
        do {
            try await persistenceService.updateCollectionProgress(id: collectionId, progress: progress)
            collections[index].progress = progress
        } catch {
            throw CollectionError.persistenceFailed(error)
        }
    }
    
    func deleteCollection(_ collectionId: UUID) async throws {
        do {
            try await persistenceService.deleteCollection(id: collectionId)
            collections.removeAll { $0.id == collectionId }
        } catch {
            throw CollectionError.persistenceFailed(error)
        }
    }
    
    func checkAchievements(for collectionId: UUID) async throws -> [Achievement] {
        guard let collection = collections.first(where: { $0.id == collectionId }) else {
            throw CollectionError.collectionNotFound
        }
        
        var newAchievements: [Achievement] = []
        
        // Check progress-based achievements
        for (threshold, achievementId) in Constants.progressThresholds {
            if collection.progress >= threshold {
                if let achievement = try? await persistenceService.fetchAchievement(id: UUID(uuidString: achievementId) ?? UUID()) {
                    if achievement.dateEarned == nil {
                        var updatedAchievement = achievement
                        updatedAchievement.dateEarned = Date()
                        try await persistenceService.saveAchievement(updatedAchievement)
                        newAchievements.append(updatedAchievement)
                    }
                }
            }
        }
        
        // Check collection-specific achievements
        if let associatedBadges = collection.associatedBadges {
            for badgeId in associatedBadges {
                if let achievement = try? await persistenceService.fetchAchievement(id: UUID(uuidString: badgeId) ?? UUID()) {
                    if achievement.dateEarned == nil && collection.progress >= 1.0 {
                        var updatedAchievement = achievement
                        updatedAchievement.dateEarned = Date()
                        try await persistenceService.saveAchievement(updatedAchievement)
                        newAchievements.append(updatedAchievement)
                    }
                }
            }
        }
        
        return newAchievements
    }
    
    // MARK: - Private Helpers
    
    // Expected JSON structure from AI
    private struct AICollectionOutlineResponse: Codable {
        let title: String
        let description: String
        let achievementIds: [String]? // Optional achievement suggestions
        let storyOutlines: [AIStoryOutline]
        
        struct AIStoryOutline: Codable {
            let theme: String // Specific theme/focus for this story
            let context: String // Brief description or context for the story
        }
    }
    
    private struct CollectionOutline {
        let title: String
        let description: String
        let achievementIds: [String]?
        let storyOutlines: [StoryOutline]
    }
    
    private struct StoryOutline {
        let theme: String
        let context: String
    }
    
    private func buildCollectionOutlinePrompt(parameters: CollectionParameters) -> String {
        // Construct the prompt for the AI
        let childInfo = parameters.childName.map { " for a child named \($0)" } ?? ""
        let charactersInfo = parameters.characters.map { " featuring characters like \($0.joined(separator: ", " ) )" } ?? ""
        
        // Basic prompt structure - can be refined significantly
        return """
        Generate a plan for a collection of exactly \(Constants.storiesPerCollection) short children's stories\(childInfo).
        The collection should be suitable for the age group '\(parameters.childAgeGroup)' and focus on the developmental area of '\(parameters.developmentalFocus)'.
        The child's interests include: \(parameters.interests).\(charactersInfo)
        
        Provide the response strictly in the following JSON format, with no other text before or after the JSON block:
        
        {
          "title": "<Creative and relevant title for the collection>",
          "description": "<A brief, engaging description of the collection's theme and purpose>",
          "achievementIds": ["<optional_badge_id_1>", "<optional_badge_id_2>"], // Optional: Suggest 1-2 relevant badge IDs (simple strings like 'bravery_badge' or 'sharing_master') if applicable, otherwise null or empty array.
          "storyOutlines": [
            {
              "theme": "<Specific theme or moral for story 1 related to \(parameters.developmentalFocus)>",
              "context": "<One-sentence context or idea for story 1, incorporating interests: \(parameters.interests)>
            },
            {
              "theme": "<Specific theme or moral for story 2 related to \(parameters.developmentalFocus)>",
              "context": "<One-sentence context or idea for story 2, incorporating interests: \(parameters.interests)>
            }
            // ... continue for exactly \(Constants.storiesPerCollection) stories
          ]
        }
        
        Ensure the title and description are creative and suitable for the target audience.
        Ensure each story outline has a specific theme related to '\(parameters.developmentalFocus)' and a context incorporating the child's interests '\(parameters.interests)'.
        Ensure the JSON is valid and complete.
        """
    }
    
    private func generateCollectionOutline(parameters: CollectionParameters) async throws -> CollectionOutline {
        let prompt = buildCollectionOutlinePrompt(parameters: parameters)
        var attempts = 0
        
        while attempts < Constants.maxRetries {
            attempts += 1
            print("[CollectionService] Attempt \(attempts)/\(Constants.maxRetries) to generate collection outline.")
            
            do {
                // Call the AI model
                let response = try await model.generateContent(prompt)
                
                guard let responseText = response.text else {
                    throw CollectionError.aiServiceError(NSError(domain: "CollectionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "AI response text was nil"]))
                }
                
                // Clean the response text: Find the JSON block
                guard let jsonStart = responseText.firstIndex(of: "{"),
                      let jsonEnd = responseText.lastIndex(of: "}") else {
                    print("[CollectionService] Failed to find JSON block in response:\n\(responseText)")
                    throw CollectionError.aiServiceError(NSError(domain: "CollectionService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not find JSON block in AI response"]))
                }
                
                let jsonString = String(responseText[jsonStart...jsonEnd])
                print("[CollectionService] Received JSON string:\n\(jsonString)")
                
                // Decode the JSON
                guard let jsonData = jsonString.data(using: .utf8) else {
                     print("[CollectionService] Failed to convert JSON string to data.")
                    throw CollectionError.aiServiceError(NSError(domain: "CollectionService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON string to Data"]))
                }
                
                let decoder = JSONDecoder()
                let aiResponse = try decoder.decode(AICollectionOutlineResponse.self, from: jsonData)
                
                // Validate number of story outlines
                guard aiResponse.storyOutlines.count == Constants.storiesPerCollection else {
                    print("[CollectionService] AI returned \(aiResponse.storyOutlines.count) outlines, expected \(Constants.storiesPerCollection).")
                    throw CollectionError.aiServiceError(NSError(domain: "CollectionService", code: 5, userInfo: [NSLocalizedDescriptionKey: "AI returned incorrect number of story outlines (\(aiResponse.storyOutlines.count)/\(Constants.storiesPerCollection))"]))
                }
                
                // Map AI response to internal structure
                let internalStoryOutlines = aiResponse.storyOutlines.map {
                    StoryOutline(theme: $0.theme, context: $0.context)
                }
                
                return CollectionOutline(
                    title: aiResponse.title,
                    description: aiResponse.description,
                    achievementIds: aiResponse.achievementIds,
                    storyOutlines: internalStoryOutlines
                )
                
            } catch let error as DecodingError {
                 print("[CollectionService] JSON Decoding Error: \(error)")
                 // Log specific decoding error details
                 let context = "Failed to decode AI response JSON: \(error.localizedDescription). Path: \(error.codingPath). Debug: \(error.failureReason ?? "N/A")"
                 await aiErrorManager.handle(error: error, context: context)
                 if attempts >= Constants.maxRetries {
                     throw CollectionError.aiServiceError(error)
                 }
                 // Optional: Small delay before retry
                 try? await Task.sleep(nanoseconds: 500_000_000)
                 
             } catch {
                print("[CollectionService] Error during outline generation attempt \(attempts): \(error)")
                // Log generic error
                await aiErrorManager.handle(error: error, context: "Collection outline generation attempt \(attempts)")
                
                if attempts >= Constants.maxRetries {
                    // If it's already a CollectionError, rethrow it, otherwise wrap it
                    if let collectionError = error as? CollectionError {
                        throw collectionError
                    } else {
                         throw CollectionError.aiServiceError(error)
                    }
                }
                // Optional: Small delay before retry
                try? await Task.sleep(nanoseconds: 1_000_000_000 * UInt64(attempts)) // Exponential backoff?
            }
        }
        
        // Should not be reached if maxRetries > 0, but needed for compiler
        fatalError("Exited retry loop unexpectedly in generateCollectionOutline")
    }
    
    private func saveCollection(_ collection: GrowthCollection) async throws {
        do {
            try await persistenceService.saveCollection(collection)
        } catch {
            throw CollectionError.persistenceFailed(error)
        }
    }
}

// MARK: - Preview Helper

extension CollectionService {
    static var preview: CollectionService {
        let storyService = StoryService.preview
        let persistenceService = PreviewPersistenceService()
        let aiErrorManager = AIErrorManager()
        
        // Need a preview/mock GenerativeModelProtocol
        struct MockStoryGenerationResponse: StoryGenerationResponse {
             var text: String? = "Mock AI Response"
        }
        struct MockGenerativeModel: GenerativeModelProtocol {
            func generateContent(_ prompt: String) async throws -> StoryGenerationResponse {
                 print("--- MOCK AI Prompt ---")
                 print(prompt)
                 print("---------------------")
                 // Simulate a delay
                 try await Task.sleep(nanoseconds: 500_000_000) 
                 // Provide a mock response suitable for collection outline (JSON ideally)
                 // For now, just a basic text response
                 return MockStoryGenerationResponse(text: """
                 {
                     "title": "Mock Collection: Exploring Bravery",
                     "description": "A mock collection about being brave.",
                     "achievementIds": ["bravery_badge_1"],
                     "storyOutlines": [
                         {"theme": "Facing Fears", "context": "A little squirrel learns to climb a tall tree."},
                         {"theme": "Trying New Things", "context": "A bear cub tastes a new berry."}
                     ]
                 }
                 """)
            }
        }

        return CollectionService(
            storyService: storyService,
            persistenceService: persistenceService,
            aiErrorManager: aiErrorManager,
            model: MockGenerativeModel() // Use the mock model for preview
        )
    }
} 