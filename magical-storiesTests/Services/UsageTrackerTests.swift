import SwiftData
import Testing

@testable import magical_stories

@MainActor
struct UsageTrackerTests {
    
    @Test("UsageTracker enforces FreeTierLimits.storiesPerMonth limit")
    func testMonthlyStoryLimit() async throws {
        let mockAnalyticsService = MockUsageAnalyticsService()
        let usageTracker = UsageTracker(usageAnalyticsService: mockAnalyticsService)
        
        // Verify initial state allows generation
        let initialCanGenerate = await usageTracker.canGenerateStory()
        #expect(initialCanGenerate)
        
        let initialRemaining = await usageTracker.getRemainingStories()
        #expect(initialRemaining == FreeTierLimits.storiesPerMonth)
        
        // Generate stories up to the limit
        for i in 0..<FreeTierLimits.storiesPerMonth {
            let canGenerate = await usageTracker.canGenerateStory()
            #expect(canGenerate, "Should be able to generate story \(i + 1)")
            
            await usageTracker.incrementStoryGeneration()
            
            let remaining = await usageTracker.getRemainingStories()
            #expect(remaining == FreeTierLimits.storiesPerMonth - (i + 1))
        }
        
        // Should not be able to generate after reaching limit
        let canGenerateAfterLimit = await usageTracker.canGenerateStory()
        #expect(!canGenerateAfterLimit)
        
        let remainingAfterLimit = await usageTracker.getRemainingStories()
        #expect(remainingAfterLimit == 0)
    }
    
    @Test("UsageTracker provides correct usage statistics")
    func testUsageStatistics() async throws {
        let mockAnalyticsService = MockUsageAnalyticsService()
        let usageTracker = UsageTracker(usageAnalyticsService: mockAnalyticsService)
        
        // Test initial statistics
        let initialStats = await usageTracker.getUsageStatistics()
        #expect(initialStats.storiesGenerated == 0)
        #expect(initialStats.remainingStories == FreeTierLimits.storiesPerMonth)
        #expect(!initialStats.isAtLimit)
        #expect(initialStats.usagePercentage == 0.0)
        
        // Generate some stories
        let storiesToGenerate = 2
        for _ in 0..<storiesToGenerate {
            await usageTracker.incrementStoryGeneration()
        }
        
        let updatedStats = await usageTracker.getUsageStatistics()
        #expect(updatedStats.storiesGenerated == storiesToGenerate)
        #expect(updatedStats.remainingStories == FreeTierLimits.storiesPerMonth - storiesToGenerate)
        #expect(!updatedStats.isAtLimit)
        #expect(updatedStats.usagePercentage == Double(storiesToGenerate) / Double(FreeTierLimits.storiesPerMonth))
        
        // Generate up to limit
        for _ in storiesToGenerate..<FreeTierLimits.storiesPerMonth {
            await usageTracker.incrementStoryGeneration()
        }
        
        let limitStats = await usageTracker.getUsageStatistics()
        #expect(limitStats.storiesGenerated == FreeTierLimits.storiesPerMonth)
        #expect(limitStats.remainingStories == 0)
        #expect(limitStats.isAtLimit)
        #expect(limitStats.usagePercentage == 1.0)
    }
    
    @Test("UsageTracker resets monthly usage correctly")
    func testMonthlyReset() async throws {
        let mockAnalyticsService = MockUsageAnalyticsService()
        let usageTracker = UsageTracker(usageAnalyticsService: mockAnalyticsService)
        
        // Generate some stories
        await usageTracker.incrementStoryGeneration()
        await usageTracker.incrementStoryGeneration()
        
        let beforeReset = await usageTracker.getCurrentUsage()
        #expect(beforeReset == 2)
        
        // Reset usage
        await usageTracker.resetMonthlyUsage()
        
        let afterReset = await usageTracker.getCurrentUsage()
        #expect(afterReset == 0)
        
        let canGenerateAfterReset = await usageTracker.canGenerateStory()
        #expect(canGenerateAfterReset)
        
        let remainingAfterReset = await usageTracker.getRemainingStories()
        #expect(remainingAfterReset == FreeTierLimits.storiesPerMonth)
    }
    
