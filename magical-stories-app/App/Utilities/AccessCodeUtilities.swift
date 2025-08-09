import Foundation
import SwiftUI

// MARK: - Access Code Formatting Utilities

/// Utilities for formatting and displaying access codes
struct AccessCodeFormatting {
    
    /// Formats an access code string for display with separators
    /// - Parameter code: The raw access code string
    /// - Returns: Formatted access code string (e.g., "RV-ABCD-EFGH-12")
    static func formatForDisplay(_ code: String) -> String {
        let cleanCode = code.replacingOccurrences(of: "-", with: "")
        guard cleanCode.count == AccessCodeFormat.codeLength else { return code }
        
        // Format as XX-XXXX-XXXX-XX
        let prefix = String(cleanCode.prefix(2))
        let middle1 = String(cleanCode.dropFirst(2).prefix(4))
        let middle2 = String(cleanCode.dropFirst(6).prefix(4))
        let suffix = String(cleanCode.suffix(2))
        
        return "\(prefix)-\(middle1)-\(middle2)-\(suffix)"
    }
    
    /// Formats an access code for sharing (removes sensitive information)
    /// - Parameter code: The access code string
    /// - Returns: Partially masked code for sharing
    static func formatForSharing(_ code: String) -> String {
        let formattedCode = formatForDisplay(code)
        let components = formattedCode.split(separator: "-")
        guard components.count == 4 else { return "****-****-****-**" }
        
        // Show first and last segments, mask middle
        return "\(components[0])-****-****-\(components[3])"
    }
    
    /// Creates an attributed string for access code display
    /// - Parameters:
    ///   - code: The access code string
    ///   - highlightType: Whether to highlight the code type prefix
    /// - Returns: AttributedString with formatting
    static func attributedString(for code: String, highlightType: Bool = true) -> AttributedString {
        let formattedCode = formatForDisplay(code)
        var attributedString = AttributedString(formattedCode)
        
        if highlightType {
            // Highlight the prefix (first 2 characters + separator)
            if let prefixRange = attributedString.range(of: String(formattedCode.prefix(3))) {
                attributedString[prefixRange].foregroundColor = .blue
                attributedString[prefixRange].font = .monospaced(.body)().bold()
            }
        }
        
        return attributedString
    }
}

// MARK: - Access Code Validation Utilities

/// Utilities for access code validation and error handling
struct AccessCodeValidationUtilities {
    
    /// Provides user-friendly error messages for validation errors
    /// - Parameter error: The validation error
    /// - Returns: User-friendly error description
    static func userFriendlyErrorMessage(for error: AccessCodeValidationError) -> String {
        switch error {
        case .invalidFormat:
            return "Please check the access code format. It should be 12 characters long."
        case .codeNotFound:
            return "This access code is not valid. Please check and try again."
        case .codeExpired(let expirationDate):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "This access code expired on \(formatter.string(from: expirationDate))."
        case .usageLimitReached(let limit):
            return "This access code has reached its usage limit of \(limit) uses."
        case .codeInactive:
            return "This access code is no longer active."
        case .checksumMismatch:
            return "The access code appears to be incorrect. Please check and try again."
        case .networkError(let message):
            return "Unable to verify access code due to network issues: \(message)"
        case .unknown(let message):
            return "An error occurred: \(message)"
        }
    }
    
    /// Provides recovery suggestions for validation errors
    /// - Parameter error: The validation error
    /// - Returns: Suggested actions for the user
    static func recoverySuggestion(for error: AccessCodeValidationError) -> String {
        switch error {
        case .invalidFormat, .checksumMismatch:
            return "Double-check the access code and make sure all characters are entered correctly."
        case .codeNotFound:
            return "Contact support if you believe this code should be valid."
        case .codeExpired:
            return "Contact the person who provided the code for a new one."
        case .usageLimitReached:
            return "This code has been fully used. Contact support for assistance."
        case .codeInactive:
            return "This code may have been deactivated. Contact support for more information."
        case .networkError:
            return "Check your internet connection and try again."
        case .unknown:
            return "Try again, or contact support if the problem persists."
        }
    }
    
