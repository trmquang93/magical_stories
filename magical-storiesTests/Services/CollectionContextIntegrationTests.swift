import Testing
import Foundation
@testable import magical_stories

@Suite("Collection Context Integration Tests")
@MainActor  
struct CollectionContextIntegrationTests {
    
    // MARK: - Test Data Creation
    
    private func createTestCollectionContext() -> CollectionVisualContext {
        return CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Ocean Adventures",
            sharedCharacters: ["Captain Marina", "Dolphin Splash"],
            unifiedArtStyle: "Watercolor ocean scenes with flowing blues and greens",
            developmentalFocus: "Environmental Awareness",
            ageGroup: "5-7",
            requiresCharacterConsistency: true,
            allowsStyleVariation: false,
            sharedProps: ["treasure map", "diving helmet", "coral compass"]
        )
    }
    
    private func createTestStoryParameters() -> StoryParameters {
        return StoryParameters(
            theme: "Underwater Exploration",
            childAge: 6,
            childName: "Sam",
            favoriteCharacter: "Seahorse",
            storyLength: "medium",
            languageCode: "en"
        )
    }
    
    // MARK: - PromptBuilder Collection Context Tests
    
    @Test("PromptBuilder with Collection Context")
    func testPromptBuilderWithCollectionContext() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let parameters = createTestStoryParameters()
        let collectionContext = createTestCollectionContext()
        
        // When
        let prompt = promptBuilder.buildPrompt(
            parameters: parameters,
            collectionContext: collectionContext,
            vocabularyBoostEnabled: false
        )
        
        // Then - Verify basic story parameters
        #expect(prompt.contains("Underwater Exploration"))
        #expect(prompt.contains("6 years old"))
        #expect(prompt.contains("Sam"))
        #expect(prompt.contains("Seahorse"))
        
        // Verify collection context integration in visual planning
        #expect(prompt.contains("COLLECTION CONSISTENCY REQUIREMENTS:"))
        #expect(prompt.contains("Ocean Adventures"))
        #expect(prompt.contains("Captain Marina, Dolphin Splash"))
        #expect(prompt.contains("Environmental Awareness"))
        #expect(prompt.contains("5-7"))
        #expect(prompt.contains("Watercolor ocean scenes"))
        
        // Verify XML format includes collection context
        #expect(prompt.contains("<collection_context>"))
        #expect(prompt.contains("<collection_theme>Ocean Adventures</collection_theme>"))
        #expect(prompt.contains("<shared_characters>Captain Marina, Dolphin Splash</shared_characters>"))
        #expect(prompt.contains("<unified_art_style>Watercolor ocean scenes with flowing blues and greens</unified_art_style>"))
        #expect(prompt.contains("<developmental_focus>Environmental Awareness</developmental_focus>"))
        #expect(prompt.contains("<consistency_requirements>Characters must maintain identical appearance across all collection stories</consistency_requirements>"))
        #expect(prompt.contains("<shared_props>treasure map, diving helmet, coral compass</shared_props>"))
        
        // Verify story structure section is present
        #expect(prompt.contains("<story_structure>"))
        #expect(prompt.contains("<page page=\"1\">"))
        #expect(prompt.contains("<characters>List of characters appearing on this page</characters>"))
        #expect(prompt.contains("<visual_focus>Main visual elements to emphasize</visual_focus>"))
        #expect(prompt.contains("<emotional_tone>Emotional atmosphere for this page</emotional_tone>"))
    }
    
    @Test("PromptBuilder without Collection Context")
    func testPromptBuilderWithoutCollectionContext() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let parameters = createTestStoryParameters()
        
        // When
        let prompt = promptBuilder.buildPrompt(
            parameters: parameters,
            collectionContext: nil,
            vocabularyBoostEnabled: false
        )
        
        // Then - Should have basic story content
        #expect(prompt.contains("Underwater Exploration"))
        #expect(prompt.contains("Sam"))
        
        // Should NOT have collection-specific content
        #expect(!prompt.contains("COLLECTION CONSISTENCY REQUIREMENTS"))
        #expect(!prompt.contains("Ocean Adventures"))
        #expect(!prompt.contains("<collection_context>"))
        #expect(!prompt.contains("<collection_theme>"))
        
        // But should still have visual consistency planning
        #expect(prompt.contains("VISUAL CONSISTENCY PLANNING"))
        #expect(prompt.contains("CHARACTER DESIGN REQUIREMENTS"))
        #expect(prompt.contains("GLOBAL REFERENCE PREPARATION"))
        
        // And should still have story structure
        #expect(prompt.contains("<story_structure>"))
    }
    
    @Test("Collection Context XML Generation")
    func testCollectionContextXMLGeneration() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let parameters = StoryParameters(theme: "Test", childAge: 5)
        let collectionContext = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Magic & Wonder",
            sharedCharacters: ["Wizard", "Dragon"],
            unifiedArtStyle: "Fantasy illustration with rich colors",
            developmentalFocus: "Creativity & Imagination", 
            ageGroup: "4-6",
            sharedProps: ["magic wand", "spell book"]
        )
        
        // When
        let prompt = promptBuilder.buildPrompt(
            parameters: parameters,
            collectionContext: collectionContext
        )
        
        // Then - Verify proper XML structure
        #expect(prompt.contains("<collection_context>"))
        #expect(prompt.contains("<collection_theme>Magic & Wonder</collection_theme>"))
        #expect(prompt.contains("<shared_characters>Wizard, Dragon</shared_characters>"))
        #expect(prompt.contains("<unified_art_style>Fantasy illustration with rich colors</unified_art_style>"))
        #expect(prompt.contains("<developmental_focus>Creativity & Imagination</developmental_focus>"))
        #expect(prompt.contains("<shared_props>magic wand, spell book</shared_props>"))
        #expect(prompt.contains("</collection_context>"))
        
        // Verify proper XML nesting within visual_guide
        let xmlStartIndex = prompt.range(of: "<visual_guide>")
        let xmlEndIndex = prompt.range(of: "</visual_guide>")
        #expect(xmlStartIndex != nil)
        #expect(xmlEndIndex != nil)
        
        if let startIndex = xmlStartIndex?.upperBound,
           let endIndex = xmlEndIndex?.lowerBound {
            let xmlSection = String(prompt[startIndex..<endIndex])
            #expect(xmlSection.contains("<collection_context>"))
        }
    }
    
    // MARK: - Collection Visual Context Validation Tests
    
    @Test("Collection Visual Context Required Fields")
    func testCollectionVisualContextRequiredFields() async throws {
        // Given
        let collectionId = UUID()
        
        // When
        let context = CollectionVisualContext(
            collectionId: collectionId,
            collectionTheme: "Science Experiments",
            sharedCharacters: ["Dr. Beaker", "Lab Assistant"],
            unifiedArtStyle: "Scientific illustration style",
            developmentalFocus: "STEM Learning",
            ageGroup: "7-9"
        )
        
        // Then - Verify all required fields
        #expect(context.collectionId == collectionId)
        #expect(context.collectionTheme == "Science Experiments")
        #expect(context.sharedCharacters == ["Dr. Beaker", "Lab Assistant"])
        #expect(context.unifiedArtStyle == "Scientific illustration style")
        #expect(context.developmentalFocus == "STEM Learning")
        #expect(context.ageGroup == "7-9")
        
        // Verify default values
        #expect(context.requiresCharacterConsistency == true)
        #expect(context.allowsStyleVariation == false)
        #expect(context.sharedProps.isEmpty == true)
    }
    
    @Test("Collection Visual Context Optional Fields")
    func testCollectionVisualContextOptionalFields() async throws {
        // Given & When
        let context = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Art Adventures",
            sharedCharacters: ["Artist", "Muse"],
            unifiedArtStyle: "Painterly style",
            developmentalFocus: "Creative Expression",
            ageGroup: "5-8",
            requiresCharacterConsistency: false,
            allowsStyleVariation: true,
            sharedProps: ["paintbrush", "canvas", "palette"]
        )
        
        // Then
        #expect(context.requiresCharacterConsistency == false)
        #expect(context.allowsStyleVariation == true)
        #expect(context.sharedProps == ["paintbrush", "canvas", "palette"])
    }
    
    @Test("Collection Visual Context Codable Compliance")
    func testCollectionVisualContextCodable() async throws {
        // Given
        let originalContext = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Time Travel Adventures",
            sharedCharacters: ["Time Traveler", "Historical Figure"],
            unifiedArtStyle: "Historical illustration with time portal effects",
            developmentalFocus: "History & Culture",
            ageGroup: "8-10",
            requiresCharacterConsistency: true,
            allowsStyleVariation: false,
            sharedProps: ["time machine", "historical artifacts"]
        )
        
        // When - Encode and decode
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalContext)
        let decoder = JSONDecoder()
        let decodedContext = try decoder.decode(CollectionVisualContext.self, from: data)
        
        // Then - Should be identical
        #expect(decodedContext == originalContext)
        #expect(decodedContext.collectionId == originalContext.collectionId)
        #expect(decodedContext.collectionTheme == originalContext.collectionTheme)
        #expect(decodedContext.sharedCharacters == originalContext.sharedCharacters)
        #expect(decodedContext.unifiedArtStyle == originalContext.unifiedArtStyle)
        #expect(decodedContext.developmentalFocus == originalContext.developmentalFocus)
        #expect(decodedContext.ageGroup == originalContext.ageGroup)
        #expect(decodedContext.requiresCharacterConsistency == originalContext.requiresCharacterConsistency)
        #expect(decodedContext.allowsStyleVariation == originalContext.allowsStyleVariation)
        #expect(decodedContext.sharedProps == originalContext.sharedProps)
    }
    
    // MARK: - Integration with Enhanced Methods Tests
    
    @Test("Enhanced Global Reference with Collection Context")
    func testEnhancedGlobalReferenceWithCollectionContext() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let visualGuide = VisualGuide(
            styleGuide: "Ocean adventure art",
            characterDefinitions: ["Marina": "Sea captain"],
            settingDefinitions: ["Ocean": "Deep blue waters"]
        )
        let collectionContext = createTestCollectionContext()
        
        // When
        let prompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: visualGuide,
            storyStructure: nil,
            storyTitle: "Ocean Quest",
            collectionContext: collectionContext
        )
        
        // Then
        #expect(prompt.contains("COLLECTION CONSISTENCY REQUIREMENTS:"))
        #expect(prompt.contains("Ocean Adventures"))
        #expect(prompt.contains("Environmental Awareness"))
        #expect(prompt.contains("Captain Marina, Dolphin Splash"))
        #expect(prompt.contains("treasure map, diving helmet, coral compass"))
    }
    
    @Test("Enhanced Sequential Illustration with Collection Context")
    func testEnhancedSequentialIllustrationWithCollectionContext() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let page = Page(content: "The adventure begins underwater", pageNumber: 1)
        let visualGuide = VisualGuide(
            styleGuide: "Ocean art",
            characterDefinitions: ["Hero": "Underwater explorer"],
            settingDefinitions: [:]
        )
        let collectionContext = createTestCollectionContext()
        
        // When
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 0,
            storyStructure: nil,
            visualGuide: visualGuide,
            collectionContext: collectionContext
        )
        
        // Then
        #expect(prompt.contains("COLLECTION CONSISTENCY:"))
        #expect(prompt.contains("Ocean Adventures"))
        #expect(prompt.contains("Environmental Awareness"))
        #expect(prompt.contains("5-7"))
        #expect(prompt.contains("Watercolor ocean scenes"))
    }
    
    // MARK: - Edge Cases
    
    @Test("Empty Shared Characters List")
    func testEmptySharedCharactersList() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let collectionContext = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Solo Adventures",
            sharedCharacters: [], // Empty
            unifiedArtStyle: "Minimalist style",
            developmentalFocus: "Independence",
            ageGroup: "4-6"
        )
        let parameters = StoryParameters(theme: "Test", childAge: 5)
        
        // When
        let prompt = promptBuilder.buildPrompt(
            parameters: parameters,
            collectionContext: collectionContext
        )
        
        // Then - Should handle empty shared characters gracefully
        #expect(prompt.contains("<shared_characters></shared_characters>"))
        #expect(prompt.contains("Solo Adventures"))
        #expect(prompt.contains("Independence"))
    }
    
    @Test("Empty Shared Props List")
    func testEmptySharedPropsList() async throws {
        // Given
        let collectionContext = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Minimalist Stories",
            sharedCharacters: ["Hero"],
            unifiedArtStyle: "Clean style",
            developmentalFocus: "Focus",
            ageGroup: "6-8",
            sharedProps: [] // Empty
        )
        let promptBuilder = PromptBuilder()
        let parameters = StoryParameters(theme: "Test", childAge: 6)
        
        // When
        let prompt = promptBuilder.buildPrompt(
            parameters: parameters,
            collectionContext: collectionContext
        )
        
        // Then
        #expect(prompt.contains("<shared_props></shared_props>"))
        #expect(prompt.contains("Hero"))
        #expect(prompt.contains("Clean style"))
    }
    
    @Test("Special Characters in Collection Context")
    func testSpecialCharactersInCollectionContext() async throws {
        // Given
        let collectionContext = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Café & Bakery Adventures",
            sharedCharacters: ["Chef François", "Barista María"],
            unifiedArtStyle: "Warm & cozy illustration style",
            developmentalFocus: "Cultural Diversity & Food",
            ageGroup: "5-7",
            sharedProps: ["café menu", "special recipe"]
        )
        let promptBuilder = PromptBuilder()
        let parameters = StoryParameters(theme: "Baking", childAge: 6)
        
        // When
        let prompt = promptBuilder.buildPrompt(
            parameters: parameters,
            collectionContext: collectionContext
        )
        
        // Then - Should handle special characters properly
        #expect(prompt.contains("Café & Bakery Adventures"))
        #expect(prompt.contains("Chef François"))
        #expect(prompt.contains("Barista María"))
        #expect(prompt.contains("Cultural Diversity & Food"))
        #expect(prompt.contains("café menu"))
    }
}