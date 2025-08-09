import Foundation
import StoreKit

/// Protocol defining the requirements for rating services
@MainActor
protocol RatingServiceProtocol: ObservableObject {
    /// Requests an app rating from the user if appropriate conditions are met
    /// - Throws: RatingError if the request fails
    func requestRating() async throws
    
    /// Manually triggers a rating request regardless of normal conditions (for testing)
    /// - Throws: RatingError if the request fails
    func forceRatingRequest() async throws
    
    /// Checks if a rating request should be shown based on user engagement
    /// - Returns: True if rating should be requested, false otherwise
    func shouldRequestRating() async -> Bool
    
    /// Records a user engagement event for rating trigger evaluation
    /// - Parameter event: The engagement event to record
    func recordEngagementEvent(_ event: RatingTriggerEvent) async
    
    /// Gets the current user engagement score
    /// - Returns: Engagement score from 0.0 to 1.0
    func getCurrentEngagementScore() async -> Double
    
    /// Resets all rating-related user data (for testing or user preference)
    func resetRatingData() async
    
    /// Updates rating configuration
    /// - Parameter configuration: New rating configuration
    func updateConfiguration(_ configuration: RatingConfiguration) async
}