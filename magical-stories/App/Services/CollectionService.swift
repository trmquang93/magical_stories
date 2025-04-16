import Combine
import Foundation
import SwiftData

/// Concrete implementation of `CollectionServiceProtocol` using SwiftData.
@MainActor
final class CollectionService: ObservableObject, CollectionServiceProtocol {
    private let repository: CollectionRepositoryProtocol
    private let storyService: StoryService

    @Published var collections: [StoryCollection] = []

    init(repository: CollectionRepositoryProtocol, storyService: StoryService) {
        self.repository = repository
        self.storyService = storyService
        // Load collections immediately on initialization
        loadCollections()
    }

    func createCollection(_ collection: StoryCollection) throws {
        print("[CollectionService] Creating collection: \(collection.title)")
        try repository.saveCollection(collection)
        print("[CollectionService] Collection saved successfully, reloading collections")
        // Reload collections after creation
        loadCollections()
    }

    func fetchCollection(id: UUID) throws -> StoryCollection? {
        try repository.fetchCollection(id: id)
    }

    func fetchAllCollections() throws -> [StoryCollection] {
        try repository.fetchAllCollections()
    }

    func updateCollectionProgress(id: UUID, progress: Float) throws {
        try repository.updateCollectionProgress(id: id, progress: Float(progress))
    }

    func deleteCollection(id: UUID) throws {
        try repository.deleteCollection(id: id)
    }

    func loadCollections() {
        do {
            let all = try repository.fetchAllCollections()
            print("[CollectionService] Loaded \(all.count) collections from repository")
            for (index, collection) in all.enumerated() {
                print(
                    "[CollectionService] Collection \(index + 1): \(collection.title), id: \(collection.id)"
                )
            }
            DispatchQueue.main.async {
                self.collections = all
                print(
                    "[CollectionService] Published collections updated: \(self.collections.count) items"
                )
            }
        } catch {
            print("[CollectionService] Failed to load collections: \(error)")
        }
    }

    /// Generate multiple stories for a given collection based on its parameters.
    /// This method asynchronously generates a fixed number of stories (e.g., 3) and adds them to the collection.
    func generateStoriesForCollection(
        _ collection: StoryCollection, parameters: CollectionParameters
    ) async throws {
        // Number of stories to generate per collection - can be adjusted
        let numberOfStories = 3

        var generatedStories: [Story] = []

        for i in 1...numberOfStories {
            // Prepare story parameters for each story
            let storyParams = StoryParameters(
                childName: parameters.childName ?? "Child",
                childAge: Int(
                    parameters.childAgeGroup.components(
                        separatedBy: CharacterSet.decimalDigits.inverted
                    ).joined()) ?? 5,
                theme: parameters.developmentalFocus,
                favoriteCharacter: parameters.characters?.first ?? "Friend"
            )

            print(
                "[CollectionService] Generating story \(i) for collection \(collection.title) with parameters: \(storyParams)"
            )

            // Generate story using StoryService
            let story = try await storyService.generateStory(parameters: storyParams)

            generatedStories.append(story)
        }

        // Add generated stories to the collection
        collection.stories = (collection.stories ?? []) + generatedStories

        // Save updated collection with stories
        try repository.saveCollection(collection)

        // Reload collections to update UI
        loadCollections()
    }
}
