import SwiftUI
import SwiftData
import Foundation
import GoogleGenerativeAI // Import for GenerativeModel

// Use local Configuration file for API keys
@main
struct MagicalStoriesApp: App {
    // Initialize services using StateObject to maintain their state throughout the app lifetime
    @StateObject private var settingsService: SettingsService
    @StateObject private var storyService: StoryService
    @StateObject private var collectionService: CollectionService // Add CollectionService StateObject
    @StateObject private var persistenceService: PersistenceService // Add PersistenceService StateObject
    
    private let container: ModelContainer
    private let aiErrorManager = AIErrorManager() // AIErrorManager can be a simple instance
    private let generativeModel: GenerativeModelProtocol // Store the AI model instance
    
    // Initialization to handle dependencies between services
    init() {
        // Initialize SwiftData container
        let container = try! ModelContainer.create() // Use a helper if needed
        let context = container.mainContext

        // Initialize AI Model
        self.generativeModel = GenerativeModelWrapper(name: "gemini-1.5-flash", apiKey: AppConfig.geminiApiKey)

        // Initialize Persistence Service (needs context)
        let persistence = PersistenceService(context: context)
        _persistenceService = StateObject(wrappedValue: persistence)

        // Initialize services in dependency order
        let settingsRepository = SettingsRepository(modelContext: context)
        let usageAnalyticsService = UsageAnalyticsService() // Assuming no repo needed now
        let settings = SettingsService(repository: settingsRepository, usageAnalyticsService: usageAnalyticsService)
        
        // StoryService now needs PersistenceService and can take the model
        let story = try! StoryService(
            model: generativeModel, // Pass the shared model
            context: context,
            persistenceService: persistence // Pass the shared persistence service
        )
        
        // CollectionService needs StoryService, PersistenceService, AIErrorManager, and the model
        let collection = CollectionService(
            storyService: story, // Pass the initialized StoryService
            persistenceService: persistence, // Pass the shared persistence service
            aiErrorManager: aiErrorManager, // Pass the AIErrorManager instance
            model: generativeModel // Pass the shared model
        )

        // Assign to StateObjects
        _settingsService = StateObject(wrappedValue: settings)
        _storyService = StateObject(wrappedValue: story)
        _collectionService = StateObject(wrappedValue: collection)

        // Store container for environment injection
        self.container = container
    }
    
    var body: some Scene {
        WindowGroup {
            // Pass all services as environment objects
            RootView()
                .environmentObject(settingsService)
                .environmentObject(storyService)
                .environmentObject(collectionService) // Inject CollectionService
                .environmentObject(persistenceService) // Inject PersistenceService
                // Pass other dependencies if needed directly by views (less common)
                // .environmentObject(aiErrorManager) 
                .modelContainer(container)
        }
    }
}

// Helper extension for container creation (optional)
extension ModelContainer {
    static func create() throws -> ModelContainer {
        // Specify all models used in your app schema
        let schema = Schema([
            StoryModel.self, 
            PageModel.self, 
            AchievementModel.self,
            // Add other @Model classes like UserProfileModel, SettingsModel etc. if they exist
            // GrowthCollection will need a SwiftData @Model version for persistence
            UserProfileModel.self,
            AppSettingsModel.self,
            ParentalControlsModel.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    }
    
    // Optional: Preview container
    @MainActor
    static func preview() throws -> ModelContainer {
        let schema = Schema([
             StoryModel.self, PageModel.self, AchievementModel.self,
             UserProfileModel.self, AppSettingsModel.self, ParentalControlsModel.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true) // In-memory for previews
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        
        // TODO: Populate with sample data if needed for previews
        // let sampleStory = StoryModel.previewExample
        // container.mainContext.insert(sampleStory)
        
        return container
    }
}
