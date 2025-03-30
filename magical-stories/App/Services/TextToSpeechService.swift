import AVFoundation
import SwiftUI

// MARK: - Text-to-Speech Service
@MainActor
class TextToSpeechService: NSObject, ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    private let settingsService: SettingsService
    
    @Published private(set) var isPlaying = false
    @Published private(set) var currentWordRange: NSRange?
    
    init(settingsService: SettingsService) {
        self.settingsService = settingsService
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(_ text: String, language: String = "en-US") {
        // Stop any ongoing speech
        stopSpeaking()
        
        // Create utterance
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = Float(settingsService.appSettings.readingSpeed) * AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.1 // Slightly higher pitch for child-friendly voice
        
        // Start speaking
        synthesizer.speak(utterance)
        isPlaying = true
    }
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        currentWordRange = nil
    }
    
    func pauseSpeaking() {
        synthesizer.pauseSpeaking(at: .immediate)
        isPlaying = false
    }
    
    func continueSpeaking() {
        synthesizer.continueSpeaking()
        isPlaying = true
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension TextToSpeechService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        currentWordRange = characterRange
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isPlaying = false
        currentWordRange = nil
        
        if settingsService.appSettings.autoPlayEnabled {
            // Handle auto-play logic if needed
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        isPlaying = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        isPlaying = true
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isPlaying = false
        currentWordRange = nil
    }
}

// MARK: - Text Highlighting View Modifier
struct TextHighlightModifier: ViewModifier {
    let text: String
    let highlightRange: NSRange?
    let highlightColor: Color
    
    func body(content: Content) -> some View {
        if let range = highlightRange {
            let prefix = text.prefix(range.location)
            let startIndex = text.index(text.startIndex, offsetBy: range.location)
            let endIndex = text.index(startIndex, offsetBy: range.length)
            let highlight = text[startIndex..<endIndex]
            let suffix = text.suffix(from: endIndex)
            
            HStack(spacing: 0) {
                Text(prefix)
                Text(highlight)
                    .foregroundColor(highlightColor)
                    .bold()
                Text(suffix)
            }
        } else {
            content
        }
    }
}

extension View {
    func highlightText(_ text: String, range: NSRange?, color: Color = .accentColor) -> some View {
        modifier(TextHighlightModifier(text: text, highlightRange: range, highlightColor: color))
    }
} 
