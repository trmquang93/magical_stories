import Foundation
import OSLog

/// Service responsible for securely storing and managing access codes
@MainActor
class AccessCodeStorage: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var activeAccessCodes: [StoredAccessCode] = []
    @Published private(set) var isLoading = false
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicalstories", 
                               category: "AccessCodeStorage")
    private let userDefaults = UserDefaults.standard
    
    // UserDefaults keys for access code storage
    private enum UserDefaultsKeys {
        static let activeAccessCodes = "active_access_codes"
        static let accessCodeHistory = "access_code_history"
        static let lastCleanupDate = "last_access_code_cleanup"
        static let accessCodeUsageStats = "access_code_usage_stats"
    }
    
    // MARK: - Initialization
    
    init() {
        loadStoredAccessCodes()
        logger.info("AccessCodeStorage initialized with \(self.activeAccessCodes.count) active codes")
    }
    
    // MARK: - Public API
    
    /// Stores a new access code securely
    /// - Parameter accessCode: The access code to store
    /// - Throws: Storage errors if saving fails
    func storeAccessCode(_ accessCode: AccessCode) async throws {
        logger.info("💾 STORAGE: Starting to store access code...")
        logger.info("   Code: '\(accessCode.code)'")
        logger.info("   Type: \(accessCode.type.displayName)")
        logger.info("   Features: \(accessCode.grantedFeatures.map(\.rawValue).joined(separator: ", "))")
        
        isLoading = true
        defer { isLoading = false }
        
        // Check if code already exists
        if let existingIndex = activeAccessCodes.firstIndex(where: { $0.accessCode.code == accessCode.code }) {
            // Update existing code
            logger.info("🔄 Code already exists at index \(existingIndex), updating...")
            let previousActivationDate = activeAccessCodes[existingIndex].activatedAt
            activeAccessCodes[existingIndex] = StoredAccessCode(
                accessCode: accessCode,
                activatedAt: previousActivationDate,
                lastUsedAt: Date()
            )
            logger.info("✅ Successfully updated existing access code")
        } else {
            // Add new code
            logger.info("🆕 Adding new code to storage...")
            let storedCode = StoredAccessCode(accessCode: accessCode, activatedAt: Date())
            activeAccessCodes.append(storedCode)
            logger.info("✅ Successfully added new access code (total: \(self.activeAccessCodes.count))")
        }
        
        // Save to persistent storage
        logger.info("💾 Saving to UserDefaults...")
        try saveAccessCodes()
        logger.info("✅ Successfully saved to persistent storage")
        
        // Cleanup expired codes
        logger.info("🧹 Running cleanup for expired codes...")
        cleanupExpiredCodes()
        
        logger.info("🎉 STORAGE COMPLETE: Access code stored and activated!")
    }
    
    /// Retrieves all active access codes
    /// - Returns: Array of active stored access codes
    func getActiveAccessCodes() -> [StoredAccessCode] {
        return activeAccessCodes.filter { $0.accessCode.isValid }
    }
    
    /// Retrieves access codes that grant access to a specific feature
    /// - Parameter feature: The premium feature to check
    /// - Returns: Array of access codes that grant the feature
    func getAccessCodesGranting(_ feature: PremiumFeature) -> [StoredAccessCode] {
        return getActiveAccessCodes().filter { storedCode in
            storedCode.accessCode.grantedFeatures.contains(feature)
        }
    }
    
    /// Checks if any active access code grants access to a specific feature
    /// - Parameter feature: The premium feature to check
    /// - Returns: True if any active code grants access to the feature
    func hasAccessTo(_ feature: PremiumFeature) -> Bool {
        return getActiveAccessCodes().contains { storedCode in
            storedCode.accessCode.grantedFeatures.contains(feature)
        }
    }
    
    /// Gets all features currently accessible through active access codes
    /// - Returns: Set of premium features currently accessible
    func getAccessibleFeatures() -> Set<PremiumFeature> {
        let allFeatures = getActiveAccessCodes().flatMap { $0.accessCode.grantedFeatures }
        return Set(allFeatures)
    }
    
    /// Increments usage count for an access code
    /// - Parameter codeString: The access code string to update
    func incrementUsage(for codeString: String) {
        logger.info("Incrementing usage for access code: \(codeString.prefix(4))...")
        
        guard let index = activeAccessCodes.firstIndex(where: { $0.accessCode.code == codeString }) else {
            logger.warning("Access code not found for usage increment: \(codeString.prefix(4))")
            return
        }
        
        var storedCode = activeAccessCodes[index]
        var accessCode = storedCode.accessCode
        accessCode.usageCount += 1
        
        storedCode = StoredAccessCode(
            accessCode: accessCode,
            activatedAt: storedCode.activatedAt,
            lastUsedAt: Date()
        )
        
        activeAccessCodes[index] = storedCode
        
        // Save updated usage
        do {
            try saveAccessCodes()
            logger.info("Usage incremented for access code, new count: \(accessCode.usageCount)")
        } catch {
            logger.error("Failed to save access code usage update: \(error.localizedDescription)")
        }
        
        // Check if code should be deactivated due to usage limit
        if !accessCode.isValid {
            logger.info("Access code reached usage limit and is now invalid")
        }
    }
    
    /// Removes an access code from storage
    /// - Parameter codeString: The access code string to remove
    func removeAccessCode(_ codeString: String) {
        logger.info("Removing access code: \(codeString.prefix(4))...")
        
        activeAccessCodes.removeAll { $0.accessCode.code == codeString }
        
        do {
            try saveAccessCodes()
            logger.info("Access code removed successfully")
        } catch {
            logger.error("Failed to save after access code removal: \(error.localizedDescription)")
        }
    }
    
    /// Clears all stored access codes
    func clearAllAccessCodes() {
        logger.info("Clearing all stored access codes")
        
        activeAccessCodes.removeAll()
        
        do {
            try saveAccessCodes()
            userDefaults.removeObject(forKey: UserDefaultsKeys.accessCodeHistory)
            userDefaults.removeObject(forKey: UserDefaultsKeys.accessCodeUsageStats)
            logger.info("All access codes cleared successfully")
        } catch {
            logger.error("Failed to clear access codes: \(error.localizedDescription)")
        }
    }
    
    /// Gets usage statistics for access codes
    /// - Returns: Dictionary with usage statistics
    func getUsageStatistics() -> [String: Any] {
        let activeCodes = getActiveAccessCodes()
        let totalCodes = activeAccessCodes.count
        let expiredCodes = activeAccessCodes.count - activeCodes.count
        
        let featureUsage = activeCodes.reduce(into: [String: Int]()) { result, storedCode in
            for feature in storedCode.accessCode.grantedFeatures {
                result[feature.rawValue, default: 0] += storedCode.accessCode.usageCount
            }
        }
        
        // Convert Date to ISO8601 string for JSON serialization
        let formatter = ISO8601DateFormatter()
        
        return [
            "totalCodes": totalCodes,
            "activeCodes": activeCodes.count,
            "expiredCodes": expiredCodes,
            "featureUsage": featureUsage,
            "lastUpdated": formatter.string(from: Date())
        ]
    }
    
    // MARK: - Private Methods
    
    /// Loads stored access codes from UserDefaults
    private func loadStoredAccessCodes() {
        guard let data = userDefaults.data(forKey: UserDefaultsKeys.activeAccessCodes) else {
            logger.info("No stored access codes found")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            activeAccessCodes = try decoder.decode([StoredAccessCode].self, from: data)
            logger.info("Loaded \(self.activeAccessCodes.count) stored access codes")
        } catch {
            logger.error("Failed to decode stored access codes: \(error.localizedDescription)")
            activeAccessCodes = []
        }
    }
    
    /// Saves access codes to UserDefaults
    private func saveAccessCodes() throws {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(activeAccessCodes)
            
            userDefaults.set(data, forKey: UserDefaultsKeys.activeAccessCodes)
            
            logger.debug("Access codes saved to UserDefaults")
        } catch {
            logger.error("Failed to encode access codes for storage: \(error.localizedDescription)")
            throw AccessCodeStorageError.encodingFailed(error)
        }
    }
    
    /// Cleans up expired and invalid access codes
    private func cleanupExpiredCodes() {
        let initialCount = self.activeAccessCodes.count
        self.activeAccessCodes.removeAll { storedCode in
            !storedCode.accessCode.isValid
        }
        
        let removedCount = initialCount - self.activeAccessCodes.count
        if removedCount > 0 {
            logger.info("Cleaned up \(removedCount) expired/invalid access codes")
            
            do {
                try saveAccessCodes()
            } catch {
                logger.error("Failed to save after cleanup: \(error.localizedDescription)")
            }
        }
        
        // Update last cleanup date
        userDefaults.set(Date(), forKey: UserDefaultsKeys.lastCleanupDate)
    }
    
    /// Performs periodic maintenance on access code storage
    func performMaintenance() async {
        logger.info("Performing access code storage maintenance")
        
        isLoading = true
        defer { isLoading = false }
        
        // Cleanup expired codes
        cleanupExpiredCodes()
        
        // Update usage statistics
        let stats = getUsageStatistics()
        let statsData = try? JSONSerialization.data(withJSONObject: stats)
        userDefaults.set(statsData, forKey: UserDefaultsKeys.accessCodeUsageStats)
        
        logger.info("Access code storage maintenance completed")
    }
    
    /// Checks if maintenance is needed based on last cleanup date
    func isMaintenanceNeeded() -> Bool {
        guard let lastCleanup = userDefaults.object(forKey: UserDefaultsKeys.lastCleanupDate) as? Date else {
            return true // Never cleaned up
        }
        
        // Perform maintenance once per day
        return Date().timeIntervalSince(lastCleanup) > 24 * 60 * 60
    }
}

