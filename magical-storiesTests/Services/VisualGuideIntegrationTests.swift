import XCTest
import Foundation
@testable import magical_stories

/// Tests for visual guide integration with illustration generation pipeline
class VisualGuideIntegrationTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var mockIllustrationService: SharedMockIllustrationService!
    private var mockRepository: MockIllustrationTaskRepository!
    private var promptBuilder: PromptBuilder!
    
    // Test data
    private let testVisualGuide = VisualGuide(
        styleGuide: "Watercolor style with soft edges and warm lighting",
        characterDefinitions: [
            "Luna": "A 6-year-old girl with curly brown hair, bright blue eyes, wearing a yellow sunflower dress",
            "Whiskers": "A fluffy white cat with orange patches and green eyes",
            "Maya": "A 7-year-old girl with straight black hair and kind brown eyes"
        ],
        settingDefinitions: [
            "Garden": "A colorful flower garden with tall sunflowers and a stone path",
            "House": "A cozy cottage with blue shutters and a red roof",
            "Forest": "A magical forest with ancient oak trees and glowing fireflies"
        ]
    )
    
    private let testCollectionContext = CollectionVisualContext(
        collectionId: UUID(),
        collectionTheme: "Friendship Adventures",
        sharedCharacters: ["Luna", "Whiskers", "Maya"],
        unifiedArtStyle: "Watercolor children's book illustration",
        developmentalFocus: "Social Skills",
        ageGroup: "5-8 years",
        requiresCharacterConsistency: true,
        allowsStyleVariation: false,
        sharedProps: ["Magic wand", "Adventure backpack", "Friendship bracelet"]
    )
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        mockRepository = MockIllustrationTaskRepository()
        promptBuilder = PromptBuilder()
        
        // Reset mocks
        mockRepository.reset()
    }
    
    @MainActor
    private func setupMainActorMocks() {
        mockIllustrationService = SharedMockIllustrationService()
        mockIllustrationService.reset()
    }
    
    override func tearDown() {
        mockIllustrationService = nil
        mockRepository = nil
        promptBuilder = nil
        super.tearDown()
    }
    
    // MARK: - Visual Guide Integration in Sequential Illustrations
    
    func testSequentialIllustrationWithVisualGuide() {
        // Given
        let page1 = Page(content: "Luna and Maya explore the magical garden together", pageNumber: 1)
        let globalReferenceBase64 = "mock-global-reference-base64"
        
        // When
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page1,
            pageIndex: 0,
            storyStructure: nil,
            visualGuide: testVisualGuide,
            globalReferenceImageBase64: globalReferenceBase64,
            previousIllustrationBase64: nil,
            collectionContext: testCollectionContext
        )
        
        // Then - Verify visual guide integration
        XCTAssertTrue(prompt.contains("VISUAL GUIDE SPECIFICATIONS:"), 
                     "Prompt should include visual guide specifications section")
        XCTAssertTrue(prompt.contains("Style Guide: Watercolor style with soft edges"), 
                     "Prompt should include style guide from visual guide")
        
        // Verify character definitions are included
        XCTAssertTrue(prompt.contains("Characters:"), 
                     "Prompt should include character section")
        XCTAssertTrue(prompt.contains("- Luna: A 6-year-old girl with curly brown hair"), 
                     "Prompt should include Luna's character definition")
        XCTAssertTrue(prompt.contains("- Maya: A 7-year-old girl with straight black hair"), 
                     "Prompt should include Maya's character definition")
        XCTAssertTrue(prompt.contains("- Whiskers: A fluffy white cat with orange patches"), 
                     "Prompt should include Whiskers' character definition")
        
        // Verify setting definitions are included
        XCTAssertTrue(prompt.contains("Settings:"), 
                     "Prompt should include settings section")
        XCTAssertTrue(prompt.contains("- Garden: A colorful flower garden"), 
                     "Prompt should include garden setting definition")
        XCTAssertTrue(prompt.contains("- House: A cozy cottage with blue shutters"), 
                     "Prompt should include house setting definition")
        
        // Verify global reference usage instructions
        XCTAssertTrue(prompt.contains("GLOBAL REFERENCE USAGE:"), 
                     "Prompt should include global reference usage section")
        XCTAssertTrue(prompt.contains("comprehensive character reference sheet is attached"), 
                     "Prompt should reference attached character sheet")
        XCTAssertTrue(prompt.contains("Use EXACT character appearances"), 
                     "Prompt should emphasize exact character consistency")
    }
    
    func testSequentialIllustrationWithGlobalReferenceAndPreviousIllustration() {
        // Given
        let page2 = Page(content: "Whiskers joins Luna and Maya for tea in the garden", pageNumber: 2)
        let globalReferenceBase64 = "mock-global-reference-base64"
        let previousIllustrationBase64 = "mock-previous-illustration-base64"
        
        // When
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page2,
            pageIndex: 1,
            storyStructure: nil,
            visualGuide: testVisualGuide,
            globalReferenceImageBase64: globalReferenceBase64,
            previousIllustrationBase64: previousIllustrationBase64,
            collectionContext: testCollectionContext
        )
        
        // Then - Verify multiple reference integration
        XCTAssertTrue(prompt.contains("GLOBAL REFERENCE USAGE:"), 
                     "Prompt should include global reference section")
        XCTAssertTrue(prompt.contains("PREVIOUS ILLUSTRATION CONTEXT:"), 
                     "Prompt should include previous illustration section")
        
        // Verify consistency requirements
        XCTAssertTrue(prompt.contains("CONSISTENCY REQUIREMENTS:"), 
                     "Prompt should include consistency requirements")
        XCTAssertTrue(prompt.contains("Match character faces, proportions, and clothing EXACTLY"), 
                     "Prompt should emphasize exact character matching")
        XCTAssertTrue(prompt.contains("Use the same art style and color palette"), 
                     "Prompt should require consistent art style")
        XCTAssertTrue(prompt.contains("Maintain visual continuity"), 
                     "Prompt should require visual continuity")
        
        // Verify reference guidance
        XCTAssertTrue(prompt.contains("REFERENCE SHEET GUIDANCE:"), 
                     "Prompt should include reference sheet guidance")
        XCTAssertTrue(prompt.contains("Study the character lineup section"), 
                     "Prompt should instruct to study character lineup")
        XCTAssertTrue(prompt.contains("Pay attention to key expressions"), 
                     "Prompt should emphasize expressions consistency")
    }
    
    // MARK: - Collection Context Integration Tests
    
    func testVisualGuideWithCollectionContext() {
        // Given
        let page = Page(content: "The friends discover a magical friendship bracelet", pageNumber: 3)
        
        // When
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 2,
            storyStructure: nil,
            visualGuide: testVisualGuide,
            globalReferenceImageBase64: "available",
            previousIllustrationBase64: nil,
            collectionContext: testCollectionContext
        )
        
        // Then - Verify collection context integration
        XCTAssertTrue(prompt.contains("COLLECTION CONSISTENCY:"), 
                     "Prompt should include collection consistency section")
        XCTAssertTrue(prompt.contains("story collection: Friendship Adventures"), 
                     "Prompt should include collection theme")
        XCTAssertTrue(prompt.contains("unified art style: Watercolor children's book illustration"), 
                     "Prompt should specify unified art style")
        XCTAssertTrue(prompt.contains("target age group: 5-8 years"), 
                     "Prompt should include target age group")
        XCTAssertTrue(prompt.contains("developmental focus: Social Skills"), 
                     "Prompt should include developmental focus")
        
        // Verify shared elements integration
        XCTAssertTrue(prompt.contains("shared elements to include: Magic wand, Adventure backpack, Friendship bracelet"), 
                     "Prompt should include shared collection props")
        XCTAssertTrue(prompt.contains("Character consistency required across collection"), 
                     "Prompt should emphasize character consistency")
    }
    
    // MARK: - Character Consistency Tests
    
    func testCharacterConsistencyRequirements() {
        // Given
        let page = Page(content: "Luna shows Maya and Whiskers her magic wand", pageNumber: 1)
        let collectionWithStrictConsistency = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Magic Series",
            sharedCharacters: ["Luna", "Maya", "Whiskers"],
            unifiedArtStyle: "Detailed watercolor",
            developmentalFocus: "Imagination",
            ageGroup: "6-9 years",
            requiresCharacterConsistency: true,
            allowsStyleVariation: false,
            sharedProps: ["Magic wand"]
        )
        
        // When
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 0,
            storyStructure: nil,
            visualGuide: testVisualGuide,
            globalReferenceImageBase64: "available",
            previousIllustrationBase64: nil,
            collectionContext: collectionWithStrictConsistency
        )
        
        // Then - Verify strict character consistency requirements
        XCTAssertTrue(prompt.contains("Character consistency required across collection"), 
                     "Prompt should require character consistency")
        XCTAssertFalse(prompt.contains("style variation allowed"), 
                      "Prompt should not allow style variation when disabled")
        XCTAssertTrue(prompt.contains("Use EXACT character appearances"), 
                     "Prompt should emphasize exact appearances")
        XCTAssertTrue(prompt.contains("Match character faces, proportions, and clothing EXACTLY"), 
                     "Prompt should require exact matching")
    }
    
    func testCharacterConsistencyWithStyleVariation() {
        // Given
        let page = Page(content: "The friends have a picnic in different weather", pageNumber: 2)
        let collectionWithVariation = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Weather Adventures",
            sharedCharacters: ["Luna", "Maya"],
            unifiedArtStyle: "Flexible watercolor",
            developmentalFocus: "Science",
            ageGroup: "5-7 years",
            requiresCharacterConsistency: true,
            allowsStyleVariation: true,
            sharedProps: ["Weather tools"]
        )
        
        // When
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 1,
            storyStructure: nil,
            visualGuide: testVisualGuide,
            globalReferenceImageBase64: "available",
            previousIllustrationBase64: nil,
            collectionContext: collectionWithVariation
        )
        
        // Then - Verify style variation allowance while maintaining character consistency
        XCTAssertTrue(prompt.contains("Character consistency required across collection"), 
                     "Prompt should still require character consistency")
        XCTAssertTrue(prompt.contains("Style variation allowed for environmental storytelling"), 
                     "Prompt should allow style variation when enabled")
        XCTAssertTrue(prompt.contains("Maintain core character features"), 
                     "Prompt should maintain core character features")
    }
    
    // MARK: - Missing Visual Guide Handling Tests
    
    func testSequentialIllustrationWithEmptyVisualGuide() {
        // Given
        let page = Page(content: "A simple story scene", pageNumber: 1)
        let emptyGuide = VisualGuide(
            styleGuide: "Basic illustration style",
            characterDefinitions: [:],
            settingDefinitions: [:]
        )
        
        // When
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 0,
            storyStructure: nil,
            visualGuide: emptyGuide,
            globalReferenceImageBase64: nil,
            previousIllustrationBase64: nil,
            collectionContext: nil
        )
        
        // Then - Verify graceful handling of empty visual guide
        XCTAssertTrue(prompt.contains("VISUAL GUIDE SPECIFICATIONS:"), 
                     "Prompt should include visual guide section even when empty")
        XCTAssertTrue(prompt.contains("Style Guide: Basic illustration style"), 
                     "Prompt should include basic style guide")
        XCTAssertFalse(prompt.contains("Characters:"), 
                      "Prompt should not include character section when empty")
        XCTAssertFalse(prompt.contains("Settings:"), 
                      "Prompt should not include settings section when empty")
        XCTAssertFalse(prompt.contains("GLOBAL REFERENCE USAGE:"), 
                      "Prompt should not include global reference when not available")
    }
    
    func testSequentialIllustrationWithPartialVisualGuide() {
        // Given
        let page = Page(content: "Luna explores alone", pageNumber: 1)
        let partialGuide = VisualGuide(
            styleGuide: "Sketchy watercolor",
            characterDefinitions: ["Luna": "A brave young explorer"],
            settingDefinitions: [:]
        )
        
        // When
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 0,
            storyStructure: nil,
            visualGuide: partialGuide,
            globalReferenceImageBase64: nil,
            previousIllustrationBase64: nil,
            collectionContext: nil
        )
        
        // Then - Verify partial guide handling
        XCTAssertTrue(prompt.contains("Style Guide: Sketchy watercolor"), 
                     "Prompt should include available style guide")
        XCTAssertTrue(prompt.contains("Characters:"), 
                     "Prompt should include character section when available")
        XCTAssertTrue(prompt.contains("- Luna: A brave young explorer"), 
                     "Prompt should include available character definitions")
        XCTAssertFalse(prompt.contains("Settings:"), 
                      "Prompt should not include settings section when empty")
    }
    
    // MARK: - Text-Free Requirements Integration Tests
    
    func testTextFreeRequirementsInAllPrompts() {
        // Given
        let page = Page(content: "Luna reads a book to Whiskers", pageNumber: 1)
        
        // When
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 0,
            storyStructure: nil,
            visualGuide: testVisualGuide,
            globalReferenceImageBase64: "available",
            previousIllustrationBase64: nil,
            collectionContext: testCollectionContext
        )
        
        // Then - Verify text-free requirements are prominently featured
        XCTAssertTrue(prompt.contains("🚫 NO TEXT in illustration"), 
                     "Prompt should include no text emoji requirement")
        XCTAssertTrue(prompt.contains("✅ Focus on accurate character representation"), 
                     "Prompt should emphasize visual representation")
        
        // Verify visual guide also includes text-free requirements
        let formattedGuide = testVisualGuide.formattedForPrompt()
        XCTAssertTrue(formattedGuide.contains("🚫 ABSOLUTELY NO TEXT ALLOWED IN ILLUSTRATION 🚫"), 
                     "Visual guide should include strong text restriction")
        XCTAssertTrue(formattedGuide.contains("❌ NO text of any kind"), 
                     "Visual guide should emphasize no text policy")
        XCTAssertTrue(formattedGuide.contains("✅ Focus ONLY on visual storytelling"), 
                     "Visual guide should promote visual storytelling")
    }
    
    // MARK: - Error Handling and Edge Cases
    
    func testVisualGuideIntegrationWithNilComponents() {
        // Given
        let page = Page(content: "A story scene", pageNumber: 1)
        
        // When
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 0,
            storyStructure: nil,
            visualGuide: testVisualGuide,
            globalReferenceImageBase64: nil, // No global reference
            previousIllustrationBase64: nil, // No previous illustration
            collectionContext: nil // No collection context
        )
        
        // Then - Verify graceful handling of nil components
        XCTAssertTrue(prompt.contains("VISUAL GUIDE SPECIFICATIONS:"), 
                     "Prompt should include visual guide even without other components")
        XCTAssertFalse(prompt.contains("GLOBAL REFERENCE USAGE:"), 
                      "Prompt should not include global reference section when nil")
        XCTAssertFalse(prompt.contains("PREVIOUS ILLUSTRATION CONTEXT:"), 
                      "Prompt should not include previous illustration when nil")
        XCTAssertFalse(prompt.contains("COLLECTION CONSISTENCY:"), 
                      "Prompt should not include collection context when nil")
        
        // Should still include essential visual guide content
        XCTAssertTrue(prompt.contains("CHARACTER - Luna:"), 
                     "Prompt should include character definitions")
        XCTAssertTrue(prompt.contains("SETTING - Garden:"), 
                     "Prompt should include setting definitions")
    }
    
    // MARK: - Integration Test - Complete Visual Guide Flow
    
    func testCompleteVisualGuideIntegrationFlow() {
        // Given - A complete story with multiple pages requiring visual consistency
        let pages = [
            Page(content: "Luna and Maya meet Whiskers in the magical garden", pageNumber: 1),
            Page(content: "The three friends discover a hidden path in the forest", pageNumber: 2),
            Page(content: "They find a cozy cottage and decide to have tea together", pageNumber: 3)
        ]
        
        var prompts: [String] = []
        var previousBase64: String? = nil
        let globalReferenceBase64 = "mock-global-reference-available"
        
        // When - Generate sequential illustrations with visual guide integration
        for (index, page) in pages.enumerated() {
            let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
                page: page,
                pageIndex: index,
                storyStructure: nil,
                visualGuide: testVisualGuide,
                globalReferenceImageBase64: globalReferenceBase64,
                previousIllustrationBase64: previousBase64,
                collectionContext: testCollectionContext
            )
            
            prompts.append(prompt)
            
            // Simulate getting illustration result for next iteration
            previousBase64 = "mock-illustration-\(index + 1)-base64"
        }
        
        // Then - Verify all prompts maintain visual consistency requirements
        for (index, prompt) in prompts.enumerated() {
            // All prompts should include visual guide specifications
            XCTAssertTrue(prompt.contains("VISUAL GUIDE SPECIFICATIONS:"), 
                         "Prompt \(index + 1) should include visual guide specifications")
            XCTAssertTrue(prompt.contains("CHARACTER - Luna:"), 
                         "Prompt \(index + 1) should include Luna character definition")
            XCTAssertTrue(prompt.contains("CHARACTER - Maya:"), 
                         "Prompt \(index + 1) should include Maya character definition")
            XCTAssertTrue(prompt.contains("CHARACTER - Whiskers:"), 
                         "Prompt \(index + 1) should include Whiskers character definition")
            
            // All prompts should include global reference usage
            XCTAssertTrue(prompt.contains("GLOBAL REFERENCE USAGE:"), 
                         "Prompt \(index + 1) should reference global character sheet")
            
            // All prompts should include collection consistency
            XCTAssertTrue(prompt.contains("COLLECTION CONSISTENCY:"), 
                         "Prompt \(index + 1) should include collection consistency")
            
            // All prompts should include text-free requirements
            XCTAssertTrue(prompt.contains("🚫 NO TEXT in illustration"), 
                         "Prompt \(index + 1) should include text-free requirement")
            
            // Only prompts after the first should include previous illustration context
            if index > 0 {
                XCTAssertTrue(prompt.contains("PREVIOUS ILLUSTRATION CONTEXT:"), 
                             "Prompt \(index + 1) should include previous illustration context")
            } else {
                XCTAssertFalse(prompt.contains("PREVIOUS ILLUSTRATION CONTEXT:"), 
                              "First prompt should not include previous illustration context")
            }
        }
        
        // Verify page-specific content is preserved
        XCTAssertTrue(prompts[0].contains("magical garden"), 
                     "First prompt should include page 1 content")
        XCTAssertTrue(prompts[1].contains("hidden path in the forest"), 
                     "Second prompt should include page 2 content")
        XCTAssertTrue(prompts[2].contains("cozy cottage and decide to have tea"), 
                     "Third prompt should include page 3 content")
    }
}