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
// Protocol for IllustrationService
protocol IllustrationServiceProtocol {
    /// Generates an illustration based on a text prompt.
    /// - Parameter prompt: The text description to generate an image from.
    /// - Returns: An optional URL pointing to the generated image, or nil if generation failed.
    /// - Throws: An error if the generation process encounters an issue (e.g., network error, API error).
    func generateIllustration(prompt: String) async throws -> URL?
}


// Type extensions to make existing services conform to protocols
extension StoryService: StoryServiceProtocol {}
extension SettingsService: SettingsServiceProtocol {}