    @Test("UsageTracker provides correct display text and progress values")
    func testDisplayHelpers() async throws {
        let mockAnalyticsService = MockUsageAnalyticsService()
        let usageTracker = UsageTracker(usageAnalyticsService: mockAnalyticsService)
        
        // Test initial display values
        let initialDisplayText = usageTracker.usageDisplayText
        #expect(initialDisplayText.contains("0 of \(FreeTierLimits.storiesPerMonth)"))
        
        let initialProgress = usageTracker.usageProgress
        #expect(initialProgress == 0.0)
        
        // Generate one story
        await usageTracker.incrementStoryGeneration()
        
        let updatedDisplayText = usageTracker.usageDisplayText
        #expect(updatedDisplayText.contains("1 of \(FreeTierLimits.storiesPerMonth)"))
        
        let updatedProgress = usageTracker.usageProgress
        #expect(updatedProgress == 1.0 / Double(FreeTierLimits.storiesPerMonth))
    }
    
    @Test("UsageTracker handles premium upgrade correctly")
    func testPremiumUpgrade() async throws {
        let mockAnalyticsService = MockUsageAnalyticsService()
        let usageTracker = UsageTracker(usageAnalyticsService: mockAnalyticsService)
        
        // Generate stories up to limit
        for _ in 0..<FreeTierLimits.storiesPerMonth {
            await usageTracker.incrementStoryGeneration()
        }
        
        let canGenerateBeforeUpgrade = await usageTracker.canGenerateStory()
        #expect(!canGenerateBeforeUpgrade)
        
        // Simulate premium upgrade
        await usageTracker.resetUsageForPremiumUpgrade()
        
        // Usage count should remain, but limit should be removed
        let usageAfterUpgrade = await usageTracker.getCurrentUsage()
        #expect(usageAfterUpgrade == FreeTierLimits.storiesPerMonth) // Count preserved
    }
    
    @Test("UsageTracker handles downgrade correctly")
    func testDowngrade() async throws {
        let mockAnalyticsService = MockUsageAnalyticsService()
        let usageTracker = UsageTracker(usageAnalyticsService: mockAnalyticsService)
        
        // Generate stories up to limit
        for _ in 0..<FreeTierLimits.storiesPerMonth {
            await usageTracker.incrementStoryGeneration()
        }
        
        // Simulate downgrade from premium
        await usageTracker.resetForDowngrade()
        
        // Should reapply limits
        let canGenerateAfterDowngrade = await usageTracker.canGenerateStory()
        #expect(!canGenerateAfterDowngrade) // Should be at limit
    }
    
    @Test("UsageTracker integrates with analytics service correctly")
    func testAnalyticsIntegration() async throws {
        let mockAnalyticsService = MockUsageAnalyticsService()
        let usageTracker = UsageTracker(usageAnalyticsService: mockAnalyticsService)
        
        // Increment story generation
        await usageTracker.incrementStoryGeneration()
        
        // Verify analytics service was updated
        let analyticsCount = await mockAnalyticsService.getStoryGenerationCount()
        #expect(analyticsCount == 1)
        
        let lastGenerationDate = await mockAnalyticsService.getLastGenerationDate()
        #expect(lastGenerationDate != nil)
    }
    
    @Test("UsageTracker calculates days until reset correctly")
    func testDaysUntilReset() async throws {
        let mockAnalyticsService = MockUsageAnalyticsService()
        let usageTracker = UsageTracker(usageAnalyticsService: mockAnalyticsService)
        
        let daysUntilReset = usageTracker.daysUntilReset
        #expect(daysUntilReset >= 0)
        #expect(daysUntilReset <= 31) // Should be within a month
        
        let resetDisplayText = usageTracker.resetDisplayText
        #expect(!resetDisplayText.isEmpty)
        #expect(resetDisplayText.contains("Reset"))
    }
    
    @Test("UsageTracker handles month boundary reset automatically")
    func testAutomaticMonthBoundaryReset() async throws {
        let mockAnalyticsService = MockUsageAnalyticsService()
        let usageTracker = UsageTracker(usageAnalyticsService: mockAnalyticsService)
        
        // Generate some stories
        await usageTracker.incrementStoryGeneration()
        await usageTracker.incrementStoryGeneration()
        
        // Manually modify the period start to simulate a new month
        await MainActor.run {
            usageTracker.currentMonthUsage.periodStart = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        }
        
        // Call resetMonthlyUsageIfNeeded to trigger automatic reset
        await usageTracker.resetMonthlyUsageIfNeeded()
        
        let usageAfterReset = await usageTracker.getCurrentUsage()
        #expect(usageAfterReset == 0)
    }
}