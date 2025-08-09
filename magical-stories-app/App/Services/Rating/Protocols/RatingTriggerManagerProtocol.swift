import Foundation

/// Protocol defining the requirements for rating trigger management
protocol RatingTriggerManagerProtocol: Sendable {
    /// Evaluates whether a rating should be triggered based on current user engagement
    /// - Returns: True if rating should be triggered, false otherwise
    func shouldTriggerRating() async -> Bool
    
    /// Records a user engagement event
    /// - Parameter event: The engagement event to record
    func recordEvent(_ event: RatingTriggerEvent) async
    
    /// Calculates the current user engagement score
    /// - Returns: Engagement score from 0.0 to 1.0
    func calculateEngagementScore() async -> Double
    
    /// Gets the time since the last rating request
    /// - Returns: Time interval since last request, nil if never requested
    func timeSinceLastRatingRequest() async -> TimeInterval?
    
    /// Gets the number of rating requests made this year
    /// - Returns: Number of requests made in the current year
    func ratingRequestsThisYear() async -> Int
    
    /// Records that a rating request was shown to the user
    func recordRatingRequestShown() async
    
    /// Resets all tracking data
    func resetTrackingData() async
    
    /// Updates trigger configuration
    /// - Parameter configuration: New rating configuration
    func updateConfiguration(_ configuration: RatingConfiguration) async
}