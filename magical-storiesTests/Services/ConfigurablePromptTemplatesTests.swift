import XCTest
@testable import magical_stories

class ConfigurablePromptTemplatesTests: XCTestCase {
    
    var templateManager: ConfigurablePromptTemplates!
    
    override func setUp() {
        super.setUp()
        templateManager = ConfigurablePromptTemplates.shared
    }
    
    // MARK: - Basic Template Access Tests
    
    func testTemplate_WithValidCategory_ShouldReturnTemplate() {
        // Act
        let template = templateManager.template(for: "storyStructure")
        
        // Assert
        XCTAssertFalse(template.isEmpty)
        XCTAssertTrue(template.contains("Story Structure Requirements"))
    }
    
    func testTemplate_WithValidCategoryAndLevel_ShouldReturnCorrectTemplate() {
        // Act
        let beginnerTemplate = templateManager.template(for: "vocabularyLevels", level: "beginner")
        let advancedTemplate = templateManager.template(for: "vocabularyLevels", level: "advanced")
        
        // Assert
        XCTAssertNotEqual(beginnerTemplate, advancedTemplate)
        XCTAssertTrue(beginnerTemplate.contains("simple"))
        XCTAssertTrue(advancedTemplate.contains("rich vocabulary"))
    }
    
    func testTemplate_WithInvalidCategory_ShouldReturnFallback() {
        // Act
        let template = templateManager.template(for: "nonExistentCategory")
        
        // Assert
        XCTAssertFalse(template.isEmpty)
        XCTAssertTrue(template.contains("engaging children's content"))
    }
    
    func testTemplate_WithInvalidLevel_ShouldReturnFallback() {
        // Act
        let template = templateManager.template(for: "textFreeEnforcement", level: "nonExistentLevel")
        
        // Assert
        XCTAssertFalse(template.isEmpty)
    }
    
    // MARK: - Substitution Tests
    
    func testTemplate_WithSubstitutions_ShouldReplaceVariables() {
        // Arrange
        let substitutions = ["targetWords": "5"]
        
        // Act
        let template = templateManager.template(
            for: "enhancedVocabulary", 
            substitutions: substitutions
        )
        
        // Assert
        XCTAssertTrue(template.contains("5 new vocabulary words"))
        XCTAssertFalse(template.contains("{targetWords}"))
    }
    
    func testTemplate_WithMultipleSubstitutions_ShouldReplaceAll() {
        // Arrange
        let substitutions = [
            "promptCount": "3",
            "animal": "elephant"
        ]
        
        // Act
        let template = templateManager.template(
            for: "interactive",
            substitutions: substitutions
        )
        
        // Assert
        XCTAssertTrue(template.contains("3 moments"))
        XCTAssertFalse(template.contains("{promptCount}"))
    }
    
    // MARK: - Priority Tests
    
    func testTemplatePriority_ShouldReturnCorrectPriority() {
        // Act
        let textFreePriority = templateManager.templatePriority(for: "textFreeEnforcement", level: "critical")
        let vocabularyPriority = templateManager.templatePriority(for: "vocabularyLevels", level: "beginner")
        
        // Assert
        XCTAssertEqual(textFreePriority, 3)
        XCTAssertEqual(vocabularyPriority, 2)
    }
    
    func testTemplatePriority_WithInvalidCategory_ShouldReturnDefaultPriority() {
        // Act
        let priority = templateManager.templatePriority(for: "nonExistent")
        
        // Assert
        XCTAssertEqual(priority, 5) // Default priority
    }
    
    // MARK: - Available Levels Tests
    
    func testAvailableLevels_ForMultiLevelCategory_ShouldReturnAllLevels() {
        // Act
        let levels = templateManager.availableLevels(for: "vocabularyLevels")
        
        // Assert
        XCTAssertTrue(levels.contains("beginner"))
        XCTAssertTrue(levels.contains("intermediate"))
        XCTAssertTrue(levels.contains("advanced"))
        XCTAssertEqual(levels.count, 3)
    }
    
    func testAvailableLevels_ForSingleLevelCategory_ShouldReturnEmptyArray() {
        // Act
        let levels = templateManager.availableLevels(for: "storyStructure")
        
        // Assert
        XCTAssertTrue(levels.isEmpty)
    }
    
    // MARK: - Convenience Methods Tests
    
    func testTextFreeEnforcement_WithCriticalLevel_ShouldReturnStrictTemplate() {
        // Act
        let template = templateManager.textFreeEnforcement(level: .critical)
        
        // Assert
        XCTAssertTrue(template.contains("ABSOLUTE TEXT PROHIBITION"))
        XCTAssertTrue(template.contains("ZERO TOLERANCE"))
    }
    
    func testTextFreeEnforcement_WithModerateLevel_ShouldReturnGentleTemplate() {
        // Act
        let template = templateManager.textFreeEnforcement(level: .moderate)
        
        // Assert
        XCTAssertTrue(template.contains("Please avoid"))
        XCTAssertFalse(template.contains("ABSOLUTE"))
    }
    
