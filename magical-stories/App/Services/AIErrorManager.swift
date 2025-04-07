import Foundation
import os.log
import SwiftUI

// MARK: - AI API Error Types

/// Common error types for AI API interactions (text and image generation)
enum AIError: Error, LocalizedError, Identifiable {
    // General errors
    case networkError(Error)
    case apiError(String, Error?)
    case configurationError(String)
    
    // Text generation specific errors
    case textGenerationFailed(String)
    case invalidTextGenerationParameters(String)
    case contentFilterTriggered(String)
    
    // Image generation specific errors
    case imageGenerationFailed(String)
    case noImageDataReturned
    case imageProcessingError(String)
    
    // Resource errors
    case resourceUnavailable(String)
    
    // Unique identifier for the error
    var id: String {
        switch self {
        case .networkError(let error):
            return "network-\(error.localizedDescription.hash)"
        case .apiError(let message, _):
            return "api-\(message.hash)"
        case .configurationError(let message):
            return "config-\(message.hash)"
        case .textGenerationFailed(let message):
            return "text-gen-\(message.hash)"
        case .invalidTextGenerationParameters(let message):
            return "invalid-params-\(message.hash)"
        case .contentFilterTriggered(let message):
            return "content-filter-\(message.hash)"
        case .imageGenerationFailed(let message):
            return "image-gen-\(message.hash)"
        case .noImageDataReturned:
            return "no-image-data"
        case .imageProcessingError(let message):
            return "image-proc-\(message.hash)"
        case .resourceUnavailable(let message):
            return "resource-\(message.hash)"
        }
    }
    
    // User-friendly error messages
    var errorDescription: String? {
        switch self {
        case .networkError(_):
            return "Network connection problem. Please check your internet connection and try again."
        case .apiError(let message, _):
            return "There was a problem with the AI service: \(message)"
        case .configurationError(let message):
            return "App configuration error: \(message)"
        case .textGenerationFailed(let message):
            return "Failed to generate story: \(message)"
        case .invalidTextGenerationParameters(let message):
            return "Invalid story parameters: \(message)"
        case .contentFilterTriggered(_):
            return "The story couldn't be generated because the content was flagged by safety filters."
        case .imageGenerationFailed(let message):
            return "Failed to generate illustration: \(message)"
        case .noImageDataReturned:
            return "The illustration service didn't return any image data."
        case .imageProcessingError(_):
            return "There was a problem processing the generated illustration."
        case .resourceUnavailable(let message):
            return "Required resource is unavailable: \(message)"
        }
    }
    
    // More detailed explanation for technical purposes
    var failureReason: String? {
        switch self {
        case .networkError(let error):
            return "Network request failed: \(error.localizedDescription)"
        case .apiError(_, let underlyingError):
            return underlyingError?.localizedDescription ?? "API returned an error response"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .textGenerationFailed(let message):
            return "Text generation failed: \(message)"
        case .invalidTextGenerationParameters(let message):
            return "Invalid parameters provided: \(message)"
        case .contentFilterTriggered(let message):
            return "Content filter triggered: \(message)"
        case .imageGenerationFailed(let message):
            return "Image generation failed: \(message)"
        case .noImageDataReturned:
            return "API response did not contain valid image data"
        case .imageProcessingError(let message):
            return "Failed to process image data: \(message)"
        case .resourceUnavailable(let message):
            return "Required resource unavailable: \(message)"
        }
    }
    
    // Recovery suggestions for the user
    var recoverySuggestion: String? {
        switch self {
        case .networkError(_):
            return "Check your internet connection and try again. If the problem persists, wait a few minutes before retrying."
        case .apiError(_, _):
            return "Wait a few moments and try again. If this issue continues, the AI service might be experiencing problems."
        case .configurationError(_):
            return "Try restarting the app. If the problem persists, reinstall the application."
        case .textGenerationFailed(_):
            return "Try generating the story again with slightly different parameters like a different theme or character."
        case .invalidTextGenerationParameters(_):
            return "Please make sure all story parameters are filled in correctly."
        case .contentFilterTriggered(_):
            return "Try generating the story with a different theme or character description that doesn't include sensitive content."
        case .imageGenerationFailed(_):
            return "Try generating the illustration again. Consider simplifying the scene description for better results."
        case .noImageDataReturned:
            return "Try generating the illustration again. If this continues, the app will use placeholder images."
        case .imageProcessingError(_):
            return "Try generating the illustration again. If this continues, the app will use placeholder images."
        case .resourceUnavailable(_):
            return "Try again later when the resource might become available."
        }
    }
    
    // Determine if this error should be displayed to the user
    var shouldDisplayToUser: Bool {
        switch self {
        // Technical errors we might not want to show to users directly
        case .configurationError(_): return false
        // All other errors should be user-visible with appropriate messaging
        default: return true
        }
    }
    
