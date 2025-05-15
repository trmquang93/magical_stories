import Foundation

/// A model that structures visual consistency information for illustrations.
public struct VisualGuide: Equatable, Codable {
    /// Initialize a new VisualGuide with the given properties
    public init(styleGuide: String, characterDefinitions: [String: String], settingDefinitions: [String: String]) {
        self.styleGuide = styleGuide
        self.characterDefinitions = characterDefinitions
        self.settingDefinitions = settingDefinitions
    }
    /// The overall artistic style of the illustrations
    public let styleGuide: String
    
    /// Dictionary mapping character names to their detailed visual descriptions
    public let characterDefinitions: [String: String]
    
    /// Dictionary mapping setting names to their detailed visual descriptions
    public let settingDefinitions: [String: String]
    
    /// Format the visual guide information for inclusion in an illustration prompt
    public func formattedForPrompt() -> String {
        var components = [String]()
        
        // Add style guide
        components.append("STYLE GUIDE: \(styleGuide)")
        
        // Add character definitions if available
        if !characterDefinitions.isEmpty {
            components.append("\nCHARACTERS:")
            for (name, definition) in characterDefinitions {
                components.append("CHARACTER - \(name): \(definition)")
            }
        }
        
        // Add setting definitions if available
        if !settingDefinitions.isEmpty {
            components.append("\nSETTINGS:")
            for (name, definition) in settingDefinitions {
                components.append("SETTING - \(name): \(definition)")
            }
        }
        
        return components.joined(separator: "\n")
    }
}