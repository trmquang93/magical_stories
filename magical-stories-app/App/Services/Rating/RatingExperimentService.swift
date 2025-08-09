import Foundation
import OSLog

/// A/B testing framework for rating system optimization
@MainActor
final class RatingExperimentService: ObservableObject {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.magicalstories.app", category: "RatingExperiment")
    private let analyticsService: RatingAnalyticsService
    private let userPreferences: RatingUserPreferences
    
    // Current experiments
    @Published private(set) var activeExperiments: [RatingExperiment] = []
    @Published private(set) var userAssignments: [String: String] = [:] // experimentId -> variant
    
    // Configuration
    private let userId: String
    private var experimentsData: [String: RatingExperimentData] = [:]
    
    // MARK: - Initialization
    
    init(
        analyticsService: RatingAnalyticsService,
        userPreferences: RatingUserPreferences,
        userId: String = UUID().uuidString
    ) {
        self.analyticsService = analyticsService
        self.userPreferences = userPreferences
        self.userId = userId
        
        setupDefaultExperiments()
        assignUserToExperiments()
    }
    
    // MARK: - Public Interface
    
    /// Get the variant for a specific experiment
    func getVariant(for experimentId: String) -> String? {
        return userAssignments[experimentId]
    }
    
    /// Get engagement threshold based on current experiment
    func getEngagementThreshold() -> Double {
        guard let variant = getVariant(for: "engagement_threshold_test") else {
            return 0.7 // Default threshold
        }
        
        switch variant {
        case "low_threshold":
            return 0.5
        case "medium_threshold":
            return 0.7
        case "high_threshold":
            return 0.9
        default:
            return 0.7
        }
    }
    
    /// Get prompt timing configuration based on current experiment
    func getPromptTiming() -> RatingPromptTiming {
        guard let variant = getVariant(for: "prompt_timing_test") else {
            return .standard
        }
        
        switch variant {
        case "immediate":
            return .immediate
        case "delayed":
            return .delayed
        case "smart":
            return .smart
        default:
            return .standard
        }
    }
    
    /// Get prompt style based on current experiment
    func getPromptStyle() -> RatingPromptStyle {
        guard let variant = getVariant(for: "prompt_style_test") else {
            return .standard
        }
        
        switch variant {
        case "minimal":
            return .minimal
        case "detailed":
            return .detailed
        case "gamified":
            return .gamified
        default:
            return .standard
        }
    }
    
    /// Record experiment conversion
    func recordConversion(
        experimentId: String,
        conversionType: RatingConversionType,
        value: Double? = nil
    ) {
        guard let variant = getVariant(for: experimentId),
              let experiment = activeExperiments.first(where: { $0.id == experimentId }) else {
            return
        }
        
        // Update experiment data
        if var data = experimentsData[experimentId] {
            data.conversions[variant, default: 0] += 1
            if conversionType == .ratingCompleted {
                data.successfulConversions[variant, default: 0] += 1
            }
            experimentsData[experimentId] = data
        }
        
        // Track analytics
        analyticsService.trackExperimentConversion(
            experimentId: experimentId,
            variant: variant,
            conversionType: conversionType.rawValue,
            value: value
        )
        
        logger.info("Recorded conversion for experiment \(experimentId), variant \(variant): \(conversionType.rawValue)")
    }
    
    /// Get experiment results for analysis
    func getExperimentResults(experimentId: String) -> RatingExperimentResults? {
        guard let experiment = activeExperiments.first(where: { $0.id == experimentId }),
              let data = experimentsData[experimentId] else {
            return nil
        }
        
        var variantResults: [String: RatingVariantResults] = [:]
        
        for variant in experiment.variants {
            let assignments = data.assignments[variant] ?? 0
            let conversions = data.conversions[variant] ?? 0
            let successfulConversions = data.successfulConversions[variant] ?? 0
            
            variantResults[variant] = RatingVariantResults(
                variant: variant,
                assignments: assignments,
                totalConversions: conversions,
                successfulConversions: successfulConversions,
                conversionRate: assignments > 0 ? Double(conversions) / Double(assignments) : 0.0,
                successRate: conversions > 0 ? Double(successfulConversions) / Double(conversions) : 0.0
            )
        }
        
        return RatingExperimentResults(
            experimentId: experimentId,
            experiment: experiment,
            variantResults: variantResults,
            totalAssignments: data.assignments.values.reduce(0, +),
            startDate: experiment.startDate,
            isStatisticallySignificant: calculateStatisticalSignificance(variantResults)
        )
    }
    
    /// Check if an experiment is ready for decision
    func isExperimentReady(experimentId: String) -> Bool {
        guard let results = getExperimentResults(experimentId: experimentId) else {
            return false
        }
        
        // Check minimum sample size
        let minSampleSize = 100
        let hasMinimumSample = results.variantResults.values.allSatisfy { $0.assignments >= minSampleSize }
        
        // Check runtime
        let minRuntime: TimeInterval = 7 * 24 * 60 * 60 // 7 days
        let hasRunLongEnough = Date().timeIntervalSince(results.startDate) >= minRuntime
        
        return hasMinimumSample && hasRunLongEnough && results.isStatisticallySignificant
    }
    
