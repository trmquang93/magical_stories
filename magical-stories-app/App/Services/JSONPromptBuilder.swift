import Foundation

// MARK: - JSON Prompt Configuration Models (Embedded for compilation)

/// Core structure for AI illustration prompts using JSON format
public struct IllustrationPrompt: Codable {
    let taskDefinition: TaskDefinition
    let visualRequirements: VisualRequirements
    let constraints: ConstraintSet
    let qualityStandards: QualityStandards
    
    public init(taskDefinition: TaskDefinition, visualRequirements: VisualRequirements, constraints: ConstraintSet, qualityStandards: QualityStandards) {
        self.taskDefinition = taskDefinition
        self.visualRequirements = visualRequirements
        self.constraints = constraints
        self.qualityStandards = qualityStandards
    }
}

/// Defines the primary task and objective for the AI
public struct TaskDefinition: Codable {
    let objective: String
    let type: IllustrationType
    let context: String?
    
    public init(objective: String, type: IllustrationType, context: String? = nil) {
        self.objective = objective
        self.type = type
        self.context = context
    }
}

/// Type of illustration being generated
public enum IllustrationType: String, Codable {
    case storyPage = "story_page"
    case masterReference = "master_reference"
}

/// Visual elements and style requirements
public struct VisualRequirements: Codable {
    let styleGuide: String
    let elements: [VisualElement]
    let settings: [VisualSetting]?
    let layout: LayoutRequirements
    
    public init(styleGuide: String, elements: [VisualElement], settings: [VisualSetting]? = nil, layout: LayoutRequirements) {
        self.styleGuide = styleGuide
        self.elements = elements
        self.settings = settings
        self.layout = layout
    }
}

/// Individual visual element definition
public struct VisualElement: Codable {
    let name: String
    let description: String
    let required: Bool
    let occurrenceLimit: Int
    
    public init(name: String, description: String, required: Bool = true, occurrenceLimit: Int = 1) {
        self.name = name
        self.description = description
        self.required = required
        self.occurrenceLimit = occurrenceLimit
    }
}

/// Setting or environment definition
public struct VisualSetting: Codable {
    let name: String
    let description: String
    
    public init(name: String, description: String) {
        self.name = name
        self.description = description
    }
}

/// Layout and arrangement requirements
public struct LayoutRequirements: Codable {
    let arrangement: String
    let aspectRatio: String?
    let composition: String?
    
    public init(arrangement: String, aspectRatio: String? = nil, composition: String? = nil) {
        self.arrangement = arrangement
        self.aspectRatio = aspectRatio
        self.composition = composition
    }
}

/// Constraints and prohibitions
public struct ConstraintSet: Codable {
    let antiDuplication: AntiDuplicationRules
    let prohibitions: [String]
    let technical: TechnicalConstraints
    
    public init(antiDuplication: AntiDuplicationRules, prohibitions: [String], technical: TechnicalConstraints) {
        self.antiDuplication = antiDuplication
        self.prohibitions = prohibitions
        self.technical = technical
    }
}

/// Specific rules to prevent element duplication
public struct AntiDuplicationRules: Codable {
    let enforceSingleOccurrence: Bool
    let verificationInstructions: [String]
    let penaltyWarnings: [String]
    
    public init(enforceSingleOccurrence: Bool = true, verificationInstructions: [String], penaltyWarnings: [String]) {
        self.enforceSingleOccurrence = enforceSingleOccurrence
        self.verificationInstructions = verificationInstructions
        self.penaltyWarnings = penaltyWarnings
    }
}

/// Technical specifications and constraints
public struct TechnicalConstraints: Codable {
    let imageFormat: String?
    let dimensions: String?
    let colorSpace: String?
    
    public init(imageFormat: String? = nil, dimensions: String? = nil, colorSpace: String? = nil) {
        self.imageFormat = imageFormat
        self.dimensions = dimensions
        self.colorSpace = colorSpace
    }
}

