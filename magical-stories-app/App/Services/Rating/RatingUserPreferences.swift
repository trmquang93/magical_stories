import Foundation
import OSLog

/// Service for managing user preferences related to the rating system
@MainActor
final class RatingUserPreferences: ObservableObject, Sendable {
    
    // MARK: - Published Properties
    
    @Published private(set) var hasOptedOutOfRatings: Bool = false
    @Published private(set) var ratingFrequencyPreference: RatingFrequency = .normal
    
    // MARK: - Constants
    
    private enum UserDefaultsKeys {
        static let hasOptedOut = "rating_system_opted_out"
        static let frequencyPreference = "rating_frequency_preference" 
        static let firstLaunchDate = "first_app_launch_date"
        static let lastRatingRequestDate = "last_rating_request_date"
        static let ratingRequestsThisYear = "rating_requests_this_year"
        static let yearOfLastRequest = "year_of_last_rating_request"
        static let totalAppLaunches = "total_app_launches"
        static let totalStoriesCreated = "total_stories_created"
        static let engagementEvents = "rating_engagement_events"
    }
    
    // MARK: - Private Properties
    
    private let userDefaults: UserDefaults
    private let logger = Logger(subsystem: "com.magicalstories.app", category: "RatingUserPreferences")
    
    // MARK: - Initialization
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadPreferences()
        initializeFirstLaunchIfNeeded()
    }
    
    // MARK: - Public API - User Preferences
    
    /// Sets user's opt-out preference for rating requests
    /// - Parameter optedOut: True if user wants to opt out of rating requests
    func setRatingOptOut(_ optedOut: Bool) {
        hasOptedOutOfRatings = optedOut
        userDefaults.set(optedOut, forKey: UserDefaultsKeys.hasOptedOut)
        
        logger.info("User rating opt-out preference updated: \(optedOut)")
    }
    
    /// Sets user's preferred frequency for rating requests
    /// - Parameter frequency: Preferred frequency setting
    func setRatingFrequency(_ frequency: RatingFrequency) {
        ratingFrequencyPreference = frequency
        userDefaults.set(frequency.rawValue, forKey: UserDefaultsKeys.frequencyPreference)
        
        logger.info("User rating frequency preference updated: \(frequency.rawValue)")
    }
    
    // MARK: - Public API - App Usage Tracking
    
    /// Records an app launch event
    func recordAppLaunch() {
        let currentCount = userDefaults.integer(forKey: UserDefaultsKeys.totalAppLaunches)
        userDefaults.set(currentCount + 1, forKey: UserDefaultsKeys.totalAppLaunches)
    }
    
    /// Records a story creation event
    func recordStoryCreation() {
        let currentCount = userDefaults.integer(forKey: UserDefaultsKeys.totalStoriesCreated)
        userDefaults.set(currentCount + 1, forKey: UserDefaultsKeys.totalStoriesCreated)
    }
    
    /// Gets the total number of app launches
    /// - Returns: Total app launches since installation
    func getTotalAppLaunches() -> Int {
        return userDefaults.integer(forKey: UserDefaultsKeys.totalAppLaunches)
    }
    
    /// Gets the total number of stories created
    /// - Returns: Total stories created by the user
    func getTotalStoriesCreated() -> Int {
        return userDefaults.integer(forKey: UserDefaultsKeys.totalStoriesCreated)
    }
    
    /// Gets the date of first app launch
    /// - Returns: Date of first launch, nil if never recorded
    func getFirstLaunchDate() -> Date? {
        return userDefaults.object(forKey: UserDefaultsKeys.firstLaunchDate) as? Date
    }
    
    /// Gets the number of days since first app launch
    /// - Returns: Days since first launch, 0 if never recorded
    func getDaysSinceFirstLaunch() -> Int {
        guard let firstLaunch = getFirstLaunchDate() else { return 0 }
        return Calendar.current.dateComponents([.day], from: firstLaunch, to: Date()).day ?? 0
    }
    
    // MARK: - Public API - Rating Request Tracking
    
    /// Records that a rating request was shown to the user
    func recordRatingRequestShown() {
        let now = Date()
        let currentYear = Calendar.current.component(.year, from: now)
        
        // Update last request date
        userDefaults.set(now, forKey: UserDefaultsKeys.lastRatingRequestDate)
        
        // Update yearly counter
        let lastRequestYear = userDefaults.integer(forKey: UserDefaultsKeys.yearOfLastRequest)
        if lastRequestYear != currentYear {
            // New year, reset counter
            userDefaults.set(1, forKey: UserDefaultsKeys.ratingRequestsThisYear)
        } else {
            // Same year, increment counter
            let currentCount = userDefaults.integer(forKey: UserDefaultsKeys.ratingRequestsThisYear)
            userDefaults.set(currentCount + 1, forKey: UserDefaultsKeys.ratingRequestsThisYear)
        }
        
        userDefaults.set(currentYear, forKey: UserDefaultsKeys.yearOfLastRequest)
        
        logger.info("Rating request recorded for year \(currentYear)")
    }
    
    /// Gets the date of the last rating request
    /// - Returns: Date of last request, nil if never requested
    func getLastRatingRequestDate() -> Date? {
        return userDefaults.object(forKey: UserDefaultsKeys.lastRatingRequestDate) as? Date
    }
    
    /// Gets the number of days since the last rating request
    /// - Returns: Days since last request, nil if never requested
    func getDaysSinceLastRatingRequest() -> Int? {
        guard let lastRequest = getLastRatingRequestDate() else { return nil }
        return Calendar.current.dateComponents([.day], from: lastRequest, to: Date()).day
    }
    
    /// Gets the number of rating requests made this year
    /// - Returns: Number of requests in current year
    func getRatingRequestsThisYear() -> Int {
        let currentYear = Calendar.current.component(.year, from: Date())
        let lastRequestYear = userDefaults.integer(forKey: UserDefaultsKeys.yearOfLastRequest)
        
        if lastRequestYear != currentYear {
            return 0 // Different year, reset counter
        }
        
        return userDefaults.integer(forKey: UserDefaultsKeys.ratingRequestsThisYear)
    }
    
    // MARK: - Public API - Engagement Events
    
    /// Saves engagement events to persistent storage
    /// - Parameter events: Array of engagement events to save
    func saveEngagementEvents(_ events: [RatingEngagementRecord]) {
        do {
            let data = try JSONEncoder().encode(events)
            userDefaults.set(data, forKey: UserDefaultsKeys.engagementEvents)
        } catch {
            logger.error("Failed to save engagement events: \(error.localizedDescription)")
        }
    }
    
    /// Loads engagement events from persistent storage
    /// - Returns: Array of saved engagement events
    func loadEngagementEvents() -> [RatingEngagementRecord] {
        guard let data = userDefaults.data(forKey: UserDefaultsKeys.engagementEvents) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([RatingEngagementRecord].self, from: data)
        } catch {
            logger.error("Failed to load engagement events: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Public API - Data Management
    
    /// Resets all rating-related user data
    func resetAllRatingData() {
        let keysToRemove = [
            UserDefaultsKeys.hasOptedOut,
            UserDefaultsKeys.frequencyPreference,
            UserDefaultsKeys.lastRatingRequestDate,
            UserDefaultsKeys.ratingRequestsThisYear,
            UserDefaultsKeys.yearOfLastRequest,
            UserDefaultsKeys.engagementEvents
        ]
        
        for key in keysToRemove {
            userDefaults.removeObject(forKey: key)
        }
        
        // Reload preferences
        loadPreferences()
        
        logger.info("All rating data has been reset")
    }
    
    /// Resets only engagement tracking data (preserves user preferences)
    func resetEngagementData() {
        let keysToRemove = [
            UserDefaultsKeys.lastRatingRequestDate,
            UserDefaultsKeys.ratingRequestsThisYear,
            UserDefaultsKeys.yearOfLastRequest,
            UserDefaultsKeys.engagementEvents
        ]
        
        for key in keysToRemove {
            userDefaults.removeObject(forKey: key)
        }
        
        logger.info("Engagement data has been reset")
    }
    
    // MARK: - Private Methods
    
    private func loadPreferences() {
        hasOptedOutOfRatings = userDefaults.bool(forKey: UserDefaultsKeys.hasOptedOut)
        
        if let frequencyRawValue = userDefaults.object(forKey: UserDefaultsKeys.frequencyPreference) as? String,
           let frequency = RatingFrequency(rawValue: frequencyRawValue) {
            ratingFrequencyPreference = frequency
        } else {
            ratingFrequencyPreference = .normal
        }
    }
    
    private func initializeFirstLaunchIfNeeded() {
        if userDefaults.object(forKey: UserDefaultsKeys.firstLaunchDate) == nil {
            userDefaults.set(Date(), forKey: UserDefaultsKeys.firstLaunchDate)
            logger.info("First app launch date recorded")
        }
    }
}

// MARK: - Supporting Types

/// User's preferred frequency for rating requests
public enum RatingFrequency: String, CaseIterable, Codable, Sendable {
    case never = "never"
    case minimal = "minimal"
    case normal = "normal"
    case frequent = "frequent"
    
    /// Display name for the frequency setting
    public var displayName: String {
        switch self {
        case .never: return "Never"
        case .minimal: return "Minimal"
        case .normal: return "Normal"
        case .frequent: return "Frequent"
        }
    }
    
    /// Description of what this frequency means
    public var description: String {
        switch self {
        case .never: return "Never show rating requests"
        case .minimal: return "Show rating requests very rarely"
        case .normal: return "Show rating requests at normal intervals"
        case .frequent: return "Show rating requests more often when appropriate"
        }
    }
    
    /// Multiplier for minimum days between requests
    public var daysBetweenRequestsMultiplier: Double {
        switch self {
        case .never: return Double.infinity
        case .minimal: return 2.0
        case .normal: return 1.0
        case .frequent: return 0.5
        }
    }
    
    /// Multiplier for engagement score requirements
    public var engagementScoreMultiplier: Double {
        switch self {
        case .never: return Double.infinity
        case .minimal: return 1.5
        case .normal: return 1.0
        case .frequent: return 0.8
        }
    }
}