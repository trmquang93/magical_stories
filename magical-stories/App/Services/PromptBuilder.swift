import Foundation

/// A service responsible for constructing AI prompts that generate age-appropriate, engaging stories
class PromptBuilder {
    
    // MARK: - Constants
    
    private enum VocabularyLevel {
        case beginner // Ages 3-4
        case intermediate // Ages 5-7
        case advanced // Ages 8+
        
        static func forAge(_ age: Int) -> VocabularyLevel {
            switch age {
            case ..<5: return .beginner
            case 5...7: return .intermediate
            default: return .advanced
            }
        }
        
        var vocabularyGuideline: String {
            switch self {
            case .beginner:
                return "Use simple, concrete words and short sentences. Repeat key words. Avoid complex tenses."
            case .intermediate:
                return "Use a mix of familiar and new vocabulary. Include some compound sentences. Introduce metaphors sparingly."
            case .advanced:
                return "Use rich vocabulary including some challenging words (with context clues). Vary sentence structure. Include figurative language."
            }
        }
        
        var narrativeGuideline: String {
            switch self {
            case .beginner:
                return "Create a linear story with clear cause-and-effect. Use repetitive patterns. Include simple emotional reactions."
            case .intermediate:
                return "Include minor subplots. Show character motivations. Include problem-solving sequences. Balance action and reflection."
            case .advanced:
                return "Develop multiple story layers. Include character growth. Explore complex emotions. Use foreshadowing."
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Builds a complete prompt for story generation based on the provided parameters
    func buildPrompt(parameters: StoryParameters) -> String {
        let vocabularyLevel = VocabularyLevel.forAge(parameters.childAge)
        
        // Create a unique randomization seed based on current timestamp
        let uniqueSeed = "\(Date().timeIntervalSince1970)"
        
        var promptComponents = [
            basePrompt(parameters: parameters),
            "\nVocabulary Guidelines:",
            vocabularyLevel.vocabularyGuideline,
            "\nNarrative Guidelines:",
            vocabularyLevel.narrativeGuideline,
            storyStructureGuidelines(),
            formatGuidelines(),
            variabilityGuidelines(seed: uniqueSeed)
        ]
        
        // Add developmental focus if specified
        if let focus = parameters.developmentalFocus, !focus.isEmpty {
            promptComponents.append(developmentalGuidelines(categories: focus))
        }
        
        // Add emotional themes if specified
        if let emotions = parameters.emotionalThemes, !emotions.isEmpty {
            promptComponents.append(emotionalGuidelines(themes: emotions))
        }
        
        return promptComponents.joined(separator: "\n\n")
    }
    
    // MARK: - Private Methods
    
    private func basePrompt(parameters: StoryParameters) -> String {
        return """
        Create an engaging children's story with the following requirements:
        - Main character name: \(parameters.childName)
        - Age group: \(parameters.childAge) years old
        - Theme: \(parameters.theme)
        - Include this character: \(parameters.favoriteCharacter)
        - Story length: \(parameters.storyLength ?? "medium (3-4 pages)")
        
        The story should be educational, entertaining, and appropriate for the child's age.
        """
    }
    
    private func storyStructureGuidelines() -> String {
        return """
        Story Structure Requirements:
        - Start with "Title: [Your Story Title]" on the first line
        - Follow with the story content
        - Divide the story into clear, logical segments that can be split into pages
        - Each segment should be 2-3 paragraphs
        - Include natural page breaks where illustrations could enhance the story
        - End with a clear resolution that reinforces the story's theme
        """
    }
    
    private func formatGuidelines() -> String {
        return """
        Format Requirements:
        - Use clear paragraph breaks
        - Keep paragraphs concise (2-4 sentences)
        - Include dialogue when appropriate
        - Use descriptive language that creates vivid mental images
        - Maintain consistent tense throughout
        """
    }
    
    private func developmentalGuidelines(categories: [GrowthCategory]) -> String {
        let categoryDescriptions = categories.map { "- \($0.rawValue): Include elements that promote this skill" }
        return """
        Developmental Focus:
        Incorporate opportunities for learning and growth in these areas:
        \(categoryDescriptions.joined(separator: "\n"))
        """
    }
    
    private func emotionalGuidelines(themes: [String]) -> String {
        return """
        Emotional Elements:
        Include appropriate exploration of these emotions/themes:
        \(themes.map { "- \($0)" }.joined(separator: "\n"))
        """
    }
    
    private func variabilityGuidelines(seed: String) -> String {
        // Generate random plot elements to incorporate
        let plotElements = [
            "unexpected treasure", "magical creature", "hidden doorway", 
            "mysterious letter", "talking animal", "secret power",
            "ancient map", "time travel", "underwater adventure",
            "flying adventure", "lost item", "new friend",
            "family secret", "special celebration", "weather event",
            "curious invention", "garden discovery", "night adventure"
        ]
        
        // Randomly select 2-3 plot elements
        let numElements = Int.random(in: 2...3)
        var selectedElements: [String] = []
        
        for _ in 0..<numElements {
            if let element = plotElements.randomElement(), !selectedElements.contains(element) {
                selectedElements.append(element)
            }
        }
        
        // Generate random settings
        let settings = [
            "enchanted forest", "bustling city", "quiet village",
            "outer space", "underwater kingdom", "mountain top",
            "desert oasis", "tropical island", "snowy tundra",
            "jungle", "farm", "castle", "schoolyard",
            "grandparent's house", "museum", "zoo",
            "amusement park", "library", "beach"
        ]
        
        // Select a random setting
        let setting = settings.randomElement() ?? "magical world"
        
        return """
        Variability Guidelines:
        - Create a completely unique and original story different from any previously generated stories.
        - Set this story in a "\(setting)" environment.
        - Incorporate these random elements: \(selectedElements.joined(separator: ", ")).
        - Use diverse supporting characters with unique personalities.
        - Include unexpected twists or challenges for the main character.
        - This story MUST be completely unique and not similar to previous generations.
        - Unique story identifier: \(seed)
        - Upon receiving this prompt, create a NEW, UNIQUE story different from ANY other story you've generated before.
        """
    }
}