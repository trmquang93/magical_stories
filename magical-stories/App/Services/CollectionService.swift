import Foundation
import SwiftData

protocol MockAIServiceProtocol {
    func generateStories(for theme: String, ageGroup: String) async throws -> [StoryModel]
}

class CollectionService: ObservableObject {
    private let aiService: MockAIServiceProtocol
    private let repository: CollectionRepository

    init(aiService: MockAIServiceProtocol, repository: CollectionRepository) {
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
        var storyModels: [StoryModel] = []

        while attempts <= maxRetries {
            do {
                storyModels = try await aiService.generateStories(for: theme, ageGroup: ageGroup)
                break
            } catch {
                attempts += 1
                if attempts > maxRetries {
                    throw error
                }
            }
        }

        let collection = StoryCollection(
            id: UUID(),
            title: title,
            descriptionText: nil,
            growthCategory: theme,
            targetAgeGroup: ageGroup,
            stories: storyModels.map { $0.toStory() },
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
                    }
                }()
            )
        )
    }
}

// Dummy preview AI service for previews
class PreviewAIService: MockAIServiceProtocol {
    func generateStories(for theme: String, ageGroup: String) async throws -> [StoryModel] {
        return []
    }
}