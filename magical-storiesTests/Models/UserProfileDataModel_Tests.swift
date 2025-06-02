import Foundation
import SwiftData
import XCTest

@testable import magical_stories

final class UserProfileDataModel_Tests: XCTestCase {
    
    // MARK: - Test Initialization
    
    func testDefaultInitialization() {
        let profile = UserProfile()
        
        // Verify core fields
        XCTAssertEqual(profile.childName, "Adventurer")
        XCTAssertTrue(profile.interests.isEmpty)
        XCTAssertTrue(profile.preferredThemes.isEmpty)
        XCTAssertTrue(profile.favoriteCharacters.isEmpty)
        
        // Verify settings
        XCTAssertTrue(profile.useTextToSpeech)
        XCTAssertNil(profile.preferredVoiceIdentifier)
        XCTAssertEqual(profile.darkModePreference, .system)
        
        // Verify statistics
        XCTAssertEqual(profile.totalStoriesRead, 0)
        XCTAssertEqual(profile.totalReadingTime, 0.0)
        XCTAssertNil(profile.lastReadDate)
        
        // Verify analytics fields
        XCTAssertEqual(profile.storyGenerationCount, 0)
        XCTAssertNil(profile.lastGenerationDate)
        XCTAssertNil(profile.lastGeneratedStoryId)
        
        // Verify subscription fields
        XCTAssertEqual(profile.monthlyStoryCount, 0)
        XCTAssertNil(profile.subscriptionExpiryDate)
        XCTAssertFalse(profile.hasActiveSubscription)
        XCTAssertNil(profile.subscriptionProductId)
        XCTAssertTrue(profile.premiumFeaturesUsed.isEmpty)
        
        // Verify dates are recent
        let now = Date()
        XCTAssertLessThan(abs(profile.createdAt.timeIntervalSince(now)), 1.0)
        XCTAssertNotNil(profile.currentPeriodStart)
        XCTAssertNotNil(profile.lastUsageReset)
    }
    
    func testCustomInitialization() {
        let customId = UUID()
        let customName = "TestChild"
        let customDOB = Date(timeIntervalSince1970: 0)
        
        let profile = UserProfile(id: customId, childName: customName, dateOfBirth: customDOB)
        
        XCTAssertEqual(profile.id, customId)
        XCTAssertEqual(profile.childName, customName)
        XCTAssertEqual(profile.dateOfBirth, customDOB)
        
        // Other fields should still have default values
        XCTAssertTrue(profile.useTextToSpeech)
        XCTAssertEqual(profile.totalStoriesRead, 0)
        XCTAssertFalse(profile.hasActiveSubscription)
    }
    
    func testDefaultDateOfBirth() {
        let profile = UserProfile()
        let now = Date()
        let fiveYearsAgo = Calendar.current.date(byAdding: .year, value: -5, to: now)!
        
        // Allow some tolerance for test execution time
        let timeDifference = abs(profile.dateOfBirth.timeIntervalSince(fiveYearsAgo))
        XCTAssertLessThan(timeDifference, 60.0) // Within 1 minute
    }
    
    // MARK: - Test Dark Mode Preference
    
    func testDarkModePreference() {
        let profile = UserProfile()
        
        // Test default value
        XCTAssertEqual(profile.darkModePreference, .system)
        XCTAssertEqual(profile.darkModePreferenceRaw, DarkModePreference.system.rawValue)
        
        // Test setting to light
        profile.darkModePreference = .light
        XCTAssertEqual(profile.darkModePreference, .light)
        XCTAssertEqual(profile.darkModePreferenceRaw, DarkModePreference.light.rawValue)
        
        // Test setting to dark
        profile.darkModePreference = .dark
        XCTAssertEqual(profile.darkModePreference, .dark)
        XCTAssertEqual(profile.darkModePreferenceRaw, DarkModePreference.dark.rawValue)
        
        // Test setting back to system
        profile.darkModePreference = .system
        XCTAssertEqual(profile.darkModePreference, .system)
        XCTAssertEqual(profile.darkModePreferenceRaw, DarkModePreference.system.rawValue)
    }
    