/// Quality and output standards
public struct QualityStandards: Codable {
    let artQuality: String
    let detailLevel: String
    let consistency: ConsistencyRequirements
    
    public init(artQuality: String, detailLevel: String, consistency: ConsistencyRequirements) {
        self.artQuality = artQuality
        self.detailLevel = detailLevel
        self.consistency = consistency
    }
}

/// Requirements for visual consistency
public struct ConsistencyRequirements: Codable {
    let characterAppearance: Bool
    let styleUniformity: Bool
    let referenceAdherence: String?
    
    public init(characterAppearance: Bool = true, styleUniformity: Bool = true, referenceAdherence: String? = nil) {
        self.characterAppearance = characterAppearance
        self.styleUniformity = styleUniformity
        self.referenceAdherence = referenceAdherence
    }
}

// MARK: - JSON Prompt Builder Service

/// Service for building structured JSON prompts for AI illustration generation
public final class JSONPromptBuilder {
    
    private let jsonEncoder: JSONEncoder
    
    public init() {
        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }
    
    // MARK: - Story Page Illustration Prompts
    
    /// Creates a JSON prompt for story page illustration
    /// - Parameters:
    ///   - pageContent: The story content for this page
    ///   - visualGuide: Visual guide containing style and element definitions
    ///   - masterReferenceData: Master reference image data for character consistency
    ///   - orderedElementNames: Ordered list of visual element names from the story
    /// - Returns: JSON prompt string for AI generation
    /// - Throws: Encoding error if JSON generation fails
    public func createStoryPagePrompt(
        pageContent: String,
        visualGuide: VisualGuide,
        masterReferenceData: Data?,
        orderedElementNames: [String]?
    ) throws -> String {
        
        // Create visual elements from the visual guide
        let elements = createVisualElements(from: visualGuide, orderedNames: orderedElementNames)
        
        // Create settings if available
        let settings = createVisualSettings(from: visualGuide)
        
        // Build the structured prompt
        let prompt = IllustrationPrompt(
            taskDefinition: TaskDefinition(
                objective: "Create a story illustration showing the scene described in the story content",
                type: .storyPage,
                context: pageContent
            ),
            visualRequirements: VisualRequirements(
                styleGuide: visualGuide.styleGuide,
                elements: elements,
                settings: settings.isEmpty ? nil : settings,
                layout: LayoutRequirements(
                    arrangement: "Natural storytelling composition showing the scene from the story content",
                    aspectRatio: "16:9 landscape (1024×576 pixels)",
                    composition: "Focus on the story action while maintaining character consistency"
                )
            ),
            constraints: createStoryPageConstraints(hasReference: masterReferenceData != nil),
            qualityStandards: createStoryPageQualityStandards(hasReference: masterReferenceData != nil)
        )
        
        return try convertToJSONString(prompt)
    }
    
    // MARK: - Master Reference Prompts
    
    /// Creates a JSON prompt for master reference image generation
    /// - Parameters:
    ///   - visualGuide: Visual guide containing style and element definitions
    ///   - storyTitle: Title of the story for context
    ///   - elementNames: Ordered list of visual element names
    /// - Returns: JSON prompt string for AI generation
    /// - Throws: Encoding error if JSON generation fails
    public func createMasterReferencePrompt(
        visualGuide: VisualGuide,
        storyTitle: String,
        elementNames: [String]
    ) throws -> String {
        
        // Create visual elements with strict single occurrence rules
        let elements = elementNames.compactMap { name -> VisualElement? in
            guard let description = visualGuide.characterDefinitions[name] else { return nil }
            return VisualElement(
                name: name,
                description: description,
                required: true,
                occurrenceLimit: 1
            )
        }
        
        let prompt = IllustrationPrompt(
            taskDefinition: TaskDefinition(
                objective: "Create a master reference image showing all visual elements for the story '\(storyTitle)'",
                type: .masterReference,
                context: "Organize all elements in a clear layout for future reference"
            ),
            visualRequirements: VisualRequirements(
                styleGuide: visualGuide.styleGuide,
                elements: elements,
                settings: nil,
                layout: LayoutRequirements(
                    arrangement: "Organized, clear layout allowing easy identification of each element",
                    aspectRatio: "16:9 landscape (1024×576 pixels)",
                    composition: "Use full image space efficiently with good visual balance"
                )
            ),
            constraints: createMasterReferenceConstraints(elementCount: elementNames.count),
            qualityStandards: createMasterReferenceQualityStandards()
        )
        
        return try convertToJSONString(prompt)
    }
    
