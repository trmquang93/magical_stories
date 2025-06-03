import XCTest
import Foundation
@testable import magical_stories

/// Quick integration test to verify visual consistency system is working end-to-end
class QuickVisualConsistencyTest: XCTestCase {
    
    private var promptBuilder: PromptBuilder!
    
    override func setUp() {
        super.setUp()
        promptBuilder = PromptBuilder()
    }
    
    override func tearDown() {
        promptBuilder = nil
        super.tearDown()
    }
    
    func testVisualConsistencySystemBasicFlow() {
        // Given - Basic test data
        let visualGuide = VisualGuide(
            styleGuide: "Watercolor children's book illustration",
            characterDefinitions: [
                "Luna": "A 6-year-old girl with curly brown hair and blue eyes",
                "Whiskers": "A fluffy orange cat with green eyes"
            ],
            settingDefinitions: [
                "Garden": "A colorful flower garden with sunflowers"
            ]
        )
        
        let collectionContext = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Friendship Adventures",
            sharedCharacters: ["Luna", "Whiskers"],
            unifiedArtStyle: "Watercolor children's book style",
            developmentalFocus: "Social Skills",
            ageGroup: "4-6 years",
            requiresCharacterConsistency: true,
            allowsStyleVariation: false,
            sharedProps: ["Adventure backpack"]
        )
        
        let testPage = Page(content: "Luna and Whiskers explore the magical garden together", pageNumber: 1)
        
        // When - Generate enhanced prompt
        let prompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
            page: testPage,
            pageIndex: 0,
            storyStructure: nil,
            visualGuide: visualGuide,
            globalReferenceImageBase64: "mock-global-reference",
            previousIllustrationBase64: nil,
            collectionContext: collectionContext
        )
        
        // Then - Verify core functionality
        print("=== GENERATED PROMPT ===")
        print(prompt)
        print("=== END PROMPT ===")
        
        // Basic checks to ensure the system is working
        XCTAssertFalse(prompt.isEmpty, "Prompt should not be empty")
        XCTAssertTrue(prompt.contains("Luna"), "Prompt should include character Luna")
        XCTAssertTrue(prompt.contains("Whiskers"), "Prompt should include character Whiskers")
        XCTAssertTrue(prompt.contains("garden"), "Prompt should include story content")
        XCTAssertTrue(prompt.contains("Watercolor"), "Prompt should include art style")
        
        // Verify enhanced features are included
        XCTAssertTrue(prompt.contains("VISUAL"), "Prompt should have visual guide sections")
        XCTAssertTrue(prompt.contains("🚫"), "Prompt should include text-free requirements")
        
        // Test global reference prompt generation
        let globalPrompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
            visualGuide: visualGuide,
            storyStructure: nil,
            storyTitle: "Luna and Whiskers Adventure",
            collectionContext: collectionContext
        )
        
        print("=== GLOBAL REFERENCE PROMPT ===")
        print(globalPrompt)
        print("=== END GLOBAL PROMPT ===")
        
        XCTAssertFalse(globalPrompt.isEmpty, "Global reference prompt should not be empty")
        XCTAssertTrue(globalPrompt.contains("CHARACTER"), "Global prompt should include character section")
        XCTAssertTrue(globalPrompt.contains("Luna"), "Global prompt should include Luna")
        XCTAssertTrue(globalPrompt.contains("Whiskers"), "Global prompt should include Whiskers")
    }
    
    func testVisualGuideIntegration() {
        // Given - Visual guide
        let visualGuide = VisualGuide(
            styleGuide: "Simple test style",
            characterDefinitions: ["Hero": "A brave character"],
            settingDefinitions: ["Forest": "A magical forest"]
        )
        
        // When - Format for prompt
        let formattedGuide = visualGuide.formattedForPrompt()
        
        // Then - Verify formatting
        print("=== FORMATTED VISUAL GUIDE ===")
        print(formattedGuide)
        print("=== END VISUAL GUIDE ===")
        
        XCTAssertTrue(formattedGuide.contains("STYLE GUIDE"), "Should have style guide section")
        XCTAssertTrue(formattedGuide.contains("Simple test style"), "Should include style guide")
        XCTAssertTrue(formattedGuide.contains("Hero"), "Should include character")
        XCTAssertTrue(formattedGuide.contains("Forest"), "Should include setting")
    }
}