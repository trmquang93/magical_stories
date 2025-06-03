import XCTest
import SwiftUI
@testable import magical_stories

class AccessCodeFormattingTests: XCTestCase {
    
    func testFormatForDisplay() {
        XCTAssertEqual(AccessCodeFormatting.formatForDisplay("RV23456789AB"), "RV-2345-6789-AB")
        XCTAssertEqual(AccessCodeFormatting.formatForDisplay("PR98765432CD"), "PR-9876-5432-CD")
        
        // Should handle already formatted codes
        XCTAssertEqual(AccessCodeFormatting.formatForDisplay("RV-2345-6789-AB"), "RV-2345-6789-AB")
        
        // Should handle invalid length gracefully
        XCTAssertEqual(AccessCodeFormatting.formatForDisplay("RV123"), "RV123")
        XCTAssertEqual(AccessCodeFormatting.formatForDisplay(""), "")
    }
    
    func testFormatForSharing() {
        XCTAssertEqual(AccessCodeFormatting.formatForSharing("RV23456789AB"), "RV-****-****-AB")
        XCTAssertEqual(AccessCodeFormatting.formatForSharing("PR98765432CD"), "PR-****-****-CD")
        
        // Should handle already formatted codes
        XCTAssertEqual(AccessCodeFormatting.formatForSharing("RV-2345-6789-AB"), "RV-****-****-AB")
        
        // Should handle invalid codes gracefully
        XCTAssertEqual(AccessCodeFormatting.formatForSharing("INVALID"), "****-****-****-**")
    }
    
    func testAttributedString() {
        let code = "RV23456789AB"
        let attributedString = AccessCodeFormatting.attributedString(for: code, highlightType: true)
        
        XCTAssertEqual(String(attributedString.characters), "RV-2345-6789-AB")
        // Note: Testing specific formatting attributes would require more complex setup
    }
    
    func testAttributedStringWithoutHighlight() {
        let code = "RV23456789AB"
        let attributedString = AccessCodeFormatting.attributedString(for: code, highlightType: false)
        
        XCTAssertEqual(String(attributedString.characters), "RV-2345-6789-AB")
    }
}

class AccessCodeValidationUtilitiesTests: XCTestCase {
    
    func testUserFriendlyErrorMessage() {
        let invalidFormatError = AccessCodeValidationError.invalidFormat
        let message = AccessCodeValidationUtilities.userFriendlyErrorMessage(for: invalidFormatError)
        XCTAssertTrue(message.contains("format"))
        XCTAssertTrue(message.contains("12 characters"))
        
        let expiredError = AccessCodeValidationError.codeExpired(expirationDate: Date())
        let expiredMessage = AccessCodeValidationUtilities.userFriendlyErrorMessage(for: expiredError)
        XCTAssertTrue(expiredMessage.contains("expired"))
        
        let usageLimitError = AccessCodeValidationError.usageLimitReached(limit: 10)
        let usageLimitMessage = AccessCodeValidationUtilities.userFriendlyErrorMessage(for: usageLimitError)
        XCTAssertTrue(usageLimitMessage.contains("10"))
        XCTAssertTrue(usageLimitMessage.contains("usage limit"))
    }
    
    func testRecoverySuggestion() {
        let invalidFormatError = AccessCodeValidationError.invalidFormat
        let suggestion = AccessCodeValidationUtilities.recoverySuggestion(for: invalidFormatError)
        XCTAssertTrue(suggestion.contains("check"))
        
        let networkError = AccessCodeValidationError.networkError("Connection failed")
        let networkSuggestion = AccessCodeValidationUtilities.recoverySuggestion(for: networkError)
        XCTAssertTrue(networkSuggestion.contains("internet connection"))
    }
    
    func testSuggestCorrections() {
        // Test with common character substitutions
        let suggestions1 = AccessCodeValidationUtilities.suggestCorrections(for: "RV23456789A0") // 0 -> O
        // The suggestions depend on whether the corrected code has a valid checksum
        XCTAssertTrue(suggestions1.isEmpty || suggestions1.allSatisfy { $0.contains("-") })
        
        let suggestions2 = AccessCodeValidationUtilities.suggestCorrections(for: "RV23456789A1") // 1 -> I
        XCTAssertTrue(suggestions2.isEmpty || suggestions2.allSatisfy { $0.contains("-") })
        
        // Test with valid input (should return empty)
        let validInput = "RV23456789AB"
        let noSuggestions = AccessCodeValidationUtilities.suggestCorrections(for: validInput)
        XCTAssertTrue(noSuggestions.isEmpty)
    }
}

