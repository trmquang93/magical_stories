import Testing
@testable import magical_stories
import Foundation

@Suite
struct PromptBuilderGlobalReferenceTests {
    
    @Test("buildGlobalReferenceImagePromptShouldIncludeStoryTitle")
    func testBuildGlobalReferenceImagePromptIncludesStoryTitle() {
        // Arrange
        let promptBuilder = PromptBuilder()
        let storyTitle = "The Dragon's Adventure"
        let visualGuide = VisualGuide(
            styleGuide: "Watercolor style",
            characterDefinitions: ["Dragon": "Red dragon with blue eyes"],
            settingDefinitions: ["Castle": "Medieval castle on a hill"]
        )
        
        // Act
        let prompt = promptBuilder.buildGlobalReferenceImagePrompt(visualGuide: visualGuide, storyTitle: storyTitle)
        
        // Assert
        #expect(prompt.contains("The Dragon's Adventure"))
    }
    
    @Test("buildGlobalReferenceImagePromptShouldIncludeVisualGuideInformation")
    func testBuildGlobalReferenceImagePromptIncludesVisualGuide() {
        // Arrange
        let promptBuilder = PromptBuilder()
        let storyTitle = "The Dragon's Adventure"
        let styleGuide = "Colorful watercolor style with soft edges"
        let characterDefinitions = [
            "Dragon": "Red dragon with blue eyes and small wings",
            "Knight": "Brave knight in silver armor with a shield"
        ]
        let settingDefinitions = [
            "Castle": "Medieval castle on a hill with tall towers",
            "Forest": "Dense forest with tall pine trees and a winding path"
        ]
        
        let visualGuide = VisualGuide(
            styleGuide: styleGuide,
            characterDefinitions: characterDefinitions,
            settingDefinitions: settingDefinitions
        )
        
        // Act
        let prompt = promptBuilder.buildGlobalReferenceImagePrompt(visualGuide: visualGuide, storyTitle: storyTitle)
        
        // Assert
        #expect(prompt.contains(styleGuide))
        
        // Check each character definition is included
        for (name, description) in characterDefinitions {
            #expect(prompt.contains(name))
            #expect(prompt.contains(description))
        }
        
        // Check each setting definition is included
        for (name, description) in settingDefinitions {
            #expect(prompt.contains(name))
            #expect(prompt.contains(description))
        }
    }
    
    @Test("buildGlobalReferenceImagePromptShouldIncludeCriticalRequirements")
    func testBuildGlobalReferenceImagePromptIncludesCriticalRequirements() {
        // Arrange
        let promptBuilder = PromptBuilder()
        let storyTitle = "The Dragon's Adventure"
        let visualGuide = VisualGuide(
            styleGuide: "Watercolor style",
            characterDefinitions: ["Dragon": "Red dragon with blue eyes"],
            settingDefinitions: ["Castle": "Medieval castle on a hill"]
        )
        
        // Act
        let prompt = promptBuilder.buildGlobalReferenceImagePrompt(visualGuide: visualGuide, storyTitle: storyTitle)
        
        // Assert
        // Check that the prompt includes the critical requirements for a global reference image
        #expect(prompt.contains("reference sheet"))
        #expect(prompt.contains("all characters"))
        #expect(prompt.contains("key story elements"))
        #expect(prompt.contains("lineup") || prompt.contains("group arrangement"))
        #expect(prompt.contains("full body"))
        #expect(prompt.contains("NO text") || prompt.contains("label-free"))
        #expect(prompt.contains("16:9"))
    }
    
    @Test("buildGlobalReferenceImagePromptShouldHandleEmptyDefinitionsGracefully")
    func testBuildGlobalReferenceImagePromptHandlesEmptyDefinitions() {
        // Arrange
        let promptBuilder = PromptBuilder()
        let storyTitle = "The Dragon's Adventure"
        let visualGuide = VisualGuide(
            styleGuide: "Watercolor style",
            characterDefinitions: [:],
            settingDefinitions: [:]
        )
        
        // Act
        let prompt = promptBuilder.buildGlobalReferenceImagePrompt(visualGuide: visualGuide, storyTitle: storyTitle)
        
        // Assert
        // Should not throw any errors and should still contain essential parts
        #expect(prompt.contains("reference sheet"))
        #expect(prompt.contains("Watercolor style"))
        #expect(prompt.contains("The Dragon's Adventure"))
    }
}