import Testing
import Foundation
@testable import magical_stories

@Suite("Enhanced PromptBuilder Tests")
@MainActor
struct EnhancedPromptBuilderTests {
    
    // MARK: - Test Utilities
    
    private func createSampleVisualGuide() -> VisualGuide {
        return VisualGuide(
            styleGuide: "Vibrant digital art with bold colors and dynamic compositions",
            characterDefinitions: [
                "Luna": "A brave 7-year-old astronaut with curly red hair, wearing a silver spacesuit with blue accents",
                "Cosmo": "A friendly alien with purple skin, three eyes, and a welcoming smile"
            ],
            settingDefinitions: [
                "Space Station": "A high-tech orbital facility with large viewing windows showing Earth and stars",
                "Alien Planet": "A colorful world with crystal formations and floating islands"
            ]
        )
    }
    
    private func createSampleStoryStructure() -> StoryStructure {
        return StoryStructure(pages: [
            PageVisualPlan(
                pageNumber: 1,
                characters: ["Luna"],
                settings: ["Space Station"],
                props: ["communication device", "star chart"],
                visualFocus: "Luna preparing for her mission",
                emotionalTone: "Excitement and anticipation"
            ),
            PageVisualPlan(
                pageNumber: 2,
                characters: ["Luna", "Cosmo"],
                settings: ["Alien Planet"],
                props: ["communication device", "friendship bracelet"],
                visualFocus: "First contact and friendship formation",
                emotionalTone: "Wonder and joy"
            ),
            PageVisualPlan(
                pageNumber: 3,
                characters: ["Luna", "Cosmo"],
                settings: ["Space Station"],
                props: ["friendship bracelet", "gift from alien world"],
                visualFocus: "Saying goodbye and promising to return",
                emotionalTone: "Bittersweet but hopeful"
            )
        ])
    }
    
