import Testing
import Foundation
@testable import magical_stories

/// Comprehensive tests for the visual consistency system
@Suite("Visual Consistency System Tests")
struct VisualConsistencySystemTests {
    
    // MARK: - Test Data
    
    private let testVisualGuide = VisualGuide(
        styleGuide: "Watercolor style with soft edges and warm lighting",
        characterDefinitions: [
            "Luna": "A 6-year-old girl with curly brown hair, bright blue eyes, wearing a yellow sunflower dress",
            "Whiskers": "A fluffy white cat with orange patches and green eyes"
        ],
        settingDefinitions: [
            "Garden": "A colorful flower garden with tall sunflowers and a stone path",
            "House": "A cozy cottage with blue shutters and a red roof"
        ]
    )
    
    private let testCollectionContext = CollectionVisualContext(
        collectionId: UUID(),
        collectionTheme: "Nature Adventures",
        sharedCharacters: ["Luna", "Whiskers"],
        unifiedArtStyle: "Watercolor children's book illustration",
        developmentalFocus: "Emotional Intelligence",
        ageGroup: "3-6 years",
        requiresCharacterConsistency: true,
        allowsStyleVariation: false,
        sharedProps: ["Garden tools", "Flower seeds"]
    )
    
    // MARK: - VisualGuide Tests
    
    @Test("VisualGuide should initialize with all provided values")
    func testVisualGuideInitialization() {
        let visualGuide = VisualGuide(
            styleGuide: "Test style",
            characterDefinitions: ["Hero": "Brave character"],
            settingDefinitions: ["Castle": "Stone fortress"],
            globalReferenceImageURL: URL(string: "https://example.com/image.png")
        )
        
        #expect(visualGuide.styleGuide == "Test style")
        #expect(visualGuide.characterDefinitions == ["Hero": "Brave character"])
        #expect(visualGuide.settingDefinitions == ["Castle": "Stone fortress"])
        #expect(visualGuide.globalReferenceImageURL?.absoluteString == "https://example.com/image.png")
    }
    
    @Test("VisualGuide formattedForPrompt should include all sections")
    func testVisualGuideFormattedForPrompt() {
        let formatted = testVisualGuide.formattedForPrompt()
        
        // Check for critical sections
        #expect(formatted.contains("🚫 ABSOLUTELY NO TEXT ALLOWED IN ILLUSTRATION 🚫"))
        #expect(formatted.contains("STYLE GUIDE: Watercolor style with soft edges and warm lighting"))
        #expect(formatted.contains("CHARACTER - Luna: A 6-year-old girl with curly brown hair"))
        #expect(formatted.contains("CHARACTER - Whiskers: A fluffy white cat with orange patches"))
        #expect(formatted.contains("SETTING - Garden: A colorful flower garden"))
        #expect(formatted.contains("SETTING - House: A cozy cottage with blue shutters"))
        #expect(formatted.contains("❌ NO text of any kind"))
        #expect(formatted.contains("✅ Focus ONLY on visual storytelling"))
    }
    
    @Test("VisualGuide withGlobalReferenceImageURL should create new instance")
    func testVisualGuideWithGlobalReference() {
        let originalGuide = VisualGuide(
            styleGuide: "Original style",
            characterDefinitions: [:],
            settingDefinitions: [:]
        )
        
        let newURL = URL(string: "https://example.com/reference.png")!
        let updatedGuide = originalGuide.withGlobalReferenceImageURL(newURL)
        
        #expect(updatedGuide.styleGuide == "Original style")
        #expect(updatedGuide.globalReferenceImageURL == newURL)
        #expect(originalGuide.globalReferenceImageURL == nil)
    }
    
    // MARK: - CollectionVisualContext Tests
    
    @Test("CollectionVisualContext should store all required fields")
    func testCollectionVisualContextInitialization() {
        let context = testCollectionContext
        
        #expect(context.collectionTheme == "Nature Adventures")
        #expect(context.sharedCharacters == ["Luna", "Whiskers"])
        #expect(context.unifiedArtStyle == "Watercolor children's book illustration")
        #expect(context.developmentalFocus == "Emotional Intelligence")
        #expect(context.ageGroup == "3-6 years")
        #expect(context.requiresCharacterConsistency == true)
        #expect(context.allowsStyleVariation == false)
        #expect(context.sharedProps == ["Garden tools", "Flower seeds"])
    }
    
    @Test("CollectionVisualContext should be codable")
    func testCollectionVisualContextCodable() throws {
        let context = testCollectionContext
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(context)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedContext = try decoder.decode(CollectionVisualContext.self, from: data)
        
        #expect(decodedContext == context)
    }
    
