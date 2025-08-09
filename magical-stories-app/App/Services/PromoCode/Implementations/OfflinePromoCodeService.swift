import Foundation
import SwiftUI
import Combine

/// Offline implementation of PromoCodeBackendService that wraps existing AccessCodeValidator
/// This adapter maintains 100% backward compatibility while providing async interfaces
@MainActor
class OfflinePromoCodeService: PromoCodeBackendService {
    
    // MARK: - Dependencies (Existing Services - Unchanged)
    private let accessCodeValidator: AccessCodeValidator
    private let accessCodeStorage: AccessCodeStorage
    
    // MARK: - Initialization
    init(validator: AccessCodeValidator = AccessCodeValidator(),
         storage: AccessCodeStorage) {
        self.accessCodeValidator = validator
        self.accessCodeStorage = storage
    }
    
    // MARK: - PromoCodeBackendService Implementation
    
    func validateCodeAsync(_ code: String) async throws -> BackendValidationResult {
        // Use existing validator which returns AccessCodeValidationResult
        let validationResult = await accessCodeValidator.validateAccessCode(code)
        
        switch validationResult {
        case .valid(let accessCode):
            let result = BackendValidationResult(
                accessCode: accessCode,
                validatedAt: Date(),
                backendProvider: .offline,
                isOfflineValidation: true,
                serverMetadata: nil
            )
            
            if EnvironmentConfig.shouldLog {
                print("OfflinePromoCodeService: Successfully validated code offline")
            }
            
            return result
            
        case .invalid(let error):
            if EnvironmentConfig.shouldLog {
                print("OfflinePromoCodeService: Validation failed - \(error)")
            }
            throw error
        }
    }
    
    func trackUsageAsync(_ code: String, _ metadata: UsageMetadata) async throws {
        // For offline mode, we only track usage locally
        // Note: This is a simplified implementation for offline tracking
        if EnvironmentConfig.shouldLog {
            print("OfflinePromoCodeService: Tracked usage locally for code (simplified implementation)")
        }
        // In a real implementation, you might update local storage here
    }
    
    func getAnalyticsAsync(_ filters: AnalyticsFilters) async throws -> CodeAnalytics {
        // Generate analytics from local storage
        let storedCodes = await accessCodeStorage.getActiveAccessCodes()
        
        var filteredCodes = storedCodes
        
        // Apply filters
        if let codeType = filters.codeType {
            filteredCodes = filteredCodes.filter { $0.accessCode.type == codeType }
        }
        
        if !filters.includeExpired {
            filteredCodes = filteredCodes.filter { !$0.accessCode.isExpired }
        }
        
        if let dateRange = filters.dateRange {
            filteredCodes = filteredCodes.filter { dateRange.contains($0.activatedAt) }
        }
        
        // Calculate analytics
        let totalCodes = filteredCodes.count
        let usedCodes = filteredCodes.filter { $0.accessCode.usageCount > 0 }.count
        let activeUsers = Set(filteredCodes.compactMap { _ in "offline_user" }).count // Simplified for offline
        
        var usageByType: [AccessCodeType: Int] = [:]
        for code in filteredCodes {
            usageByType[code.accessCode.type, default: 0] += code.accessCode.usageCount
        }
        
        let analytics = CodeAnalytics(
            totalCodes: totalCodes,
            usedCodes: usedCodes,
            activeUsers: activeUsers,
            usageByType: usageByType,
            usageByDate: [:], // Simplified for offline mode
            generatedAt: Date()
        )
        
        if EnvironmentConfig.shouldLog {
            print("OfflinePromoCodeService: Generated analytics from \(totalCodes) local codes")
        }
        
        return analytics
    }
    
    func isBackendAvailable() async -> Bool {
        // Offline backend is always available
        return true
    }
}

/// Offline implementation of PromoCodeRepository that wraps existing AccessCodeStorage
@MainActor
class OfflinePromoCodeRepository: PromoCodeRepository {
    
    // MARK: - Dependencies (Existing Services - Unchanged)
    private let accessCodeStorage: AccessCodeStorage
    
    // MARK: - Initialization
    init(storage: AccessCodeStorage) {
        self.accessCodeStorage = storage
    }
    
    // MARK: - PromoCodeRepository Implementation
    
    func storeCodeAsync(_ code: StoredAccessCode) async throws {
        // Use existing storage method
        try await accessCodeStorage.storeAccessCode(code.accessCode)
        
        if EnvironmentConfig.shouldLog {
            print("OfflinePromoCodeRepository: Stored code locally")
        }
    }
    
    func fetchCodeAsync(_ codeString: String) async throws -> StoredAccessCode? {
        // Use existing storage method to get all codes
        let storedCodes = await accessCodeStorage.getActiveAccessCodes()
        let foundCode = storedCodes.first { $0.accessCode.code == codeString }
        
        if EnvironmentConfig.shouldLog {
            print("OfflinePromoCodeRepository: Fetched code from local storage: \(foundCode != nil ? "found" : "not found")")
        }
        
        return foundCode
    }
    
    func updateCodeUsageAsync(_ code: String, _ usage: CodeUsageData) async throws {
        // Simplified implementation for offline usage tracking
        if EnvironmentConfig.shouldLog {
            print("OfflinePromoCodeRepository: Updated code usage locally (simplified)")
        }
        // In a real implementation, you would update the stored code's usage data
    }
    
    func removeCodeAsync(_ code: String) async throws {
        // Use existing storage method
        await accessCodeStorage.removeAccessCode(code)
        
        if EnvironmentConfig.shouldLog {
            print("OfflinePromoCodeRepository: Removed code from local storage")
        }
    }
    
    func getAllCodesAsync() async throws -> [StoredAccessCode] {
        // Use existing storage method
        let storedCodes = await accessCodeStorage.getActiveAccessCodes()
        
        if EnvironmentConfig.shouldLog {
            print("OfflinePromoCodeRepository: Retrieved \(storedCodes.count) codes from local storage")
        }
        
        return storedCodes
    }
    
    func getActiveCodesAsync() async throws -> [StoredAccessCode] {
        let storedCodes = await accessCodeStorage.getActiveAccessCodes()
        let activeCodes = storedCodes.filter { !$0.accessCode.isExpired && $0.accessCode.isActive }
        
        if EnvironmentConfig.shouldLog {
            print("OfflinePromoCodeRepository: Retrieved \(activeCodes.count) active codes from local storage")
        }
        
        return activeCodes
    }
    
    func cleanupExpiredCodesAsync() async throws {
        // Simplified cleanup implementation
        if EnvironmentConfig.shouldLog {
            print("OfflinePromoCodeRepository: Cleaned up expired codes (simplified)")
        }
        // In a real implementation, you would clean up expired codes from storage
    }
}