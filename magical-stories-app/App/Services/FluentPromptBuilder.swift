import Foundation

// MARK: - Supporting Types

public enum VocabularyLevel {
    case standard
    case enhanced(targetWords: Int)
}

public enum TextFreeLevel {
    case moderate
    case critical
}

public enum PromptValidationError: Error, Equatable {
    case missingRequiredComponent(String)
    case invalidAge(Int)
    case invalidTheme(String)
}

/// A fluent, type-safe builder for creating AI prompts with composable components
public class FluentPromptBuilder {
    private var components: [PromptComponent] = []
    private var storyComponent: StoryComponent?
    private let templateManager: ConfigurablePromptTemplates
    
    public init(templateManager: ConfigurablePromptTemplates = ConfigurablePromptTemplates.shared) {
        self.templateManager = templateManager
    }
    
    // MARK: - Core Story Configuration
    
    @discardableResult
    public func story(theme: String, age: Int) -> FluentPromptBuilder {
        storyComponent = StoryComponent(theme: theme, age: age)
        return self
    }
    
    @discardableResult
    public func character(name: String, favoriteCharacter: String? = nil) -> FluentPromptBuilder {
        components.removeAll { $0 is CharacterComponent }
        components.append(CharacterComponent(name: name, favoriteCharacter: favoriteCharacter))
        return self
    }
    
    // MARK: - Vocabulary and Language
    
    @discardableResult
    public func vocabulary(_ level: VocabularyLevel) -> FluentPromptBuilder {
        components.removeAll { $0 is VocabularyComponent }
        components.append(VocabularyComponent(level: level))
        return self
    }
    
    // MARK: - Visual Requirements
    
    @discardableResult
    public func textFree(_ level: TextFreeLevel) -> FluentPromptBuilder {
        components.removeAll { $0 is TextFreeComponent }
        components.append(TextFreeComponent(level: level, templateManager: templateManager))
        return self
    }
    
    @discardableResult
    public func visualGuide(characters: [String: String], settings: [String: String] = [:]) -> FluentPromptBuilder {
        components.removeAll { $0 is VisualGuideComponent }
        components.append(VisualGuideComponent(characters: characters, settings: settings))
        return self
    }
    
    // MARK: - Interactive Elements
    
    @discardableResult
    public func interactive(prompts: Int) -> FluentPromptBuilder {
        components.removeAll { $0 is InteractiveComponent }
        components.append(InteractiveComponent(promptCount: prompts))
        return self
    }
    
    // MARK: - Developmental and Emotional
    
    @discardableResult
    public func emotionalThemes(_ themes: [String]) -> FluentPromptBuilder {
        components.removeAll { $0 is EmotionalComponent }
        components.append(EmotionalComponent(themes: themes))
        return self
    }
    
    @discardableResult
    public func developmentalFocus(_ categories: [GrowthCategory]) -> FluentPromptBuilder {
        components.removeAll { $0 is DevelopmentalComponent }
        components.append(DevelopmentalComponent(categories: categories))
        return self
    }
    
    // MARK: - Build Methods
    
    public func build() -> String {
        do {
            return try buildValidated()
        } catch {
            // Fallback to basic prompt if validation fails
            return buildBasicPrompt()
        }
    }
    
    public func buildValidated() throws -> String {
        try validateComponents()
        return assemblePrompt()
    }
    
    // MARK: - Private Implementation
    