    // Convert from other error types
    static func from(_ error: Error) -> AIError {
        // Handle specific error conversions
        if let illError = error as? IllustrationError {
            return fromIllustrationError(illError)
        } else if let storyError = error as? StoryServiceError {
            return fromStoryServiceError(storyError)
        } else if let configError = error as? ConfigurationError {
            return .configurationError(configError.localizedDescription)
        } else if let urlError = error as? URLError {
            return .networkError(urlError)
        } else {
            // Generic conversion for unhandled error types
            return .apiError("Unexpected error", error)
        }
    }
    
    // Convert from IllustrationError
    private static func fromIllustrationError(_ error: IllustrationError) -> AIError {
        switch error {
        case .missingConfiguration(let detail):
            return .configurationError(detail)
        case .invalidURL:
            return .apiError("Invalid URL encountered", nil)
        case .networkError(let underlyingError):
            return .networkError(underlyingError)
        case .apiError(let underlyingError):
            return .apiError("API request failed", underlyingError)
        case .invalidResponse(let reason):
            return .apiError("Invalid response: \(reason)", nil)
        case .noImageDataFound:
            return .noImageDataReturned
        case .imageProcessingError(let reason):
            return .imageProcessingError(reason)
        case .generationFailed(let reason):
            return .imageGenerationFailed(reason)
        case .unsupportedModel:
            return .configurationError("Unsupported image generation model")
        }
    }
    
    // Convert from StoryServiceError
    private static func fromStoryServiceError(_ error: StoryServiceError) -> AIError {
        switch error {
        case .generationFailed(let message):
            return .textGenerationFailed(message)
        case .invalidParameters:
            return .invalidTextGenerationParameters("Required story parameters are missing or invalid")
        case .persistenceFailed:
            return .resourceUnavailable("Story storage")
        case .networkError:
            return .networkError(NSError(domain: "StoryService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Network connection error"]))
        }
    }
}

// MARK: - AIErrorManager

/// Manager for handling AI API errors consistently across the app
class AIErrorManager {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app.magical-stories", category: "AIErrors")
    
    // MARK: - Error Logging
    
    /// Log an error with appropriate level and information
    /// - Parameters:
    ///   - error: The error to log
    ///   - source: Source component generating the error
    ///   - additionalInfo: Any additional context for the error
    static func logError(_ error: Error, source: String, additionalInfo: String? = nil) {
        let aiError = AIError.from(error)
        
        // Format the log message with source and additional info
        var logMessage = "[\(source)] \(aiError.failureReason ?? error.localizedDescription)"
        if let info = additionalInfo, !info.isEmpty {
            logMessage += " | \(info)"
        }
        
        // Log with appropriate level based on error severity
        switch aiError {
        case .networkError(_), .apiError(_, _):
            // Network/API errors are common and often temporary
            logger.info("\(logMessage)")
        case .configurationError(_):
            // Configuration errors are serious app issues
            logger.error("\(logMessage)")
        case .contentFilterTriggered(_):
            // Content filter triggers are important to track but not critical errors
            logger.notice("\(logMessage)")
        default:
            // Standard logging for other errors
            logger.warning("\(logMessage)")
        }
    }
    
    // MARK: - Fallback Helpers
    
    /// Get a placeholder illustration URL for cases where image generation fails
    /// - Parameter theme: The story theme to match the placeholder to
    /// - Returns: URL to an appropriate placeholder image
    static func placeholderIllustrationURL(for theme: String) -> URL? {
        // In a real implementation, this could return different themed placeholders
        // For now, we use the placeholder from the asset catalog
        
        // Since the real service returns file URLs, we'll simulate the same by
        // creating a local URL that will be specially handled by the UI layer
        let placeholderURL = URL(string: "asset://placeholder-illustration")
        return placeholderURL
    }
    
    /// Get a placeholder story when text generation fails
    /// - Parameter parameters: The story parameters to incorporate into the placeholder
    /// - Returns: A basic placeholder story
    static func placeholderStory(for parameters: StoryParameters) -> String {
        return """
        Title: \(parameters.childName)'s Adventure
        
        Once upon a time, there was a child named \(parameters.childName) who loved adventures. 
        One day, \(parameters.childName) met a friend named \(parameters.favoriteCharacter).
        They had a wonderful time learning about \(parameters.theme).
        The end.
        """
    }
    
    // MARK: - Alert Creation
    
    /// Create an alert to display to the user for an AI error
    /// - Parameters:
    ///   - error: The error to display
    ///   - retryAction: Optional action to run when the user taps retry
    /// - Returns: An Alert to display
    static func createAlert(for error: Error, retryAction: (() -> Void)? = nil) -> Alert {
        let aiError = AIError.from(error)
        
        // If we have a retry action, include a retry button
        if let retry = retryAction {
            return Alert(
                title: Text("Something Went Wrong"),
                message: Text([aiError.errorDescription, aiError.recoverySuggestion].compactMap { $0 }.joined(separator: "\n\n")),
                primaryButton: .default(Text("Try Again"), action: retry),
                secondaryButton: .cancel(Text("Cancel"))
            )
        } else {
            // Simple OK button if no retry action
            return Alert(
                title: Text("Something Went Wrong"),
                message: Text([aiError.errorDescription, aiError.recoverySuggestion].compactMap { $0 }.joined(separator: "\n\n")),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}