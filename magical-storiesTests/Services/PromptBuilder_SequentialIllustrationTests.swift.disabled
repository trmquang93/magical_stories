import Foundation
import Testing
@testable import magical_stories

@Suite
struct PromptBuilderSequentialIllustrationTests {
    
    @Test("buildSequentialIllustrationPromptShouldIncludePageContent")
    func testBuildSequentialIllustrationPromptIncludesPageContent() {
        // Arrange
        let promptBuilder = PromptBuilder()
        let pageContent = "The dragon flew over the castle."
        let page = Page(content: pageContent, pageNumber: 1)
        let visualGuide = VisualGuide(
            styleGuide: "Watercolor style",
            characterDefinitions: ["Dragon": "Red dragon with blue eyes"],
            settingDefinitions: ["Castle": "Medieval castle on a hill"]
        )
        
        // Act
        let prompt = promptBuilder.buildSequentialIllustrationPrompt(
            page: page,
            pageIndex: 1,
            visualGuide: visualGuide
        )
        
        // Assert
        #expect(prompt.contains(pageContent))
    }
    
    @Test("buildSequentialIllustrationPromptShouldIncludeVisualGuideInformation")
    func testBuildSequentialIllustrationPromptIncludesVisualGuide() {
        // Arrange
        let promptBuilder = PromptBuilder()
        let page = Page(content: "The dragon flew over the castle.", pageNumber: 1)
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
        let prompt = promptBuilder.buildSequentialIllustrationPrompt(
            page: page,
            pageIndex: 1,
            visualGuide: visualGuide
        )
        
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
    
    @Test("buildSequentialIllustrationPromptShouldIncludeGlobalReferenceImageWhenProvided")
    func testBuildSequentialIllustrationPromptIncludesGlobalReference() {
        // Arrange
        let promptBuilder = PromptBuilder()
        let page = Page(content: "The dragon flew over the castle.", pageNumber: 1)
        let visualGuide = VisualGuide(
            styleGuide: "Watercolor style",
            characterDefinitions: ["Dragon": "Red dragon with blue eyes"],
            settingDefinitions: ["Castle": "Medieval castle on a hill"]
        )
        let globalReferenceImageBase64 = "base64encodedglobalimage"
        
        // Act
        let prompt = promptBuilder.buildSequentialIllustrationPrompt(
            page: page,
            pageIndex: 1,
            visualGuide: visualGuide,
            globalReferenceImageBase64: globalReferenceImageBase64
        )
        
        // Assert
        #expect(prompt.contains("GLOBAL REFERENCE IMAGE"))
        #expect(prompt.contains(globalReferenceImageBase64))
    }
    
    @Test("buildSequentialIllustrationPromptShouldIncludePreviousIllustrationWhenProvided")
    func testBuildSequentialIllustrationPromptIncludesPreviousIllustration() {
        // Arrange
        let promptBuilder = PromptBuilder()
        let page = Page(content: "The dragon flew over the castle.", pageNumber: 1)
        let visualGuide = VisualGuide(
            styleGuide: "Watercolor style",
            characterDefinitions: ["Dragon": "Red dragon with blue eyes"],
            settingDefinitions: ["Castle": "Medieval castle on a hill"]
        )
        let previousIllustrationBase64 = "base64encodedpreviousimage"
        
        // Act
        let prompt = promptBuilder.buildSequentialIllustrationPrompt(
            page: page,
            pageIndex: 1,
            visualGuide: visualGuide,
            previousIllustrationBase64: previousIllustrationBase64
        )
        
        // Assert
        #expect(prompt.contains("PREVIOUS PAGE ILLUSTRATION"))
        #expect(prompt.contains(previousIllustrationBase64))
    }
    
    @Test("buildSequentialIllustrationPromptShouldIncludeBothReferencesWhenProvided")
    func testBuildSequentialIllustrationPromptIncludesBothReferences() {
        // Arrange
        let promptBuilder = PromptBuilder()
        let page = Page(content: "The dragon flew over the castle.", pageNumber: 1)
        let visualGuide = VisualGuide(
            styleGuide: "Watercolor style",
            characterDefinitions: ["Dragon": "Red dragon with blue eyes"],
            settingDefinitions: ["Castle": "Medieval castle on a hill"]
        )
        let globalReferenceImageBase64 = "base64encodedglobalimage"
        let previousIllustrationBase64 = "base64encodedpreviousimage"
        
        // Act
        let prompt = promptBuilder.buildSequentialIllustrationPrompt(
            page: page,
            pageIndex: 1,
            visualGuide: visualGuide,
            globalReferenceImageBase64: globalReferenceImageBase64,
            previousIllustrationBase64: previousIllustrationBase64
        )
        
        // Assert
        #expect(prompt.contains("GLOBAL REFERENCE IMAGE"))
        #expect(prompt.contains(globalReferenceImageBase64))
        #expect(prompt.contains("PREVIOUS PAGE ILLUSTRATION"))
        #expect(prompt.contains(previousIllustrationBase64))
    }
    
    @Test("buildSequentialIllustrationPromptShouldIncludeCriticalRequirementsForTextFreeIllustrations")
    func testBuildSequentialIllustrationPromptIncludesCriticalRequirements() {
        // Arrange
        let promptBuilder = PromptBuilder()
        let page = Page(content: "The dragon flew over the castle.", pageNumber: 1)
        let visualGuide = VisualGuide(
            styleGuide: "Watercolor style",
            characterDefinitions: ["Dragon": "Red dragon with blue eyes"],
            settingDefinitions: ["Castle": "Medieval castle on a hill"]
        )
        
        // Act
        let prompt = promptBuilder.buildSequentialIllustrationPrompt(
            page: page,
            pageIndex: 1,
            visualGuide: visualGuide
        )
        
        // Assert
        #expect(prompt.contains("CRITICAL REQUIREMENTS") || prompt.contains("IMPORTANT"))
        #expect(prompt.contains("NO text") || prompt.contains("text-free") || prompt.contains("DO NOT include any text"))
        #expect(prompt.contains("16:9"))
        #expect(prompt.contains("landscape"))
    }
    
    @Test("buildSequentialIllustrationPromptShouldHandleFirstPageWithoutPreviousIllustration")
    func testBuildSequentialIllustrationPromptHandlesFirstPage() {
        // Arrange
        let promptBuilder = PromptBuilder()
        let page = Page(content: "Once upon a time, there was a dragon.", pageNumber: 0)
        let visualGuide = VisualGuide(
            styleGuide: "Watercolor style",
            characterDefinitions: ["Dragon": "Red dragon with blue eyes"],
            settingDefinitions: ["Castle": "Medieval castle on a hill"]
        )
        
        // Act
        let prompt = promptBuilder.buildSequentialIllustrationPrompt(
            page: page,
            pageIndex: 0,  // First page
            visualGuide: visualGuide
        )
        
        // Assert
        #expect(prompt.contains("Once upon a time"))
        #expect(!prompt.contains("PREVIOUS PAGE ILLUSTRATION"))
    }
}