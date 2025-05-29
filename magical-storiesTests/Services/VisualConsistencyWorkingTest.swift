import Testing
import Foundation
import SwiftData
@testable import magical_stories

@Suite("Visual Consistency Working Tests")
@MainActor
struct VisualConsistencyWorkingTest {
    
    @Test("Enhanced PromptBuilder methods exist and work")
    func testEnhancedPromptBuilderMethodsWork() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let visualGuide = VisualGuide(
            styleGuide: "Test watercolor style",
            characterDefinitions: ["Hero": "A brave character with red cape"],
            settingDefinitions: ["Castle": "A magical stone castle"]
        )
        
        // When - Test enhanced global reference method
        let globalPrompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: visualGuide,
            storyStructure: nil,
            storyTitle: "Test Adventure",
            collectionContext: nil
        )
        
        // Then - Verify enhanced content
        #expect(globalPrompt.contains("COMPREHENSIVE CHARACTER REFERENCE SHEET"))
        #expect(globalPrompt.contains("Test Adventure"))
        #expect(globalPrompt.contains("CHARACTER LINEUP"))
        #expect(globalPrompt.contains("Test watercolor style"))
        #expect(globalPrompt.contains("Hero"))
        #expect(globalPrompt.contains("Castle"))
        #expect(globalPrompt.contains("NO TEXT OR LABELS"))
    }
    
    @Test("Enhanced sequential illustration method works")
    func testEnhancedSequentialIllustrationWorks() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let page = Page(content: "The hero explored the magical castle.", pageNumber: 1)
        let visualGuide = VisualGuide(
            styleGuide: "Fairy tale illustration",
            characterDefinitions: ["Hero": "Main character"],
            settingDefinitions: ["Castle": "Stone fortress"]
        )
        
        // When - Test enhanced sequential method
        let sequentialPrompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 0,
            storyStructure: nil,
            visualGuide: visualGuide,
            globalReferenceImageBase64: nil,
            previousIllustrationBase64: nil,
            collectionContext: nil
        )
        
        // Then - Verify enhanced content
        #expect(sequentialPrompt.contains("Generate illustration for page 1"))
        #expect(sequentialPrompt.contains("The hero explored the magical castle"))
        #expect(sequentialPrompt.contains("VISUAL GUIDE SPECIFICATIONS"))
        #expect(sequentialPrompt.contains("CONSISTENCY REQUIREMENTS"))
        #expect(sequentialPrompt.contains("Fairy tale illustration"))
        #expect(sequentialPrompt.contains("NO TEXT in illustration"))
    }
    
    @Test("Collection visual context data model works")
    func testCollectionVisualContextWorks() async throws {
        // Given
        let collectionId = UUID()
        
        // When
        let context = CollectionVisualContext(
            collectionId: collectionId,
            collectionTheme: "Ocean Adventure",
            sharedCharacters: ["Captain", "Dolphin"],
            unifiedArtStyle: "Watercolor ocean style",
            developmentalFocus: "Environmental Awareness",
            ageGroup: "5-7"
        )
        
        // Then
        #expect(context.collectionId == collectionId)
        #expect(context.collectionTheme == "Ocean Adventure")
        #expect(context.sharedCharacters == ["Captain", "Dolphin"])
        #expect(context.unifiedArtStyle == "Watercolor ocean style")
        #expect(context.developmentalFocus == "Environmental Awareness")
        #expect(context.ageGroup == "5-7")
        #expect(context.requiresCharacterConsistency == true)  // Default value
        #expect(context.allowsStyleVariation == false)  // Default value
        
        // Test Codable compliance
        let encoder = JSONEncoder()
        let data = try encoder.encode(context)
        let decoder = JSONDecoder()
        let decodedContext = try decoder.decode(CollectionVisualContext.self, from: data)
        
        #expect(decodedContext == context)
    }
    
    @Test("Story structure data model works")
    func testStoryStructureWorks() async throws {
        // Given
        let pages = [
            PageVisualPlan(
                pageNumber: 1,
                characters: ["Hero", "Guide"],
                settings: ["Forest"],
                props: ["sword", "map"],
                visualFocus: "Journey begins",
                emotionalTone: "Excited"
            ),
            PageVisualPlan(
                pageNumber: 2,
                characters: ["Hero"],
                settings: ["Mountain"],
                props: ["sword"],
                visualFocus: "Climbing challenge",
                emotionalTone: "Determined"
            )
        ]
        
        // When
        let storyStructure = StoryStructure(pages: pages)
        
        // Then
        #expect(storyStructure.pages.count == 2)
        #expect(storyStructure.pages[0].pageNumber == 1)
        #expect(storyStructure.pages[0].characters == ["Hero", "Guide"])
        #expect(storyStructure.pages[1].pageNumber == 2)
        #expect(storyStructure.pages[1].characters == ["Hero"])
        
        // Test Codable compliance
        let encoder = JSONEncoder()
        let data = try encoder.encode(storyStructure)
        let decoder = JSONDecoder()
        let decodedStructure = try decoder.decode(StoryStructure.self, from: data)
        
        #expect(decodedStructure == storyStructure)
    }
    
    @Test("PromptBuilder with collection context integration")
    func testPromptBuilderWithCollectionContext() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let parameters = StoryParameters(
            theme: "Space Adventure",
            childAge: 6,
            childName: "Alex"
        )
        let collectionContext = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Space Explorer Collection",
            sharedCharacters: ["Alex", "Robot Buddy"],
            unifiedArtStyle: "Sci-fi cartoon style",
            developmentalFocus: "STEM Learning",
            ageGroup: "5-7"
        )
        
        // When
        let prompt = promptBuilder.buildPrompt(
            parameters: parameters,
            collectionContext: collectionContext
        )
        
        // Then
        #expect(prompt.contains("Space Adventure"))
        #expect(prompt.contains("Alex"))
        #expect(prompt.contains("COLLECTION CONSISTENCY REQUIREMENTS"))
        #expect(prompt.contains("Space Explorer Collection"))
        #expect(prompt.contains("Alex, Robot Buddy"))
        #expect(prompt.contains("STEM Learning"))
        #expect(prompt.contains("5-7"))
        #expect(prompt.contains("<collection_context>"))
        #expect(prompt.contains("<collection_theme>Space Explorer Collection</collection_theme>"))
        #expect(prompt.contains("<shared_characters>Alex, Robot Buddy</shared_characters>"))
    }
    
    @Test("Enhanced global reference with collection context")
    func testEnhancedGlobalReferenceWithCollectionContext() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let visualGuide = VisualGuide(
            styleGuide: "Space adventure art",
            characterDefinitions: ["Alex": "Young astronaut"],
            settingDefinitions: ["Spaceship": "Advanced spacecraft"]
        )
        let collectionContext = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Space Adventures",
            sharedCharacters: ["Alex", "Robot"],
            unifiedArtStyle: "Sci-fi illustration",
            developmentalFocus: "Science",
            ageGroup: "6-8"
        )
        
        // When
        let prompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: visualGuide,
            storyStructure: nil,
            storyTitle: "Alex's Space Mission",
            collectionContext: collectionContext
        )
        
        // Then
        #expect(prompt.contains("COLLECTION CONSISTENCY REQUIREMENTS"))
        #expect(prompt.contains("Space Adventures"))
        #expect(prompt.contains("6-8"))
        #expect(prompt.contains("Alex, Robot"))
        #expect(prompt.contains("6-8"))
        #expect(prompt.contains("Shared characters (maintain identical across collection): Alex, Robot"))
    }
    
    @Test("Backward compatibility maintained")
    func testBackwardCompatibilityMaintained() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let visualGuide = VisualGuide(
            styleGuide: "Classic style",
            characterDefinitions: ["Hero": "Main character"],
            settingDefinitions: ["Forest": "Green woods"]
        )
        let page = Page(content: "The adventure begins", pageNumber: 1)
        
        // When - Test legacy methods still work
        let legacyGlobal = promptBuilder.buildGlobalReferenceImagePrompt(
            visualGuide: visualGuide,
            storyTitle: "Classic Story"
        )
        
        let legacySequential = promptBuilder.buildSequentialIllustrationPrompt(
            page: page,
            pageIndex: 0,
            visualGuide: visualGuide,
            globalReferenceImageBase64: nil,
            previousIllustrationBase64: nil
        )
        
        // Then - Legacy methods should still work
        #expect(!legacyGlobal.isEmpty)
        #expect(!legacySequential.isEmpty)
        #expect(legacyGlobal.contains("Classic Story"))
        #expect(legacySequential.contains("The adventure begins"))
        
        // Enhanced methods with nil parameters should also work  
        let enhancedGlobal = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: visualGuide,
            storyStructure: nil,
            storyTitle: "Classic Story",
            collectionContext: nil
        )
        
        let enhancedSequential = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 0,
            storyStructure: nil,
            visualGuide: visualGuide,
            globalReferenceImageBase64: nil,
            previousIllustrationBase64: nil,
            collectionContext: nil
        )
        
        #expect(!enhancedGlobal.isEmpty)
        #expect(!enhancedSequential.isEmpty)
        #expect(enhancedGlobal.contains("Classic Story"))
        #expect(enhancedSequential.contains("The adventure begins"))
    }
}