    // MARK: - Enhanced PromptBuilder Tests
    
    @Test("PromptBuilder should generate enhanced global reference prompt")
    func testEnhancedGlobalReferencePrompt() {
        let promptBuilder = PromptBuilder()
        let storyTitle = "Luna's Garden Adventure"
        
        let prompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: testVisualGuide,
            storyStructure: nil,
            storyTitle: storyTitle,
            collectionContext: testCollectionContext
        )
        
        // Verify structure
        #expect(prompt.contains("COMPREHENSIVE CHARACTER REFERENCE SHEET"))
        #expect(prompt.contains("Luna's Garden Adventure"))
        #expect(prompt.contains("CHARACTER LINEUP"))
        #expect(prompt.contains("KEY EXPRESSIONS"))
        #expect(prompt.contains("KEY PROPS AND SETTINGS"))
        
        // Verify visual guide integration
        #expect(prompt.contains("ARTISTIC STYLE:"))
        #expect(prompt.contains("CHARACTER SPECIFICATIONS:"))
        #expect(prompt.contains("CHARACTER - Luna:"))
        #expect(prompt.contains("CHARACTER - Whiskers:"))
        
        // Verify collection context integration
        #expect(prompt.contains("COLLECTION CONSISTENCY REQUIREMENTS:"))
        #expect(prompt.contains("Art style must be: Watercolor children's book illustration"))
        #expect(prompt.contains("Collection theme: Nature Adventures"))
        #expect(prompt.contains("Target age group: 3-6 years"))
        
