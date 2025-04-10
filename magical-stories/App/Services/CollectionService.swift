import Foundation
import SwiftData

protocol MockAIServiceProtocol {
    func generateStories(for theme: String, ageGroup: String) async throws -> [StoryModel]
}

class CollectionService {
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
        var stories: [StoryModel] = []

        while attempts <= maxRetries {
            do {
                stories = try await aiService.generateStories(for: theme, ageGroup: ageGroup)
                break
            } catch {
                attempts += 1
                if attempts > maxRetries {
                    throw error
                }
            }
        }

        let collection = StoryCollection(
            id: UUID().uuidString,
            title: title,
            theme: theme,
            ageGroup: ageGroup,
            focusArea: focusArea,
            createdDate: Date(),
            stories: stories,
            progress: 0.0,
            achievements: []
        )

        try await repository.create(collection)
        return collection
    }

    func fetchCollections() async throws -> [StoryCollection] {
        let descriptor = FetchDescriptor<StoryCollection>()
        return try await repository.fetch(descriptor)
    }

    func updateProgress(for collectionId: String, progress: Double) async throws {
        guard let collection = try await repository.get(byId: collectionId) else { return }
        collection.progress = progress

        if progress >= 1.0 {
            let achievement = AchievementModel(
                name: "Completed Collection",
                achievementDescription: "Finished all stories in the collection",
                type: .specialMilestone
            )
            collection.achievements.append(achievement)
        }

        try await repository.update(collection)
    }
}