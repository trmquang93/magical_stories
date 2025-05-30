import Foundation

// MARK: - Configuration Models

public struct PromptTemplateConfig: Codable {
    let version: String
    let templates: [String: TemplateCategory]
    let experiments: [String: [TemplateVariant]]?
    let abTests: [String: ABTestConfig]?
}

public struct TemplateCategory: Codable {
    // For categories with multiple levels (like vocabularyLevels)
    private let templateLevels: [String: TemplateDefinition]?
    // For single templates (like storyStructure)
    private let singleTemplate: TemplateDefinition?
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        
        // Try to decode as single template first
        if let template = try? TemplateDefinition(from: decoder) {
            self.singleTemplate = template
            self.templateLevels = nil
            return
        }
        
        // Otherwise decode as dictionary of template levels
        var levels: [String: TemplateDefinition] = [:]
        for key in container.allKeys {
            levels[key.stringValue] = try container.decode(TemplateDefinition.self, forKey: key)
        }
        self.templateLevels = levels
        self.singleTemplate = nil
    }
    
    public func encode(to encoder: Encoder) throws {
        if let single = singleTemplate {
            try single.encode(to: encoder)
        } else if let levels = templateLevels {
            var container = encoder.container(keyedBy: DynamicKey.self)
            for (key, value) in levels {
                try container.encode(value, forKey: DynamicKey(stringValue: key)!)
            }
        }
    }
    
    public func template(for level: String = "default") -> TemplateDefinition? {
        return templateLevels?[level] ?? singleTemplate
    }
    
    public func allLevels() -> [String] {
        return templateLevels?.keys.map { $0 } ?? []
    }
}

public struct TemplateDefinition: Codable {
    let template: String
    let priority: Int?
    
    public func render(with substitutions: [String: String] = [:]) -> String {
        var result = template
        for (key, value) in substitutions {
            result = result.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return result
    }
}

public struct TemplateVariant: Codable {
    let name: String
    let template: String
}

public struct ABTestConfig: Codable {
    let variants: [String]
    let weights: [Double]
    let metrics: [String]
}

// Dynamic key for JSON decoding
private struct DynamicKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

// MARK: - Configurable Prompt Templates

public class ConfigurablePromptTemplates {
    public static let shared = ConfigurablePromptTemplates()
    
    private var config: PromptTemplateConfig?
    private var abTestAssignments: [String: String] = [:]
    
    private init() {
        loadConfiguration()
    }
    
    // MARK: - Configuration Loading
    
    private func loadConfiguration() {
        guard let path = Bundle.main.path(forResource: "PromptTemplates", ofType: "json"),
              let data = NSData(contentsOfFile: path) as? Data else {
            print("[ConfigurablePromptTemplates] Warning: Could not load PromptTemplates.json")
            return
        }
        
        do {
            config = try JSONDecoder().decode(PromptTemplateConfig.self, from: data)
            print("[ConfigurablePromptTemplates] Loaded configuration version: \(config?.version ?? "unknown")")
            initializeABTests()
        } catch {
            print("[ConfigurablePromptTemplates] Error loading configuration: \(error)")
        }
    }
    
    public func reloadConfiguration() {
        loadConfiguration()
    }
    
    // MARK: - Template Access
    
    public func template(for category: String, level: String = "default", substitutions: [String: String] = [:]) -> String {
        // Check for A/B test assignment first
        if let assignedVariant = abTestAssignments[category] {
            if let template = config?.templates[category]?.template(for: assignedVariant) {
                return template.render(with: substitutions)
            }
        }
        
        // Fall back to normal template lookup
        if let template = config?.templates[category]?.template(for: level) {
            return template.render(with: substitutions)
        }
        
        // Return fallback if template not found
        return getFallbackTemplate(for: category, level: level)
    }
    
    public func availableLevels(for category: String) -> [String] {
        return config?.templates[category]?.allLevels() ?? []
    }
    
    public func templatePriority(for category: String, level: String = "default") -> Int {
        return config?.templates[category]?.template(for: level)?.priority ?? 5
    }
    
    // MARK: - A/B Testing
    
    private func initializeABTests() {
        guard let abTests = config?.abTests else { return }
        
        for (category, testConfig) in abTests {
            let assignment = selectABTestVariant(variants: testConfig.variants, weights: testConfig.weights)
            abTestAssignments[category] = assignment
            print("[ConfigurablePromptTemplates] A/B Test assignment for \(category): \(assignment)")
        }
    }
    
