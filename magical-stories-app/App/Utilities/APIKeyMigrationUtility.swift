import Foundation

// MARK: - API Key Migration Utility
/// Utility for one-time API key setup in production environment
public struct APIKeyMigrationUtility {
    
    private static let keychainService = KeychainService()
    
    /// Manually stores the API key in Keychain for production deployment
    /// This should be called once during the deployment process
    /// - Parameter apiKey: The Gemini API key to store securely
    /// - Throws: KeychainError if storage fails
    public static func storeProductionAPIKey(_ apiKey: String) throws {
        guard !apiKey.isEmpty else {
            throw KeychainError.invalidData
        }
        
        try keychainService.storeAPIKey(apiKey)
        print("[Security Setup] Production API key stored successfully in Keychain")
    }
    
    /// Verifies that the API key is properly stored in Keychain
    /// - Returns: True if API key exists and is accessible, false otherwise
    public static func verifyAPIKeySetup() -> Bool {
        do {
            let key = try keychainService.retrieveAPIKey()
            return !key.isEmpty
        } catch {
            return false
        }
    }
    
    /// Retrieves the current API key for verification purposes
    /// - Returns: The stored API key
    /// - Throws: KeychainError if retrieval fails
    public static func getCurrentAPIKey() throws -> String {
        return try keychainService.retrieveAPIKey()
    }
}