import Foundation
import OSLog
import SwiftUI

/// Feature flags for controlling app functionality rollout
public enum FeatureFlag: String, CaseIterable, Sendable {
    case ratingSystem = "rating_system"
    case enhancedRatingAnalytics = "enhanced_rating_analytics"
    case ratingAutoPrompt = "rating_auto_prompt"
    case ratingDebugMode = "rating_debug_mode"
    
    /// Default state for the feature flag
    var defaultValue: Bool {
        switch self {
        case .ratingSystem:
            return true
        case .enhancedRatingAnalytics:
            return true
        case .ratingAutoPrompt:
            return true // Enable auto-prompting based on engagement
        case .ratingDebugMode:
            #if DEBUG
            return true
            #else
            return false
            #endif
        }
    }
    
    /// User-friendly name for the feature
    var displayName: String {
        switch self {
        case .ratingSystem:
            return "Rating System"
        case .enhancedRatingAnalytics:
            return "Enhanced Rating Analytics"
        case .ratingAutoPrompt:
            return "Auto Rating Prompts"
        case .ratingDebugMode:
            return "Rating Debug Mode"
        }
    }
    
    /// Description of what the feature does
    var description: String {
        switch self {
        case .ratingSystem:
            return "Enable the entire rating system functionality"
        case .enhancedRatingAnalytics:
            return "Track detailed analytics for rating events"
        case .ratingAutoPrompt:
            return "Automatically show rating prompts based on engagement"
        case .ratingDebugMode:
            return "Enable debug controls and verbose logging for rating system"
        }
    }
}

/// Service for managing feature flags
@MainActor
public final class FeatureFlagService: ObservableObject, @unchecked Sendable {
    
    // MARK: - Published Properties
    
    @Published private var flags: [FeatureFlag: Bool] = [:]
    
    // MARK: - Private Properties
    
    private let userDefaults: UserDefaults
    private let logger = Logger(subsystem: "com.magicalstories.app", category: "FeatureFlagService")
    private static let keyPrefix = "feature_flag_"
    
    // MARK: - Singleton
    
    public static let shared = FeatureFlagService()
    
    // MARK: - Initialization
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadFeatureFlags()
    }
    
    // MARK: - Public Interface
    
    /// Check if a feature is enabled
    public func isEnabled(_ feature: FeatureFlag) -> Bool {
        return flags[feature] ?? feature.defaultValue
    }
    
    /// Enable or disable a feature
    public func setFeature(_ feature: FeatureFlag, enabled: Bool) {
        flags[feature] = enabled
        userDefaults.set(enabled, forKey: Self.keyPrefix + feature.rawValue)
        
        logger.info("Feature flag '\(feature.rawValue)' set to: \(enabled)")
        
        // Notify about feature flag changes if needed
        NotificationCenter.default.post(
            name: .featureFlagChanged,
            object: nil,
            userInfo: [
                "feature": feature,
                "enabled": enabled
            ]
        )
    }
    
    /// Reset feature to its default value
    public func resetFeature(_ feature: FeatureFlag) {
        flags[feature] = feature.defaultValue
        userDefaults.removeObject(forKey: Self.keyPrefix + feature.rawValue)
        
        logger.info("Feature flag '\(feature.rawValue)' reset to default: \(feature.defaultValue)")
    }
    
    /// Reset all features to their default values
    public func resetAllFeatures() {
        for feature in FeatureFlag.allCases {
            resetFeature(feature)
        }
        
        logger.info("All feature flags reset to defaults")
    }
    
    /// Get all feature flags with their current states
    public func getAllFeatures() -> [(feature: FeatureFlag, enabled: Bool)] {
        return FeatureFlag.allCases.map { feature in
            (feature: feature, enabled: isEnabled(feature))
        }
    }
    
    // MARK: - Private Methods
    
    private func loadFeatureFlags() {
        for feature in FeatureFlag.allCases {
            let key = Self.keyPrefix + feature.rawValue
            if userDefaults.object(forKey: key) != nil {
                flags[feature] = userDefaults.bool(forKey: key)
            } else {
                flags[feature] = feature.defaultValue
            }
        }
        
        logger.info("Loaded \(self.flags.count) feature flags")
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let featureFlagChanged = Notification.Name("FeatureFlagChanged")
}

// MARK: - SwiftUI Environment Key

struct FeatureFlagServiceKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue: FeatureFlagService = FeatureFlagService.shared
}

extension EnvironmentValues {
    var featureFlagService: FeatureFlagService {
        get { self[FeatureFlagServiceKey.self] }
        set { self[FeatureFlagServiceKey.self] = newValue }
    }
}

// MARK: - Convenience Extensions

extension FeatureFlagService {
    /// Convenience method for rating system features
    var ratingSystemEnabled: Bool {
        isEnabled(.ratingSystem)
    }
    
    var ratingAnalyticsEnabled: Bool {
        isEnabled(.enhancedRatingAnalytics)
    }
    
    var ratingAutoPromptEnabled: Bool {
        isEnabled(.ratingAutoPrompt)
    }
    
    var ratingDebugModeEnabled: Bool {
        isEnabled(.ratingDebugMode)
    }
}

// MARK: - View Modifier for Feature Flags

struct FeatureGatedView<Content: View>: View {
    let feature: FeatureFlag
    let content: Content
    let fallback: (() -> AnyView)?
    
    @EnvironmentObject private var featureFlagService: FeatureFlagService
    
    init(
        _ feature: FeatureFlag,
        fallback: (() -> AnyView)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.feature = feature
        self.fallback = fallback
        self.content = content()
    }
    
    var body: some View {
        if featureFlagService.isEnabled(feature) {
            content
        } else if let fallback = fallback {
            fallback()
        } else {
            EmptyView()
        }
    }
}

extension View {
    /// Apply feature gating to this view
    func featureGated(_ feature: FeatureFlag) -> some View {
        FeatureGatedView(feature) {
            self
        }
    }
    
    /// Apply feature gating with a fallback view
    func featureGated<Fallback: View>(
        _ feature: FeatureFlag,
        fallback: @escaping () -> Fallback
    ) -> some View {
        FeatureGatedView(feature, fallback: { AnyView(fallback()) }) {
            self
        }
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension FeatureFlagService {
    /// Create a test instance with specific feature states
    static func testInstance(features: [FeatureFlag: Bool] = [:]) -> FeatureFlagService {
        let service = FeatureFlagService()
        for (feature, enabled) in features {
            service.setFeature(feature, enabled: enabled)
        }
        return service
    }
}
#endif
