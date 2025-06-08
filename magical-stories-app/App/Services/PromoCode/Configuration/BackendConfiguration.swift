import Foundation
import SwiftUI

/// Enum defining available backend providers for promo code services
enum BackendProvider: String, CaseIterable {
    case offline = "offline"
    case firebase = "firebase"
    case customAPI = "custom_api"
    
    var displayName: String {
        switch self {
        case .offline:
            return "Offline Only"
        case .firebase:
            return "Firebase"
        case .customAPI:
            return "Custom API"
        }
    }
    
    var requiresNetwork: Bool {
        switch self {
        case .offline:
            return false
        case .firebase, .customAPI:
            return true
        }
    }
}

/// Configuration management for backend services
class BackendConfiguration: ObservableObject {
    
    // MARK: - Singleton
    static let shared = BackendConfiguration()
    
    // MARK: - Published Properties
    @Published private(set) var currentProvider: BackendProvider
    @Published private(set) var isNetworkAvailable: Bool = true
    @Published private(set) var lastConfigUpdate: Date
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let configKey = "PromoCodeBackendProvider"
    private let lastUpdateKey = "PromoCodeConfigLastUpdate"
    
    // MARK: - Initialization
    private init() {
        // Load saved configuration or default to offline
        let savedProvider = userDefaults.string(forKey: configKey) ?? BackendProvider.offline.rawValue
        self.currentProvider = BackendProvider(rawValue: savedProvider) ?? .offline
        
        let savedUpdate = userDefaults.object(forKey: lastUpdateKey) as? Date ?? Date()
        self.lastConfigUpdate = savedUpdate
        
        // Monitor network status
        startNetworkMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Updates the current backend provider
    /// - Parameter provider: The new backend provider to use
    func setProvider(_ provider: BackendProvider) {
        guard provider != currentProvider else { return }
        
        currentProvider = provider
        lastConfigUpdate = Date()
        
        // Persist configuration
        userDefaults.set(provider.rawValue, forKey: configKey)
        userDefaults.set(lastConfigUpdate, forKey: lastUpdateKey)
        
        print("Backend provider changed to: \(provider.displayName)")
    }
    
    /// Gets the effective provider based on current conditions
    /// - Returns: The provider that should be used considering network availability
    func getEffectiveProvider() -> BackendProvider {
        // If current provider requires network but network is unavailable, fall back to offline
        if currentProvider.requiresNetwork && !isNetworkAvailable {
            return .offline
        }
        return currentProvider
    }
    
    /// Checks if a specific provider can be used currently
    /// - Parameter provider: The provider to check
    /// - Returns: True if the provider can be used
    func canUseProvider(_ provider: BackendProvider) -> Bool {
        if provider.requiresNetwork {
            return isNetworkAvailable
        }
        return true
    }
    
    /// Resets configuration to default values
    func resetToDefaults() {
        setProvider(.offline)
    }
    
    // MARK: - Private Methods
    
    private func startNetworkMonitoring() {
        // Simple network monitoring - in a real app you might use Network framework
        // For now, we'll assume network is available
        isNetworkAvailable = true
        
        // TODO: Implement proper network monitoring when Firebase integration is added
    }
}

/// Feature flags for promo code functionality
struct PromoCodeFeatureFlags {
    
    // MARK: - Backend Features
    static let enableBackendValidation: Bool = false
    static let enableAsyncValidation: Bool = false
    static let enableUsageTracking: Bool = false
    static let enableAnalytics: Bool = false
    
    // MARK: - Firebase Features (Phase 2)
    static let enableFirebaseIntegration: Bool = false
    static let enableFirebaseAnalytics: Bool = false
    static let enableFirebaseOfflineSupport: Bool = false
    
    // MARK: - UI Features
    static let enableAsyncUI: Bool = false
    static let enableBackendStatusIndicator: Bool = false
    static let enableAdvancedErrorHandling: Bool = false
    
    // MARK: - Development Features
    static let enableDebugLogging: Bool = true
    static let enableMockBackend: Bool = false
    
    // MARK: - Helper Methods
    
    /// Checks if any backend features are enabled
    static var isBackendEnabled: Bool {
        return enableBackendValidation || enableAsyncValidation || enableUsageTracking || enableAnalytics
    }
    
    /// Checks if any async features are enabled
    static var isAsyncEnabled: Bool {
        return enableAsyncValidation || enableAsyncUI
    }
    
    /// Gets a summary of enabled features for debugging
    static var enabledFeatures: [String] {
        var features: [String] = []
        
        if enableBackendValidation { features.append("BackendValidation") }
        if enableAsyncValidation { features.append("AsyncValidation") }
        if enableUsageTracking { features.append("UsageTracking") }
        if enableAnalytics { features.append("Analytics") }
        if enableAsyncUI { features.append("AsyncUI") }
        if enableBackendStatusIndicator { features.append("StatusIndicator") }
        if enableAdvancedErrorHandling { features.append("AdvancedErrors") }
        if enableDebugLogging { features.append("DebugLogging") }
        if enableMockBackend { features.append("MockBackend") }
        
        return features
    }
}

/// Environment-specific configuration
struct EnvironmentConfig {
    
    // MARK: - Environment Detection
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Default Providers by Environment
    static var defaultProvider: BackendProvider {
        if isDebug {
            return .offline // Safe default for development
        } else {
            return .offline // Conservative default for production
        }
    }
    
    // MARK: - Logging Configuration
    static var shouldLog: Bool {
        return isDebug || PromoCodeFeatureFlags.enableDebugLogging
    }
}