import Foundation
import SwiftData

enum CollectionFilter {
    case theme(String)
}

enum CollectionSort {
    case createdDateDescending
}

class CollectionRepository: BaseRepository<StoryCollection> {
    init(context: ModelContext) {
        super.init(modelContext: context)
    }

    func create(_ collection: StoryCollection) async throws {
        try await save(collection)
    }

    func get(byId id: String) async throws -> StoryCollection? {
        let descriptor = FetchDescriptor<StoryCollection>(
            predicate: #Predicate { $0.id == id }
        )
        let results = try await fetch(descriptor)
        return results.first
    }

    override func update(_ collection: StoryCollection) async throws {
        try await super.update(collection)
    }

    func delete(byId id: String) async throws {
        if let collection = try await get(byId: id) {
            try await delete(collection)
        }
    }

    func fetch(filter: CollectionFilter) async throws -> [StoryCollection] {
        switch filter {
        case .theme(let theme):
            let descriptor = FetchDescriptor<StoryCollection>(
                predicate: #Predicate { $0.theme == theme }
            )
            return try await fetch(descriptor)
        }
    }

    func fetchSorted(by sort: CollectionSort) async throws -> [StoryCollection] {
        switch sort {
        case .createdDateDescending:
            let descriptor = FetchDescriptor<StoryCollection>(
                sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
            )
            return try await fetch(descriptor)
        }
    }

    func addStory(_ story: StoryModel, toCollectionId id: String) async throws {
        guard let collection = try await get(byId: id) else { return }
        if !collection.stories.contains(where: { $0.id == story.id }) {
            collection.stories.append(story)
            try await update(collection)
        }
    }

    func removeStory(storyId: String, fromCollectionId id: String) async throws {
        guard let collection = try await get(byId: id) else { return }
        guard let uuid = UUID(uuidString: storyId) else { return }
        collection.stories.removeAll { $0.id == uuid }
        try await update(collection)
    }
}