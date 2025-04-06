import Foundation

// MARK: - Configuration Errors
enum ConfigurationError: Error, LocalizedError {
    case plistNotFound(String)
    case keyMissing(String)
    case invalidValue(String)
    // Keep other relevant errors if necessary, e.g., token generation
    // case tokenGenerationFailed(Error?)

    var errorDescription: String? {
        switch self {
        case .plistNotFound(let fileName):
            return "Configuration file '\(fileName)' not found."
        case .keyMissing(let key):
            return "Required configuration key '\(key)' is missing in Config.plist."
        case .invalidValue(let key):
            return "Invalid value type for configuration key '\(key)' in Config.plist."
        // case .tokenGenerationFailed(let underlyingError):
        //     return "Failed to generate authentication token: \(underlyingError?.localizedDescription ?? "Unknown error")"
        }
    }
}

// MARK: - App Configuration
struct AppConfig {

    private static let config: [String: Any] = {
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

    /// Gemini API Key (Loaded from Config.plist)
    static var geminiApiKey: String {
         do {
            return try value(forKey: "GeminiAPIKey")
        } catch {
            fatalError(error.localizedDescription) // Handle error appropriately
        }
    }

    /// Environment Information
    static let isDebugMode: Bool = ProcessInfo.processInfo.environment["DEBUG"] != nil

    // Add other configuration properties as needed, loading from plist or using other sources
}