    /// Suggests fixes for common input errors
    /// - Parameter input: The user's input string
    /// - Returns: Suggested corrections, if any
    static func suggestCorrections(for input: String) -> [String] {
        var suggestions: [String] = []
        
        let cleanInput = input.uppercased().replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        
        // Check for common character substitutions
        let corrections = [
            ("0", "O"), ("1", "I"), ("5", "S"), ("8", "B")
        ]
        
        for (wrong, correct) in corrections {
            if cleanInput.contains(wrong) {
                let corrected = cleanInput.replacingOccurrences(of: wrong, with: correct)
                if AccessCodeFormat.isValidFormat(corrected) {
                    suggestions.append(AccessCodeFormatting.formatForDisplay(corrected))
                }
            }
        }
        
        return suggestions
    }
}

// MARK: - Access Code Feature Utilities

/// Utilities for working with access code features
struct AccessCodeFeatureUtilities {
    
    /// Creates a feature comparison between two access codes
    /// - Parameters:
    ///   - code1: First access code
    ///   - code2: Second access code
    /// - Returns: Feature comparison result
    static func compareFeatures(code1: AccessCode, code2: AccessCode) -> FeatureComparison {
        let features1 = Set(code1.grantedFeatures)
        let features2 = Set(code2.grantedFeatures)
        
        let commonFeatures = features1.intersection(features2)
        let uniqueToCode1 = features1.subtracting(features2)
        let uniqueToCode2 = features2.subtracting(features1)
        
        return FeatureComparison(
            commonFeatures: Array(commonFeatures),
            uniqueToFirst: Array(uniqueToCode1),
            uniqueToSecond: Array(uniqueToCode2)
        )
    }
    
    /// Gets a prioritized list of features for display
    /// - Parameter features: Array of premium features
    /// - Returns: Features sorted by importance/priority
    static func prioritizeFeatures(_ features: [PremiumFeature]) -> [PremiumFeature] {
        let priorityOrder: [PremiumFeature] = [
            .unlimitedStoryGeneration,
            .growthPathCollections,
            .advancedIllustrations,
            .multipleChildProfiles,
            .priorityGeneration,
            .parentalAnalytics,
            .offlineReading,
            .customThemes
        ]
        
        // Sort features based on priority order
        return features.sorted { feature1, feature2 in
            let index1 = priorityOrder.firstIndex(of: feature1) ?? Int.max
            let index2 = priorityOrder.firstIndex(of: feature2) ?? Int.max
            return index1 < index2
        }
    }
    
    /// Creates a feature summary for display
    /// - Parameter features: Array of premium features
    /// - Returns: Human-readable feature summary
    static func createFeatureSummary(_ features: [PremiumFeature]) -> String {
        let prioritized = prioritizeFeatures(features)
        
        if prioritized.count == PremiumFeature.allCases.count {
            return "All Premium Features"
        } else if prioritized.isEmpty {
            return "No Premium Features"
        } else if prioritized.count <= 3 {
            return prioritized.map { $0.displayName }.joined(separator: ", ")
        } else {
            let first3 = prioritized.prefix(3).map { $0.displayName }.joined(separator: ", ")
            let remaining = prioritized.count - 3
            return "\(first3) and \(remaining) more"
        }
    }
}

// MARK: - Access Code Expiration Utilities

/// Utilities for handling access code expiration
struct AccessCodeExpirationUtilities {
    
    /// Calculates time remaining for an access code
    /// - Parameter accessCode: The access code to check
    /// - Returns: Time remaining description
    static func timeRemainingDescription(for accessCode: AccessCode) -> String {
        guard let expiresAt = accessCode.expiresAt else {
            return "Never expires"
        }
        
        let timeRemaining = expiresAt.timeIntervalSince(Date())
        
        if timeRemaining <= 0 {
            return "Expired"
        }
        
        let days = Int(timeRemaining / (24 * 60 * 60))
        let hours = Int((timeRemaining.truncatingRemainder(dividingBy: 24 * 60 * 60)) / (60 * 60))
        
        if days > 0 {
            return days == 1 ? "1 day remaining" : "\(days) days remaining"
        } else if hours > 0 {
            return hours == 1 ? "1 hour remaining" : "\(hours) hours remaining"
        } else {
            let minutes = Int(timeRemaining / 60)
            return minutes <= 1 ? "Less than a minute remaining" : "\(minutes) minutes remaining"
        }
    }
    