    // MARK: - Private Helper Methods
    
    /// Creates visual elements from visual guide
    private func createVisualElements(from visualGuide: VisualGuide, orderedNames: [String]?) -> [VisualElement] {
        let names = orderedNames ?? Array(visualGuide.characterDefinitions.keys.sorted())
        
        return names.compactMap { name in
            guard let description = visualGuide.characterDefinitions[name] else { return nil }
            return VisualElement(
                name: name,
                description: description,
                required: false, // For story pages, elements are contextual
                occurrenceLimit: 1
            )
        }
    }
    
    /// Creates visual settings from visual guide
    private func createVisualSettings(from visualGuide: VisualGuide) -> [VisualSetting] {
        return visualGuide.settingDefinitions.map { (name, description) in
            VisualSetting(name: name, description: description)
        }
    }
    
    /// Creates constraint set for story page illustrations
    private func createStoryPageConstraints(hasReference: Bool) -> ConstraintSet {
        let antiDuplication = AntiDuplicationRules(
            enforceSingleOccurrence: true,
            verificationInstructions: [
                "Each visual element must appear exactly once in the illustration",
                "If an element appears in the scene, show it in ONE position only",
                "Verify no element is duplicated across different areas of the image"
            ],
            penaltyWarnings: [
                "CRITICAL ERROR: Duplicated elements will result in illustration rejection",
                "Each character, object, or visual element should appear only once",
                "Multiple instances of the same element are strictly forbidden"
            ]
        )
        
        var prohibitions = [
            "No text, words, letters, or numbers anywhere in the image",
            "No speech bubbles or dialogue",
            "No captions, labels, or written signs",
            "No story text overlay",
            "No duplicate visual elements",
            "No same element appearing multiple times"
        ]
        
        if hasReference {
            prohibitions.append("Characters must match the appearance shown in the reference image")
        }
        
        return ConstraintSet(
            antiDuplication: antiDuplication,
            prohibitions: prohibitions,
            technical: TechnicalConstraints(
                imageFormat: "PNG or JPEG",
                dimensions: "1024×576 pixels",
                colorSpace: "sRGB"
            )
        )
    }
    
    /// Creates constraint set for master reference images
    private func createMasterReferenceConstraints(elementCount: Int) -> ConstraintSet {
        let antiDuplication = AntiDuplicationRules(
            enforceSingleOccurrence: true,
            verificationInstructions: [
                "CRITICAL: Each visual element must appear EXACTLY ONCE in the image",
                "Every element listed must be present and unique",
                "Verify all \(elementCount) elements are shown without duplication",
                "Each element should be clearly separated and identifiable"
            ],
            penaltyWarnings: [
                "ABSOLUTE REQUIREMENT: No element duplication allowed",
                "Missing or duplicated elements will cause reference failure",
                "Each of the \(elementCount) elements must appear exactly once"
            ]
        )
        
        return ConstraintSet(
            antiDuplication: antiDuplication,
            prohibitions: [
                "NO text, labels, words, letters, or numbers anywhere",
                "NO borders, frames, or reference sheet styling",
                "NO extra elements or objects not listed",
                "NO duplicate elements",
                "NO same element appearing multiple times",
                "NO overlapping that makes elements hard to identify"
            ],
            technical: TechnicalConstraints(
                imageFormat: "PNG",
                dimensions: "1024×576 pixels",
                colorSpace: "sRGB"
            )
        )
    }
    
