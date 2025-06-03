import XCTest
import Foundation
@testable import magical_stories

/// Tests for enhanced prompt building with character consistency features
class EnhancedPromptBuildingTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var promptBuilder: PromptBuilder!
    
    // Test data
    private let testVisualGuide = VisualGuide(
        styleGuide: "Detailed watercolor illustration with soft lighting and vibrant colors",
        characterDefinitions: [
            "Princess Aria": "A 8-year-old princess with long golden hair in braids, wearing a purple dress with silver details",
            "Dragon Pip": "A small friendly dragon with emerald green scales and golden wings",
            "Wizard Merlin": "An elderly wizard with a long white beard, wearing blue robes with star patterns"
        ],
        settingDefinitions: [
            "Castle": "A majestic castle with tall towers and colorful flags",
            "Enchanted Forest": "A mystical forest with glowing mushrooms and talking trees",
            "Royal Garden": "A beautiful garden with rose bushes and crystal fountains"
        ]
    )
    
    private let testCollectionContext = CollectionVisualContext(
        collectionId: UUID(),
        collectionTheme: "Royal Adventures",
        sharedCharacters: ["Princess Aria", "Dragon Pip"],
        unifiedArtStyle: "Fantasy watercolor children's book style",
        developmentalFocus: "Courage and Friendship",
        ageGroup: "6-10 years",
        requiresCharacterConsistency: true,
        allowsStyleVariation: true,
        sharedProps: ["Magic crystal", "Royal crown", "Adventure map"]
    )
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        promptBuilder = PromptBuilder()
    }
    
    override func tearDown() {
        promptBuilder = nil
        super.tearDown()
    }
    
    // MARK: - Enhanced Global Reference Prompt Tests
    
    func testEnhancedGlobalReferencePromptStructure() {
        // Given
        let storyTitle = "Princess Aria and the Crystal Quest"
        
        // When
        let prompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: testVisualGuide,
            storyStructure: nil,
            storyTitle: storyTitle,
            collectionContext: testCollectionContext
        )
        
        // Then - Verify comprehensive structure
        XCTAssertTrue(prompt.contains("COMPREHENSIVE CHARACTER REFERENCE SHEET"), 
                     "Prompt should include main header")
        XCTAssertTrue(prompt.contains("Princess Aria and the Crystal Quest"), 
                     "Prompt should include story title")
        
        // Verify all major sections are present
        let expectedSections = [
            "CHARACTER LINEUP",
            "KEY EXPRESSIONS",
            "KEY PROPS AND SETTINGS",
            "ARTISTIC STYLE:",
            "CHARACTER SPECIFICATIONS:",
            "SETTING SPECIFICATIONS:",
            "COLLECTION CONSISTENCY REQUIREMENTS:",
            "REFERENCE SHEET REQUIREMENTS:"
        ]
        
        for section in expectedSections {
            XCTAssertTrue(prompt.contains(section), 
                         "Prompt should include section: \(section)")
        }
    }
    
    func testEnhancedGlobalReferenceCharacterSpecifications() {
        // Given
        let storyTitle = "Test Story"
        
        // When
        let prompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: testVisualGuide,
            storyStructure: nil,
            storyTitle: storyTitle,
            collectionContext: testCollectionContext
        )
        
        // Then - Verify detailed character specifications
        XCTAssertTrue(prompt.contains("CHARACTER SPECIFICATIONS:"), 
                     "Prompt should include character specifications section")
        
        // Verify all characters are included with full details
        XCTAssertTrue(prompt.contains("CHARACTER - Princess Aria:"), 
                     "Prompt should include Princess Aria specification")
        XCTAssertTrue(prompt.contains("long golden hair in braids"), 
                     "Prompt should include specific character details")
        XCTAssertTrue(prompt.contains("purple dress with silver details"), 
                     "Prompt should include clothing details")
        
        XCTAssertTrue(prompt.contains("CHARACTER - Dragon Pip:"), 
                     "Prompt should include Dragon Pip specification")
        XCTAssertTrue(prompt.contains("emerald green scales and golden wings"), 
                     "Prompt should include dragon physical details")
        
        XCTAssertTrue(prompt.contains("CHARACTER - Wizard Merlin:"), 
                     "Prompt should include Wizard Merlin specification")
        XCTAssertTrue(prompt.contains("long white beard"), 
                     "Prompt should include wizard appearance details")
        XCTAssertTrue(prompt.contains("blue robes with star patterns"), 
                     "Prompt should include clothing patterns")
    }
    
    func testEnhancedGlobalReferenceCollectionRequirements() {
        // Given
        let storyTitle = "Collection Story"
        
        // When
        let prompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: testVisualGuide,
            storyStructure: nil,
            storyTitle: storyTitle,
            collectionContext: testCollectionContext
        )
        
        // Then - Verify collection consistency requirements
        XCTAssertTrue(prompt.contains("COLLECTION CONSISTENCY REQUIREMENTS:"), 
                     "Prompt should include collection requirements section")
        XCTAssertTrue(prompt.contains("used across multiple stories in the collection"), 
                     "Prompt should explain collection purpose")
        
        // Verify collection details are included
        XCTAssertTrue(prompt.contains("Art style must be: Fantasy watercolor children's book style"), 
                     "Prompt should specify required art style")
        XCTAssertTrue(prompt.contains("Collection theme: Royal Adventures"), 
                     "Prompt should include collection theme")
        XCTAssertTrue(prompt.contains("Target age group: 6-10 years"), 
                     "Prompt should include target age")
        XCTAssertTrue(prompt.contains("Developmental focus: Courage and Friendship"), 
                     "Prompt should include developmental focus")
        
        // Verify shared elements
        XCTAssertTrue(prompt.contains("Shared elements: Magic crystal, Royal crown, Adventure map"), 
                     "Prompt should include shared props")
        XCTAssertTrue(prompt.contains("Shared characters (maintain identical across collection): Princess Aria, Dragon Pip"), 
                     "Prompt should specify shared characters")
        
        // Verify consistency instructions
        XCTAssertTrue(prompt.contains("Professional character reference sheet"), 
                     "Prompt should request professional quality")
        XCTAssertTrue(prompt.contains("Each character must be visually distinct and memorable"), 
                     "Prompt should emphasize distinctiveness")
    }
    
    func testEnhancedGlobalReferenceArtisticStyle() {
        // Given
        let storyTitle = "Style Test"
        
        // When
        let prompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: testVisualGuide,
            storyStructure: nil,
            storyTitle: storyTitle,
            collectionContext: testCollectionContext
        )
        
        // Then - Verify artistic style specifications
        XCTAssertTrue(prompt.contains("ARTISTIC STYLE:"), 
                     "Prompt should include artistic style section")
        XCTAssertTrue(prompt.contains("Detailed watercolor illustration with soft lighting"), 
                     "Prompt should include style guide details")
        XCTAssertTrue(prompt.contains("vibrant colors"), 
                     "Prompt should include color specifications")
        
        // Verify reference sheet specific requirements
        XCTAssertTrue(prompt.contains("REFERENCE SHEET REQUIREMENTS:"), 
                     "Prompt should include reference sheet requirements")
        XCTAssertTrue(prompt.contains("Show each character in multiple angles"), 
                     "Prompt should request multiple angles")
        XCTAssertTrue(prompt.contains("Include key expressions"), 
                     "Prompt should request expressions")
        XCTAssertTrue(prompt.contains("Display important props and settings"), 
                     "Prompt should request props and settings")
    }
    
    // MARK: - Enhanced Sequential Illustration Prompt Tests
    
    func testEnhancedSequentialIllustrationPromptStructure() {
        // Given
        let page = Page(content: "Princess Aria meets Dragon Pip in the enchanted forest", pageNumber: 1)
        let globalReferenceBase64 = "mock-global-reference"
        
        // When
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 0,
            storyStructure: nil,
            visualGuide: testVisualGuide,
            globalReferenceImageBase64: globalReferenceBase64,
            previousIllustrationBase64: nil,
            collectionContext: testCollectionContext
        )
        
        // Then - Verify comprehensive structure
        let expectedSections = [
            "Generate illustration for page 1",
            "GLOBAL REFERENCE USAGE:",
            "VISUAL GUIDE SPECIFICATIONS:",
            "CONSISTENCY REQUIREMENTS:",
            "COLLECTION CONSISTENCY:",
            "REFERENCE SHEET GUIDANCE:",
            "🚫 NO TEXT in illustration"
        ]
        
        for section in expectedSections {
            XCTAssertTrue(prompt.contains(section), 
                         "Prompt should include section: \(section)")
        }
    }
    
    func testEnhancedSequentialIllustrationGlobalReferenceUsage() {
        // Given
        let page = Page(content: "Dragon Pip shows Princess Aria his treasure collection", pageNumber: 2)
        let globalReferenceBase64 = "available-global-reference"
        
        // When
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 1,
            storyStructure: nil,
            visualGuide: testVisualGuide,
            globalReferenceImageBase64: globalReferenceBase64,
            previousIllustrationBase64: nil,
            collectionContext: testCollectionContext
        )
        
        // Then - Verify global reference usage instructions
        XCTAssertTrue(prompt.contains("GLOBAL REFERENCE USAGE:"), 
                     "Prompt should include global reference section")
        XCTAssertTrue(prompt.contains("comprehensive character reference sheet is attached"), 
                     "Prompt should indicate attached reference")
        XCTAssertTrue(prompt.contains("Use EXACT character appearances"), 
                     "Prompt should emphasize exact appearances")
        XCTAssertTrue(prompt.contains("Match facial features, proportions, and clothing precisely"), 
                     "Prompt should specify what to match")
        XCTAssertTrue(prompt.contains("Follow the character lineup"), 
                     "Prompt should reference character lineup")
    }
    
    func testEnhancedSequentialIllustrationConsistencyRequirements() {
        // Given
        let page = Page(content: "Wizard Merlin teaches Princess Aria a magic spell", pageNumber: 3)
        let globalReferenceBase64 = "available"
        let previousIllustrationBase64 = "previous-available"
        
        // When
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 2,
            storyStructure: nil,
            visualGuide: testVisualGuide,
            globalReferenceImageBase64: globalReferenceBase64,
            previousIllustrationBase64: previousIllustrationBase64,
            collectionContext: testCollectionContext
        )
        
        // Then - Verify consistency requirements
        XCTAssertTrue(prompt.contains("CONSISTENCY REQUIREMENTS:"), 
                     "Prompt should include consistency requirements section")
        XCTAssertTrue(prompt.contains("Match character faces, proportions, and clothing EXACTLY"), 
                     "Prompt should emphasize exact matching")
        XCTAssertTrue(prompt.contains("Use the same art style and color palette"), 
                     "Prompt should require consistent style")
        XCTAssertTrue(prompt.contains("Maintain visual continuity"), 
                     "Prompt should require visual continuity")
        XCTAssertTrue(prompt.contains("Keep character sizes and proportions consistent"), 
                     "Prompt should maintain proportions")
    }
    
    func testEnhancedSequentialIllustrationReferenceGuidance() {
        // Given
        let page = Page(content: "The three friends explore the castle together", pageNumber: 4)
        let globalReferenceBase64 = "available"
        
        // When
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 3,
            storyStructure: nil,
            visualGuide: testVisualGuide,
            globalReferenceImageBase64: globalReferenceBase64,
            previousIllustrationBase64: nil,
            collectionContext: testCollectionContext
        )
        
        // Then - Verify reference sheet guidance
        XCTAssertTrue(prompt.contains("REFERENCE SHEET GUIDANCE:"), 
                     "Prompt should include reference guidance section")
        XCTAssertTrue(prompt.contains("Study the character lineup section"), 
                     "Prompt should instruct to study lineup")
        XCTAssertTrue(prompt.contains("Pay attention to key expressions"), 
                     "Prompt should emphasize expressions")
        XCTAssertTrue(prompt.contains("Note the proportional relationships"), 
                     "Prompt should mention proportions")
        XCTAssertTrue(prompt.contains("Observe clothing details and colors"), 
                     "Prompt should emphasize clothing details")
    }
    
    // MARK: - Previous Illustration Context Tests
    
    func testEnhancedSequentialIllustrationWithPreviousContext() {
        // Given
        let page = Page(content: "Princess Aria continues her journey with new determination", pageNumber: 5)
        let globalReferenceBase64 = "available"
        let previousIllustrationBase64 = "previous-scene-available"
        
        // When
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 4,
            storyStructure: nil,
            visualGuide: testVisualGuide,
            globalReferenceImageBase64: globalReferenceBase64,
            previousIllustrationBase64: previousIllustrationBase64,
            collectionContext: testCollectionContext
        )
        
        // Then - Verify previous illustration context
        XCTAssertTrue(prompt.contains("PREVIOUS ILLUSTRATION CONTEXT:"), 
                     "Prompt should include previous illustration section")
        XCTAssertTrue(prompt.contains("previous illustration is attached for reference"), 
                     "Prompt should indicate attached previous illustration")
        XCTAssertTrue(prompt.contains("Maintain visual continuity"), 
                     "Prompt should require visual continuity")
        XCTAssertTrue(prompt.contains("Keep consistent character poses and positioning"), 
                     "Prompt should maintain character positioning")
        XCTAssertTrue(prompt.contains("Ensure smooth narrative flow"), 
                     "Prompt should ensure narrative flow")
    }
    
    func testEnhancedSequentialIllustrationWithoutPreviousContext() {
        // Given (first page scenario)
        let page = Page(content: "Princess Aria begins her adventure", pageNumber: 1)
        let globalReferenceBase64 = "available"
        
        // When
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 0,
            storyStructure: nil,
            visualGuide: testVisualGuide,
            globalReferenceImageBase64: globalReferenceBase64,
            previousIllustrationBase64: nil,
            collectionContext: testCollectionContext
        )
        
        // Then - Verify no previous illustration context for first page
        XCTAssertFalse(prompt.contains("PREVIOUS ILLUSTRATION CONTEXT:"), 
                      "First page should not include previous illustration context")
        XCTAssertTrue(prompt.contains("GLOBAL REFERENCE USAGE:"), 
                     "First page should still include global reference usage")
        XCTAssertTrue(prompt.contains("CONSISTENCY REQUIREMENTS:"), 
                     "First page should include basic consistency requirements")
    }
    
    // MARK: - Character-Specific Prompt Enhancement Tests
    
    func testCharacterSpecificPromptEnhancements() {
        // Given
        let page = Page(content: "Princess Aria shows different emotions throughout her journey", pageNumber: 2)
        let globalReferenceBase64 = "available"
        
        // When
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 1,
            storyStructure: nil,
            visualGuide: testVisualGuide,
            globalReferenceImageBase64: globalReferenceBase64,
            previousIllustrationBase64: nil,
            collectionContext: testCollectionContext
        )
        
        // Then - Verify character-specific enhancements
        XCTAssertTrue(prompt.contains("CHARACTER - Princess Aria:"), 
                     "Prompt should include specific character details")
        XCTAssertTrue(prompt.contains("CHARACTER - Dragon Pip:"), 
                     "Prompt should include all relevant characters")
        XCTAssertTrue(prompt.contains("CHARACTER - Wizard Merlin:"), 
                     "Prompt should include all characters from visual guide")
        
        // Verify expression guidance
        XCTAssertTrue(prompt.contains("emotional expressions"), 
                     "Prompt should reference emotional expressions")
        XCTAssertTrue(prompt.contains("facial features"), 
                     "Prompt should emphasize facial features consistency")
    }
    
    // MARK: - Collection Context Style Variation Tests
    
    func testStyleVariationAllowed() {
        // Given
        let page = Page(content: "The castle changes with the seasons", pageNumber: 3)
        let collectionWithVariation = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Seasonal Adventures",
            sharedCharacters: ["Princess Aria"],
            unifiedArtStyle: "Flexible watercolor",
            developmentalFocus: "Nature Appreciation",
            ageGroup: "5-8 years",
            requiresCharacterConsistency: true,
            allowsStyleVariation: true,
            sharedProps: ["Season symbols"]
        )
        
        // When
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 2,
            storyStructure: nil,
            visualGuide: testVisualGuide,
            globalReferenceImageBase64: "available",
            previousIllustrationBase64: nil,
            collectionContext: collectionWithVariation
        )
        
        // Then - Verify style variation allowance
        XCTAssertTrue(prompt.contains("Style variation allowed for environmental storytelling"), 
                     "Prompt should allow style variation when enabled")
        XCTAssertTrue(prompt.contains("Maintain core character features"), 
                     "Prompt should still maintain character consistency")
        XCTAssertTrue(prompt.contains("Adapt artistic style to match seasonal theme"), 
                     "Prompt should allow thematic adaptation")
    }
    
    func testStyleVariationNotAllowed() {
        // Given
        let page = Page(content: "Princess Aria in various settings", pageNumber: 2)
        let collectionWithoutVariation = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Consistent Adventures",
            sharedCharacters: ["Princess Aria"],
            unifiedArtStyle: "Strict watercolor",
            developmentalFocus: "Consistency",
            ageGroup: "5-8 years",
            requiresCharacterConsistency: true,
            allowsStyleVariation: false,
            sharedProps: ["Consistent elements"]
        )
        
        // When
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 1,
            storyStructure: nil,
            visualGuide: testVisualGuide,
            globalReferenceImageBase64: "available",
            previousIllustrationBase64: nil,
            collectionContext: collectionWithoutVariation
        )
        
        // Then - Verify strict consistency requirements
        XCTAssertFalse(prompt.contains("Style variation allowed"), 
                      "Prompt should not allow style variation when disabled")
        XCTAssertTrue(prompt.contains("Maintain exact art style consistency"), 
                     "Prompt should require exact style consistency")
        XCTAssertTrue(prompt.contains("Use identical color palette and technique"), 
                     "Prompt should require identical techniques")
    }
    
    // MARK: - Error Handling and Edge Cases
    
    func testPromptBuildingWithMinimalInput() {
        // Given
        let emptyGuide = VisualGuide(styleGuide: "", characterDefinitions: [:], settingDefinitions: [:])
        let page = Page(content: "Basic scene", pageNumber: 1)
        
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
        
        // Then - Verify graceful handling
        XCTAssertTrue(prompt.contains("Generate illustration for page 1"), 
                     "Prompt should include basic page generation request")
        XCTAssertTrue(prompt.contains("Basic scene"), 
                     "Prompt should include page content")
        XCTAssertTrue(prompt.contains("VISUAL GUIDE SPECIFICATIONS:"), 
                     "Prompt should include visual guide section even when empty")
        XCTAssertFalse(prompt.contains("GLOBAL REFERENCE USAGE:"), 
                      "Prompt should not include global reference when not available")
    }
    
    // MARK: - Integration Test - Complete Enhanced Prompt Flow
    
    func testCompleteEnhancedPromptFlow() {
        // Given - A multi-page story requiring enhanced prompting
        let storyTitle = "Princess Aria's Greatest Adventure"
        let pages = [
            Page(content: "Princess Aria discovers a mysterious map in the royal library", pageNumber: 1),
            Page(content: "She meets Dragon Pip who offers to be her guide", pageNumber: 2),
            Page(content: "Wizard Merlin gives them magical tools for their quest", pageNumber: 3),
            Page(content: "The trio faces their first challenge in the enchanted forest", pageNumber: 4)
        ]
        
        // When - Generate complete prompt sequence
        // 1. Global reference prompt
        let globalPrompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: testVisualGuide,
            storyStructure: nil,
            storyTitle: storyTitle,
            collectionContext: testCollectionContext
        )
        
        // 2. Sequential illustration prompts
        var sequentialPrompts: [String] = []
        var previousBase64: String? = nil
        let globalReferenceBase64 = "generated-global-reference"
        
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
            
            sequentialPrompts.append(prompt)
            previousBase64 = "illustration-\(index + 1)-generated"
        }
        
        // Then - Verify complete enhanced prompt flow
        
        // Global prompt verification
        XCTAssertTrue(globalPrompt.contains("COMPREHENSIVE CHARACTER REFERENCE SHEET"), 
                     "Global prompt should be comprehensive")
        XCTAssertTrue(globalPrompt.contains("Princess Aria's Greatest Adventure"), 
                     "Global prompt should include story title")
        XCTAssertGreaterThan(globalPrompt.count, 2000, 
                            "Global prompt should be detailed")
        
        // Sequential prompts verification
        XCTAssertEqual(sequentialPrompts.count, 4, 
                      "Should generate prompts for all pages")
        
        for (index, prompt) in sequentialPrompts.enumerated() {
            // All prompts should reference global character sheet
            XCTAssertTrue(prompt.contains("GLOBAL REFERENCE USAGE:"), 
                         "Prompt \(index + 1) should reference global sheet")
            
            // All prompts should include character consistency
            XCTAssertTrue(prompt.contains("CONSISTENCY REQUIREMENTS:"), 
                         "Prompt \(index + 1) should include consistency requirements")
            
            // All prompts should include collection context
            XCTAssertTrue(prompt.contains("COLLECTION CONSISTENCY:"), 
                         "Prompt \(index + 1) should include collection consistency")
            
            // Previous illustration context should increase with each page
            if index > 0 {
                XCTAssertTrue(prompt.contains("PREVIOUS ILLUSTRATION CONTEXT:"), 
                             "Prompt \(index + 1) should include previous context")
            }
            
            // Verify page-specific content
            XCTAssertTrue(prompt.contains(pages[index].content), 
                         "Prompt \(index + 1) should include page content")
            
            // All prompts should be substantial
            XCTAssertGreaterThan(prompt.count, 1000, 
                                "Prompt \(index + 1) should be comprehensive")
        }
    }
}