    func testVocabularyGuideline_WithStandardLevel_ShouldReturnIntermediateTemplate() {
        // Act
        let template = templateManager.vocabularyGuideline(for: .standard)
        
        // Assert
        XCTAssertTrue(template.contains("mix of familiar"))
    }
    
    func testVocabularyGuideline_WithEnhancedLevel_ShouldIncludeTargetWords() {
        // Act
        let template = templateManager.vocabularyGuideline(for: .enhanced(targetWords: 4))
        
        // Assert
        XCTAssertTrue(template.contains("4 new vocabulary words"))
    }
    
    func testNarrativeGuideline_WithDifferentAges_ShouldReturnAppropriateLevel() {
        // Act
        let youngerTemplate = templateManager.narrativeGuideline(for: 3)
        let middleTemplate = templateManager.narrativeGuideline(for: 6)
        let olderTemplate = templateManager.narrativeGuideline(for: 9)
        
        // Assert
        XCTAssertTrue(youngerTemplate.contains("linear story"))
        XCTAssertTrue(middleTemplate.contains("minor subplots"))
        XCTAssertTrue(olderTemplate.contains("multiple story layers"))
    }
    
    func testEmotionalThemes_WithMultipleThemes_ShouldFormatCorrectly() {
        // Arrange
        let themes = ["happiness", "friendship", "courage"]
        
        // Act
        let template = templateManager.emotionalThemes(themes)
        
        // Assert
        XCTAssertTrue(template.contains("- happiness"))
        XCTAssertTrue(template.contains("- friendship"))
        XCTAssertTrue(template.contains("- courage"))
    }
    
    func testDevelopmentalFocus_WithCategories_ShouldFormatCorrectly() {
        // Arrange
        let categories: [GrowthCategory] = [.emotionalIntelligence, .creativityImagination]
        
        // Act
        let template = templateManager.developmentalFocus(categories)
        
        // Assert
        XCTAssertTrue(template.contains("Emotional Intelligence"))
        XCTAssertTrue(template.contains("Creativity & Imagination"))
        XCTAssertTrue(template.contains("promote this skill"))
    }
    
    func testVariabilityGuidelines_WithSeed_ShouldIncludeSeed() {
        // Arrange
        let seed = "unique-story-seed-123"
        
        // Act
        let template = templateManager.variabilityGuidelines(seed: seed)
        
        // Assert
        XCTAssertTrue(template.contains(seed))
        XCTAssertTrue(template.contains("unique"))
        XCTAssertTrue(template.contains("creative"))
    }
    
    // MARK: - Configuration Tests
    
    func testReloadConfiguration_ShouldSucceed() {
        // Act & Assert (should not crash)
        templateManager.reloadConfiguration()
    }
    
    func testDebugInfo_ShouldReturnConfigurationInfo() {
        // Act
        let debugInfo = templateManager.debugInfo()
        
        // Assert
        XCTAssertFalse(debugInfo.isEmpty)
        XCTAssertTrue(debugInfo.contains("Configuration Version"))
        XCTAssertTrue(debugInfo.contains("Available Categories"))
    }
    
    // MARK: - A/B Testing Tests
    
    func testABTestAssignment_ShouldReturnAssignment() {
        // Act
        let assignment = templateManager.getABTestAssignment(for: "textFreeEnforcement")
        
        // Assert
        // Assignment could be nil if no A/B test is configured, or a string if configured
        if let assignment = assignment {
            XCTAssertTrue(["critical", "moderate"].contains(assignment))
        }
    }
    
    // MARK: - Metrics Tests
    
    func testLogTemplateUsage_ShouldNotCrash() {
        // Act & Assert (should not crash)
        templateManager.logTemplateUsage(category: "textFreeEnforcement", level: "critical", success: true)
        templateManager.logTemplateUsage(category: "vocabularyLevels", level: "beginner", success: false)
    }
    
    // MARK: - Performance Tests
    
    func testTemplateAccess_WithManyRequests_ShouldBeEfficient() {
        // Arrange
        let categories = ["textFreeEnforcement", "vocabularyLevels", "narrativeGuidelines", "storyStructure"]
        let levels = ["critical", "moderate", "beginner", "intermediate", "advanced"]
        
        // Act & Assert
        measure {
            for _ in 0..<1000 {
                let category = categories.randomElement()!
                let level = levels.randomElement()!
                let _ = templateManager.template(for: category, level: level)
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testTemplateWithFluentBuilder_ShouldWork() {
        // Arrange
        let builder = FluentPromptBuilder()
        let templates = ConfigurablePromptTemplates.shared
        
        // Act
        let prompt = builder
            .story(theme: "Adventure", age: 6)
            .build()
        
        let textFreeTemplate = templates.textFreeEnforcement(level: .critical)
        
        // Assert
        XCTAssertFalse(prompt.isEmpty)
        XCTAssertFalse(textFreeTemplate.isEmpty)
        // Templates should be compatible with builder output
        XCTAssertTrue(textFreeTemplate.contains("NO TEXT"))
    }
}