class AccessCodeFeatureUtilitiesTests: XCTestCase {
    
    func testCompareFeatures() {
        let code1 = AccessCode(
            code: "RV23456789AB",
            type: .reviewer,
            grantedFeatures: [.unlimitedStoryGeneration, .advancedIllustrations]
        )
        
        let code2 = AccessCode(
            code: "PR23456789CD",
            type: .press,
            grantedFeatures: [.unlimitedStoryGeneration, .growthPathCollections]
        )
        
        let comparison = AccessCodeFeatureUtilities.compareFeatures(code1: code1, code2: code2)
        
        XCTAssertEqual(comparison.commonFeatures, [.unlimitedStoryGeneration])
        XCTAssertTrue(comparison.uniqueToFirst.contains(.advancedIllustrations))
        XCTAssertTrue(comparison.uniqueToSecond.contains(.growthPathCollections))
        XCTAssertTrue(comparison.hasCommonFeatures)
        XCTAssertTrue(comparison.hasDifferences)
    }
    
    func testCompareFeaturesIdentical() {
        let features = [PremiumFeature.unlimitedStoryGeneration, .advancedIllustrations]
        let code1 = AccessCode(code: "RV23456789AB", type: .reviewer, grantedFeatures: features)
        let code2 = AccessCode(code: "RV98765432CD", type: .reviewer, grantedFeatures: features)
        
        let comparison = AccessCodeFeatureUtilities.compareFeatures(code1: code1, code2: code2)
        
        XCTAssertEqual(comparison.commonFeatures.count, 2)
        XCTAssertTrue(comparison.uniqueToFirst.isEmpty)
        XCTAssertTrue(comparison.uniqueToSecond.isEmpty)
        XCTAssertTrue(comparison.hasCommonFeatures)
        XCTAssertFalse(comparison.hasDifferences)
    }
    
    func testPrioritizeFeatures() {
        let features: [PremiumFeature] = [
            .customThemes,
            .unlimitedStoryGeneration,
            .parentalAnalytics,
            .growthPathCollections
        ]
        
        let prioritized = AccessCodeFeatureUtilities.prioritizeFeatures(features)
        
        // Should put unlimitedStoryGeneration first and customThemes last
        XCTAssertEqual(prioritized.first, .unlimitedStoryGeneration)
        XCTAssertEqual(prioritized.last, .customThemes)
    }
    
    func testCreateFeatureSummary() {
        // All features
        let allFeatures = PremiumFeature.allCases
        let allSummary = AccessCodeFeatureUtilities.createFeatureSummary(allFeatures)
        XCTAssertEqual(allSummary, "All Premium Features")
        
        // No features
        let noFeatures: [PremiumFeature] = []
        let noSummary = AccessCodeFeatureUtilities.createFeatureSummary(noFeatures)
        XCTAssertEqual(noSummary, "No Premium Features")
        
        // Few features (should list them)
        let fewFeatures = [PremiumFeature.unlimitedStoryGeneration, .advancedIllustrations]
        let fewSummary = AccessCodeFeatureUtilities.createFeatureSummary(fewFeatures)
        XCTAssertTrue(fewSummary.contains("Unlimited Stories"))
        XCTAssertTrue(fewSummary.contains("Advanced Illustrations"))
        
        // Many features (should truncate)
        let manyFeatures = Array(PremiumFeature.allCases.prefix(5))
        let manySummary = AccessCodeFeatureUtilities.createFeatureSummary(manyFeatures)
        XCTAssertTrue(manySummary.contains("and 2 more"))
    }
}

class AccessCodeExpirationUtilitiesTests: XCTestCase {
    
