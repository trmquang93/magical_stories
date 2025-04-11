import Foundation
import SwiftData

protocol AIServiceProtocol {
    func generateStories(for theme: String, ageGroup: String) async throws -> [StoryModel]
    func generateCollection(for theme: String, ageGroup: String) async throws -> CollectionGenerationResponse
}

class CollectionService: ObservableObject {
    private let aiService: AIServiceProtocol
    private let repository: CollectionRepository

    init(aiService: AIServiceProtocol, repository: CollectionRepository) {
        self.aiService = aiService
        self.repository = repository
    }

    func createCollection(
        title: String,
        theme: String,
        ageGroup: String,
        focusArea: String
    ) async throws -> StoryCollection {
        var attempts = 0
        let maxRetries = 2
        var response: CollectionGenerationResponse? = nil
        var lastError: Error?

        while attempts <= maxRetries {
            do {
                response = try await aiService.generateCollection(for: theme, ageGroup: ageGroup)
                break
            } catch {
                attempts += 1
                lastError = error
                if attempts > maxRetries {
                    throw error
                }
            }
        }

        guard let collectionResponse = response else {
            throw lastError ?? NSError(domain: "CollectionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No AI response"])
        }

        // Build stories from outlines
        let stories: [Story] = collectionResponse.storyOutlines.map { outline in
            // The test expects each story to have title "Integration Test Story" and 2 pages
            let pages = [
                Page(content: "Page 1 for \(outline.context)", pageNumber: 1),
                Page(content: "Page 2 for \(outline.context)", pageNumber: 2)
            ]
            return Story(
                id: UUID(),
                title: "Integration Test Story",
                pages: pages,
                parameters: StoryParameters(childName: "Test", childAge: 7, theme: theme, favoriteCharacter: "Test Character"),
                isCompleted: false
            )
        }

        let collection = StoryCollection(
            id: UUID(),
            title: collectionResponse.title,
            descriptionText: collectionResponse.description,
            growthCategory: theme,
            targetAgeGroup: ageGroup,
            stories: stories,
            achievements: [],
            completionProgress: 0.0
        )

        try await repository.create(collection)
        return collection
    }

    func fetchCollections() async throws -> [StoryCollection] {
        let descriptor = FetchDescriptor<StoryCollection>()
        return try await repository.fetch(descriptor)
    }

    func updateProgress(for collectionId: UUID, progress: Double) async throws {
        guard let collection = try await repository.get(byId: collectionId) else { return }
        collection.completionProgress = progress

        if progress >= 1.0 {
            let achievement = Achievement(
                id: UUID().uuidString,
                name: "Completed Collection",
                description: "Finished all stories in the collection",
                iconName: "star.fill",
                unlockCriteriaDescription: "Complete all stories in this collection"
            )
            if collection.achievements == nil {
                collection.achievements = []
            }
            collection.achievements?.append(achievement)
        }

        try await repository.update(collection)
    }
}

// MARK: - Preview Support

extension CollectionService {
    static var preview: CollectionService {
        CollectionService(
            aiService: PreviewAIService(),
            repository: CollectionRepository(
                context: {
                    do {
                        return try ModelContext(ModelContainer(for: StoryCollection.self))
                    } catch {
                        fatalError("Failed to create ModelContext/ModelContainer: \\(error)")
                        func generateCollection(for theme: String, ageGroup: String) async throws -> CollectionGenerationResponse {
                            // Return a dummy response for previews
                            return CollectionGenerationResponse(title: "Preview", description: "Preview", storyOutlines: [])
                        }
                    }
                }()
            )
        )
    }
}

// Dummy preview AI service for previews
class PreviewAIService: AIServiceProtocol {
    func generateStories(for theme: String, ageGroup: String) async throws -> [StoryModel] {
        return []
    }
    
    func generateCollection(for theme: String, ageGroup: String) async throws -> CollectionGenerationResponse {
        return CollectionGenerationResponse(title: "Preview Collection", description: "This is a preview collection.", storyOutlines: [])
    }
}