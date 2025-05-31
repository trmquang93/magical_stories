import Foundation
@testable import magical_stories

class MockUsageAnalyticsService: UsageAnalyticsServiceProtocol {
    func getStoryGenerationCount() async -> Int { 0 }
    func incrementStoryGenerationCount() async { }
    func updateLastGenerationDate(date: Date?) async { }
    func getLastGenerationDate() async -> Date? { nil }
    func updateLastGeneratedStoryId(id: UUID?) async { }
    func getLastGeneratedStoryId() async -> UUID? { nil }
    
    // Monthly usage tracking methods
    func getMonthlyUsageCount() async -> Int { 0 }
    func canGenerateStoryThisMonth() async -> Bool { true }
    func resetMonthlyUsageIfNeeded() async { }
    func updateSubscriptionStatus(isActive: Bool, productId: String?, expiryDate: Date?) async { }
    func trackPremiumFeatureUsage(_ feature: String) async { }
}