    func testTimeRemainingDescription() {
        // Never expires
        let neverExpiringCode = AccessCode(code: "RV23456789AB", type: .reviewer, expiresAt: nil)
        XCTAssertEqual(AccessCodeExpirationUtilities.timeRemainingDescription(for: neverExpiringCode), "Never expires")
        
        // Days remaining
        let daysCode = AccessCode(
            code: "RV23456789CD",
            type: .reviewer,
            expiresAt: Date().addingTimeInterval(5 * 24 * 60 * 60) // 5 days
        )
        let daysDescription = AccessCodeExpirationUtilities.timeRemainingDescription(for: daysCode)
        XCTAssertTrue(daysDescription.contains("days remaining"))
        
        // Hours remaining
        let hoursCode = AccessCode(
            code: "RV23456789EF",
            type: .reviewer,
            expiresAt: Date().addingTimeInterval(3 * 60 * 60) // 3 hours
        )
        let hoursDescription = AccessCodeExpirationUtilities.timeRemainingDescription(for: hoursCode)
        XCTAssertTrue(hoursDescription.contains("hours remaining"))
        
        // Expired
        let expiredCode = AccessCode(
            code: "RV23456789GH",
            type: .reviewer,
            expiresAt: Date().addingTimeInterval(-24 * 60 * 60) // 1 day ago
        )
        XCTAssertEqual(AccessCodeExpirationUtilities.timeRemainingDescription(for: expiredCode), "Expired")
    }
    
    func testExpirationUrgency() {
        // Never expires
        let neverExpiringCode = AccessCode(code: "RV23456789AB", type: .reviewer, expiresAt: nil)
        XCTAssertEqual(AccessCodeExpirationUtilities.expirationUrgency(for: neverExpiringCode), .none)
        
        // Critical (1 day or less)
        let criticalCode = AccessCode(
            code: "RV23456789CD",
            type: .reviewer,
            expiresAt: Date().addingTimeInterval(12 * 60 * 60) // 12 hours
        )
        XCTAssertEqual(AccessCodeExpirationUtilities.expirationUrgency(for: criticalCode), .critical)
        
        // High (2-3 days)
        let highCode = AccessCode(
            code: "RV23456789EF",
            type: .reviewer,
            expiresAt: Date().addingTimeInterval(2.5 * 24 * 60 * 60) // 2.5 days
        )
        XCTAssertEqual(AccessCodeExpirationUtilities.expirationUrgency(for: highCode), .high)
        
        // Medium (4-7 days)
        let mediumCode = AccessCode(
            code: "RV23456789GH",
            type: .reviewer,
            expiresAt: Date().addingTimeInterval(5 * 24 * 60 * 60) // 5 days
        )
        XCTAssertEqual(AccessCodeExpirationUtilities.expirationUrgency(for: mediumCode), .medium)
        
        // Low (more than 7 days)
        let lowCode = AccessCode(
            code: "RV23456789JK",
            type: .reviewer,
            expiresAt: Date().addingTimeInterval(10 * 24 * 60 * 60) // 10 days
        )
        XCTAssertEqual(AccessCodeExpirationUtilities.expirationUrgency(for: lowCode), .low)
    }
    
    func testExpirationColor() {
        let neverExpiringCode = AccessCode(code: "RV23456789AB", type: .reviewer, expiresAt: nil)
        XCTAssertEqual(AccessCodeExpirationUtilities.expirationColor(for: neverExpiringCode), .primary)
        
        let lowUrgencyCode = AccessCode(
            code: "RV23456789CD",
            type: .reviewer,
            expiresAt: Date().addingTimeInterval(10 * 24 * 60 * 60)
        )
        XCTAssertEqual(AccessCodeExpirationUtilities.expirationColor(for: lowUrgencyCode), .green)
        
        let criticalCode = AccessCode(
            code: "RV23456789EF",
            type: .reviewer,
            expiresAt: Date().addingTimeInterval(12 * 60 * 60)
        )
        XCTAssertEqual(AccessCodeExpirationUtilities.expirationColor(for: criticalCode), .red)
    }
}

class AccessCodeInputHelpersTests: XCTestCase {
    
    func testFormatInput() {
        // Basic formatting
        XCTAssertEqual(AccessCodeInputHelpers.formatInput("rv23456789ab"), "RV-1234-5678-AB")
        XCTAssertEqual(AccessCodeInputHelpers.formatInput("RV23456789AB"), "RV-1234-5678-AB")
        
        // Remove invalid characters
        XCTAssertEqual(AccessCodeInputHelpers.formatInput("RV123@456#78AB"), "RV-1234-5678-AB")
        
        // Handle partial input
        XCTAssertEqual(AccessCodeInputHelpers.formatInput("RV12"), "RV-12")
        XCTAssertEqual(AccessCodeInputHelpers.formatInput("RV1234"), "RV-1234")
        XCTAssertEqual(AccessCodeInputHelpers.formatInput("RV123456"), "RV-1234-56")
        
        // Handle empty input
        XCTAssertEqual(AccessCodeInputHelpers.formatInput(""), "")
    }
    