    func testDarkModePreferenceInvalidRawValue() {
        let profile = UserProfile()
        
        // Set invalid raw value directly
        profile.darkModePreferenceRaw = "invalid_value"
        
        // Should fall back to system default
        XCTAssertEqual(profile.darkModePreference, .system)
    }
    
    // MARK: - Test Data Modification
    
    func testChildInformationModification() {
        let profile = UserProfile()
        
        // Modify child information
        profile.childName = "Emma"
        profile.dateOfBirth = Date(timeIntervalSince1970: 1000000000)
        profile.interests = ["dragons", "princesses", "adventures"]
        
        XCTAssertEqual(profile.childName, "Emma")
        XCTAssertEqual(profile.dateOfBirth.timeIntervalSince1970, 1000000000)
        XCTAssertEqual(profile.interests, ["dragons", "princesses", "adventures"])
    }
    
    func testPreferencesModification() {
        let profile = UserProfile()
        
        // Modify preferences
        profile.preferredThemes = ["fantasy", "adventure"]
        profile.favoriteCharacters = ["wizard", "dragon"]
        
        XCTAssertEqual(profile.preferredThemes, ["fantasy", "adventure"])
        XCTAssertEqual(profile.favoriteCharacters, ["wizard", "dragon"])
    }
    
    func testSettingsModification() {
        let profile = UserProfile()
        
        // Modify settings
        profile.useTextToSpeech = false
        profile.preferredVoiceIdentifier = "com.apple.voice.english.alex"
        profile.darkModePreference = .dark
        
        XCTAssertFalse(profile.useTextToSpeech)
        XCTAssertEqual(profile.preferredVoiceIdentifier, "com.apple.voice.english.alex")
        XCTAssertEqual(profile.darkModePreference, .dark)
    }
    
    func testStatisticsModification() {
        let profile = UserProfile()
        let testDate = Date(timeIntervalSince1970: 1000000000)
        
        // Modify statistics
        profile.totalStoriesRead = 25
        profile.totalReadingTime = 3600.5
        profile.lastReadDate = testDate
        
        XCTAssertEqual(profile.totalStoriesRead, 25)
        XCTAssertEqual(profile.totalReadingTime, 3600.5)
        XCTAssertEqual(profile.lastReadDate, testDate)
    }
    
    // MARK: - Test Analytics Fields
    
    func testAnalyticsFieldsModification() {
        let profile = UserProfile()
        let testDate = Date(timeIntervalSince1970: 1500000000)
        let testUUID = UUID()
        
        // Modify analytics fields
        profile.storyGenerationCount = 10
        profile.lastGenerationDate = testDate
        profile.lastGeneratedStoryId = testUUID
        
        XCTAssertEqual(profile.storyGenerationCount, 10)
        XCTAssertEqual(profile.lastGenerationDate, testDate)
        XCTAssertEqual(profile.lastGeneratedStoryId, testUUID)
    }
    
    // MARK: - Test Subscription Fields
    
    func testSubscriptionFieldsModification() {
        let profile = UserProfile()
        let testExpiryDate = Date(timeIntervalSince1970: 2000000000)
        let testResetDate = Date(timeIntervalSince1970: 1900000000)
        let testPeriodStart = Date(timeIntervalSince1970: 1800000000)
        
        // Modify subscription fields
        profile.monthlyStoryCount = 15
        profile.currentPeriodStart = testPeriodStart
        profile.subscriptionExpiryDate = testExpiryDate
        profile.hasActiveSubscription = true
        profile.subscriptionProductId = "com.magicalstories.premium"
        profile.lastUsageReset = testResetDate
        profile.premiumFeaturesUsed = ["illustration_generation", "voice_synthesis"]
        
        XCTAssertEqual(profile.monthlyStoryCount, 15)
        XCTAssertEqual(profile.currentPeriodStart, testPeriodStart)
        XCTAssertEqual(profile.subscriptionExpiryDate, testExpiryDate)
        XCTAssertTrue(profile.hasActiveSubscription)
        XCTAssertEqual(profile.subscriptionProductId, "com.magicalstories.premium")
        XCTAssertEqual(profile.lastUsageReset, testResetDate)
        XCTAssertEqual(profile.premiumFeaturesUsed, ["illustration_generation", "voice_synthesis"])
    }
    
