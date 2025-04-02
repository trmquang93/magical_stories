import SwiftUI
import SwiftData

@main
struct MagicalStoriesApp: App {
    // Initialize services using StateObject to maintain their state throughout the app lifetime
    @StateObject private var storyService = StoryService()
    @StateObject private var settingsService = SettingsService()
    @StateObject private var textToSpeechService: TextToSpeechService
    
    // Initialization to handle dependencies between services
    init() {
        // Need to initialize settingsService first since TextToSpeechService depends on it
        let settingsService = SettingsService()
        // Create TextToSpeechService with its dependency
        let textToSpeechService = TextToSpeechService(settingsService: settingsService)
        // Assign to StateObjects
        self._settingsService = StateObject(wrappedValue: settingsService)
        self._textToSpeechService = StateObject(wrappedValue: textToSpeechService)
    }
    
    var body: some Scene {
        WindowGroup {
            // Pass all services as environment objects to make them available throughout the view hierarchy
            RootView()
                .environmentObject(storyService)
                .environmentObject(settingsService)
                .environmentObject(textToSpeechService)
        }
    }
}
