import Foundation

/// A model that structures visual consistency information for illustrations.
public struct VisualGuide: Equatable, Codable, Sendable {
    /// Initialize a new VisualGuide with the given properties
    public init(
        styleGuide: String,
        characterDefinitions: [String: String],
        settingDefinitions: [String: String],
        globalReferenceImageURL: URL? = nil
    ) {
        self.styleGuide = styleGuide
        self.characterDefinitions = characterDefinitions
        self.settingDefinitions = settingDefinitions
        self.globalReferenceImageURL = globalReferenceImageURL
    }
    
    /// The overall artistic style of the illustrations
    public let styleGuide: String
    
    /// Dictionary mapping visual element names to their detailed descriptions
    /// This includes characters, toys, objects, and any key visual elements that need consistency
    /// Example: ["Emma": "young girl with curly red hair", "Magic Wand": "golden wand with star tip", "Dragon": "friendly green dragon"]
    public let characterDefinitions: [String: String]
    
    /// Dictionary mapping setting names to their detailed visual descriptions
    public let settingDefinitions: [String: String]
    
    /// URL pointing to the global reference image for this story's illustrations
    public let globalReferenceImageURL: URL?
    
    /// Creates a new VisualGuide with an updated global reference image URL
    public func withGlobalReferenceImageURL(_ url: URL) -> VisualGuide {
        return VisualGuide(
            styleGuide: self.styleGuide,
            characterDefinitions: self.characterDefinitions,
            settingDefinitions: self.settingDefinitions,
            globalReferenceImageURL: url
        )
    }
    
    /// Format the visual guide information for inclusion in an illustration prompt
    public func formattedForPrompt() -> String {
        var components = [String]()
        
        // Add critical text-free requirement at the top
        components.append("🚫 ABSOLUTELY NO TEXT ALLOWED IN ILLUSTRATION 🚫")
        components.append("‼️ CRITICAL: This illustration must be COMPLETELY TEXT-FREE ‼️")
        components.append("")
        
        // Add style guide
        components.append("STYLE GUIDE: \(styleGuide)")
        
        // Add visual element definitions if available
        if !characterDefinitions.isEmpty {
            components.append("\nVISUAL ELEMENTS:")
            for (name, definition) in characterDefinitions {
                components.append("ELEMENT - \(name): \(definition)")
            }
        }
        
        // Add setting definitions if available
        if !settingDefinitions.isEmpty {
            components.append("\nSETTINGS:")
            for (name, definition) in settingDefinitions {
                components.append("SETTING - \(name): \(definition)")
            }
        }
        
        // Add text-free enforcement at the bottom
        components.append("")
        components.append("🚫 FORBIDDEN ELEMENTS - NEVER INCLUDE:")
        components.append("❌ NO text of any kind")
        components.append("❌ NO words or letters") 
        components.append("❌ NO captions or labels")
        components.append("❌ NO speech bubbles or dialogue")
        components.append("❌ NO written signs or text elements")
        components.append("❌ NO story text overlay")
        components.append("")
        components.append("✅ Focus ONLY on visual storytelling without ANY written words")
        components.append("✅ The app displays story text separately below the image")
        
        return components.joined(separator: "\n")
    }
    
    // MARK: - Visual Element Management
    
    /// Gets all visual element names in the order they were defined
    public var visualElementNames: [String] {
        // Return sorted keys of characterDefinitions to maintain consistent order
        return Array(characterDefinitions.keys.sorted())
    }
    
    /// Creates descriptive mapping text for visual elements in master reference
    /// Format: "{element_name} is {detailed_description} in the reference image"
    /// - Parameter orderedNames: Optional array to specify element order
    /// - Returns: Array of descriptive mapping strings
    public func createDescriptiveMapping(orderedNames: [String]? = nil) -> [String] {
        let names = orderedNames ?? visualElementNames
        return names.compactMap { name in
            guard let description = characterDefinitions[name] else { return nil }
            return "\(name) is \(description) in the reference image"
        }
    }
    
    /// Creates a single descriptive mapping string for use in prompts
    /// - Parameter orderedNames: Optional array to specify element order
    /// - Returns: Combined descriptive mapping text
    public func descriptiveMappingText(orderedNames: [String]? = nil) -> String {
        let mappings = createDescriptiveMapping(orderedNames: orderedNames)
        return mappings.joined(separator: "\n")
    }
}