    // MARK: - Test Edge Cases
    
    func testEmptyStringArrays() {
        let profile = UserProfile()
        
        // Set arrays to empty explicitly
        profile.interests = []
        profile.preferredThemes = []
        profile.favoriteCharacters = []
        profile.premiumFeaturesUsed = []
        
        XCTAssertTrue(profile.interests.isEmpty)
        XCTAssertTrue(profile.preferredThemes.isEmpty)
        XCTAssertTrue(profile.favoriteCharacters.isEmpty)
        XCTAssertTrue(profile.premiumFeaturesUsed.isEmpty)
    }
    
    func testNilOptionalValues() {
        let profile = UserProfile()
        
        // Set optional values to nil explicitly
        profile.preferredVoiceIdentifier = nil
        profile.lastReadDate = nil
        profile.lastGenerationDate = nil
        profile.lastGeneratedStoryId = nil
        profile.subscriptionExpiryDate = nil
        profile.subscriptionProductId = nil
        
        XCTAssertNil(profile.preferredVoiceIdentifier)
        XCTAssertNil(profile.lastReadDate)
        XCTAssertNil(profile.lastGenerationDate)
        XCTAssertNil(profile.lastGeneratedStoryId)
        XCTAssertNil(profile.subscriptionExpiryDate)
        XCTAssertNil(profile.subscriptionProductId)
    }
    
    func testLargeValues() {
        let profile = UserProfile()
        
        // Set large values
        profile.totalStoriesRead = Int.max
        profile.totalReadingTime = Double.greatestFiniteMagnitude
        profile.storyGenerationCount = 999999
        profile.monthlyStoryCount = 100000
        
        XCTAssertEqual(profile.totalStoriesRead, Int.max)
        XCTAssertEqual(profile.totalReadingTime, Double.greatestFiniteMagnitude)
        XCTAssertEqual(profile.storyGenerationCount, 999999)
        XCTAssertEqual(profile.monthlyStoryCount, 100000)
    }
    
    // MARK: - Test UUID Uniqueness
    
    func testUniqueIDs() {
        let profile1 = UserProfile()
        let profile2 = UserProfile()
        
        XCTAssertNotEqual(profile1.id, profile2.id)
    }
    
    func testSameIDWhenExplicitlySet() {
        let sharedId = UUID()
        let profile1 = UserProfile(id: sharedId, childName: "Child1")
        let profile2 = UserProfile(id: sharedId, childName: "Child2")
        
        XCTAssertEqual(profile1.id, profile2.id)
        XCTAssertNotEqual(profile1.childName, profile2.childName)
    }
}

// MARK: - Supporting Enum Tests

final class DarkModePreference_Tests: XCTestCase {
    
    func testAllCases() {
        let allCases = DarkModePreference.allCases
        
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.light))
        XCTAssertTrue(allCases.contains(.dark))
        XCTAssertTrue(allCases.contains(.system))
    }
    
    func testRawValues() {
        XCTAssertEqual(DarkModePreference.light.rawValue, "light")
        XCTAssertEqual(DarkModePreference.dark.rawValue, "dark")
        XCTAssertEqual(DarkModePreference.system.rawValue, "system")
    }
    
    func testInitFromRawValue() {
        XCTAssertEqual(DarkModePreference(rawValue: "light"), .light)
        XCTAssertEqual(DarkModePreference(rawValue: "dark"), .dark)
        XCTAssertEqual(DarkModePreference(rawValue: "system"), .system)
        XCTAssertNil(DarkModePreference(rawValue: "invalid"))
    }
    
    func testCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Test encoding and decoding each case
        for preference in DarkModePreference.allCases {
            let data = try encoder.encode(preference)
            let decoded = try decoder.decode(DarkModePreference.self, from: data)
            XCTAssertEqual(decoded, preference)
        }
    }
}