        // Verify text-free requirements
        #expect(prompt.contains("🚫 NO TEXT OR LABELS"))
        #expect(prompt.contains("⛔️ CRITICAL: NO TEXT, LETTERS, OR WRITTEN ELEMENTS"))
    }
    
    @Test("PromptBuilder should generate enhanced sequential illustration prompt")
    func testEnhancedSequentialIllustrationPrompt() {
        let promptBuilder = PromptBuilder()
        let page = Page(content: "Luna and Whiskers explore the garden together", pageNumber: 2)
        
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 1,
            storyStructure: nil,
            visualGuide: testVisualGuide,
            globalReferenceImageBase64: "available",
            previousIllustrationBase64: "available",
            collectionContext: testCollectionContext
        )
        
        // Verify page content inclusion
        #expect(prompt.contains("Generate illustration for page 2"))
        #expect(prompt.contains("Luna and Whiskers explore the garden together"))
        
        // Verify global reference usage
        #expect(prompt.contains("GLOBAL REFERENCE USAGE:"))
        #expect(prompt.contains("comprehensive character reference sheet is attached"))
        #expect(prompt.contains("Use EXACT character appearances"))
        
        // Verify visual guide specifications
        #expect(prompt.contains("VISUAL GUIDE SPECIFICATIONS:"))
        #expect(prompt.contains("Style Guide: Watercolor style with soft edges"))
        #expect(prompt.contains("- Luna: A 6-year-old girl with curly brown hair"))
        #expect(prompt.contains("- Whiskers: A fluffy white cat with orange patches"))
        
        // Verify consistency requirements
        #expect(prompt.contains("CONSISTENCY REQUIREMENTS:"))
        #expect(prompt.contains("Match character faces, proportions, and clothing EXACTLY"))
        #expect(prompt.contains("Use the same art style and color palette"))
        
        // Verify collection context
        #expect(prompt.contains("COLLECTION CONSISTENCY:"))
        #expect(prompt.contains("story collection: Nature Adventures"))
        #expect(prompt.contains("unified art style: Watercolor children's book illustration"))
        
        // Verify reference guidance
        #expect(prompt.contains("REFERENCE SHEET GUIDANCE:"))
        #expect(prompt.contains("Study the character lineup section"))
        
        // Verify previous illustration context
        #expect(prompt.contains("PREVIOUS ILLUSTRATION CONTEXT:"))
        #expect(prompt.contains("visual continuity"))
        
        // Verify text-free requirements
        #expect(prompt.contains("🚫 NO TEXT in illustration"))
        #expect(prompt.contains("✅ Focus on accurate character representation"))
    }
    
    @Test("PromptBuilder should handle missing visual guide gracefully")
    func testPromptBuilderMissingVisualGuide() {
        let promptBuilder = PromptBuilder()
        let page = Page(content: "Test content", pageNumber: 1)
        
        // Test with empty visual guide
        let emptyGuide = VisualGuide(
            styleGuide: "Basic style",
            characterDefinitions: [:],
            settingDefinitions: [:]
        )
        
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 0,
            storyStructure: nil,
            visualGuide: emptyGuide,
            globalReferenceImageBase64: nil,
            previousIllustrationBase64: nil,
            collectionContext: nil
        )
        
        #expect(prompt.contains("VISUAL GUIDE SPECIFICATIONS:"))
        #expect(prompt.contains("Style Guide: Basic style"))
        #expect(!prompt.contains("Characters:"))
        #expect(!prompt.contains("Settings:"))
        #expect(!prompt.contains("COLLECTION CONSISTENCY:"))
    }
    
    // MARK: - Integration Tests
    
    @Test("Visual consistency system should work end-to-end for global reference")
    func testGlobalReferenceGenerationFlow() {
        let promptBuilder = PromptBuilder()
        
        // 1. Create visual guide with collection context
        let visualGuide = testVisualGuide
        let collectionContext = testCollectionContext
        
        // 2. Generate global reference prompt
        let globalPrompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: visualGuide,
            storyStructure: nil,
            storyTitle: "Test Story",
            collectionContext: collectionContext
        )
        
        // 3. Verify the prompt contains all necessary elements for visual consistency
        #expect(globalPrompt.contains("CHARACTER LINEUP"))
        #expect(globalPrompt.contains("KEY EXPRESSIONS"))
        #expect(globalPrompt.contains("Luna"))
        #expect(globalPrompt.contains("Whiskers"))
        #expect(globalPrompt.contains("Nature Adventures"))
        #expect(globalPrompt.contains("Watercolor children's book illustration"))
        #expect(globalPrompt.contains("🚫 NO TEXT OR LABELS"))
        
        // Verify prompt is substantial and detailed
        #expect(globalPrompt.count > 1000)
    }
    
    @Test("Visual consistency system should work end-to-end for sequential illustrations")
    func testSequentialIllustrationConsistencyFlow() {
        let promptBuilder = PromptBuilder()
        
        // 1. Create pages for a story
        let page1 = Page(content: "Luna discovers a magical garden", pageNumber: 1)
        let page2 = Page(content: "Luna and Whiskers plant flower seeds", pageNumber: 2)
        
        // 2. Generate sequential prompts
        let prompt1 = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page1,
            pageIndex: 0,
            storyStructure: nil,
            visualGuide: testVisualGuide,
            globalReferenceImageBase64: "available",
            previousIllustrationBase64: nil,
            collectionContext: testCollectionContext
        )
        
        let prompt2 = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page2,
            pageIndex: 1,
            storyStructure: nil,
            visualGuide: testVisualGuide,
            globalReferenceImageBase64: "available",
            previousIllustrationBase64: "available",
            collectionContext: testCollectionContext
        )
        
        // 3. Verify both prompts maintain consistency requirements
        for prompt in [prompt1, prompt2] {
            #expect(prompt.contains("GLOBAL REFERENCE USAGE"))
            #expect(prompt.contains("CONSISTENCY REQUIREMENTS"))
            #expect(prompt.contains("COLLECTION CONSISTENCY"))
            #expect(prompt.contains("Use EXACT character appearances"))
            #expect(prompt.contains("same art style and color palette"))
            #expect(prompt.contains("🚫 NO TEXT in illustration"))
        }
        
        // 4. Verify page-specific content
        #expect(prompt1.contains("magical garden"))
        #expect(prompt2.contains("plant flower seeds"))
        
        // 5. Verify previous illustration context only in second prompt
        #expect(!prompt1.contains("PREVIOUS ILLUSTRATION CONTEXT"))
        #expect(prompt2.contains("PREVIOUS ILLUSTRATION CONTEXT"))
    }
    
    @Test("Visual consistency should integrate with collection requirements")
    func testCollectionIntegrationRequirements() {
        let promptBuilder = PromptBuilder()
        
        let prompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: testVisualGuide,
            storyStructure: nil,
            storyTitle: "Collection Story",
            collectionContext: testCollectionContext
        )
        
        // Verify all collection requirements are included
        #expect(prompt.contains("COLLECTION CONSISTENCY REQUIREMENTS"))
        #expect(prompt.contains("used across multiple stories in the collection"))
        #expect(prompt.contains("Art style must be: Watercolor children's book illustration"))
        #expect(prompt.contains("Collection theme: Nature Adventures"))
        #expect(prompt.contains("Target age group: 3-6 years"))
        #expect(prompt.contains("Shared elements: Garden tools, Flower seeds"))
        #expect(prompt.contains("Shared characters (maintain identical across collection): Luna, Whiskers"))
        
        // Verify consistency enforcement
        #expect(prompt.contains("Professional character reference sheet"))
        #expect(prompt.contains("Each character must be visually distinct and memorable"))
    }
}