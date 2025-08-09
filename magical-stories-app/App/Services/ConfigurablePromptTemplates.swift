import Foundation

// MARK: - Configuration Models

public struct PromptTemplateConfig: Codable, Sendable {
    let version: String
    let templates: [String: TemplateCategory]
    let experiments: [String: [TemplateVariant]]?
    let abTests: [String: ABTestConfig]?
}

public struct TemplateCategory: Codable, Sendable {
    // For categories with multiple levels (like vocabularyLevels)
    private let templateLevels: [String: TemplateDefinition]?
    // For single templates (like storyStructure)
    private let singleTemplate: TemplateDefinition?
    
    public init(from decoder: any Decoder) throws {
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
    
    public func encode(to encoder: any Encoder) throws {
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

public struct TemplateDefinition: Codable, Sendable {
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

public struct TemplateVariant: Codable, Sendable {
    let name: String
    let template: String
}

public struct ABTestConfig: Codable, Sendable {
    let variants: [String]
    let weights: [Double]
    let metrics: [String]
}

struct DynamicKey: CodingKey {
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

// MARK: - Actor Implementation

/// Actor-based implementation for optimal Swift 6 concurrency performance
public actor ConfigurablePromptTemplatesActor {
    public static let shared = ConfigurablePromptTemplatesActor()
    
    private var config: PromptTemplateConfig?
    private var abTestAssignments: [String: String] = [:]
    
    private init() {
        // Initialize configuration asynchronously
        Task {
            await loadConfiguration()
        }
    }
    
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
    
    public func getABTestAssignment(for category: String) -> String? {
        return abTestAssignments[category]
    }
    
    public func experimentalTemplate(for category: String, experiment: String) -> String? {
        return config?.experiments?[category]?.first { $0.name == experiment }?.template
    }
    
    public func availableExperiments(for category: String) -> [String] {
        return config?.experiments?[category]?.map { $0.name } ?? []
    }
    
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
    
    public func reloadConfiguration() async {
        await loadConfiguration()
    }
    
    public func recordTemplateUsage(category: String, level: String, assignment: String?, success: Bool) {
        print("[ConfigurablePromptTemplates] Template usage - Category: \(category), Variant: \(assignment), Success: \(success)")
    }
    
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
    
    // MARK: - Configuration Loading
    
    private func loadConfiguration() async {
        guard let path = Bundle.main.path(forResource: "PromptTemplates", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let decodedConfig = try? JSONDecoder().decode(PromptTemplateConfig.self, from: data) else {
            print("[ConfigurablePromptTemplates] Failed to load configuration from bundle")
            return
        }
        
        config = decodedConfig
        abTestAssignments = [:]
        initializeABTests()
        
        print("[ConfigurablePromptTemplates] Configuration loaded successfully - Version: \(decodedConfig.version)")
        print("[ConfigurablePromptTemplates] Available categories: \(Array(decodedConfig.templates.keys).joined(separator: ", "))")
    }
    
    private func initializeABTests() {
        guard let config = config, let abTests = config.abTests else { return }
        
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
}

// MARK: - Synchronous Wrapper for Compatibility

/// Synchronous wrapper for ConfigurablePromptTemplates actor
/// This maintains API compatibility while using actor-based implementation
@MainActor
public final class ConfigurablePromptTemplatesSync: ObservableObject {
    public static let shared = ConfigurablePromptTemplatesSync()
    
    private let actor = ConfigurablePromptTemplatesActor.shared
    
    private init() {}
    
    public func template(for category: String, level: String = "default", substitutions: [String: String] = [:]) -> String {
        let task = Task { await actor.template(for: category, level: level, substitutions: substitutions) }
        
        // Simple blocking wait for the actor result
        var result: String?
        let group = DispatchGroup()
        group.enter()
        
        Task {
            result = await task.value
            group.leave()
        }
        
        group.wait()
        return result ?? getFallbackTemplate(for: category, level: level)
    }
    
    public func availableLevels(for category: String) -> [String] {
        let task = Task { await actor.availableLevels(for: category) }
        
        var result: [String]?
        let group = DispatchGroup()
        group.enter()
        
        Task {
            result = await task.value
            group.leave()
        }
        
        group.wait()
        return result ?? []
    }
    
    public func templatePriority(for category: String, level: String = "default") -> Int {
        let task = Task { await actor.templatePriority(for: category, level: level) }
        
        var result: Int?
        let group = DispatchGroup()
        group.enter()
        
        Task {
            result = await task.value
            group.leave()
        }
        
        group.wait()
        return result ?? 5
    }
    
    public func getABTestAssignment(for category: String) -> String? {
        let task = Task { await actor.getABTestAssignment(for: category) }
        
        var result: String??
        let group = DispatchGroup()
        group.enter()
        
        Task {
            result = await task.value
            group.leave()
        }
        
        group.wait()
        return result ?? nil
    }
    
    public func experimentalTemplate(for category: String, experiment: String) -> String? {
        let task = Task { await actor.experimentalTemplate(for: category, experiment: experiment) }
        
        var result: String??
        let group = DispatchGroup()
        group.enter()
        
        Task {
            result = await task.value
            group.leave()
        }
        
        group.wait()
        return result ?? nil
    }
    
    public func availableExperiments(for category: String) -> [String] {
        let task = Task { await actor.availableExperiments(for: category) }
        
        var result: [String]?
        let group = DispatchGroup()
        group.enter()
        
        Task {
            result = await task.value
            group.leave()
        }
        
        group.wait()
        return result ?? []
    }
    
    public func debugInfo() -> String {
        let task = Task { await actor.debugInfo() }
        
        var result: String?
        let group = DispatchGroup()
        group.enter()
        
        Task {
            result = await task.value
            group.leave()
        }
        
        group.wait()
        return result ?? "Debug info unavailable"
    }
    
    public func reloadConfiguration() {
        Task { await actor.reloadConfiguration() }
    }
    
    // MARK: - Analytics
    
    public func recordTemplateUsage(category: String, level: String, assignment: String?, success: Bool) {
        Task { await actor.recordTemplateUsage(category: category, level: level, assignment: assignment, success: success) }
    }
    
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
}

// Keep the old name as alias for compatibility
public typealias ConfigurablePromptTemplates = ConfigurablePromptTemplatesSync

// MARK: - Convenience Extensions

extension ConfigurablePromptTemplatesSync {
    
    // Quick access methods for common templates
    public func textFreeEnforcement(level: String = "critical") -> String {
        return template(for: "textFreeEnforcement", level: level)
    }
    
    public func vocabularyLevel(_ level: String) -> String {
        return template(for: "vocabularyLevels", level: level)
    }
    
    public func narrativeGuidelines() -> String {
        return template(for: "narrativeGuidelines")
    }
    
    public func storyStructure() -> String {
        return template(for: "storyStructure")
    }
}