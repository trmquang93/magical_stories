import Testing
import Foundation
@testable import magical_stories

@Suite("Visual Consistency Validation - Quick Tests")
@MainActor
struct VisualConsistencyValidation {
    
    // MARK: - Basic Functionality Tests
    
    @Test("PromptBuilder Enhanced Methods Exist")
    func testEnhancedMethodsExist() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let visualGuide = VisualGuide(
            styleGuide: "Test style",
            characterDefinitions: ["Test": "Character"],
            settingDefinitions: [:]
        )
        
        // When & Then - These should compile and run without error
        let globalPrompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: visualGuide,
            storyStructure: nil,
            storyTitle: "Test",
            collectionContext: nil
        )
        
        let page = Page(content: "Test", pageNumber: 1)
        let sequentialPrompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 0,
            storyStructure: nil,
            visualGuide: visualGuide,
            globalReferenceImageBase64: nil,
            previousIllustrationBase64: nil,
            collectionContext: nil
        )
        
        // Basic validation
        #expect(!globalPrompt.isEmpty)
        #expect(!sequentialPrompt.isEmpty)
        #expect(globalPrompt.contains("Test"))
        #expect(sequentialPrompt.contains("Test"))
    }
    
    @Test("Collection Visual Context Creation")
    func testCollectionVisualContextCreation() async throws {
        // Given & When
        let context = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Test Theme",
            sharedCharacters: ["Hero"],
            unifiedArtStyle: "Test Style",
            developmentalFocus: "Test Focus",
            ageGroup: "5-7"
        )
        
        // Then
        #expect(context.collectionTheme == "Test Theme")
        #expect(context.sharedCharacters == ["Hero"])
        #expect(context.unifiedArtStyle == "Test Style")
        #expect(context.developmentalFocus == "Test Focus")
        #expect(context.ageGroup == "5-7")
        #expect(context.requiresCharacterConsistency == true) // Default value
        #expect(context.allowsStyleVariation == false) // Default value
    }
    
    @Test("Story Structure Creation")
    func testStoryStructureCreation() async throws {
        // Given & When
        let page1 = PageVisualPlan(
            pageNumber: 1,
            characters: ["Hero"],
            settings: ["Forest"],
            props: ["Sword"],
            visualFocus: "Introduction",
            emotionalTone: "Brave"
        )
        let structure = StoryStructure(pages: [page1])
        
        // Then
        #expect(structure.pages.count == 1)
        #expect(structure.pages[0].pageNumber == 1)
        #expect(structure.pages[0].characters == ["Hero"])
        #expect(structure.pages[0].settings == ["Forest"])
        #expect(structure.pages[0].props == ["Sword"])
    }
    
    @Test("PromptBuilder Collection Integration")
    func testPromptBuilderCollectionIntegration() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let parameters = StoryParameters(
            theme: "Adventure",
            childAge: 6,
            childName: "Test"
        )
        let collectionContext = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Adventure Collection",
            sharedCharacters: ["Hero"],
            unifiedArtStyle: "Cartoon style",
            developmentalFocus: "Courage",
            ageGroup: "5-7"
        )
        
        // When
        let prompt = promptBuilder.buildPrompt(
            parameters: parameters,
            collectionContext: collectionContext
        )
        
        // Then
        #expect(prompt.contains("Adventure"))
        #expect(prompt.contains("Test"))
        #expect(prompt.contains("Adventure Collection"))
        #expect(prompt.contains("Hero"))
        #expect(prompt.contains("Cartoon style"))
        #expect(prompt.contains("Courage"))
        #expect(prompt.contains("<collection_context>"))
    }
    
    @Test("Enhanced Global Reference Basic Content")
    func testEnhancedGlobalReferenceBasicContent() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let visualGuide = VisualGuide(
            styleGuide: "Watercolor style",
            characterDefinitions: ["Alice": "Young girl with blonde hair"],
            settingDefinitions: ["Garden": "Beautiful flower garden"]
        )
        let storyTitle = "Alice's Garden Adventure"
        
        // When
        let prompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: visualGuide,
            storyStructure: nil,
            storyTitle: storyTitle,
            collectionContext: nil
        )
        
        // Then
        #expect(prompt.contains("COMPREHENSIVE CHARACTER REFERENCE SHEET"))
        #expect(prompt.contains("Alice's Garden Adventure"))
        #expect(prompt.contains("CHARACTER LINEUP"))
        #expect(prompt.contains("KEY EXPRESSIONS"))
        #expect(prompt.contains("PROPS AND SETTINGS"))
        #expect(prompt.contains("Watercolor style"))
        #expect(prompt.contains("Alice"))
        #expect(prompt.contains("Garden"))
        #expect(prompt.contains("NO TEXT OR LABELS"))
    }
    
    @Test("Enhanced Sequential Illustration Basic Content")
    func testEnhancedSequentialIllustrationBasicContent() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let page = Page(content: "Alice walked through the beautiful garden, admiring the colorful flowers.", pageNumber: 1)
        let visualGuide = VisualGuide(
            styleGuide: "Watercolor garden scenes",
            characterDefinitions: ["Alice": "Young adventurer"],
            settingDefinitions: [:]
        )
        
        // When
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 0,
            storyStructure: nil,
            visualGuide: visualGuide,
            globalReferenceImageBase64: nil,
            previousIllustrationBase64: nil,
            collectionContext: nil
        )
        
        // Then
        #expect(prompt.contains("Generate illustration for page 1"))
        #expect(prompt.contains("Alice walked through the beautiful garden"))
        #expect(prompt.contains("VISUAL GUIDE SPECIFICATIONS"))
        #expect(prompt.contains("CONSISTENCY REQUIREMENTS"))
        #expect(prompt.contains("Watercolor garden scenes"))
        #expect(prompt.contains("Alice"))
        #expect(prompt.contains("NO TEXT in illustration"))
    }
    
    @Test("Backward Compatibility - Legacy Methods Work")
    func testBackwardCompatibility() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let visualGuide = VisualGuide(
            styleGuide: "Classic style",
            characterDefinitions: ["Hero": "Main character"],
            settingDefinitions: [:]
        )
        let page = Page(content: "Legacy test", pageNumber: 1)
        
        // When - Use legacy methods
        let legacyGlobal = promptBuilder.buildGlobalReferenceImagePrompt(
            visualGuide: visualGuide,
            storyTitle: "Legacy Story"
        )
        
        let legacySequential = promptBuilder.buildSequentialIllustrationPrompt(
            page: page,
            pageIndex: 0,
            visualGuide: visualGuide,
            globalReferenceImageBase64: nil,
            previousIllustrationBase64: nil
        )
        
        // Then
        #expect(!legacyGlobal.isEmpty)
        #expect(!legacySequential.isEmpty)
        #expect(legacyGlobal.contains("Legacy Story"))
        #expect(legacySequential.contains("Legacy test"))
    }
    
    @Test("Error Handling - Empty Inputs")
    func testErrorHandlingEmptyInputs() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let emptyVisualGuide = VisualGuide(
            styleGuide: "",
            characterDefinitions: [:],
            settingDefinitions: [:]
        )
        let emptyPage = Page(content: "", pageNumber: 1)
        
        // When & Then - Should not crash
        let globalPrompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: emptyVisualGuide,
            storyStructure: nil,
            storyTitle: "",
            collectionContext: nil
        )
        
        let sequentialPrompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: emptyPage,
            pageIndex: 0,
            storyStructure: nil,
            visualGuide: emptyVisualGuide,
            globalReferenceImageBase64: nil,
            previousIllustrationBase64: nil,
            collectionContext: nil
        )
        
        // Should handle gracefully
        #expect(!globalPrompt.isEmpty)
        #expect(!sequentialPrompt.isEmpty)
    }
}