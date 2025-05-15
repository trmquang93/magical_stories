import Testing
@testable import magical_stories
import Foundation

@Suite("Visual Guide Tests")
struct VisualGuideTests {
    
    @Test("Visual Guide initialization should store all provided values correctly")
    func testVisualGuideInitialization() {
        // Arrange
        let styleGuide = "Colorful watercolor style with soft edges and warm lighting"
        let characterDefinitions = [
            "Luna": "A 6-year-old girl with curly brown hair, bright blue eyes, and freckles. She wears a yellow sunflower dress with red sneakers and carries a small purple backpack.",
            "Whiskers": "A fluffy white cat with orange patches, green eyes, and a blue collar with a gold tag."
        ]
        let settingDefinitions = [
            "Enchanted Forest": "A lush green forest with tall oak trees, colorful mushrooms, and a winding dirt path. Rays of golden sunlight filter through the leaves creating a magical atmosphere.",
            "Luna's Bedroom": "A cozy room with light blue walls, a bed with star-patterned sheets, bookshelves filled with colorful books, and a window overlooking a garden."
        ]
        
        // Act
        let visualGuide = VisualGuide(
            styleGuide: styleGuide,
            characterDefinitions: characterDefinitions,
            settingDefinitions: settingDefinitions
        )
        
        // Assert
        #expect(visualGuide.styleGuide == styleGuide)
        #expect(visualGuide.characterDefinitions == characterDefinitions)
        #expect(visualGuide.settingDefinitions == settingDefinitions)
    }
    
    @Test("Visual Guide formattedForPrompt should format all information properly")
    func testFormattedForPrompt() {
        // Arrange
        let styleGuide = "Watercolor style"
        let characterDefinitions = ["Hero": "Tall with blue eyes"]
        let settingDefinitions = ["Castle": "Stone fortress on a hill"]
        
        let visualGuide = VisualGuide(
            styleGuide: styleGuide,
            characterDefinitions: characterDefinitions,
            settingDefinitions: settingDefinitions
        )
        
        // Act
        let formattedGuide = visualGuide.formattedForPrompt()
        
        // Assert
        #expect(formattedGuide.contains("STYLE GUIDE: Watercolor style"))
        #expect(formattedGuide.contains("CHARACTER - Hero: Tall with blue eyes"))
        #expect(formattedGuide.contains("SETTING - Castle: Stone fortress on a hill"))
    }
    
    @Test("Visual Guide formattedForPrompt should handle empty collections")
    func testFormattedForPromptWithEmptyCollections() {
        // Arrange
        let styleGuide = "Watercolor style"
        let visualGuide = VisualGuide(
            styleGuide: styleGuide,
            characterDefinitions: [:],
            settingDefinitions: [:]
        )
        
        // Act
        let formattedGuide = visualGuide.formattedForPrompt()
        
        // Assert
        #expect(formattedGuide.contains("STYLE GUIDE: Watercolor style"))
        #expect(!formattedGuide.contains("CHARACTER"))
        #expect(!formattedGuide.contains("SETTING"))
    }
}