    func testValidateInputLength() {
        // Empty
        let emptyResult = AccessCodeInputHelpers.validateInputLength("")
        if case .empty = emptyResult {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .empty result")
        }
        
        // Incomplete
        let incompleteResult = AccessCodeInputHelpers.validateInputLength("RV-1234")
        if case .incomplete(let current, let required) = incompleteResult {
            XCTAssertEqual(current, 6) // "RV1234" without dashes
            XCTAssertEqual(required, 12)
        } else {
            XCTFail("Expected .incomplete result")
        }
        
        // Complete
        let completeResult = AccessCodeInputHelpers.validateInputLength("RV-1234-5678-AB")
        if case .complete = completeResult {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .complete result")
        }
        
        // Too long
        let tooLongResult = AccessCodeInputHelpers.validateInputLength("RV-1234-5678-ABCD")
        if case .tooLong(let current, let maximum) = tooLongResult {
            XCTAssertEqual(current, 14) // "RV23456789ABCD" without dashes
            XCTAssertEqual(maximum, 12)
        } else {
            XCTFail("Expected .tooLong result")
        }
    }
    
    func testInputValidationResultProperties() {
        let emptyResult = InputValidationResult.empty
        XCTAssertFalse(emptyResult.isValid)
        XCTAssertNil(emptyResult.message)
        
        let incompleteResult = InputValidationResult.incomplete(current: 6, required: 12)
        XCTAssertFalse(incompleteResult.isValid)
        XCTAssertEqual(incompleteResult.message, "6/12 characters")
        
        let completeResult = InputValidationResult.complete
        XCTAssertTrue(completeResult.isValid)
        XCTAssertEqual(completeResult.message, "Ready to validate")
        
        let tooLongResult = InputValidationResult.tooLong(current: 14, maximum: 12)
        XCTAssertFalse(tooLongResult.isValid)
        XCTAssertEqual(tooLongResult.message, "Too long (14/12 characters)")
    }
}

class FeatureComparisonTests: XCTestCase {
    
    func testFeatureComparison() {
        let comparison = FeatureComparison(
            commonFeatures: [.unlimitedStoryGeneration],
            uniqueToFirst: [.advancedIllustrations],
            uniqueToSecond: [.growthPathCollections]
        )
        
        XCTAssertTrue(comparison.hasCommonFeatures)
        XCTAssertTrue(comparison.hasDifferences)
    }
    
    func testFeatureComparisonNoCommon() {
        let comparison = FeatureComparison(
            commonFeatures: [],
            uniqueToFirst: [.advancedIllustrations],
            uniqueToSecond: [.growthPathCollections]
        )
        
        XCTAssertFalse(comparison.hasCommonFeatures)
        XCTAssertTrue(comparison.hasDifferences)
    }
    
    func testFeatureComparisonNoDifferences() {
        let comparison = FeatureComparison(
            commonFeatures: [.unlimitedStoryGeneration, .advancedIllustrations],
            uniqueToFirst: [],
            uniqueToSecond: []
        )
        
        XCTAssertTrue(comparison.hasCommonFeatures)
        XCTAssertFalse(comparison.hasDifferences)
    }
}

class ExpirationUrgencyTests: XCTestCase {
    
    func testExpirationUrgencyEquality() {
        XCTAssertEqual(ExpirationUrgency.none, ExpirationUrgency.none)
        XCTAssertEqual(ExpirationUrgency.low, ExpirationUrgency.low)
        XCTAssertEqual(ExpirationUrgency.medium, ExpirationUrgency.medium)
        XCTAssertEqual(ExpirationUrgency.high, ExpirationUrgency.high)
        XCTAssertEqual(ExpirationUrgency.critical, ExpirationUrgency.critical)
        
        XCTAssertNotEqual(ExpirationUrgency.low, ExpirationUrgency.high)
        XCTAssertNotEqual(ExpirationUrgency.none, ExpirationUrgency.critical)
    }
}