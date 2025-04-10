import Foundation
import SwiftData

enum CollectionFilter {
    case growthCategory(String)
    case targetAgeGroup(String)
}

enum CollectionSort {
    case createdAtDescending
}

class CollectionRepository: BaseRepository<StoryCollection> {
    init(context: ModelContext) {
        super.init(modelContext: context)
    }

    func create(_ collection: StoryCollection) async throws {
        try await save(collection)
    }

    func get(byId id: UUID) async throws -> StoryCollection? {
        let descriptor = FetchDescriptor<StoryCollection>(
            predicate: #Predicate { $0.id == id }
        )
        let results = try await fetch(descriptor)
        return results.first
    }

    override func update(_ collection: StoryCollection) async throws {
        try await super.update(collection)
    }

    func delete(byId id: UUID) async throws {
        if let collection = try await get(byId: id) {
            try await delete(collection)
        }
    }

    func fetch(filter: CollectionFilter) async throws -> [StoryCollection] {
        switch filter {
        case .growthCategory(let category):
            let descriptor = FetchDescriptor<StoryCollection>(
                predicate: #Predicate { $0.growthCategory == category }
            )
            return try await fetch(descriptor)
        case .targetAgeGroup(let ageGroup):
            let descriptor = FetchDescriptor<StoryCollection>(
                predicate: #Predicate { $0.targetAgeGroup == ageGroup }
            )
            return try await fetch(descriptor)
        }
    }

    func fetchSorted(by sort: CollectionSort) async throws -> [StoryCollection] {
        switch sort {
        case .createdAtDescending:
            let descriptor = FetchDescriptor<StoryCollection>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            return try await fetch(descriptor)
        }
    }

    func addStory(_ story: Story, toCollectionId id: UUID) async throws {
        guard let collection = try await get(byId: id) else { return }
        if !collection.stories.contains(where: { $0.id == story.id }) {
            collection.stories.append(story)
            try await update(collection)
        }
    }

    func removeStory(storyId: UUID, fromCollectionId id: UUID) async throws {
        guard let collection = try await get(byId: id) else { return }
        collection.stories.removeAll { $0.id == storyId }
        try await update(collection)
    }
}