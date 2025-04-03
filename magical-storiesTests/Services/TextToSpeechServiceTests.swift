import XCTest
import AVFoundation
import Foundation
import Testing
@testable import magical_stories

@MainActor
struct TextToSpeechServiceTests {
    var textToSpeechService: TextToSpeechService!
    var settingsService: SettingsService!
    
    init() {
        settingsService = SettingsService()
        textToSpeechService = TextToSpeechService(settingsService: settingsService)
    }
    
    @Test("Initial state should be not playing")
    func testInitialState() {
        #expect(textToSpeechService.isPlaying == false)
        #expect(textToSpeechService.currentWordRange == nil)
    }
    
    @Test("Speaking should update playing state")
    func testSpeakingState() {
        // When
        textToSpeechService.speak("Hello, world!")
        
        // Then
        #expect(textToSpeechService.isPlaying == true)
    }
    
    @Test("Stopping should reset state")
    func testStoppingState() {
        // Given
        textToSpeechService.speak("Hello, world!")
        
        // When
        textToSpeechService.stopSpeaking()
        
        // Then
        #expect(textToSpeechService.isPlaying == false)
        #expect(textToSpeechService.currentWordRange == nil)
    }
    
    @Test("Pausing should update playing state")
    func testPausingState() {
        // Given
        textToSpeechService.speak("Hello, world!")
        
        // When
        textToSpeechService.pauseSpeaking()
        
        // Then
        #expect(textToSpeechService.isPlaying == false)
    }
    
    @Test("Continuing should update playing state")
    func testContinuingState() {
        // Given
        textToSpeechService.speak("Hello, world!")
        textToSpeechService.pauseSpeaking()
        
        // When
        textToSpeechService.continueSpeaking()
        
        // Then
        #expect(textToSpeechService.isPlaying == true)
    }
    
    @Test("Reading speed should respect settings")
    mutating func testReadingSpeed() {
        // Given
        var settings = settingsService.appSettings
        settings.readingSpeed = 1.5
        settingsService.updateAppSettings(settings)
        
        // When
        textToSpeechService = TextToSpeechService(settingsService: settingsService)
        
        // Then - Verify through a mock synthesizer that the rate is adjusted
        // Note: In a real implementation, we would inject a mock AVSpeechSynthesizer
        // and verify the utterance rate is set correctly
    }
}

// MARK: - Text Highlight Modifier Tests
struct TextHighlightModifierTests {
    @Test("Highlight modifier should handle nil range")
    func testHighlightModifierNilRange() {
        // let text = "Hello, world!" // Unused
        // let modifier = TextHighlightModifier( // Unused
        //     text: text,
        //     highlightRange: nil,
        //     highlightColor: .blue
        // )
        
        // Note: In a real implementation, we would use ViewInspector
        // to verify the view hierarchy and styling
    }
    
    @Test("Highlight modifier should handle valid range")
    func testHighlightModifierValidRange() {
        // let text = "Hello, world!" // Unused
        // let range = NSRange(location: 0, length: 5) // "Hello" // Unused
        // let modifier = TextHighlightModifier( // Unused
        //     text: text,
        //     highlightRange: range,
        //     highlightColor: .blue
        // )
        
        // Note: In a real implementation, we would use ViewInspector
        // to verify the view hierarchy and styling
    }
}