    /// Creates quality standards for story page illustrations
    private func createStoryPageQualityStandards(hasReference: Bool) -> QualityStandards {
        let referenceNote = hasReference ? 
            "Maintain exact character appearance consistency with master reference image" : 
            "Maintain consistent character appearance as described"
        
        return QualityStandards(
            artQuality: "High-quality digital illustration suitable for children's story",
            detailLevel: "Detailed enough for story engagement, clear and recognizable elements",
            consistency: ConsistencyRequirements(
                characterAppearance: true,
                styleUniformity: true,
                referenceAdherence: referenceNote
            )
        )
    }
    
    /// Creates quality standards for master reference images
    private func createMasterReferenceQualityStandards() -> QualityStandards {
        return QualityStandards(
            artQuality: "Clear, detailed reference quality suitable for future illustration guidance",
            detailLevel: "Sufficient detail for easy identification and description of each element",
            consistency: ConsistencyRequirements(
                characterAppearance: true,
                styleUniformity: true,
                referenceAdherence: "Establish the definitive appearance for all future illustrations"
            )
        )
    }
    
    /// Converts prompt structure to JSON string
    private func convertToJSONString(_ prompt: IllustrationPrompt) throws -> String {
        let jsonData = try jsonEncoder.encode(prompt)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw JSONPromptBuilderError.encodingFailed
        }
        
        // DEBUG: Print the final JSON for debugging purposes
        let separator = String(repeating: "=", count: 80)
        let divider = String(repeating: "-", count: 80)
        
        print("\n" + separator)
        print("🔍 [JSONPromptBuilder] GENERATED JSON PROMPT - DEBUG OUTPUT")
        print(separator)
        print("📊 JSON Length: \(jsonString.count) characters")
        print("📅 Generated at: \(Date())")
        print(divider)
        print("📋 COMPLETE JSON STRUCTURE:")
        print(divider)
        print(jsonString)
        print(divider)
        print("✅ [JSONPromptBuilder] JSON GENERATION COMPLETE")
        print(separator + "\n")
        
        return jsonString
    }
    
    // MARK: - Debug Helper Methods
    
    /// Creates a sample JSON prompt for debugging and testing purposes
    /// - Returns: Sample JSON prompt string demonstrating the structure
    public func createSamplePromptForTesting() throws -> String {
        // Create a sample visual guide
        let sampleVisualGuide = VisualGuide(
            styleGuide: "Whimsical children's book illustration style with warm colors, soft lighting, and friendly characters. Digital painting technique with gentle brushstrokes.",
            characterDefinitions: [
                "Emma": "A 7-year-old girl with curly brown hair, wearing a blue dress and red shoes, with bright green eyes and a warm smile",
                "Magic Wand": "A golden wand with a star-shaped tip that sparkles with rainbow colors",
                "Friendly Dragon": "A small, cute dragon with emerald green scales, purple wings, and kind amber eyes"
            ],
            settingDefinitions: [
                "Enchanted Garden": "A magical garden with oversized flowers, floating butterflies, and paths made of glowing stones"
            ]
        )
        
        // Create sample story page prompt
        return try createStoryPagePrompt(
            pageContent: "Emma waved her magic wand and watched as the friendly dragon appeared in the enchanted garden, ready for their next adventure together.",
            visualGuide: sampleVisualGuide,
            masterReferenceData: Data(count: 1024), // Mock data for testing
            orderedElementNames: ["Emma", "Magic Wand", "Friendly Dragon"]
        )
    }
}

// MARK: - Error Types

public enum JSONPromptBuilderError: Error, LocalizedError {
    case encodingFailed
    case invalidVisualGuide
    case missingRequiredData(String)
    
    public var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode prompt structure to JSON"
        case .invalidVisualGuide:
            return "Visual guide data is invalid or incomplete"
        case .missingRequiredData(let detail):
            return "Missing required data: \(detail)"
        }
    }
}