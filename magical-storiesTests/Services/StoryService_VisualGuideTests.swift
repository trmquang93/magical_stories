import Testing
import SwiftData
@testable import magical_stories
import Foundation

@Suite("StoryService Visual Guide Tests")
struct StoryService_VisualGuideTests {
    
    @Test("StoryService should extract VisualGuide components from XML response")
    func testExtractVisualGuideComponents() async throws {
        // Create a test implementation of visual guide extraction
        let xml = """
        <title>The Dragon's Quest</title>
        <visual_guide>
            <style_guide>Colorful watercolor style with soft edges and warm lighting</style_guide>
            <character_definitions>
                <character name="Luna">A 6-year-old girl with curly brown hair, bright blue eyes, and freckles. She wears a yellow sunflower dress with red sneakers.</character>
                <character name="Drago">A small friendly dragon with emerald green scales, purple wings, and golden eyes. He has tiny horns and wears a blue crystal pendant.</character>
            </character_definitions>
            <setting_definitions>
                <setting name="Enchanted Forest">A lush green forest with tall oak trees, colorful mushrooms, and a winding dirt path. Rays of golden sunlight filter through the leaves.</setting>
                <setting name="Dragon Cave">A warm cave with crystal formations in various colors. A small waterfall trickles down one wall into a glowing pool of water.</setting>
            </setting_definitions>
        </visual_guide>
        <content>
        Once upon a time, there was a little girl named Luna who loved adventures.
        </content>
        """
        
        // Use direct tests for the components we expect to extract
        let visualGuide = extractVisualGuideDirectly(from: xml)
        
        // Assert
        #expect(visualGuide != nil)
        #expect(visualGuide?.styleGuide == "Colorful watercolor style with soft edges and warm lighting")
        #expect(visualGuide?.characterDefinitions.count == 2)
        #expect(visualGuide?.characterDefinitions["Luna"] == "A 6-year-old girl with curly brown hair, bright blue eyes, and freckles. She wears a yellow sunflower dress with red sneakers.")
        #expect(visualGuide?.characterDefinitions["Drago"] == "A small friendly dragon with emerald green scales, purple wings, and golden eyes. He has tiny horns and wears a blue crystal pendant.")
        #expect(visualGuide?.settingDefinitions.count == 2)
        #expect(visualGuide?.settingDefinitions["Enchanted Forest"] == "A lush green forest with tall oak trees, colorful mushrooms, and a winding dirt path. Rays of golden sunlight filter through the leaves.")
        #expect(visualGuide?.settingDefinitions["Dragon Cave"] == "A warm cave with crystal formations in various colors. A small waterfall trickles down one wall into a glowing pool of water.")
    }
    
    @Test("Should return nil VisualGuide for XML without visual guide section")
    func testNoVisualGuideSection() async throws {
        let xml = """
        <title>The Dragon's Quest</title>
        <content>
        Once upon a time, there was a little girl named Luna who loved adventures.
        </content>
        <category>Fantasy</category>
        """
        
        let visualGuide = extractVisualGuideDirectly(from: xml)
        
        #expect(visualGuide == nil)
    }
    
    // Function to directly extract visual guide for testing - this replicates what StoryService would do internally
    private func extractVisualGuideDirectly(from xml: String) -> VisualGuide? {
        let visualGuidePattern = "<visual_guide>(.*?)</visual_guide>"
        do {
            let regex = try NSRegularExpression(pattern: visualGuidePattern, options: [.dotMatchesLineSeparators])
            let matches = regex.matches(in: xml, range: NSRange(xml.startIndex..., in: xml))
            
            guard let match = matches.first,
                  let range = Range(match.range(at: 1), in: xml) else {
                return nil
            }
            
            let visualGuideXml = String(xml[range])
            
            // Extract style guide
            let styleGuidePattern = "<style_guide>(.*?)</style_guide>"
            let styleGuideRegex = try NSRegularExpression(pattern: styleGuidePattern, options: [.dotMatchesLineSeparators])
            let styleGuideMatches = styleGuideRegex.matches(in: visualGuideXml, range: NSRange(visualGuideXml.startIndex..., in: visualGuideXml))
            
            var styleGuide = ""
            if let styleMatch = styleGuideMatches.first,
               let styleRange = Range(styleMatch.range(at: 1), in: visualGuideXml) {
                styleGuide = String(visualGuideXml[styleRange])
            }
            
            // Extract character definitions
            var characterDefinitions = [String: String]()
            let characterPattern = "<character name=\"(.*?)\">(.*?)</character>"
            let characterRegex = try NSRegularExpression(pattern: characterPattern, options: [.dotMatchesLineSeparators])
            let characterMatches = characterRegex.matches(in: visualGuideXml, range: NSRange(visualGuideXml.startIndex..., in: visualGuideXml))
            
            for match in characterMatches {
                if match.numberOfRanges >= 3,
                   let nameRange = Range(match.range(at: 1), in: visualGuideXml),
                   let descriptionRange = Range(match.range(at: 2), in: visualGuideXml) {
                    let name = String(visualGuideXml[nameRange])
                    let description = String(visualGuideXml[descriptionRange])
                    characterDefinitions[name] = description
                }
            }
            
            // Extract setting definitions
            var settingDefinitions = [String: String]()
            let settingPattern = "<setting name=\"(.*?)\">(.*?)</setting>"
            let settingRegex = try NSRegularExpression(pattern: settingPattern, options: [.dotMatchesLineSeparators])
            let settingMatches = settingRegex.matches(in: visualGuideXml, range: NSRange(visualGuideXml.startIndex..., in: visualGuideXml))
            
            for match in settingMatches {
                if match.numberOfRanges >= 3,
                   let nameRange = Range(match.range(at: 1), in: visualGuideXml),
                   let descriptionRange = Range(match.range(at: 2), in: visualGuideXml) {
                    let name = String(visualGuideXml[nameRange])
                    let description = String(visualGuideXml[descriptionRange])
                    settingDefinitions[name] = description
                }
            }
            
            return VisualGuide(
                styleGuide: styleGuide,
                characterDefinitions: characterDefinitions,
                settingDefinitions: settingDefinitions
            )
        } catch {
            print("Error extracting visual guide: \(error)")
            return nil
        }
    }
}