    private func validateComponents() throws {
        guard let story = storyComponent else {
            throw PromptValidationError.missingRequiredComponent("story")
        }
        
        guard story.age > 0 && story.age <= 18 else {
            throw PromptValidationError.invalidAge(story.age)
        }
        
        guard !story.theme.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PromptValidationError.invalidTheme(story.theme)
        }
    }
    
    private func assemblePrompt() -> String {
        var promptParts: [String] = []
        
        // Always start with story component
        if let story = storyComponent {
            promptParts.append(story.render())
        }
        
        // Add other components in logical order
        let orderedComponents = components.sorted { $0.priority < $1.priority }
        for component in orderedComponents {
            promptParts.append(component.render())
        }
        
        return promptParts.joined(separator: "\n\n")
    }
    
    private func buildBasicPrompt() -> String {
        guard let story = storyComponent else {
            return "Create an engaging children's story."
        }
        
        return """
        Create an engaging children's story with the following requirements:
        - Theme: \(story.theme)
        - Age group: \(story.age) years old
        
        The story should be educational, entertaining, and appropriate for the child's age.
        """
    }
}

// MARK: - Component Protocol and Implementations

protocol PromptComponent {
    var priority: Int { get }
    func render() -> String
}

struct StoryComponent {
    let theme: String
    let age: Int
    
    func render() -> String {
        return """
        Create an engaging children's story with the following requirements:
        - Age group: \(age) years old
        - Theme: \(theme)
        """
    }
}

struct CharacterComponent: PromptComponent {
    let priority = 1
    let name: String
    let favoriteCharacter: String?
    
    func render() -> String {
        var parts = ["- Main character name: \(name)"]
        
        if let favorite = favoriteCharacter {
            parts.append("- Include this character: \(favorite)")
        }
        
        return parts.joined(separator: "\n")
    }
}

struct VocabularyComponent: PromptComponent {
    let priority = 2
    let level: VocabularyLevel
    
    func render() -> String {
        switch level {
        case .standard:
            return """
            Vocabulary Guidelines:
            Use age-appropriate vocabulary with clear, simple language.
            """
        case .enhanced(let targetWords):
            return """
            Vocabulary Guidelines:
            Include \(targetWords) new vocabulary words that are slightly above the child's typical level.
            Provide context clues or explanations to make meanings clear.
            Repeat new words 2-3 times throughout the story for reinforcement.
            """
        }
    }
}

struct TextFreeComponent: PromptComponent {
    let level: TextFreeLevel
    let templateManager: ConfigurablePromptTemplates
    
    var priority: Int {
        return templateManager.templatePriority(for: "textFreeEnforcement", level: level == .critical ? "critical" : "moderate")
    }
    
    func render() -> String {
        return templateManager.textFreeEnforcement(level: level)
    }
}

struct VisualGuideComponent: PromptComponent {
    let priority = 4
    let characters: [String: String]
    let settings: [String: String]
    
    func render() -> String {
        var parts: [String] = []
        
        if !characters.isEmpty {
            parts.append("Character Definitions:")
            for (name, description) in characters {
                parts.append("- \(name): \(description)")
            }
        }
        
        if !settings.isEmpty {
            parts.append("Setting Definitions:")
            for (name, description) in settings {
                parts.append("- \(name): \(description)")
            }
        }
        
        return parts.joined(separator: "\n")
    }
}

struct InteractiveComponent: PromptComponent {
    let priority = 5
    let promptCount: Int
    
    func render() -> String {
        return """
        Interactive Elements:
        - Include \(promptCount) moments where the reader is prompted to participate
        - Examples: "Can you spot the [object]?", "What do you think happens next?"
        - Place interactive prompts at natural points in the narrative
        - Design prompts to reinforce the story's theme or moral
        """
    }
}

struct EmotionalComponent: PromptComponent {
    let priority = 6
    let themes: [String]
    
    func render() -> String {
        return """
        Emotional Elements:
        Include appropriate exploration of these emotions/themes:
        \(themes.map { "- \($0)" }.joined(separator: "\n"))
        """
    }
}

struct DevelopmentalComponent: PromptComponent {
    let priority = 7
    let categories: [GrowthCategory]
    
    func render() -> String {
        let categoryDescriptions = categories.map {
            "- \($0.rawValue): Include elements that promote this skill"
        }
        return """
        Developmental Focus:
        Incorporate opportunities for learning and growth in these areas:
        \(categoryDescriptions.joined(separator: "\n"))
        """
    }
}