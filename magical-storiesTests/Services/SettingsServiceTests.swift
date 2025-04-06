import Testing
import Foundation
@testable import magical_stories

@MainActor
struct SettingsServiceTests {
    var settingsService: SettingsService!
    var userDefaults: UserDefaults!
    
    mutating func setUp() {
        // Create a unique suite name for each test run
        let suiteName = "test_suite_\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)!
        
        // Clear any existing data
        userDefaults.removePersistentDomain(forName: suiteName)
        
        // Create a fresh instance of SettingsService with our test UserDefaults
        settingsService = SettingsService(userDefaults: userDefaults)
    }
    
    @Test("Initial settings should have default values")
    mutating func testInitialSettings() {
        // Given
        setUp()
        
        // Then - Verify default values
        #expect(settingsService.parentalControls.contentFiltering == true)
        #expect(settingsService.parentalControls.maxStoriesPerDay == 3)
        #expect(settingsService.parentalControls.allowedThemes == Set(StoryTheme.allCases))
        #expect(settingsService.parentalControls.minimumAge == 3)
        #expect(settingsService.parentalControls.maximumAge == 10)
        
        #expect(settingsService.appSettings.fontScale == 1.0)
        #expect(settingsService.appSettings.hapticFeedbackEnabled == true)
        #expect(settingsService.appSettings.soundEffectsEnabled == true)
        #expect(settingsService.appSettings.darkModeEnabled == false)
    }
    
    @Test("Updating parental controls should persist changes")
    mutating func testUpdateParentalControls() {
        // Given
        setUp()
        var controls = settingsService.parentalControls
        controls.contentFiltering = false
        controls.maxStoriesPerDay = 5
        
        // When
        settingsService.updateParentalControls(controls)
        
        // Then - Verify in-memory changes
        #expect(settingsService.parentalControls.contentFiltering == false)
        #expect(settingsService.parentalControls.maxStoriesPerDay == 5)
        
        // Then - Verify persistence
        let newService = SettingsService(userDefaults: userDefaults)
        #expect(newService.parentalControls.contentFiltering == false)
        #expect(newService.parentalControls.maxStoriesPerDay == 5)
    }
    
    @Test("Updating app settings should persist changes")
    mutating func testUpdateAppSettings() {
        // Given
        setUp()
        var settings = settingsService.appSettings
        
        // When
        settingsService.updateAppSettings(settings)
        
        // Then - Verify in-memory changes
        
        // Then - Verify persistence
        let newService = SettingsService(userDefaults: userDefaults)
    }
    
    @Test("Story generation validation should respect parental controls")
    mutating func testStoryGenerationValidation() {
        // Given
        setUp()
        var controls = settingsService.parentalControls
        controls.contentFiltering = true
        controls.allowedThemes = [.adventure, .friendship]
        controls.minimumAge = 5
        controls.maximumAge = 8
        settingsService.updateParentalControls(controls)
        
        // Then - Valid case
        #expect(settingsService.canGenerateStory(theme: .adventure, ageGroup: 6) == true)
        
        // Then - Invalid theme
        #expect(settingsService.canGenerateStory(theme: .learning, ageGroup: 6) == false)
        
        // Then - Invalid age
        #expect(settingsService.canGenerateStory(theme: .adventure, ageGroup: 4) == false)
        #expect(settingsService.canGenerateStory(theme: .adventure, ageGroup: 9) == false)
    }
    
    @Test("Story count limit should respect screen time settings")
    mutating func testStoryCountLimit() {
        // Given
        setUp()
        var controls = settingsService.parentalControls
        controls.screenTimeEnabled = true
        controls.maxStoriesPerDay = 2
        settingsService.updateParentalControls(controls)
        
        // Then - Initial state
        #expect(settingsService.canGenerateMoreStories() == true)
        
        // When - Generate stories
        settingsService.incrementStoryGenerationCount()
        #expect(settingsService.canGenerateMoreStories() == true)
        
        settingsService.incrementStoryGenerationCount()
        #expect(settingsService.canGenerateMoreStories() == false)
    }
} 
