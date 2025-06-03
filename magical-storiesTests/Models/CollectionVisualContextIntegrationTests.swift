import XCTest
import Foundation
@testable import magical_stories

/// Tests for CollectionVisualContext integration with the visual consistency system
class CollectionVisualContextIntegrationTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var promptBuilder: PromptBuilder!
    
    // Test data
    private let testVisualGuide = VisualGuide(
        styleGuide: "Magical realism watercolor with ethereal lighting and rich color depth",
        characterDefinitions: [
            "Zara": "A 7-year-old girl with long silver hair and violet eyes, wearing a flowing purple cloak with star patterns",
            "Phoenix": "A small mythical bird with golden feathers and ruby eyes, capable of creating rainbow sparks",
            "Elder Oak": "An ancient wise tree with a kind face formed in its bark and glowing amber leaves"
        ],
        settingDefinitions: [
            "Enchanted Grove": "A mystical forest clearing with glowing mushrooms and floating particles of light",
            "Crystal Cave": "A hidden cave filled with luminescent crystals that sing in harmonious tones",
            "Sky Bridge": "A bridge made of solidified clouds connecting floating islands"
        ]
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
    
    // MARK: - Collection Context Creation and Validation Tests
    
    func testCollectionVisualContextCreation() {
        // Given
        let collectionId = UUID()
        
        // When
        let collectionContext = CollectionVisualContext(
            collectionId: collectionId,
            collectionTheme: "Magical Adventures and Self-Discovery",
            sharedCharacters: ["Zara", "Phoenix"],
            unifiedArtStyle: "Magical realism watercolor children's book style",
            developmentalFocus: "Imagination and Problem Solving",
            ageGroup: "6-10 years",
            requiresCharacterConsistency: true,
            allowsStyleVariation: true,
            sharedProps: ["Magic wand", "Ancient spellbook", "Crystal compass"]
        )
        
        // Then
        XCTAssertEqual(collectionContext.collectionId, collectionId, 
                      "Should store correct collection ID")
        XCTAssertEqual(collectionContext.collectionTheme, "Magical Adventures and Self-Discovery", 
                      "Should store collection theme")
        XCTAssertEqual(collectionContext.sharedCharacters, ["Zara", "Phoenix"], 
                      "Should store shared characters list")
        XCTAssertEqual(collectionContext.unifiedArtStyle, "Magical realism watercolor children's book style", 
                      "Should store unified art style")
        XCTAssertEqual(collectionContext.developmentalFocus, "Imagination and Problem Solving", 
                      "Should store developmental focus")
        XCTAssertEqual(collectionContext.ageGroup, "6-10 years", 
                      "Should store target age group")
        XCTAssertTrue(collectionContext.requiresCharacterConsistency, 
                     "Should store character consistency requirement")
        XCTAssertTrue(collectionContext.allowsStyleVariation, 
                     "Should store style variation allowance")
        XCTAssertEqual(collectionContext.sharedProps, ["Magic wand", "Ancient spellbook", "Crystal compass"], 
                      "Should store shared props list")
    }
    
    func testCollectionVisualContextCodable() throws {
        // Given
        let originalContext = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Fantasy Quest Series",
            sharedCharacters: ["Hero", "Companion", "Guide"],
            unifiedArtStyle: "Epic fantasy illustration",
            developmentalFocus: "Courage and Teamwork",
            ageGroup: "8-12 years",
            requiresCharacterConsistency: true,
            allowsStyleVariation: false,
            sharedProps: ["Magic sword", "Healing potion", "Map of destiny"]
        )
        
        // When - Encode to JSON
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(originalContext)
        
        // Decode from JSON
        let decoder = JSONDecoder()
        let decodedContext = try decoder.decode(CollectionVisualContext.self, from: jsonData)
        
        // Then
        XCTAssertEqual(decodedContext, originalContext, 
                      "Decoded context should match original")
        XCTAssertEqual(decodedContext.collectionId, originalContext.collectionId, 
                      "Collection ID should be preserved")
        XCTAssertEqual(decodedContext.collectionTheme, originalContext.collectionTheme, 
                      "Collection theme should be preserved")
        XCTAssertEqual(decodedContext.sharedCharacters, originalContext.sharedCharacters, 
                      "Shared characters should be preserved")
        XCTAssertEqual(decodedContext.unifiedArtStyle, originalContext.unifiedArtStyle, 
                      "Art style should be preserved")
        XCTAssertEqual(decodedContext.developmentalFocus, originalContext.developmentalFocus, 
                      "Developmental focus should be preserved")
        XCTAssertEqual(decodedContext.ageGroup, originalContext.ageGroup, 
                      "Age group should be preserved")
        XCTAssertEqual(decodedContext.requiresCharacterConsistency, originalContext.requiresCharacterConsistency, 
                      "Character consistency requirement should be preserved")
        XCTAssertEqual(decodedContext.allowsStyleVariation, originalContext.allowsStyleVariation, 
                      "Style variation allowance should be preserved")
        XCTAssertEqual(decodedContext.sharedProps, originalContext.sharedProps, 
                      "Shared props should be preserved")
    }
    
    // MARK: - Collection Context Integration with Global Reference Tests
    
    func testCollectionContextInGlobalReferencePrompt() {
        // Given
        let collectionContext = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Mystical Friendship Chronicles",
            sharedCharacters: ["Zara", "Phoenix", "Elder Oak"],
            unifiedArtStyle: "Magical realism watercolor with ethereal effects",
            developmentalFocus: "Emotional Intelligence and Nature Connection",
            ageGroup: "5-9 years",
            requiresCharacterConsistency: true,
            allowsStyleVariation: false,
            sharedProps: ["Friendship crystal", "Nature journal", "Wisdom feather"]
        )
        
        // When
        let globalPrompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: testVisualGuide,
            storyStructure: nil,
            storyTitle: "Zara and the Singing Crystals",
            collectionContext: collectionContext
        )
        
        // Then - Verify collection context integration
        XCTAssertTrue(globalPrompt.contains("COLLECTION CONSISTENCY REQUIREMENTS:"), 
                     "Global prompt should include collection requirements section")
        
        // Verify collection theme integration
        XCTAssertTrue(globalPrompt.contains("Collection theme: Mystical Friendship Chronicles"), 
                     "Should include collection theme")
        XCTAssertTrue(globalPrompt.contains("used across multiple stories in the collection"), 
                     "Should explain collection purpose")
        
        // Verify art style requirements
        XCTAssertTrue(globalPrompt.contains("Art style must be: Magical realism watercolor with ethereal effects"), 
                     "Should specify required art style from collection")
        XCTAssertTrue(globalPrompt.contains("maintain exact art style consistency"), 
                     "Should enforce strict style consistency when allowsStyleVariation is false")
        
        // Verify developmental focus integration
        XCTAssertTrue(globalPrompt.contains("Developmental focus: Emotional Intelligence and Nature Connection"), 
                     "Should include developmental focus")
        XCTAssertTrue(globalPrompt.contains("Target age group: 5-9 years"), 
                     "Should include target age group")
        
        // Verify shared elements integration
        XCTAssertTrue(globalPrompt.contains("Shared elements: Friendship crystal, Nature journal, Wisdom feather"), 
                     "Should include shared props")
        XCTAssertTrue(globalPrompt.contains("Shared characters (maintain identical across collection): Zara, Phoenix, Elder Oak"), 
                     "Should specify shared characters with consistency requirement")
        
        // Verify character consistency enforcement
        XCTAssertTrue(globalPrompt.contains("Professional character reference sheet"), 
                     "Should request professional quality for collection consistency")
        XCTAssertTrue(globalPrompt.contains("Each character must be visually distinct and memorable"), 
                     "Should emphasize character distinctiveness for collection")
    }
    
    func testCollectionContextWithStyleVariationAllowed() {
        // Given
        let collectionWithVariation = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Seasonal Magic Adventures",
            sharedCharacters: ["Zara", "Phoenix"],
            unifiedArtStyle: "Adaptive watercolor style",
            developmentalFocus: "Adaptability and Change",
            ageGroup: "4-8 years",
            requiresCharacterConsistency: true,
            allowsStyleVariation: true, // Style variation allowed
            sharedProps: ["Season crystal", "Weather wand"]
        )
        
        // When
        let globalPrompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: testVisualGuide,
            storyStructure: nil,
            storyTitle: "Zara's Winter Wonder",
            collectionContext: collectionWithVariation
        )
        
        // Then
        XCTAssertTrue(globalPrompt.contains("Style variation allowed for thematic storytelling"), 
                     "Should allow style variation when enabled in collection")
        XCTAssertTrue(globalPrompt.contains("Maintain core character features while adapting style"), 
                     "Should balance character consistency with style flexibility")
        XCTAssertTrue(globalPrompt.contains("Seasonal Magic Adventures"), 
                     "Should include collection theme that supports variation")
    }
    
    // MARK: - Collection Context Integration with Sequential Illustrations Tests
    
    func testCollectionContextInSequentialIllustrationPrompt() {
        // Given
        let collectionContext = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Magical Learning Adventures",
            sharedCharacters: ["Zara", "Phoenix"],
            unifiedArtStyle: "Enchanted watercolor with magical lighting effects",
            developmentalFocus: "Curiosity and Discovery",
            ageGroup: "6-9 years",
            requiresCharacterConsistency: true,
            allowsStyleVariation: false,
            sharedProps: ["Learning crystal", "Discovery map", "Curiosity compass"]
        )
        
        let page = Page(content: "Zara and Phoenix discover a hidden library in the enchanted grove", pageNumber: 2)
        
        // When
        let sequentialPrompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 1,
            storyStructure: nil,
            visualGuide: testVisualGuide,
            globalReferenceImageBase64: "available",
            previousIllustrationBase64: "previous-page-data",
            collectionContext: collectionContext
        )
        
        // Then - Verify collection integration in sequential prompt
        XCTAssertTrue(sequentialPrompt.contains("COLLECTION CONSISTENCY:"), 
                     "Sequential prompt should include collection consistency section")
        
        // Verify collection details
        XCTAssertTrue(sequentialPrompt.contains("story collection: Magical Learning Adventures"), 
                     "Should include collection theme")
        XCTAssertTrue(sequentialPrompt.contains("unified art style: Enchanted watercolor with magical lighting effects"), 
                     "Should specify collection art style")
        XCTAssertTrue(sequentialPrompt.contains("target age group: 6-9 years"), 
                     "Should include collection age group")
        XCTAssertTrue(sequentialPrompt.contains("developmental focus: Curiosity and Discovery"), 
                     "Should include collection developmental focus")
        
        // Verify shared elements
        XCTAssertTrue(sequentialPrompt.contains("shared elements to include: Learning crystal, Discovery map, Curiosity compass"), 
                     "Should include collection shared props")
        
        // Verify character consistency requirements
        XCTAssertTrue(sequentialPrompt.contains("Character consistency required across collection"), 
                     "Should enforce character consistency for collection")
        XCTAssertTrue(sequentialPrompt.contains("Maintain exact art style consistency"), 
                     "Should enforce strict style consistency when variation is not allowed")
    }
    
    func testCollectionContextWithoutRequiredCharacterConsistency() {
        // Given
        let flexibleCollection = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Diverse Story Explorations",
            sharedCharacters: ["Zara"],
            unifiedArtStyle: "Flexible illustration style",
            developmentalFocus: "Diversity and Inclusion",
            ageGroup: "5-10 years",
            requiresCharacterConsistency: false, // Character consistency not required
            allowsStyleVariation: true,
            sharedProps: ["Universal friendship token"]
        )
        
        let page = Page(content: "Zara meets new friends from different worlds", pageNumber: 1)
        
        // When
        let sequentialPrompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 0,
            storyStructure: nil,
            visualGuide: testVisualGuide,
            globalReferenceImageBase64: "available",
            previousIllustrationBase64: nil,
            collectionContext: flexibleCollection
        )
        
        // Then
        XCTAssertFalse(sequentialPrompt.contains("Character consistency required across collection"), 
                      "Should not require character consistency when disabled")
        XCTAssertTrue(sequentialPrompt.contains("Style variation allowed for environmental storytelling"), 
                     "Should allow style variation when enabled")
        XCTAssertTrue(sequentialPrompt.contains("Maintain recognizable core features"), 
                     "Should maintain basic character recognition without strict consistency")
    }
    
    // MARK: - Multiple Collection Context Scenarios Tests
    
    func testDifferentCollectionContextsGenerateDifferentRequirements() {
        // Given - Two different collection contexts
        let educationalCollection = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Educational STEM Adventures",
            sharedCharacters: ["Zara", "Phoenix"],
            unifiedArtStyle: "Clear, instructional watercolor style",
            developmentalFocus: "Scientific Thinking and Problem Solving",
            ageGroup: "7-11 years",
            requiresCharacterConsistency: true,
            allowsStyleVariation: false,
            sharedProps: ["Science kit", "Experiment journal", "Discovery tools"]
        )
        
        let fantasyCollection = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Mystical Realm Chronicles",
            sharedCharacters: ["Zara", "Phoenix", "Elder Oak"],
            unifiedArtStyle: "Ethereal fantasy watercolor with magical effects",
            developmentalFocus: "Imagination and Creative Thinking",
            ageGroup: "5-9 years",
            requiresCharacterConsistency: true,
            allowsStyleVariation: true,
            sharedProps: ["Magic artifacts", "Mystical gems", "Ancient scrolls"]
        )
        
        // When - Generate prompts for both collections
        let educationalPrompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: testVisualGuide,
            storyStructure: nil,
            storyTitle: "Zara's Science Discovery",
            collectionContext: educationalCollection
        )
        
        let fantasyPrompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: testVisualGuide,
            storyStructure: nil,
            storyTitle: "Zara's Mystical Quest",
            collectionContext: fantasyCollection
        )
        
        // Then - Verify different collection requirements
        
        // Educational collection specifics
        XCTAssertTrue(educationalPrompt.contains("Educational STEM Adventures"), 
                     "Educational prompt should include STEM theme")
        XCTAssertTrue(educationalPrompt.contains("Scientific Thinking and Problem Solving"), 
                     "Educational prompt should include scientific focus")
        XCTAssertTrue(educationalPrompt.contains("Clear, instructional watercolor style"), 
                     "Educational prompt should specify instructional style")
        XCTAssertTrue(educationalPrompt.contains("Science kit, Experiment journal, Discovery tools"), 
                     "Educational prompt should include science props")
        XCTAssertTrue(educationalPrompt.contains("maintain exact art style consistency"), 
                     "Educational prompt should enforce strict consistency")
        
        // Fantasy collection specifics
        XCTAssertTrue(fantasyPrompt.contains("Mystical Realm Chronicles"), 
                     "Fantasy prompt should include mystical theme")
        XCTAssertTrue(fantasyPrompt.contains("Imagination and Creative Thinking"), 
                     "Fantasy prompt should include imagination focus")
        XCTAssertTrue(fantasyPrompt.contains("Ethereal fantasy watercolor with magical effects"), 
                     "Fantasy prompt should specify fantasy style")
        XCTAssertTrue(fantasyPrompt.contains("Magic artifacts, Mystical gems, Ancient scrolls"), 
                     "Fantasy prompt should include magical props")
        XCTAssertTrue(fantasyPrompt.contains("Style variation allowed for thematic storytelling"), 
                     "Fantasy prompt should allow style variation")
        
        // Different character sets
        XCTAssertTrue(educationalPrompt.contains("Shared characters (maintain identical across collection): Zara, Phoenix"), 
                     "Educational collection should have 2 shared characters")
        XCTAssertTrue(fantasyPrompt.contains("Shared characters (maintain identical across collection): Zara, Phoenix, Elder Oak"), 
                     "Fantasy collection should have 3 shared characters")
        
        // Different age groups
        XCTAssertTrue(educationalPrompt.contains("Target age group: 7-11 years"), 
                     "Educational collection should target older children")
        XCTAssertTrue(fantasyPrompt.contains("Target age group: 5-9 years"), 
                     "Fantasy collection should target younger children")
    }
    
    // MARK: - Collection Context Error Handling Tests
    
    func testPromptGenerationWithoutCollectionContext() {
        // Given
        let page = Page(content: "Zara explores the enchanted grove alone", pageNumber: 1)
        
        // When - Generate prompt without collection context
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: page,
            pageIndex: 0,
            storyStructure: nil,
            visualGuide: testVisualGuide,
            globalReferenceImageBase64: "available",
            previousIllustrationBase64: nil,
            collectionContext: nil // No collection context
        )
        
        // Then
        XCTAssertFalse(prompt.contains("COLLECTION CONSISTENCY:"), 
                      "Should not include collection section when context is nil")
        XCTAssertFalse(prompt.contains("story collection:"), 
                      "Should not reference collection when none provided")
        XCTAssertFalse(prompt.contains("shared elements to include:"), 
                      "Should not include shared elements when no collection")
        XCTAssertFalse(prompt.contains("Character consistency required across collection"), 
                      "Should not require collection character consistency")
        
        // Should still include other essential sections
        XCTAssertTrue(prompt.contains("VISUAL GUIDE SPECIFICATIONS:"), 
                     "Should include visual guide even without collection")
        XCTAssertTrue(prompt.contains("CONSISTENCY REQUIREMENTS:"), 
                     "Should include basic consistency requirements")
        XCTAssertTrue(prompt.contains("GLOBAL REFERENCE USAGE:"), 
                     "Should include global reference usage")
    }
    
    func testCollectionContextWithEmptyValues() {
        // Given
        let emptyCollection = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "",
            sharedCharacters: [],
            unifiedArtStyle: "",
            developmentalFocus: "",
            ageGroup: "",
            requiresCharacterConsistency: false,
            allowsStyleVariation: true,
            sharedProps: []
        )
        
        // When
        let globalPrompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: testVisualGuide,
            storyStructure: nil,
            storyTitle: "Empty Collection Test",
            collectionContext: emptyCollection
        )
        
        // Then - Should handle empty values gracefully
        XCTAssertTrue(globalPrompt.contains("COLLECTION CONSISTENCY REQUIREMENTS:"), 
                     "Should include collection section even with empty values")
        XCTAssertFalse(globalPrompt.contains("Collection theme: "), 
                      "Should not include empty theme")
        XCTAssertFalse(globalPrompt.contains("Shared characters"), 
                      "Should not include shared characters when list is empty")
        XCTAssertFalse(globalPrompt.contains("Shared elements:"), 
                      "Should not include shared elements when list is empty")
        
        // Should still include non-empty essential content
        XCTAssertTrue(globalPrompt.contains("CHARACTER LINEUP"), 
                     "Should include character lineup from visual guide")
        XCTAssertTrue(globalPrompt.contains("COMPREHENSIVE CHARACTER REFERENCE SHEET"), 
                     "Should maintain core structure")
    }
    
    // MARK: - Collection Context Validation Tests
    
    func testCollectionContextEquality() {
        // Given
        let collectionId = UUID()
        
        let context1 = CollectionVisualContext(
            collectionId: collectionId,
            collectionTheme: "Test Theme",
            sharedCharacters: ["Character1", "Character2"],
            unifiedArtStyle: "Test Style",
            developmentalFocus: "Test Focus",
            ageGroup: "Test Age",
            requiresCharacterConsistency: true,
            allowsStyleVariation: false,
            sharedProps: ["Prop1", "Prop2"]
        )
        
        let context2 = CollectionVisualContext(
            collectionId: collectionId,
            collectionTheme: "Test Theme",
            sharedCharacters: ["Character1", "Character2"],
            unifiedArtStyle: "Test Style",
            developmentalFocus: "Test Focus",
            ageGroup: "Test Age",
            requiresCharacterConsistency: true,
            allowsStyleVariation: false,
            sharedProps: ["Prop1", "Prop2"]
        )
        
        let context3 = CollectionVisualContext(
            collectionId: UUID(), // Different ID
            collectionTheme: "Test Theme",
            sharedCharacters: ["Character1", "Character2"],
            unifiedArtStyle: "Test Style",
            developmentalFocus: "Test Focus",
            ageGroup: "Test Age",
            requiresCharacterConsistency: true,
            allowsStyleVariation: false,
            sharedProps: ["Prop1", "Prop2"]
        )
        
        // Then
        XCTAssertEqual(context1, context2, "Contexts with same values should be equal")
        XCTAssertNotEqual(context1, context3, "Contexts with different collection IDs should not be equal")
    }
    
    // MARK: - Integration Test - Complete Collection Context Flow
    
    func testCompleteCollectionContextIntegrationFlow() {
        // Given - A realistic collection scenario
        let magicalSeriesCollection = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Zara's Magical Growth Journey",
            sharedCharacters: ["Zara", "Phoenix", "Elder Oak"],
            unifiedArtStyle: "Progressive magical watercolor showing character growth",
            developmentalFocus: "Personal Growth and Self-Discovery",
            ageGroup: "6-10 years",
            requiresCharacterConsistency: true,
            allowsStyleVariation: true,
            sharedProps: ["Growth crystal", "Memory journal", "Wisdom compass"]
        )
        
        let story1Pages = [
            Page(content: "Young Zara first meets Phoenix in the enchanted grove", pageNumber: 1),
            Page(content: "Elder Oak teaches Zara about the magic within herself", pageNumber: 2)
        ]
        
        let story2Pages = [
            Page(content: "Now more confident, Zara guides Phoenix to the crystal cave", pageNumber: 1),
            Page(content: "Zara uses her grown wisdom to help other young creatures", pageNumber: 2)
        ]
        
        // When - Generate prompts for multiple stories in the collection
        
        // Story 1: Beginning of journey
        let story1GlobalPrompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: testVisualGuide,
            storyStructure: nil,
            storyTitle: "Zara's First Magic Lesson",
            collectionContext: magicalSeriesCollection
        )
        
        var story1SequentialPrompts: [String] = []
        for (index, page) in story1Pages.enumerated() {
            let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
                page: page,
                pageIndex: index,
                storyStructure: nil,
                visualGuide: testVisualGuide,
                globalReferenceImageBase64: "story1-global-reference",
                previousIllustrationBase64: index > 0 ? "story1-previous-page" : nil,
                collectionContext: magicalSeriesCollection
            )
            story1SequentialPrompts.append(prompt)
        }
        
        // Story 2: Growth and mastery
        let story2GlobalPrompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: testVisualGuide,
            storyStructure: nil,
            storyTitle: "Zara's Wisdom Shared",
            collectionContext: magicalSeriesCollection
        )
        
        var story2SequentialPrompts: [String] = []
        for (index, page) in story2Pages.enumerated() {
            let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
                page: page,
                pageIndex: index,
                storyStructure: nil,
                visualGuide: testVisualGuide,
                globalReferenceImageBase64: "story2-global-reference",
                previousIllustrationBase64: index > 0 ? "story2-previous-page" : nil,
                collectionContext: magicalSeriesCollection
            )
            story2SequentialPrompts.append(prompt)
        }
        
        // Then - Verify collection consistency across multiple stories
        
        // Both global prompts should have identical collection requirements
        let collectionElements = [
            "COLLECTION CONSISTENCY REQUIREMENTS:",
            "Collection theme: Zara's Magical Growth Journey",
            "unified art style: Progressive magical watercolor showing character growth",
            "developmental focus: Personal Growth and Self-Discovery",
            "target age group: 6-10 years",
            "Shared characters (maintain identical across collection): Zara, Phoenix, Elder Oak",
            "Shared elements: Growth crystal, Memory journal, Wisdom compass"
        ]
        
        for element in collectionElements {
            XCTAssertTrue(story1GlobalPrompt.contains(element), 
                         "Story 1 global prompt should include: \(element)")
            XCTAssertTrue(story2GlobalPrompt.contains(element), 
                         "Story 2 global prompt should include: \(element)")
        }
        
        // All sequential prompts should maintain collection consistency
        let allSequentialPrompts = story1SequentialPrompts + story2SequentialPrompts
        for (index, prompt) in allSequentialPrompts.enumerated() {
            XCTAssertTrue(prompt.contains("COLLECTION CONSISTENCY:"), 
                         "Sequential prompt \(index + 1) should include collection consistency")
            XCTAssertTrue(prompt.contains("Zara's Magical Growth Journey"), 
                         "Sequential prompt \(index + 1) should include collection theme")
            XCTAssertTrue(prompt.contains("Personal Growth and Self-Discovery"), 
                         "Sequential prompt \(index + 1) should include developmental focus")
            XCTAssertTrue(prompt.contains("Character consistency required across collection"), 
                         "Sequential prompt \(index + 1) should require character consistency")
            XCTAssertTrue(prompt.contains("Style variation allowed for thematic storytelling"), 
                         "Sequential prompt \(index + 1) should allow appropriate style variation")
        }
        
        // Verify story-specific content is preserved
        XCTAssertTrue(story1GlobalPrompt.contains("Zara's First Magic Lesson"), 
                     "Story 1 should include its specific title")
        XCTAssertTrue(story2GlobalPrompt.contains("Zara's Wisdom Shared"), 
                     "Story 2 should include its specific title")
        
        XCTAssertTrue(story1SequentialPrompts[0].contains("Young Zara first meets Phoenix"), 
                     "Story 1 page 1 should include its specific content")
        XCTAssertTrue(story2SequentialPrompts[1].contains("Zara uses her grown wisdom"), 
                     "Story 2 page 2 should show character growth")
        
        // Verify character consistency requirements are maintained across stories
        for prompt in [story1GlobalPrompt, story2GlobalPrompt] + allSequentialPrompts {
            XCTAssertTrue(prompt.contains("CHARACTER - Zara:"), 
                         "All prompts should include Zara's character definition")
            XCTAssertTrue(prompt.contains("CHARACTER - Phoenix:"), 
                         "All prompts should include Phoenix's character definition")
            XCTAssertTrue(prompt.contains("CHARACTER - Elder Oak:"), 
                         "All prompts should include Elder Oak's character definition")
        }
    }
}