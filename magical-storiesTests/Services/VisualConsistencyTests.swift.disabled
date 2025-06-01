import Testing
import Foundation
import SwiftData
@testable import magical_stories

@Suite("Visual Consistency System Tests")
@MainActor
struct VisualConsistencyTests {
    
    // MARK: - Helper Methods
    
    private func createTestModelContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Story.self, StoryCollection.self, configurations: config)
        return container.mainContext
    }
    
    // MARK: - Test Data
    
    private func createTestCollectionContext() -> CollectionVisualContext {
        return CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Forest Adventure",
            sharedCharacters: ["Maya", "Forest Guardian"],
            unifiedArtStyle: "Watercolor children's book illustration with warm earth tones",
            developmentalFocus: "Problem Solving",
            ageGroup: "5-7",
            requiresCharacterConsistency: true,
            allowsStyleVariation: false,
            sharedProps: ["magical compass", "forest map", "glowing crystals"]
        )
    }
    
    private func createTestStoryStructure() -> StoryStructure {
        let pages = [
            PageVisualPlan(
                pageNumber: 1,
                characters: ["Maya", "Forest Guardian"],
                settings: ["Enchanted Forest Entrance"],
                props: ["magical compass"],
                visualFocus: "Character introduction and setting establishment",
                emotionalTone: "Wonder and curiosity"
            ),
            PageVisualPlan(
                pageNumber: 2,
                characters: ["Maya"],
                settings: ["Deep Forest Path"],
                props: ["forest map", "glowing crystals"],
                visualFocus: "Problem discovery",
                emotionalTone: "Determination and slight concern"
            )
        ]
        return StoryStructure(pages: pages)
    }
    
    private func createTestVisualGuide() -> VisualGuide {
        return VisualGuide(
            styleGuide: "Watercolor children's book style with soft edges and warm lighting",
            characterDefinitions: [
                "Maya": "A curious 6-year-old girl with brown hair in braids, wearing a green adventure vest and brown boots",
                "Forest Guardian": "A wise, gentle creature with moss-covered bark skin and glowing amber eyes"
            ],
            settingDefinitions: [
                "Enchanted Forest": "A magical woodland with towering ancient trees, dappled sunlight, and sparkling fairy lights"
            ]
        )
    }
    
    // MARK: - Enhanced Global Reference Tests
    
    @Test("Enhanced Global Reference Prompt Generation")
    func testEnhancedGlobalReferencePrompt() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let visualGuide = createTestVisualGuide()
        let storyStructure = createTestStoryStructure()
        let collectionContext = createTestCollectionContext()
        let storyTitle = "Maya's Forest Adventure"
        
        // When
        let prompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: visualGuide,
            storyStructure: storyStructure,
            storyTitle: storyTitle,
            collectionContext: collectionContext
        )
        
        // Then
        #expect(prompt.contains("COMPREHENSIVE CHARACTER REFERENCE SHEET"))
        #expect(prompt.contains(storyTitle))
        #expect(prompt.contains("CHARACTER LINEUP"))
        #expect(prompt.contains("KEY EXPRESSIONS"))
        #expect(prompt.contains("PROPS AND SETTINGS"))
        
        // Verify visual guide integration
        #expect(prompt.contains("Watercolor children's book style"))
        #expect(prompt.contains("Maya"))
        #expect(prompt.contains("Forest Guardian"))
        
        // Verify story structure integration
        #expect(prompt.contains("magical compass"))
        #expect(prompt.contains("glowing crystals"))
        #expect(prompt.contains("Wonder and curiosity"))
        
        // Verify collection context integration
        #expect(prompt.contains("COLLECTION CONSISTENCY REQUIREMENTS"))
        #expect(prompt.contains("Forest Adventure"))
        #expect(prompt.contains("Problem Solving"))
        #expect(prompt.contains("5-7"))
        
        // Verify text-free enforcement
        #expect(prompt.contains("NO TEXT OR LABELS"))
    }
    
    @Test("Enhanced Global Reference Prompt - Backward Compatibility")
    func testEnhancedGlobalReferenceBackwardCompatibility() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let visualGuide = createTestVisualGuide()
        let storyTitle = "Simple Story"
        
        // When - using legacy method
        let legacyPrompt = promptBuilder.buildGlobalReferenceImagePrompt(
            visualGuide: visualGuide,
            storyTitle: storyTitle
        )
        
        // When - using enhanced method with nil parameters
        let enhancedPrompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: visualGuide,
            storyStructure: nil,
            storyTitle: storyTitle,
            collectionContext: nil
        )
        
        // Then - both should contain core elements
        #expect(legacyPrompt.contains("COMPREHENSIVE CHARACTER REFERENCE SHEET"))
        #expect(enhancedPrompt.contains("COMPREHENSIVE CHARACTER REFERENCE SHEET"))
        #expect(legacyPrompt.contains(storyTitle))
        #expect(enhancedPrompt.contains(storyTitle))
        
        // Enhanced method should not contain collection-specific content when nil
        #expect(!enhancedPrompt.contains("COLLECTION CONSISTENCY REQUIREMENTS"))
        #expect(!enhancedPrompt.contains("STORY VISUAL REQUIREMENTS"))
    }
    
    // MARK: - Enhanced Sequential Illustration Tests
    
    @Test("Enhanced Sequential Illustration Prompt Generation")
    func testEnhancedSequentialIllustrationPrompt() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let page = Page(content: "Maya discovered a glowing crystal hidden beneath the ancient oak tree.", pageNumber: 2)
        let visualGuide = createTestVisualGuide()
        let storyStructure = createTestStoryStructure()
        let collectionContext = createTestCollectionContext()
        
        // When
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 1, // Page 2 (0-indexed)
            storyStructure: storyStructure,
            visualGuide: visualGuide,
            globalReferenceImageBase64: "mock_base64_data",
            previousIllustrationBase64: "mock_previous_base64",
            collectionContext: collectionContext
        )
        
        // Then
        #expect(prompt.contains("Generate illustration for page 2"))
        #expect(prompt.contains("Maya discovered a glowing crystal"))
        
        // Verify global reference usage
        #expect(prompt.contains("GLOBAL REFERENCE USAGE"))
        #expect(prompt.contains("comprehensive character reference sheet is attached"))
        
        // Verify story structure integration
        #expect(prompt.contains("Characters to include: Maya"))
        #expect(prompt.contains("Key props to include: forest map, glowing crystals"))
        #expect(prompt.contains("Visual focus: Problem discovery"))
        #expect(prompt.contains("Emotional tone: Determination and slight concern"))
        
        // Verify collection context integration
        #expect(prompt.contains("COLLECTION CONSISTENCY"))
        #expect(prompt.contains("Forest Adventure"))
        #expect(prompt.contains("Problem Solving"))
        
        // Verify visual guide specifications
        #expect(prompt.contains("VISUAL GUIDE SPECIFICATIONS"))
        #expect(prompt.contains("Watercolor children's book style"))
        
        // Verify consistency requirements
        #expect(prompt.contains("CONSISTENCY REQUIREMENTS"))
        #expect(prompt.contains("Match character faces, proportions, and clothing EXACTLY"))
        
        // Verify previous illustration context
        #expect(prompt.contains("PREVIOUS ILLUSTRATION CONTEXT"))
        #expect(prompt.contains("visual continuity"))
        
        // Verify text-free requirements
        #expect(prompt.contains("NO TEXT in illustration"))
    }
    
    @Test("Enhanced Sequential Illustration Prompt - Backward Compatibility")
    func testEnhancedSequentialIllustrationBackwardCompatibility() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let page = Page(content: "Test content", pageNumber: 1)
        let visualGuide = createTestVisualGuide()
        
        // When - using legacy method
        let legacyPrompt = promptBuilder.buildSequentialIllustrationPrompt(
            page: page,
            pageIndex: 0,
            visualGuide: visualGuide,
            globalReferenceImageBase64: "mock_base64",
            previousIllustrationBase64: nil
        )
        
        // When - using enhanced method with nil parameters
        let enhancedPrompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 0,
            storyStructure: nil,
            visualGuide: visualGuide,
            globalReferenceImageBase64: "mock_base64",
            previousIllustrationBase64: nil,
            collectionContext: nil
        )
        
        // Then - both should contain core elements
        #expect(legacyPrompt.contains("Generate illustration for page 1"))
        #expect(enhancedPrompt.contains("Generate illustration for page 1"))
        #expect(legacyPrompt.contains("Test content"))
        #expect(enhancedPrompt.contains("Test content"))
        
        // Enhanced method should not contain structure-specific content when nil
        #expect(!enhancedPrompt.contains("COLLECTION CONSISTENCY"))
        #expect(!enhancedPrompt.contains("Characters to include"))
    }
    
    // MARK: - Collection Context Integration Tests
    
    @Test("Collection Context Data Model")
    func testCollectionVisualContextModel() async throws {
        // Given
        let collectionId = UUID()
        
        // When
        let context = CollectionVisualContext(
            collectionId: collectionId,
            collectionTheme: "Space Adventure",
            sharedCharacters: ["Alex", "Robot Buddy"],
            unifiedArtStyle: "Digital cartoon style",
            developmentalFocus: "STEM Learning",
            ageGroup: "6-8",
            requiresCharacterConsistency: true,
            allowsStyleVariation: false,
            sharedProps: ["spaceship", "star map"]
        )
        
        // Then
        #expect(context.collectionId == collectionId)
        #expect(context.collectionTheme == "Space Adventure")
        #expect(context.sharedCharacters == ["Alex", "Robot Buddy"])
        #expect(context.unifiedArtStyle == "Digital cartoon style")
        #expect(context.developmentalFocus == "STEM Learning")
        #expect(context.ageGroup == "6-8")
        #expect(context.requiresCharacterConsistency == true)
        #expect(context.allowsStyleVariation == false)
        #expect(context.sharedProps == ["spaceship", "star map"])
        
        // Test Codable compliance
        let encoder = JSONEncoder()
        let data = try encoder.encode(context)
        let decoder = JSONDecoder()
        let decodedContext = try decoder.decode(CollectionVisualContext.self, from: data)
        
        #expect(decodedContext == context)
    }
    
    @Test("Story Structure Data Model")
    func testStoryStructureModel() async throws {
        // Given
        let pages = [
            PageVisualPlan(
                pageNumber: 1,
                characters: ["Hero"],
                settings: ["Castle"],
                props: ["sword"],
                visualFocus: "Character introduction",
                emotionalTone: "Brave"
            ),
            PageVisualPlan(
                pageNumber: 2,
                characters: ["Hero", "Dragon"],
                settings: ["Mountain Cave"],
                props: ["sword", "treasure"],
                visualFocus: "Confrontation",
                emotionalTone: "Tense"
            )
        ]
        
        // When
        let storyStructure = StoryStructure(pages: pages)
        
        // Then
        #expect(storyStructure.pages.count == 2)
        #expect(storyStructure.pages[0].pageNumber == 1)
        #expect(storyStructure.pages[0].characters == ["Hero"])
        #expect(storyStructure.pages[1].pageNumber == 2)
        #expect(storyStructure.pages[1].characters == ["Hero", "Dragon"])
        
        // Test Codable compliance
        let encoder = JSONEncoder()
        let data = try encoder.encode(storyStructure)
        let decoder = JSONDecoder()
        let decodedStructure = try decoder.decode(StoryStructure.self, from: data)
        
        #expect(decodedStructure == storyStructure)
    }
    
    // MARK: - PromptBuilder Integration Tests
    
    @Test("PromptBuilder Collection Context Integration")
    func testPromptBuilderCollectionContextIntegration() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let parameters = StoryParameters(
            theme: "Magic Forest",
            childAge: 6,
            childName: "Emma",
            favoriteCharacter: "Fairy"
        )
        let collectionContext = createTestCollectionContext()
        
        // When
        let prompt = promptBuilder.buildPrompt(
            parameters: parameters,
            collectionContext: collectionContext,
            vocabularyBoostEnabled: false
        )
        
        // Then
        #expect(prompt.contains("Magic Forest"))
        #expect(prompt.contains("Emma"))
        #expect(prompt.contains("Fairy"))
        
        // Verify collection context integration
        #expect(prompt.contains("COLLECTION CONSISTENCY REQUIREMENTS"))
        #expect(prompt.contains("Forest Adventure"))
        #expect(prompt.contains("Maya, Forest Guardian"))
        #expect(prompt.contains("Problem Solving"))
        #expect(prompt.contains("5-7"))
        
        // Verify visual planning guidelines
        #expect(prompt.contains("VISUAL CONSISTENCY PLANNING"))
        #expect(prompt.contains("CHARACTER DESIGN REQUIREMENTS"))
        #expect(prompt.contains("GLOBAL REFERENCE PREPARATION"))
        
        // Verify XML format includes collection context
        #expect(prompt.contains("<collection_context>"))
        #expect(prompt.contains("<story_structure>"))
    }
    
    @Test("PromptBuilder Without Collection Context")
    func testPromptBuilderWithoutCollectionContext() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let parameters = StoryParameters(
            theme: "Space Adventure",
            childAge: 7,
            childName: "Alex"
        )
        
        // When
        let prompt = promptBuilder.buildPrompt(
            parameters: parameters,
            collectionContext: nil,
            vocabularyBoostEnabled: false
        )
        
        // Then
        #expect(prompt.contains("Space Adventure"))
        #expect(prompt.contains("Alex"))
        
        // Verify no collection-specific content
        #expect(!prompt.contains("COLLECTION CONSISTENCY REQUIREMENTS"))
        #expect(!prompt.contains("<collection_context>"))
        
        // But should still have visual consistency planning
        #expect(prompt.contains("VISUAL CONSISTENCY PLANNING"))
        #expect(prompt.contains("CHARACTER DESIGN REQUIREMENTS"))
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Empty Visual Guide Handling")
    func testEmptyVisualGuideHandling() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let emptyVisualGuide = VisualGuide(
            styleGuide: "Basic style",
            characterDefinitions: [:],
            settingDefinitions: [:]
        )
        let storyTitle = "Test Story"
        
        // When
        let prompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: emptyVisualGuide,
            storyStructure: nil,
            storyTitle: storyTitle,
            collectionContext: nil
        )
        
        // Then - should handle empty definitions gracefully
        #expect(prompt.contains("COMPREHENSIVE CHARACTER REFERENCE SHEET"))
        #expect(prompt.contains("Basic style"))
        #expect(prompt.contains("Test Story"))
        #expect(!prompt.contains("CHARACTER SPECIFICATIONS"))
        #expect(!prompt.contains("KEY SETTINGS/ELEMENTS"))
    }
    
    @Test("Empty Story Structure Handling")
    func testEmptyStoryStructureHandling() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let emptyStructure = StoryStructure(pages: [])
        let visualGuide = createTestVisualGuide()
        let page = Page(content: "Test content", pageNumber: 1)
        
        // When
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 0,
            storyStructure: emptyStructure,
            visualGuide: visualGuide,
            globalReferenceImageBase64: nil,
            previousIllustrationBase64: nil,
            collectionContext: nil
        )
        
        // Then - should handle empty structure gracefully
        #expect(prompt.contains("Generate illustration for page 1"))
        #expect(prompt.contains("Test content"))
        #expect(!prompt.contains("Characters to include"))
        #expect(!prompt.contains("Key props to include"))
    }
}