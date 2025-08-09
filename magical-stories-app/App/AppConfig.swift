import Foundation

// MARK: - Configuration Errors
public enum ConfigurationError: Error, LocalizedError { // Make enum public
    case plistNotFound(String)
    case keyMissing(String)
    case invalidValue(String)
    case keychainError(String)
    case migrationFailed(any Error)
    // Keep other relevant errors if necessary, e.g., token generation
    // case tokenGenerationFailed(Error?)

    public var errorDescription: String? { // Make property public
        switch self {
        case .plistNotFound(let fileName):
            return "Configuration file '\(fileName)' not found."
        case .keyMissing(let key):
            return "Required configuration key '\(key)' is missing in Config.plist."
        case .invalidValue(let key):
            return "Invalid value type for configuration key '\(key)' in Config.plist."
        case .keychainError(let error):
            return "Keychain operation failed: \(error)"
        case .migrationFailed(let error):
            return "API key migration failed: \(error.localizedDescription)"
        // case .tokenGenerationFailed(let underlyingError):
        //     return "Failed to generate authentication token: \(underlyingError?.localizedDescription ?? "Unknown error")"
        }
    }
}

// MARK: - App Configuration
public struct AppConfig: @unchecked Sendable { // Make struct public

    private static nonisolated(unsafe) let config: [String: Any] = {
        guard let plistPath = Bundle.main.path(forResource: "Config", ofType: "plist") else {
            fatalError(ConfigurationError.plistNotFound("Config.plist").localizedDescription)
        }
        guard let plistData = FileManager.default.contents(atPath: plistPath) else {
            fatalError("Could not read Config.plist data.") // Or throw a specific error
        }
        do {
            guard let plistDict = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] else {
                fatalError("Could not deserialize Config.plist.") // Or throw
            }
            return plistDict
        } catch {
            fatalError("Error reading Config.plist: \(error.localizedDescription)") // Or throw
        }
    }()

    /// Retrieves a configuration value for a given key, throwing an error if missing or invalid.
    private static func value<T>(forKey key: String) throws -> T {
        guard let value = config[key] else {
            throw ConfigurationError.keyMissing(key)
        }
        guard let typedValue = value as? T else {
            throw ConfigurationError.invalidValue(key)
        }
        return typedValue
    }

    // --- Configuration Properties ---

    /// Google Cloud Project ID (Loaded from Config.plist)
    static var googleCloudProjectID: String {
        do {
            return try value(forKey: "GoogleCloudProjectID")
        } catch {
            fatalError(error.localizedDescription) // Handle error appropriately in production (e.g., log and return default/empty)
        }
    }

    /// Keychain service for secure API key storage
    private static let keychainService = KeychainService()
    
    /// Gemini API Key (Loaded from Keychain or development config)
    public static var geminiApiKey: String { // Make property public
        // In development, try development config first
        #if DEBUG
        if let devKey = getDevelopmentAPIKey() {
            print("[Development] Using API key from Config.dev.plist")
            return devKey
        }
        #endif
        
        // Try to retrieve from keychain first
        do {
            return try keychainService.retrieveAPIKey()
        } catch {
            // Key not found in keychain, try legacy migration from Config.plist if it still exists
            do {
                let plistKey: String = try value(forKey: "GeminiAPIKey")
                
                // Attempt to store the key from plist into keychain
                do {
                    try keychainService.storeAPIKey(plistKey)
                    print("[Security Migration] API key successfully migrated from Config.plist to Keychain")
                    return plistKey
                } catch {
                    print("[Security Migration] Warning: Failed to store API key in keychain, using plist fallback: \(error.localizedDescription)")
                    return plistKey
                }
            } catch {
                // Critical error: API key required for production
                print("[CRITICAL] API key not found in keychain or Config.plist")
                print("[CRITICAL] Production builds require valid API key")
                fatalError("Production API key not configured. Check Config.plist or keychain setup.")
            }
        }
    }
    
    /// Get API key from development configuration (DEBUG builds only)
    private static func getDevelopmentAPIKey() -> String? {
        guard let devConfigPath = Bundle.main.path(forResource: "Config.dev", ofType: "plist") else {
            return nil
        }
        
        guard let devConfigData = FileManager.default.contents(atPath: devConfigPath) else {
            return nil
        }
        
        do {
            guard let devConfig = try PropertyListSerialization.propertyList(from: devConfigData, options: [], format: nil) as? [String: Any] else {
                return nil
            }
            
            return devConfig["GeminiAPIKey"] as? String
        } catch {
            print("[Development] Error reading Config.dev.plist: \(error)")
            return nil
        }
    }

    /// Environment Information
    static let isDebugMode: Bool = ProcessInfo.processInfo.environment["DEBUG"] != nil

    // MARK: - Legal URLs
    /// Base URL for legal documents hosted on Firebase
    private static let legalBaseURL = "https://magical-stories-60046.web.app"
    
    /// Terms of Use URL
    static let termsOfUseURL = "\(legalBaseURL)/terms"
    
    /// Privacy Policy URL
    static let privacyPolicyURL = "\(legalBaseURL)/privacy"

    // Add other configuration properties as needed, loading from plist or using other sources
}