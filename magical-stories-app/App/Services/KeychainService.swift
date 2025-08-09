import Foundation
import Security

// MARK: - KeychainError
public enum KeychainError: Error, LocalizedError, Equatable {
    case invalidData
    case itemNotFound
    case operationFailed(OSStatus)
    
    public var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid data provided to keychain operation"
        case .itemNotFound:
            return "API key not found in keychain"
        case .operationFailed(let status):
            return "Keychain operation failed with status: \(status)"
        }
    }
    
    public static func == (lhs: KeychainError, rhs: KeychainError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidData, .invalidData):
            return true
        case (.itemNotFound, .itemNotFound):
            return true
        case (.operationFailed(let lhsStatus), .operationFailed(let rhsStatus)):
            return lhsStatus == rhsStatus
        default:
            return false
        }
    }
}

// MARK: - KeychainService
public final class KeychainService: @unchecked Sendable {
    
    // MARK: - Properties
    public let account: String
    public let service: String
    
    // MARK: - Initialization
    public init(account: String = "GeminiAPIKey", service: String = "com.magical-stories.api-keys") {
        self.account = account
        self.service = service
    }
    
    // MARK: - Public Methods
    
    /// Stores an API key in the iOS Keychain
    /// - Parameter key: The API key to store
    /// - Throws: KeychainError if the operation fails
    public func storeAPIKey(_ key: String) throws {
        guard !key.isEmpty else {
            throw KeychainError.invalidData
        }
        
        guard let keyData = key.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        // Create query for the keychain item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecValueData as String: keyData
        ]
        
        // Delete any existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.operationFailed(status)
        }
    }
    
    /// Retrieves the API key from the iOS Keychain
    /// - Returns: The stored API key
    /// - Throws: KeychainError if the key is not found or operation fails
    public func retrieveAPIKey() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            } else {
                throw KeychainError.operationFailed(status)
            }
        }
        
        guard let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return key
    }
}