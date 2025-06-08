import Foundation
import SwiftUI
import Combine

/// Factory class for creating promo code services based on configuration
/// This provides a single point of control for backend switching
class PromoCodeServiceFactory: ObservableObject {
    
    // MARK: - Singleton
    static let shared = PromoCodeServiceFactory()
    
    // MARK: - Dependencies
    private let configuration = BackendConfiguration.shared
    
    // MARK: - Cached Services
    private var cachedBackendService: PromoCodeBackendService?
    private var cachedRepository: PromoCodeRepository?
    private var lastProviderUsed: BackendProvider?
    
    // MARK: - Initialization
    private init() {
        // Observe configuration changes
        configuration.objectWillChange.sink { [weak self] _ in
            self?.invalidateCache()
        }.store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Service Creation
    
    /// Creates a backend service based on current configuration
    /// - Returns: PromoCodeBackendService implementation
    func createBackendService() -> PromoCodeBackendService {
        let currentProvider = configuration.getEffectiveProvider()
        
        // Return cached service if provider hasn't changed
        if let cached = cachedBackendService,
           lastProviderUsed == currentProvider {
            return cached
        }
        
        let service: PromoCodeBackendService
        
        switch currentProvider {
        case .offline:
            service = OfflinePromoCodeService()
            if EnvironmentConfig.shouldLog {
                print("PromoCodeServiceFactory: Created OfflinePromoCodeService")
            }
            
        case .firebase:
            // TODO: Implement in Phase 2
            if EnvironmentConfig.shouldLog {
                print("PromoCodeServiceFactory: Firebase not yet implemented, falling back to offline")
            }
            service = OfflinePromoCodeService()
            
        case .customAPI:
            // TODO: Implement in Phase 3
            if EnvironmentConfig.shouldLog {
                print("PromoCodeServiceFactory: Custom API not yet implemented, falling back to offline")
            }
            service = OfflinePromoCodeService()
        }
        
        // Cache the service
        cachedBackendService = service
        lastProviderUsed = currentProvider
        
        return service
    }
    
    /// Creates a repository based on current configuration
    /// - Returns: PromoCodeRepository implementation
    func createRepository() -> PromoCodeRepository {
        let currentProvider = configuration.getEffectiveProvider()
        
        // Return cached repository if provider hasn't changed
        if let cached = cachedRepository,
           lastProviderUsed == currentProvider {
            return cached
        }
        
        let repository: PromoCodeRepository
        
        switch currentProvider {
        case .offline:
            repository = OfflinePromoCodeRepository()
            if EnvironmentConfig.shouldLog {
                print("PromoCodeServiceFactory: Created OfflinePromoCodeRepository")
            }
            
        case .firebase:
            // TODO: Implement in Phase 2
            if EnvironmentConfig.shouldLog {
                print("PromoCodeServiceFactory: Firebase repository not yet implemented, falling back to offline")
            }
            repository = OfflinePromoCodeRepository()
            
        case .customAPI:
            // TODO: Implement in Phase 3
            if EnvironmentConfig.shouldLog {
                print("PromoCodeServiceFactory: Custom API repository not yet implemented, falling back to offline")
            }
            repository = OfflinePromoCodeRepository()
        }
        
        // Cache the repository
        cachedRepository = repository
        lastProviderUsed = currentProvider
        
        return repository
    }
    
    // MARK: - Convenience Methods
    
    /// Gets the current backend service (cached)
    var backendService: PromoCodeBackendService {
        return createBackendService()
    }
    
    /// Gets the current repository (cached)
    var repository: PromoCodeRepository {
        return createRepository()
    }
    
    /// Checks if the current backend is available
    func isBackendAvailable() async -> Bool {
        let service = createBackendService()
        return await service.isBackendAvailable()
    }
    
    /// Gets information about the current backend
    var currentBackendInfo: BackendInfo {
        let provider = configuration.getEffectiveProvider()
        let configuredProvider = configuration.currentProvider
        
        return BackendInfo(
            configuredProvider: configuredProvider,
            effectiveProvider: provider,
            isNetworkRequired: provider.requiresNetwork,
            isNetworkAvailable: configuration.isNetworkAvailable,
            isFallback: provider != configuredProvider
        )
    }
    
    // MARK: - Cache Management
    
    private func invalidateCache() {
        cachedBackendService = nil
        cachedRepository = nil
        lastProviderUsed = nil
        
        if EnvironmentConfig.shouldLog {
            print("PromoCodeServiceFactory: Cache invalidated due to configuration change")
        }
    }
    
    /// Forces recreation of services (useful for testing)
    func refreshServices() {
        invalidateCache()
    }
}

// MARK: - Supporting Types

/// Information about the current backend configuration
struct BackendInfo {
    let configuredProvider: BackendProvider
    let effectiveProvider: BackendProvider
    let isNetworkRequired: Bool
    let isNetworkAvailable: Bool
    let isFallback: Bool
    
    var statusDescription: String {
        if isFallback {
            return "Using \(effectiveProvider.displayName) (fallback from \(configuredProvider.displayName))"
        } else {
            return "Using \(effectiveProvider.displayName)"
        }
    }
    
    var isOptimal: Bool {
        return !isFallback
    }
}

// MARK: - Combine Support

extension PromoCodeServiceFactory {
    /// Publisher that emits when the backend configuration changes
    var configurationDidChange: AnyPublisher<BackendInfo, Never> {
        configuration.objectWillChange
            .map { [weak self] _ in
                self?.currentBackendInfo ?? BackendInfo(
                    configuredProvider: .offline,
                    effectiveProvider: .offline,
                    isNetworkRequired: false,
                    isNetworkAvailable: true,
                    isFallback: false
                )
            }
            .eraseToAnyPublisher()
    }
}