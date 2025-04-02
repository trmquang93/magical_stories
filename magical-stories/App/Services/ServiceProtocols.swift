import SwiftUI
import SwiftData
import AVFoundation

// MARK: - Service Protocols

// Protocol for StoryService
@MainActor protocol StoryServiceProtocol: ObservableObject {
    var stories: [Story] { get }
    var isGenerating: Bool { get }
    
    func generateStory(parameters: StoryParameters) async throws -> Story
    func loadStories() async
}

// Protocol for SettingsService
@MainActor protocol SettingsServiceProtocol: ObservableObject {
    var parentalControls: ParentalControls { get }
    var appSettings: AppSettings { get }
    
    func updateParentalControls(_ controls: ParentalControls)
    func updateAppSettings(_ settings: AppSettings)
    
    func toggleTextToSpeech()
    func updateReadingSpeed(_ speed: Double)
}

// Protocol for TextToSpeechService
@MainActor protocol TextToSpeechServiceProtocol: ObservableObject {
    var isPlaying: Bool { get }
    var currentWordRange: NSRange? { get }
    
    func speak(_ text: String, language: String)
    func stopSpeaking()
    func pauseSpeaking()
    func continueSpeaking()
}

// Type extensions to make existing services conform to protocols
extension StoryService: StoryServiceProtocol {}
extension SettingsService: SettingsServiceProtocol {}
extension TextToSpeechService: TextToSpeechServiceProtocol {}