    /// Get recommended action for an experiment
    func getExperimentRecommendation(experimentId: String) -> RatingExperimentRecommendation? {
        guard let results = getExperimentResults(experimentId: experimentId),
              isExperimentReady(experimentId: experimentId) else {
            return nil
        }
        
        // Find best performing variant
        let sortedVariants = results.variantResults.values.sorted { $0.successRate > $1.successRate }
        guard let winner = sortedVariants.first,
              let control = results.variantResults["control"] else {
            return nil
        }
        
        let improvement = winner.successRate - control.successRate
        let significantImprovement = improvement > 0.05 // 5% improvement threshold
        
        if winner.variant == "control" {
            return RatingExperimentRecommendation(
                action: .keepControl,
                winningVariant: "control",
                improvement: 0.0,
                confidence: calculateConfidence(results),
                recommendation: "Continue with current implementation"
            )
        } else if significantImprovement {
            return RatingExperimentRecommendation(
                action: .adoptWinner,
                winningVariant: winner.variant,
                improvement: improvement,
                confidence: calculateConfidence(results),
                recommendation: "Adopt \(winner.variant) variant (improved success rate by \(String(format: "%.1f", improvement * 100))%)"
            )
        } else {
            return RatingExperimentRecommendation(
                action: .noChange,
                winningVariant: winner.variant,
                improvement: improvement,
                confidence: calculateConfidence(results),
                recommendation: "No significant improvement detected, keep current implementation"
            )
        }
    }
    
    // MARK: - Private Implementation
    
    private func setupDefaultExperiments() {
        // Engagement Threshold Test
        let engagementThresholdTest = RatingExperiment(
            id: "engagement_threshold_test",
            name: "Engagement Threshold Optimization",
            description: "Test different engagement score thresholds for rating prompts",
            variants: ["control", "low_threshold", "medium_threshold", "high_threshold"],
            trafficAllocation: [
                "control": 0.25,
                "low_threshold": 0.25,
                "medium_threshold": 0.25,
                "high_threshold": 0.25
            ],
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
            isActive: true
        )
        
        // Prompt Timing Test
        let promptTimingTest = RatingExperiment(
            id: "prompt_timing_test",
            name: "Prompt Timing Optimization",
            description: "Test different timing strategies for showing rating prompts",
            variants: ["control", "immediate", "delayed", "smart"],
            trafficAllocation: [
                "control": 0.25,
                "immediate": 0.25,
                "delayed": 0.25,
                "smart": 0.25
            ],
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
            isActive: true
        )
        
        // Prompt Style Test
        let promptStyleTest = RatingExperiment(
            id: "prompt_style_test",
            name: "Prompt Style Optimization",
            description: "Test different visual styles and messaging for rating prompts",
            variants: ["control", "minimal", "detailed", "gamified"],
            trafficAllocation: [
                "control": 0.25,
                "minimal": 0.25,
                "detailed": 0.25,
                "gamified": 0.25
            ],
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
            isActive: true
        )
        
        activeExperiments = [engagementThresholdTest, promptTimingTest, promptStyleTest]
        
        // Initialize experiment data
        for experiment in self.activeExperiments {
            experimentsData[experiment.id] = RatingExperimentData()
        }
        
        logger.info("Setup \(self.activeExperiments.count) default rating experiments")
    }
    
    private func assignUserToExperiments() {
        for experiment in self.activeExperiments {
            guard experiment.isActive else { continue }
            
            let variant = assignUserToVariant(experiment: experiment)
            userAssignments[experiment.id] = variant
            
            // Update assignment count
            if var data = experimentsData[experiment.id] {
                data.assignments[variant, default: 0] += 1
                experimentsData[experiment.id] = data
            }
            
            // Track assignment
            analyticsService.trackExperimentAssignment(
                experimentId: experiment.id,
                variant: variant,
                userId: userId
            )
            
            logger.info("Assigned user to experiment \(experiment.id), variant: \(variant)")
        }
    }
    
    private func assignUserToVariant(experiment: RatingExperiment) -> String {
        // Use consistent hashing to ensure same user gets same variant
        let hashInput = userId + experiment.id
        let hash = hashInput.hash
        let normalizedHash = Double(abs(hash)) / Double(Int.max)
        
        var cumulativeProbability = 0.0
        for (variant, allocation) in experiment.trafficAllocation {
            cumulativeProbability += allocation
            if normalizedHash <= cumulativeProbability {
                return variant
            }
        }
        
        // Fallback to control
        return "control"
    }
    
