import Testing
import XCTest

@testable import magical_stories

@Suite("PromptBuilder Visual Guide Tests")
struct PromptBuilder_VisualGuideTests {
    
    @Test("PromptBuilder should include visual guide instructions in buildPrompt output")
    func testPromptBuilderIncludesVisualGuideInstructions() {
        // Arrange - Create a new PromptBuilder
        let promptBuilder = PromptBuilder()
        
        // Instead of accessing private methods directly, test the public API
        let parameters = StoryParameters(
            theme: "Adventure",
            childAge: 6,
            childName: "Emma",
            favoriteCharacter: "Dragon"
        )
        
        // Act - Build the prompt using the public method
        let prompt = promptBuilder.buildPrompt(parameters: parameters)
        
        // Assert - Verify visual guide related instructions are included somewhere in the prompt
        #expect(prompt.contains("<visual_guide>"))
        #expect(prompt.contains("<style_guide>"))
        #expect(prompt.contains("<character_definitions>"))
        #expect(prompt.contains("<character name="))
        #expect(prompt.contains("<setting_definitions>"))
        #expect(prompt.contains("<setting name="))
    }
    
    @Test("BuildPrompt includes visual guide directives")
    func testBuildPromptIncludesVisualGuideDirectives() {
        // Arrange
        let promptBuilder = PromptBuilder()
        let parameters = StoryParameters(
            theme: "Adventure",
            childAge: 6,
            childName: "Emma",
            favoriteCharacter: "Dragon"
        )
        
        // Act
        let prompt = promptBuilder.buildPrompt(parameters: parameters)
        
        // Assert - check for general visual guide related terms
        #expect(prompt.contains("<visual_guide>"))
        #expect(prompt.contains("style"))
        #expect(prompt.contains("character"))
        #expect(prompt.contains("setting"))
    }
}

// We don't need the NSObject extension anymore as we're not using reflection