import Foundation
@testable import magical_stories

class MockUsageAnalyticsService: UsageAnalyticsServiceProtocol {
    func getStoryGenerationCount() async -> Int { 0 }
    func incrementStoryGenerationCount() async { }
    func updateLastGenerationDate(date: Date?) async { }
    func getLastGenerationDate() async -> Date? { nil }
    func updateLastGeneratedStoryId(id: UUID?) async { }
    func getLastGeneratedStoryId() async -> UUID? { nil }
}