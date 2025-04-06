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
    /// Generates an illustration URL for the given page text and theme.
    /// - Parameters:
    ///   - pageText: The text content of the story page.
    ///   - theme: The overall theme of the story.
    /// - Returns: An optional URL pointing to the generated illustration, or `nil` if generation fails gracefully.
    /// - Throws: `IllustrationError` for configuration, network, or API issues.
    func generateIllustration(for pageText: String, theme: String) async throws -> URL?
}


// Type extensions to make existing services conform to protocols
extension StoryService: StoryServiceProtocol {}
extension SettingsService: SettingsServiceProtocol {}
