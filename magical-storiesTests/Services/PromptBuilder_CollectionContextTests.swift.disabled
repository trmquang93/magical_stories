import Foundation
import Testing
@testable import magical_stories

@Suite("PromptBuilder Collection Context Tests")
struct PromptBuilder_CollectionContextTests {
    
    @Test("PromptBuilder includes collection context in prompts")
    func testPromptBuilderCollectionContext() {
        let promptBuilder = PromptBuilder()
        
        let parameters = StoryParameters(
            theme: "Magic Forest",
            childAge: 6,
            childName: "Alex",
            favoriteCharacter: "Unicorn"
        )
        
        let collectionContext = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Emotional Intelligence through Animals",
            sharedCharacters: ["Wise Owl", "Friendly Bear"],
            unifiedArtStyle: "Warm, engaging children's book illustration style with soft edges and vibrant colors. Detailed illustrations with rich visual storytelling. Visual elements that support Emotional Intelligence development.",
            developmentalFocus: "Emotional Intelligence",
            ageGroup: "5-7",
            requiresCharacterConsistency: true,
            allowsStyleVariation: false,
            sharedProps: ["friendly animals", "expressive faces"]
        )
        
        // Generate prompt with collection context
        let promptWithContext = promptBuilder.buildPrompt(
            parameters: parameters,
            collectionContext: collectionContext,
            vocabularyBoostEnabled: false
        )
        
        // Generate prompt without collection context
        let promptWithoutContext = promptBuilder.buildPrompt(
            parameters: parameters,
            collectionContext: nil,
            vocabularyBoostEnabled: false
        )
        
        // Verify collection context is included
        #expect(promptWithContext.contains("COLLECTION CONSISTENCY REQUIREMENTS"))
        #expect(promptWithContext.contains("Emotional Intelligence through Animals"))
        #expect(promptWithContext.contains("Wise Owl, Friendly Bear"))
        #expect(promptWithContext.contains("friendly animals, expressive faces"))
        #expect(promptWithContext.contains("collection_context"))
        
        // Verify prompt without context doesn't have collection elements
        #expect(!promptWithoutContext.contains("COLLECTION CONSISTENCY REQUIREMENTS"))
        #expect(!promptWithoutContext.contains("collection_context"))
        
        // Verify prompt with context is longer (has additional guidance)
        #expect(promptWithContext.count > promptWithoutContext.count)
    }
    
    @Test("PromptBuilder visual planning guidelines include collection context")
    func testVisualPlanningGuidelinesWithCollectionContext() {
        let promptBuilder = PromptBuilder()
        
        let parameters = StoryParameters(
            theme: "Ocean Adventure",
            childAge: 5,
            childName: "Marina"
        )
        
        let collectionContext = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Problem Solving through Ocean",
            sharedCharacters: ["Dolphin", "Seahorse"],
            unifiedArtStyle: "Underwater themed illustrations",
            developmentalFocus: "Problem Solving",
            ageGroup: "4-6",
            sharedProps: ["seashells and waves"]
        )
        
        let prompt = promptBuilder.buildPrompt(
            parameters: parameters,
            collectionContext: collectionContext
        )
        
        // Verify visual planning guidelines include collection context
        #expect(prompt.contains("VISUAL CONSISTENCY PLANNING"))
        #expect(prompt.contains("CHARACTER DESIGN REQUIREMENTS"))
        #expect(prompt.contains("GLOBAL REFERENCE PREPARATION"))
        #expect(prompt.contains("PAGE-LEVEL VISUAL PLANNING"))
        
        // Verify collection-specific guidelines
        #expect(prompt.contains("COLLECTION CONSISTENCY REQUIREMENTS"))
        #expect(prompt.contains("Underwater themed illustrations"))
        #expect(prompt.contains("Dolphin, Seahorse"))
        #expect(prompt.contains("Problem Solving"))
        #expect(prompt.contains("4-6"))
        #expect(prompt.contains("Problem Solving through Ocean"))
    }
    
    @Test("PromptBuilder format guidelines include collection XML structure")
    func testFormatGuidelinesCollectionXMLStructure() {
        let promptBuilder = PromptBuilder()
        
        let parameters = StoryParameters(
            theme: "Space Adventure",
            childAge: 7,
            childName: "Cosmos"
        )
        
        let collectionContext = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Science Learning through Space",
            sharedCharacters: ["Robot Helper"],
            unifiedArtStyle: "Futuristic space illustrations",
            developmentalFocus: "Science Learning",
            ageGroup: "6-8",
            sharedProps: ["stars and planets"]
        )
        
        let prompt = promptBuilder.buildPrompt(
            parameters: parameters,
            collectionContext: collectionContext
        )
        
        // Verify XML structure includes collection context
        #expect(prompt.contains("<visual_guide>"))
        #expect(prompt.contains("<collection_context>"))
        #expect(prompt.contains("<collection_theme>"))
        #expect(prompt.contains("<shared_characters>"))
        #expect(prompt.contains("<unified_art_style>"))
        #expect(prompt.contains("<developmental_focus>"))
        #expect(prompt.contains("<consistency_requirements>"))
        #expect(prompt.contains("<shared_props>"))
        
        // Verify specific collection values appear in XML
        #expect(prompt.contains("Science Learning through Space"))
        #expect(prompt.contains("Robot Helper"))
        #expect(prompt.contains("Futuristic space illustrations"))
        #expect(prompt.contains("Science Learning"))
        #expect(prompt.contains("stars and planets"))
    }
    
    @Test("PromptBuilder backward compatibility without collection context")
    func testBackwardCompatibilityWithoutCollectionContext() {
        let promptBuilder = PromptBuilder()
        
        let parameters = StoryParameters(
            theme: "Friendship",
            childAge: 5,
            childName: "Sam"
        )
        
        // Generate prompt without collection context (backward compatibility)
        let prompt = promptBuilder.buildPrompt(parameters: parameters)
        
        // Verify basic prompt structure still works
        #expect(prompt.contains("Friendship"))
        #expect(prompt.contains("Sam"))
        #expect(prompt.contains("VISUAL CONSISTENCY PLANNING"))
        #expect(prompt.contains("FORMAT REQUIREMENTS"))
        #expect(prompt.contains("<visual_guide>"))
        #expect(prompt.contains("<content>"))
        #expect(prompt.contains("<category>"))
        
        // Verify collection-specific elements are NOT present
        #expect(!prompt.contains("<collection_context>"))
        #expect(!prompt.contains("COLLECTION CONSISTENCY REQUIREMENTS"))
        #expect(!prompt.contains("unified art style"))
        #expect(!prompt.contains("shared characters"))
    }
}