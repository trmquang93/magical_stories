import SwiftUI

// MARK: - Service Protocols

// Protocol for StoryService
@MainActor protocol StoryServiceProtocol: ObservableObject {
    var stories: [Story] { get }
    var isGenerating: Bool { get }
    
    func generateStory(parameters: StoryParameters) async throws -> Story
    func loadStories() async
}

// Protocol for PersistenceService
protocol PersistenceServiceProtocol {
    func saveStories(_ stories: [Story]) throws
    func loadStories() throws -> [Story]
    func saveStory(_ story: Story) throws
    func deleteStory(withId id: UUID) throws
}

// Protocol for SettingsService
@MainActor protocol SettingsServiceProtocol: ObservableObject {
    var parentalControls: ParentalControls { get }
    var appSettings: AppSettings { get }
    
    func updateParentalControls(_ controls: ParentalControls)
    func updateAppSettings(_ settings: AppSettings)
}

// Type extensions to make existing services conform to protocols
extension StoryService: StoryServiceProtocol {}
extension SettingsService: SettingsServiceProtocol {}
