import Testing
import Foundation
@testable import magical_stories

@MainActor
struct SettingsServiceTests {
    var settingsService: SettingsService = SettingsService()
    var userDefaults: UserDefaults? = UserDefaults(suiteName: #function)
    
    @Test("Initial settings should have default values")
    func testInitialSettings() {
        // Then
        #expect(settingsService.parentalControls.contentFiltering == true)
        #expect(settingsService.parentalControls.maxStoriesPerDay == 3)
        #expect(settingsService.parentalControls.allowedThemes == Set(StoryTheme.allCases))
        
        #expect(settingsService.appSettings.textToSpeechEnabled == true)
        #expect(settingsService.appSettings.readingSpeed == 1.0)
        #expect(settingsService.appSettings.fontScale == 1.0)
    }
    
    @Test("Updating parental controls should persist changes")
    func testUpdateParentalControls() {
        // Given
        var controls = settingsService.parentalControls
        controls.contentFiltering = false
        controls.maxStoriesPerDay = 5
        
        // When
        settingsService.updateParentalControls(controls)
        
        // Then
        #expect(settingsService.parentalControls.contentFiltering == false)
        #expect(settingsService.parentalControls.maxStoriesPerDay == 5)
    }
    
    @Test("Updating app settings should persist changes")
    func testUpdateAppSettings() {
        // Given
        var settings = settingsService.appSettings
        settings.textToSpeechEnabled = false
        settings.readingSpeed = 1.5
        
        // When
        settingsService.updateAppSettings(settings)
        
        // Then
        #expect(settingsService.appSettings.textToSpeechEnabled == false)
        #expect(settingsService.appSettings.readingSpeed == 1.5)
    }
    
    @Test("Story generation validation should respect parental controls")
    func testStoryGenerationValidation() {
        // Given
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
    func testStoryCountLimit() {
        // Given
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