    private func calculateStatisticalSignificance(_ variantResults: [String: RatingVariantResults]) -> Bool {
        guard variantResults.count >= 2,
              let control = variantResults["control"] else {
            return false
        }
        
        // Simple significance check - in production, use proper statistical tests
        let minSampleSize = 100
        let hasMinimumSamples = variantResults.values.allSatisfy { $0.assignments >= minSampleSize }
        
        if !hasMinimumSamples {
            return false
        }
        
        // Check if any variant has significantly different conversion rate
        for (_, variant) in variantResults {
            if variant.variant == "control" { continue }
            
            let difference = abs(variant.conversionRate - control.conversionRate)
            if difference > 0.05 { // 5% difference threshold
                return true
            }
        }
        
        return false
    }
    
    private func calculateConfidence(_ results: RatingExperimentResults) -> Double {
        // Simplified confidence calculation
        // In production, use proper statistical methods
        let totalSample = results.totalAssignments
        
        if totalSample < 100 {
            return 0.5
        } else if totalSample < 500 {
            return 0.8
        } else {
            return 0.95
        }
    }
}

// MARK: - Supporting Types

struct RatingExperiment: Sendable, Identifiable {
    let id: String
    let name: String
    let description: String
    let variants: [String]
    let trafficAllocation: [String: Double] // variant -> percentage
    let startDate: Date
    let endDate: Date?
    let isActive: Bool
}

struct RatingExperimentData: Sendable {
    var assignments: [String: Int] = [:] // variant -> count
    var conversions: [String: Int] = [:] // variant -> count
    var successfulConversions: [String: Int] = [:] // variant -> count
}

struct RatingVariantResults: Sendable {
    let variant: String
    let assignments: Int
    let totalConversions: Int
    let successfulConversions: Int
    let conversionRate: Double
    let successRate: Double
}

struct RatingExperimentResults: Sendable {
    let experimentId: String
    let experiment: RatingExperiment
    let variantResults: [String: RatingVariantResults]
    let totalAssignments: Int
    let startDate: Date
    let isStatisticallySignificant: Bool
}

struct RatingExperimentRecommendation: Sendable {
    let action: ExperimentAction
    let winningVariant: String
    let improvement: Double
    let confidence: Double
    let recommendation: String
}

enum ExperimentAction: String, CaseIterable, Sendable {
    case keepControl = "keep_control"
    case adoptWinner = "adopt_winner"
    case noChange = "no_change"
    case extendTest = "extend_test"
}

enum RatingConversionType: String, CaseIterable, Sendable {
    case promptShown = "prompt_shown"
    case ratingCompleted = "rating_completed"
    case promptDismissed = "prompt_dismissed"
    case remindLater = "remind_later"
    case dontAskAgain = "dont_ask_again"
}

enum RatingPromptTiming: Sendable {
    case immediate // Show immediately when conditions are met
    case delayed // Wait for additional engagement
    case smart // Use ML-based timing
    case standard // Default timing
}

enum RatingPromptStyle: Sendable {
    case standard // Default iOS rating prompt
    case minimal // Simple, clean interface
    case detailed // More context and explanation
    case gamified // Game-like elements and rewards
}

// MARK: - Experiment Configuration Extensions

extension RatingExperimentService {
    
    /// Create a custom experiment
    func createExperiment(
        id: String,
        name: String,
        description: String,
        variants: [String],
        trafficAllocation: [String: Double],
        duration: TimeInterval
    ) -> Bool {
        // Validate traffic allocation sums to 1.0
        let totalAllocation = trafficAllocation.values.reduce(0, +)
        guard abs(totalAllocation - 1.0) < 0.001 else {
            logger.error("Invalid traffic allocation for experiment \(id): total = \(totalAllocation)")
            return false
        }
        
        let experiment = RatingExperiment(
            id: id,
            name: name,
            description: description,
            variants: variants,
            trafficAllocation: trafficAllocation,
            startDate: Date(),
            endDate: Date().addingTimeInterval(duration),
            isActive: true
        )
        
        activeExperiments.append(experiment)
        experimentsData[id] = RatingExperimentData()
        
        // Assign current user to new experiment
        let variant = assignUserToVariant(experiment: experiment)
        userAssignments[id] = variant
        
        if var data = experimentsData[id] {
            data.assignments[variant, default: 0] += 1
            experimentsData[id] = data
        }
        
        analyticsService.trackExperimentAssignment(
            experimentId: id,
            variant: variant,
            userId: userId
        )
        
        logger.info("Created and assigned user to experiment \(id), variant: \(variant)")
        return true
    }
    
    /// Stop an active experiment
    func stopExperiment(experimentId: String) {
        if let index = activeExperiments.firstIndex(where: { $0.id == experimentId }) {
            var experiment = activeExperiments[index]
            experiment = RatingExperiment(
                id: experiment.id,
                name: experiment.name,
                description: experiment.description,
                variants: experiment.variants,
                trafficAllocation: experiment.trafficAllocation,
                startDate: experiment.startDate,
                endDate: Date(),
                isActive: false
            )
            activeExperiments[index] = experiment
            
            logger.info("Stopped experiment \(experimentId)")
        }
    }
    
    /// Get all experiment results for dashboard
    func getAllExperimentResults() -> [RatingExperimentResults] {
        return activeExperiments.compactMap { experiment in
            getExperimentResults(experimentId: experiment.id)
        }
    }
}