    private func createSampleCollectionContext() -> CollectionVisualContext {
        return CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Friendship Across the Stars",
            sharedCharacters: ["Luna", "Cosmo"],
            unifiedArtStyle: "Vibrant space adventure art with consistent character designs",
            developmentalFocus: "Social Skills and Cultural Understanding",
            ageGroup: "6-8",
            requiresCharacterConsistency: true,
            allowsStyleVariation: false,
            sharedProps: ["communication device", "star maps", "friendship symbols"]
        )
    }
    
    // MARK: - Enhanced Global Reference Tests
    
    @Test("Global Reference with All Parameters")
    func testGlobalReferenceWithAllParameters() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let visualGuide = createSampleVisualGuide()
        let storyStructure = createSampleStoryStructure()
        let collectionContext = createSampleCollectionContext()
        let storyTitle = "Luna's Space Adventure"
        
        // When
        let prompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: visualGuide,
            storyStructure: storyStructure,
            storyTitle: storyTitle,
            collectionContext: collectionContext
        )
        
        // Then - Verify structure
        #expect(prompt.contains("COMPREHENSIVE CHARACTER REFERENCE SHEET"))
        #expect(prompt.contains("Luna's Space Adventure"))
        #expect(prompt.contains("TOP SECTION - CHARACTER LINEUP"))
        #expect(prompt.contains("MIDDLE SECTION - KEY EXPRESSIONS"))
        #expect(prompt.contains("BOTTOM SECTION - KEY PROPS AND SETTINGS"))
        
        // Verify artistic style integration
        #expect(prompt.contains("ARTISTIC STYLE:"))
        #expect(prompt.contains("Vibrant digital art with bold colors"))
        
        // Verify character specifications
        #expect(prompt.contains("CHARACTER SPECIFICATIONS:"))
        #expect(prompt.contains("CHARACTER - Luna:"))
        #expect(prompt.contains("CHARACTER - Cosmo:"))
        #expect(prompt.contains("silver spacesuit with blue accents"))
        #expect(prompt.contains("purple skin, three eyes"))
        
        // Verify setting definitions
        #expect(prompt.contains("KEY SETTINGS/ELEMENTS:"))
        #expect(prompt.contains("Space Station:"))
        #expect(prompt.contains("Alien Planet:"))
        
        // Verify story structure integration
        #expect(prompt.contains("STORY VISUAL REQUIREMENTS:"))
        #expect(prompt.contains("All story characters: Luna, Cosmo"))
        #expect(prompt.contains("Key props needed:"))
        #expect(prompt.contains("communication device"))
        #expect(prompt.contains("friendship bracelet"))
        #expect(prompt.contains("Emotional range:"))
        #expect(prompt.contains("Excitement and anticipation"))
        #expect(prompt.contains("Wonder and joy"))
        
        // Verify collection context integration
        #expect(prompt.contains("COLLECTION CONSISTENCY REQUIREMENTS:"))
        #expect(prompt.contains("Friendship Across the Stars"))
        #expect(prompt.contains("Social Skills and Cultural Understanding"))
        #expect(prompt.contains("6-8"))
        #expect(prompt.contains("Shared characters (maintain identical across collection): Luna, Cosmo"))
        
        // Verify critical requirements
        #expect(prompt.contains("CRITICAL REQUIREMENTS:"))
        #expect(prompt.contains("NO TEXT OR LABELS"))
        #expect(prompt.contains("Professional character reference sheet"))
        
        // Verify text-free enforcement
        #expect(prompt.contains("⛔️ CRITICAL: NO TEXT, LETTERS, OR WRITTEN ELEMENTS"))
    }
    
    @Test("Global Reference with Minimal Parameters")
    func testGlobalReferenceWithMinimalParameters() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let visualGuide = VisualGuide(
            styleGuide: "Simple cartoon style",
            characterDefinitions: ["Hero": "A brave character"],
            settingDefinitions: [:]
        )
        let storyTitle = "Simple Story"
        
        // When
        let prompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: visualGuide,
            storyStructure: nil,
            storyTitle: storyTitle,
            collectionContext: nil
        )
        
        // Then
        #expect(prompt.contains("COMPREHENSIVE CHARACTER REFERENCE SHEET"))
        #expect(prompt.contains("Simple Story"))
        #expect(prompt.contains("Simple cartoon style"))
        #expect(prompt.contains("CHARACTER - Hero:"))
        
        // Should not contain optional sections
        #expect(!prompt.contains("STORY VISUAL REQUIREMENTS"))
        #expect(!prompt.contains("COLLECTION CONSISTENCY REQUIREMENTS"))
        #expect(!prompt.contains("KEY SETTINGS/ELEMENTS"))
        
        // But should still have core sections
        #expect(prompt.contains("CRITICAL REQUIREMENTS"))
        #expect(prompt.contains("NO TEXT OR LABELS"))
    }
    
    // MARK: - Enhanced Sequential Illustration Tests
    
    @Test("Sequential Illustration with Full Context")
    func testSequentialIllustrationWithFullContext() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let page = Page(
            content: "Luna and Cosmo worked together to solve the crystal puzzle, their friendship growing stronger with each shared discovery.",
            pageNumber: 2
        )
        let visualGuide = createSampleVisualGuide()
        let storyStructure = createSampleStoryStructure()
        let collectionContext = createSampleCollectionContext()
        
        // When
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 1, // Second page (0-indexed)
            storyStructure: storyStructure,
            visualGuide: visualGuide,
            globalReferenceImageBase64: "mock_reference_data",
            previousIllustrationBase64: "mock_previous_data",
            collectionContext: collectionContext
        )
        
        // Then - Verify page content
        #expect(prompt.contains("Generate illustration for page 2"))
        #expect(prompt.contains("Luna and Cosmo worked together"))
        
        // Verify global reference usage
        #expect(prompt.contains("GLOBAL REFERENCE USAGE:"))
        #expect(prompt.contains("comprehensive character reference sheet is attached"))
        #expect(prompt.contains("Use EXACT character appearances"))
        
        // Verify story structure integration (page 2 data)
        #expect(prompt.contains("Characters to include: Luna, Cosmo"))
        #expect(prompt.contains("Key props to include: communication device, friendship bracelet"))
        #expect(prompt.contains("Visual focus: First contact and friendship formation"))
        #expect(prompt.contains("Emotional tone: Wonder and joy"))
        
        // Verify scene requirements
        #expect(prompt.contains("SCENE REQUIREMENTS:"))
        #expect(prompt.contains("Setting: Alien Planet"))
        #expect(prompt.contains("Props needed: communication device, friendship bracelet"))
        #expect(prompt.contains("Emotional atmosphere: Wonder and joy"))
        
        // Verify visual guide specifications
        #expect(prompt.contains("VISUAL GUIDE SPECIFICATIONS:"))
        #expect(prompt.contains("Vibrant digital art with bold colors"))
        #expect(prompt.contains("Luna:"))
        #expect(prompt.contains("Cosmo:"))
        
        // Verify consistency requirements
        #expect(prompt.contains("CONSISTENCY REQUIREMENTS:"))
        #expect(prompt.contains("Match character faces, proportions, and clothing EXACTLY"))
        #expect(prompt.contains("Use the same art style and color palette"))
        
        // Verify collection consistency
        #expect(prompt.contains("COLLECTION CONSISTENCY:"))
        #expect(prompt.contains("Friendship Across the Stars"))
        #expect(prompt.contains("Social Skills and Cultural Understanding"))
        #expect(prompt.contains("6-8"))
        
        // Verify reference sheet guidance
        #expect(prompt.contains("REFERENCE SHEET GUIDANCE:"))
        #expect(prompt.contains("Study the character lineup section"))
        #expect(prompt.contains("Use the expression examples"))
        
        // Verify previous illustration context
        #expect(prompt.contains("PREVIOUS ILLUSTRATION CONTEXT:"))
        #expect(prompt.contains("visual continuity"))
        #expect(prompt.contains("logical visual progression"))
        
        // Verify text-free requirements
        #expect(prompt.contains("NO TEXT in illustration"))
        #expect(prompt.contains("Focus on accurate character representation"))
    }
    
    @Test("Sequential Illustration with Minimal Context")
    func testSequentialIllustrationWithMinimalContext() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let page = Page(content: "The hero walks through the forest.", pageNumber: 1)
        let visualGuide = VisualGuide(
            styleGuide: "Simple style",
            characterDefinitions: ["Hero": "Main character"],
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
        #expect(prompt.contains("The hero walks through the forest"))
        #expect(prompt.contains("VISUAL GUIDE SPECIFICATIONS"))
        #expect(prompt.contains("Simple style"))
        
        // Should not contain optional sections
        #expect(!prompt.contains("GLOBAL REFERENCE USAGE"))
        #expect(!prompt.contains("COLLECTION CONSISTENCY"))
        #expect(!prompt.contains("PREVIOUS ILLUSTRATION CONTEXT"))
        #expect(!prompt.contains("Characters to include"))
        
        // But should still have core requirements
        #expect(prompt.contains("CONSISTENCY REQUIREMENTS"))
        #expect(prompt.contains("NO TEXT in illustration"))
    }
    
    // MARK: - Page Visual Plan Matching Tests
    
    @Test("Page Visual Plan Matching by Page Number")
    func testPageVisualPlanMatching() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let storyStructure = createSampleStoryStructure()
        let visualGuide = createSampleVisualGuide()
        
        // Test page 1 (index 0)
        let page1 = Page(content: "Page 1 content", pageNumber: 1)
        let prompt1 = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page1,
            pageIndex: 0,
            storyStructure: storyStructure,
            visualGuide: visualGuide
        )
        
        // Should match page 1 plan
        #expect(prompt1.contains("Characters to include: Luna"))
        #expect(prompt1.contains("Setting: Space Station"))
        #expect(prompt1.contains("Excitement and anticipation"))
        
        // Test page 2 (index 1)
        let page2 = Page(content: "Page 2 content", pageNumber: 2)
        let prompt2 = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page2,
            pageIndex: 1,
            storyStructure: storyStructure,
            visualGuide: visualGuide
        )
        
        // Should match page 2 plan
        #expect(prompt2.contains("Characters to include: Luna, Cosmo"))
        #expect(prompt2.contains("Setting: Alien Planet"))
        #expect(prompt2.contains("Wonder and joy"))
        
        // Test page 3 (index 2)
        let page3 = Page(content: "Page 3 content", pageNumber: 3)
        let prompt3 = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page3,
            pageIndex: 2,
            storyStructure: storyStructure,
            visualGuide: visualGuide
        )
        
        // Should match page 3 plan
        #expect(prompt3.contains("Characters to include: Luna, Cosmo"))
        #expect(prompt3.contains("Setting: Space Station"))
        #expect(prompt3.contains("Bittersweet but hopeful"))
    }
    
    @Test("Page Visual Plan Non-Match Handling")
    func testPageVisualPlanNonMatch() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let storyStructure = createSampleStoryStructure() // Has pages 1, 2, 3
        let visualGuide = createSampleVisualGuide()
        
        // When - requesting page 4 (doesn't exist in structure)
        let page4 = Page(content: "Page 4 content", pageNumber: 4)
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page4,
            pageIndex: 3,
            storyStructure: storyStructure,
            visualGuide: visualGuide
        )
        
        // Then - should handle gracefully without visual plan data
        #expect(prompt.contains("Generate illustration for page 4"))
        #expect(prompt.contains("Page 4 content"))
        #expect(!prompt.contains("Characters to include:"))
        #expect(!prompt.contains("Key props to include:"))
        #expect(!prompt.contains("Visual focus:"))
        #expect(!prompt.contains("Emotional tone:"))
        
        // But should still have other sections
        #expect(prompt.contains("VISUAL GUIDE SPECIFICATIONS"))
        #expect(prompt.contains("CONSISTENCY REQUIREMENTS"))
    }
    
    // MARK: - Edge Cases and Error Handling
    
    @Test("Empty Character Definitions Handling")
    func testEmptyCharacterDefinitions() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let visualGuide = VisualGuide(
            styleGuide: "Test style",
            characterDefinitions: [:], // Empty
            settingDefinitions: ["Forest": "A green place"]
        )
        
        // When
        let prompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: visualGuide,
            storyStructure: nil,
            storyTitle: "Test",
            collectionContext: nil
        )
        
        // Then
        #expect(prompt.contains("Test style"))
        #expect(!prompt.contains("CHARACTER SPECIFICATIONS:"))
        #expect(prompt.contains("KEY SETTINGS/ELEMENTS:"))
        #expect(prompt.contains("Forest:"))
    }
    
    @Test("Empty Settings Definitions Handling")
    func testEmptySettingsDefinitions() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let visualGuide = VisualGuide(
            styleGuide: "Test style",
            characterDefinitions: ["Hero": "Main character"],
            settingDefinitions: [:] // Empty
        )
        
        // When
        let prompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: visualGuide,
            storyStructure: nil,
            storyTitle: "Test",
            collectionContext: nil
        )
        
        // Then
        #expect(prompt.contains("Test style"))
        #expect(prompt.contains("CHARACTER SPECIFICATIONS:"))
        #expect(prompt.contains("Hero:"))
        #expect(!prompt.contains("KEY SETTINGS/ELEMENTS:"))
    }
    
    @Test("Special Characters in Content Handling")
    func testSpecialCharactersHandling() async throws {
        // Given
        let promptBuilder = PromptBuilder()
        let visualGuide = VisualGuide(
            styleGuide: "Style with \"quotes\" and 'apostrophes'",
            characterDefinitions: ["Café Owner": "A character with àccénts"],
            settingDefinitions: [:]
        )
        
        // When
        let prompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: visualGuide,
            storyStructure: nil,
            storyTitle: "Tëst Story",
            collectionContext: nil
        )
        
        // Then - should handle special characters gracefully
        #expect(prompt.contains("Tëst Story"))
        #expect(prompt.contains("\"quotes\""))
        #expect(prompt.contains("'apostrophes'"))
        #expect(prompt.contains("Café Owner"))
        #expect(prompt.contains("àccénts"))
    }
}