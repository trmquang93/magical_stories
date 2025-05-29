import XCTest
@testable import magical_stories

class FluentPromptBuilderTests: XCTestCase {
    
    // MARK: - Basic Builder Tests
    
    func testBuilder_WithBasicStoryComponents_ShouldCreateValidPrompt() {
        // Arrange & Act
        let prompt = FluentPromptBuilder()
            .story(theme: "Adventure", age: 6)
            .character(name: "Emma")
            .build()
        
        // Assert
        XCTAssertFalse(prompt.isEmpty)
        XCTAssertTrue(prompt.contains("Adventure"))
        XCTAssertTrue(prompt.contains("Emma"))
        XCTAssertTrue(prompt.contains("6 years old"))
    }
    
    func testBuilder_WithVocabularyLevel_ShouldIncludeVocabularyGuidelines() {
        // Arrange & Act
        let prompt = FluentPromptBuilder()
            .story(theme: "Fantasy", age: 8)
            .vocabulary(.enhanced(targetWords: 5))
            .build()
        
        // Assert
        XCTAssertTrue(prompt.contains("vocabulary"))
        XCTAssertTrue(prompt.contains("5"))
    }
    
    func testBuilder_WithTextFreeEnforcement_ShouldIncludeTextProhibition() {
        // Arrange & Act
        let prompt = FluentPromptBuilder()
            .story(theme: "Animals", age: 4)
            .textFree(.critical)
            .build()
        
        // Assert
        XCTAssertTrue(prompt.contains("NO TEXT"))
        XCTAssertTrue(prompt.contains("ABSOLUTE"))
        XCTAssertTrue(prompt.contains("PROHIBITION"))
    }
    
    func testBuilder_WithVisualGuide_ShouldIncludeCharacterDefinitions() {
        // Arrange
        let characters = ["Emma": "A brave young girl with brown hair", "Luna": "A magical white unicorn"]
        
        // Act
        let prompt = FluentPromptBuilder()
            .story(theme: "Fantasy", age: 7)
            .visualGuide(characters: characters)
            .build()
        
        // Assert
        XCTAssertTrue(prompt.contains("Emma"))
        XCTAssertTrue(prompt.contains("brown hair"))
        XCTAssertTrue(prompt.contains("Luna"))
        XCTAssertTrue(prompt.contains("unicorn"))
    }
    
    func testBuilder_WithInteractiveElements_ShouldIncludeInteractivity() {
        // Arrange & Act
        let prompt = FluentPromptBuilder()
            .story(theme: "Adventure", age: 5)
            .interactive(prompts: 3)
            .build()
        
        // Assert
        XCTAssertTrue(prompt.contains("interactive"))
        XCTAssertTrue(prompt.contains("3"))
    }
    
    // MARK: - Chaining Tests
    
    func testBuilder_WithFullChain_ShouldIncludeAllComponents() {
        // Arrange & Act
        let prompt = FluentPromptBuilder()
            .story(theme: "Bedtime", age: 4)
            .character(name: "Mia", favoriteCharacter: "teddy bear")
            .vocabulary(.standard)
            .textFree(.critical)
            .visualGuide(characters: ["Mia": "Small girl with curly hair"])
            .interactive(prompts: 2)
            .emotionalThemes(["comfort", "security"])
            .developmentalFocus([.emotionalIntelligence, .creativityImagination])
            .build()
        
        // Assert
        XCTAssertTrue(prompt.contains("Bedtime"))
        XCTAssertTrue(prompt.contains("Mia"))
        XCTAssertTrue(prompt.contains("teddy bear"))
        XCTAssertTrue(prompt.contains("NO TEXT"))
        XCTAssertTrue(prompt.contains("curly hair"))
        XCTAssertTrue(prompt.contains("comfort"))
        XCTAssertTrue(prompt.contains("Emotional Intelligence"), "Expected 'Emotional Intelligence' in prompt")
        XCTAssertTrue(prompt.contains("Creativity"), "Expected 'Creativity' in prompt")
    }
    
    // MARK: - Edge Cases
    
    func testBuilder_WithEmptyStory_ShouldThrowError() {
        // Arrange
        let builder = FluentPromptBuilder()
        
        // Act & Assert
        XCTAssertThrowsError(try builder.buildValidated()) { error in
            XCTAssertTrue(error is PromptValidationError)
            if case PromptValidationError.missingRequiredComponent(let component) = error {
                XCTAssertEqual(component, "story")
            }
        }
    }
    
    func testBuilder_WithInvalidAge_ShouldThrowError() {
        // Arrange & Act & Assert
        XCTAssertThrowsError(
            try FluentPromptBuilder()
                .story(theme: "Adventure", age: -1)
                .buildValidated()
        ) { error in
            XCTAssertTrue(error is PromptValidationError)
            if case PromptValidationError.invalidAge(let age) = error {
                XCTAssertEqual(age, -1)
            }
        }
    }
    
    func testBuilder_WithDuplicateComponents_ShouldUseLastValue() {
        // Arrange & Act
        let prompt = FluentPromptBuilder()
            .story(theme: "Adventure", age: 6)
            .story(theme: "Fantasy", age: 8) // Override
            .build()
        
        // Assert
        XCTAssertTrue(prompt.contains("Fantasy"))
        XCTAssertTrue(prompt.contains("8 years old"))
        XCTAssertFalse(prompt.contains("Adventure"))
        XCTAssertFalse(prompt.contains("6 years old"))
    }
    
    // MARK: - Performance Tests
    
    func testBuilder_WithComplexPrompt_ShouldCompleteQuickly() {
        // Arrange
        let characters = (1...50).reduce(into: [String: String]()) { dict, i in
            dict["Character\(i)"] = "Description for character \(i)"
        }
        
        // Act & Assert
        measure {
            let _ = FluentPromptBuilder()
                .story(theme: "Epic Adventure", age: 10)
                .character(name: "Hero")
                .vocabulary(.enhanced(targetWords: 10))
                .textFree(.critical)
                .visualGuide(characters: characters)
                .interactive(prompts: 5)
                .build()
        }
    }
    
    // MARK: - Component Isolation Tests
    
    func testBuilder_VocabularyComponent_ShouldBeIndependent() {
        // Arrange
        let baseBuilder = FluentPromptBuilder().story(theme: "Test", age: 5)
        
        // Act
        let standardPrompt = baseBuilder.vocabulary(.standard).build()
        let enhancedPrompt = baseBuilder.vocabulary(.enhanced(targetWords: 3)).build()
        
        // Assert
        XCTAssertNotEqual(standardPrompt, enhancedPrompt)
        XCTAssertTrue(enhancedPrompt.contains("3"))
        XCTAssertFalse(standardPrompt.contains("3"))
    }
    
    func testBuilder_TextFreeComponent_ShouldHaveVariations() {
        // Arrange
        let baseBuilder = FluentPromptBuilder().story(theme: "Test", age: 5)
        
        // Act
        let criticalPrompt = baseBuilder.textFree(.critical).build()
        let moderatePrompt = baseBuilder.textFree(.moderate).build()
        
        // Assert
        XCTAssertNotEqual(criticalPrompt, moderatePrompt)
        XCTAssertTrue(criticalPrompt.contains("ABSOLUTE"))
        XCTAssertFalse(moderatePrompt.contains("ABSOLUTE"))
    }
}