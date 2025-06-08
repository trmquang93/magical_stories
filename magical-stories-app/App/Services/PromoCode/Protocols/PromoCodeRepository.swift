import Foundation

/// Protocol defining repository operations for promo code storage and retrieval
/// This abstraction allows switching between different storage backends
protocol PromoCodeRepository {
    
    /// Stores a promo code with its metadata
    /// - Parameter code: The promo code to store
    /// - Throws: Error if storage fails
    func storeCodeAsync(_ code: StoredAccessCode) async throws
    
    /// Retrieves a promo code by its string value
    /// - Parameter codeString: The code string to search for
    /// - Returns: StoredAccessCode if found, nil otherwise
    /// - Throws: Error if retrieval fails
    func fetchCodeAsync(_ codeString: String) async throws -> StoredAccessCode?
    
    /// Updates usage information for a promo code
    /// - Parameters:
    ///   - code: The code string to update
    ///   - usage: Updated usage information
    /// - Throws: Error if update fails
    func updateCodeUsageAsync(_ code: String, _ usage: CodeUsageData) async throws
    
    /// Removes a promo code from storage
    /// - Parameter code: The code string to remove
    /// - Throws: Error if removal fails
    func removeCodeAsync(_ code: String) async throws
    
    /// Gets all stored promo codes
    /// - Returns: Array of all stored codes
    /// - Throws: Error if retrieval fails
    func getAllCodesAsync() async throws -> [StoredAccessCode]
    
    /// Gets active (non-expired, non-exhausted) promo codes
    /// - Returns: Array of active codes
    /// - Throws: Error if retrieval fails
    func getActiveCodesAsync() async throws -> [StoredAccessCode]
    
    /// Cleans up expired and exhausted codes
    /// - Throws: Error if cleanup fails
    func cleanupExpiredCodesAsync() async throws
}

/// Extended usage data for promo codes
struct CodeUsageData {
    let usageCount: Int
    let lastUsedAt: Date?
    let deviceIds: Set<String>
    let userIds: Set<String>
    
    init(usageCount: Int = 0,
         lastUsedAt: Date? = nil,
         deviceIds: Set<String> = [],
         userIds: Set<String> = []) {
        self.usageCount = usageCount
        self.lastUsedAt = lastUsedAt
        self.deviceIds = deviceIds
        self.userIds = userIds
    }
}

/// Repository query filters
struct RepositoryFilters {
    let includeExpired: Bool
    let includeExhausted: Bool
    let codeType: AccessCodeType?
    let dateRange: ClosedRange<Date>?
    
    init(includeExpired: Bool = false,
         includeExhausted: Bool = false,
         codeType: AccessCodeType? = nil,
         dateRange: ClosedRange<Date>? = nil) {
        self.includeExpired = includeExpired
        self.includeExhausted = includeExhausted
        self.codeType = codeType
        self.dateRange = dateRange
    }
}

/// Error types for repository operations
enum RepositoryError: LocalizedError {
    case codeNotFound(String)
    case storageUnavailable
    case invalidData
    case duplicateCode(String)
    
    var errorDescription: String? {
        switch self {
        case .codeNotFound(let code):
            return "Promo code '\(code)' not found in storage"
        case .storageUnavailable:
            return "Storage backend is currently unavailable"
        case .invalidData:
            return "Invalid data format in storage"
        case .duplicateCode(let code):
            return "Promo code '\(code)' already exists in storage"
        }
    }
}