    private func selectABTestVariant(variants: [String], weights: [Double]) -> String {
        guard variants.count == weights.count else {
            return variants.first ?? "default"
        }
        
        let random = Double.random(in: 0...1)
        var cumulativeWeight = 0.0
        
        for (index, weight) in weights.enumerated() {
            cumulativeWeight += weight
            if random <= cumulativeWeight {
                return variants[index]
            }
        }
        
        return variants.last ?? "default"
    }
    
    public func getABTestAssignment(for category: String) -> String? {
        return abTestAssignments[category]
    }
    
    // MARK: - Experiments
    
    public func experimentalTemplate(for category: String, experiment: String) -> String? {
        return config?.experiments?[category]?.first { $0.name == experiment }?.template
    }
    
    public func availableExperiments(for category: String) -> [String] {
        return config?.experiments?[category]?.map { $0.name } ?? []
    }
    
    // MARK: - Fallbacks
    
    private func getFallbackTemplate(for category: String, level: String) -> String {
        switch category {
        case "textFreeEnforcement":
            return level == "critical" ? 
                "⛔️ NO TEXT IN ILLUSTRATIONS ⛔️\nCreate text-free visual illustrations only." :
                "Please avoid text in illustrations. Focus on visual storytelling."
        case "vocabularyLevels":
            return "Use age-appropriate vocabulary with clear, simple language."
        case "narrativeGuidelines":
            return "Create an engaging story with clear structure and appropriate pacing."
        case "storyStructure":
            return "Divide the story into clear pages with '---' separators between sections."
        default:
            return "Please follow the guidelines for creating engaging children's content."
        }
    }
    
    // MARK: - Metrics and Analytics
    
    public func logTemplateUsage(category: String, level: String, success: Bool) {
        // In a real implementation, this would send metrics to analytics
        let assignment = abTestAssignments[category] ?? level
        print("[ConfigurablePromptTemplates] Template usage - Category: \(category), Variant: \(assignment), Success: \(success)")
    }
    
    // MARK: - Development Helpers
    
    public func debugInfo() -> String {
        guard let config = config else {
            return "No configuration loaded"
        }
        
        var info = ["Configuration Version: \(config.version)"]
        info.append("Available Categories: \(Array(config.templates.keys).joined(separator: ", "))")
        
        if !abTestAssignments.isEmpty {
            info.append("A/B Test Assignments:")
            for (category, assignment) in abTestAssignments {
                info.append("  \(category): \(assignment)")
            }
        }
        
        return info.joined(separator: "\n")
    }
}

// MARK: - Convenience Extensions

extension ConfigurablePromptTemplates {
    
    // Quick access methods for common templates
    // Note: These methods are currently unused and reference undefined types
    // public func textFreeEnforcement(level: TextFreeLevel = .critical) -> String {
    //     let levelString = level == .critical ? "critical" : "moderate"
    //     return template(for: "textFreeEnforcement", level: levelString)
    // }
    // 
    // public func vocabularyGuideline(for vocabularyLevel: VocabularyLevel) -> String {
    //     switch vocabularyLevel {
    //     case .standard:
    //         return template(for: "vocabularyLevels", level: "intermediate")
    //     case .enhanced(let targetWords):
    //         return template(for: "enhancedVocabulary", substitutions: ["targetWords": "\(targetWords)"])
    //     }
    // }
    
    public func narrativeGuideline(for age: Int) -> String {
        let level: String
        switch age {
        case ..<5: level = "beginner"
        case 5...7: level = "intermediate"
        default: level = "advanced"
        }
        return template(for: "narrativeGuidelines", level: level)
    }
    
    public func interactiveElements(promptCount: Int) -> String {
        return template(for: "interactive", substitutions: ["promptCount": "\(promptCount)"])
    }
    
    public func emotionalThemes(_ themes: [String]) -> String {
        let themesList = themes.map { "- \($0)" }.joined(separator: "\n")
        return template(for: "emotional", substitutions: ["themes": themesList])
    }
    
    public func developmentalFocus(_ categories: [GrowthCategory]) -> String {
        let categoriesList = categories.map {
            "- \($0.rawValue): Include elements that promote this skill"
        }.joined(separator: "\n")
        return template(for: "developmental", substitutions: ["categories": categoriesList])
    }
    
    public func variabilityGuidelines(seed: String) -> String {
        return template(for: "variability", substitutions: ["seed": seed])
    }
}