// MARK: - Access Code Storage Errors

/// Errors that can occur during access code storage operations
enum AccessCodeStorageError: LocalizedError {
    case encodingFailed(any Error)
    case decodingFailed(any Error)
    case keychainError(OSStatus)
    case dataCorrupted
    case insufficientSpace
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed(let error):
            return "Failed to encode access code data: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode access code data: \(error.localizedDescription)"
        case .keychainError(let status):
            return "Keychain operation failed with status: \(status)"
        case .dataCorrupted:
            return "Access code data is corrupted"
        case .insufficientSpace:
            return "Insufficient storage space for access codes"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .encodingFailed, .decodingFailed:
            return "Try clearing and re-adding access codes"
        case .keychainError:
            return "Check device security settings and available storage"
        case .dataCorrupted:
            return "Clear all access codes and re-add them"
        case .insufficientSpace:
            return "Free up device storage space and try again"
        }
    }
}

// MARK: - Extensions

extension AccessCodeStorage {
    
    /// Gets a summary of the current access code status
    var statusSummary: AccessCodeStatusSummary {
        let activeCodes = getActiveAccessCodes()
        let accessibleFeatures = getAccessibleFeatures()
        
        let expiringCodes = activeCodes.filter { storedCode in
            guard let daysRemaining = storedCode.accessCode.daysRemaining else { return false }
            return daysRemaining <= 7 // Expiring within 7 days
        }
        
        return AccessCodeStatusSummary(
            totalActiveCodes: activeCodes.count,
            accessibleFeatures: Array(accessibleFeatures),
            expiringCodesCount: expiringCodes.count,
            hasUnlimitedAccess: accessibleFeatures.count == PremiumFeature.allCases.count
        )
    }
}

// MARK: - Access Code Status Summary

/// Summary of current access code status
struct AccessCodeStatusSummary {
    let totalActiveCodes: Int
    let accessibleFeatures: [PremiumFeature]
    let expiringCodesCount: Int
    let hasUnlimitedAccess: Bool
    
    var hasAnyAccess: Bool {
        return totalActiveCodes > 0 && !accessibleFeatures.isEmpty
    }
    
    var statusDescription: String {
        if hasUnlimitedAccess {
            return "Full Premium Access"
        } else if accessibleFeatures.isEmpty {
            return "No Premium Access"
        } else {
            return "\(accessibleFeatures.count) Premium Feature\(accessibleFeatures.count == 1 ? "" : "s")"
        }
    }
}