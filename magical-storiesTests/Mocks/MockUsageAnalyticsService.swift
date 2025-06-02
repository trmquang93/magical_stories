import Foundation
@testable import magical_stories

@MainActor
class MockUsageAnalyticsService: UsageAnalyticsServiceProtocol {
    private var storyCount = 0
    private var lastGenerationDate: Date?
    private var lastGeneratedStoryId: UUID?
    private var monthlyUsageCount = 0
    private var subscriptionActive = false
    private var subscriptionProductId: String?
    private var subscriptionExpiryDate: Date?
    
    func incrementStoryGenerationCount() async {
        storyCount += 1
        monthlyUsageCount += 1
    }
    
    func getStoryGenerationCount() async -> Int {
        return storyCount
    }
    
    func updateLastGenerationDate(date: Date?) async {
        lastGenerationDate = date
    }
    
    func getLastGenerationDate() async -> Date? {
        return lastGenerationDate
    }
    
    func updateLastGeneratedStoryId(id: UUID?) async {
        lastGeneratedStoryId = id
    }
    
    func getLastGeneratedStoryId() async -> UUID? {
        return lastGeneratedStoryId
    }
    
    func getMonthlyUsageCount() async -> Int {
        return monthlyUsageCount
    }
    
    func canGenerateStoryThisMonth() async -> Bool {
        if subscriptionActive {
            return true
        }
        return monthlyUsageCount < 3 // Free tier limit
    }
    
    func resetMonthlyUsageIfNeeded() async {
        monthlyUsageCount = 0
    }
    
    func updateSubscriptionStatus(isActive: Bool, productId: String?, expiryDate: Date?) async {
        subscriptionActive = isActive
        subscriptionProductId = productId
        subscriptionExpiryDate = expiryDate
    }
    
    func trackPremiumFeatureUsage(_ feature: String) async {
        // Mock implementation - do nothing for tests
    }
}