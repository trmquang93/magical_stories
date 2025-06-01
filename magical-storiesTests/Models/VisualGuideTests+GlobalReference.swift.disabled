import Testing
@testable import magical_stories
import Foundation

@Suite
struct VisualGuideGlobalReferenceTests {
    
    @Test("visualGuideInitializationWithGlobalReferenceImageURLShouldStoreTheURLCorrectly")
    func testVisualGuideWithGlobalReferenceURL() {
        // Arrange
        let styleGuide = "Colorful watercolor style"
        let characterDefinitions = ["Hero": "Tall with blue eyes"]
        let settingDefinitions = ["Castle": "Stone fortress"]
        let globalReferenceImageURL = URL(string: "file:///path/to/global/reference.png")!
        
        // Act
        let visualGuide = VisualGuide(
            styleGuide: styleGuide,
            characterDefinitions: characterDefinitions,
            settingDefinitions: settingDefinitions,
            globalReferenceImageURL: globalReferenceImageURL
        )
        
        // Assert
        #expect(visualGuide.styleGuide == styleGuide)
        #expect(visualGuide.characterDefinitions == characterDefinitions)
        #expect(visualGuide.settingDefinitions == settingDefinitions)
        #expect(visualGuide.globalReferenceImageURL == globalReferenceImageURL)
    }
    
    @Test("visualGuideInitializationWithoutGlobalReferenceImageURLShouldSetItToNil")
    func testVisualGuideWithoutGlobalReferenceURL() {
        // Arrange
        let styleGuide = "Colorful watercolor style"
        let characterDefinitions = ["Hero": "Tall with blue eyes"]
        let settingDefinitions = ["Castle": "Stone fortress"]
        
        // Act
        let visualGuide = VisualGuide(
            styleGuide: styleGuide,
            characterDefinitions: characterDefinitions,
            settingDefinitions: settingDefinitions
        )
        
        // Assert
        #expect(visualGuide.globalReferenceImageURL == nil)
    }
    
    @Test("visualGuideShouldBeUpdatableWithAGlobalReferenceImageURL")
    func testVisualGuideUpdateWithGlobalReferenceURL() {
        // Arrange
        let styleGuide = "Colorful watercolor style"
        let characterDefinitions = ["Hero": "Tall with blue eyes"]
        let settingDefinitions = ["Castle": "Stone fortress"]
        
        let originalVisualGuide = VisualGuide(
            styleGuide: styleGuide,
            characterDefinitions: characterDefinitions,
            settingDefinitions: settingDefinitions
        )
        
        let globalReferenceImageURL = URL(string: "file:///path/to/global/reference.png")!
        
        // Act
        let updatedVisualGuide = originalVisualGuide.withGlobalReferenceImageURL(globalReferenceImageURL)
        
        // Assert
        #expect(updatedVisualGuide.styleGuide == styleGuide)
        #expect(updatedVisualGuide.characterDefinitions == characterDefinitions)
        #expect(updatedVisualGuide.settingDefinitions == settingDefinitions)
        #expect(updatedVisualGuide.globalReferenceImageURL == globalReferenceImageURL)
        #expect(originalVisualGuide.globalReferenceImageURL == nil) // Original should be unchanged
    }
}