    /// Determines the urgency level of expiration
    /// - Parameter accessCode: The access code to check
    /// - Returns: Expiration urgency level
    static func expirationUrgency(for accessCode: AccessCode) -> ExpirationUrgency {
        guard let daysRemaining = accessCode.daysRemaining else {
            return .none
        }
        
        if daysRemaining <= 1 {
            return .critical
        } else if daysRemaining <= 3 {
            return .high
        } else if daysRemaining <= 7 {
            return .medium
        } else {
            return .low
        }
    }
    
    /// Gets appropriate color for expiration status
    /// - Parameter accessCode: The access code to check
    /// - Returns: Color for UI display
    static func expirationColor(for accessCode: AccessCode) -> Color {
        switch expirationUrgency(for: accessCode) {
        case .none:
            return .primary
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        case .critical:
            return .red
        }
    }
}

// MARK: - Supporting Types

/// Result of comparing features between two access codes
struct FeatureComparison {
    let commonFeatures: [PremiumFeature]
    let uniqueToFirst: [PremiumFeature]
    let uniqueToSecond: [PremiumFeature]
    
    var hasCommonFeatures: Bool {
        return !commonFeatures.isEmpty
    }
    
    var hasDifferences: Bool {
        return !uniqueToFirst.isEmpty || !uniqueToSecond.isEmpty
    }
}

/// Urgency level for access code expiration
enum ExpirationUrgency {
    case none       // Never expires
    case low        // More than 7 days
    case medium     // 4-7 days
    case high       // 2-3 days
    case critical   // 1 day or less
}

// MARK: - Access Code Input Helpers

/// Utilities for handling access code input
struct AccessCodeInputHelpers {
    
    /// Cleans and formats user input as they type
    /// - Parameter input: Raw user input
    /// - Returns: Cleaned and formatted input
    static func formatInput(_ input: String) -> String {
        // Remove invalid characters and convert to uppercase
        let cleaned = input
            .uppercased()
            .filter { AccessCodeFormat.allowedCharacters.contains($0) || $0 == "-" }
        
        // Auto-format with dashes
        return autoFormatWithDashes(cleaned)
    }
    
    /// Automatically adds dashes to access code input
    /// - Parameter input: Input string without formatting
    /// - Returns: Formatted string with dashes
    private static func autoFormatWithDashes(_ input: String) -> String {
        let digitsOnly = input.replacingOccurrences(of: "-", with: "")
        var formatted = ""
        
        for (index, character) in digitsOnly.enumerated() {
            if index == 2 || index == 6 || index == 10 {
                formatted += "-"
            }
            formatted += String(character)
        }
        
        return formatted
    }
    
    /// Validates input length and provides feedback
    /// - Parameter input: User input string
    /// - Returns: Input validation result
    static func validateInputLength(_ input: String) -> InputValidationResult {
        let cleanInput = input.replacingOccurrences(of: "-", with: "")
        
        if cleanInput.isEmpty {
            return .empty
        } else if cleanInput.count < AccessCodeFormat.codeLength {
            return .incomplete(current: cleanInput.count, required: AccessCodeFormat.codeLength)
        } else if cleanInput.count == AccessCodeFormat.codeLength {
            return .complete
        } else {
            return .tooLong(current: cleanInput.count, maximum: AccessCodeFormat.codeLength)
        }
    }
}

/// Result of input validation
enum InputValidationResult {
    case empty
    case incomplete(current: Int, required: Int)
    case complete
    case tooLong(current: Int, maximum: Int)
    
    var isValid: Bool {
        switch self {
        case .complete:
            return true
        default:
            return false
        }
    }
    
    var message: String? {
        switch self {
        case .empty:
            return nil
        case .incomplete(let current, let required):
            return "\(current)/\(required) characters"
        case .complete:
            return "Ready to validate"
        case .tooLong(let current, let maximum):
            return "Too long (\(current)/\(maximum) characters)"
        }
    }
}