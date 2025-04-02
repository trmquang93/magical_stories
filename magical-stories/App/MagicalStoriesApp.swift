import SwiftUI
import SwiftData

// Import for API keys
import Foundation

@main
struct MagicalStoriesApp: App {
    // Initialize services using StateObject to maintain their state throughout the app lifetime
    @StateObject private var settingsService: SettingsService
    @StateObject private var storyService: StoryService
    @StateObject private var textToSpeechService: TextToSpeechService
    
    // Initialization to handle dependencies between services
    init() {
        // Initialize services in dependency order
        let settings = SettingsService()
        let story = StoryService(apiKey: Configuration.geminiApiKey)
        let tts = TextToSpeechService(settingsService: settings)
        
        // Assign to StateObjects
        _settingsService = StateObject(wrappedValue: settings)
        _storyService = StateObject(wrappedValue: story)
        _textToSpeechService = StateObject(wrappedValue: tts)
    }
    
    var body: some Scene {
        WindowGroup {
            // Pass all services as environment objects to make them available throughout the view hierarchy
            RootView()
                .environmentObject(settingsService)
                .environmentObject(storyService)
                .environmentObject(textToSpeechService)
        }
    }
}
