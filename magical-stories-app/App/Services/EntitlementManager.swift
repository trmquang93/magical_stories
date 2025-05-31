import Foundation
import StoreKit
import OSLog

/// Service responsible for managing user subscription entitlements and feature access control
@MainActor
final class EntitlementManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .free
    @Published private(set) var hasLifetimeAccess = false
    @Published private(set) var isCheckingEntitlements = false
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicalstories", 
                               category: "EntitlementManager")
    private let userDefaults = UserDefaults.standard
    
    // User defaults keys for caching subscription state
    private enum UserDefaultsKeys {
        static let subscriptionStatus = "subscription_status"
        static let subscriptionExpiryDate = "subscription_expiry_date"
        static let hasLifetimeAccess = "has_lifetime_access"
        static let lastEntitlementCheck = "last_entitlement_check"
    }
    
    // MARK: - Dependencies
    
    private weak var usageTracker: UsageTracker?
    
    // MARK: - Initialization
    
    init() {
        loadCachedSubscriptionState()
        
        // Check entitlements on initialization
        Task {
            await checkInitialEntitlements()
        }
    }
    
    // MARK: - Dependency Injection
    
    /// Sets the usage tracker dependency
    /// - Parameter usageTracker: The usage tracker to coordinate with
    func setUsageTracker(_ usageTracker: UsageTracker) {
        self.usageTracker = usageTracker
    }
    
    // MARK: - Public API
    
    /// Checks if the user has access to a specific premium feature
    /// - Parameter feature: The premium feature to check
    /// - Returns: True if user has access, false otherwise
    func hasAccess(to feature: PremiumFeature) -> Bool {
        switch feature {
        case .unlimitedStoryGeneration:
            return isPremiumUser
        case .growthPathCollections:
            return isPremiumUser
        case .multipleChildProfiles:
            return isPremiumUser
        case .advancedIllustrations:
            return isPremiumUser
        case .priorityGeneration:
            return isPremiumUser
        case .offlineReading:
            return isPremiumUser
        case .parentalAnalytics:
            return isPremiumUser
        case .customThemes:
            return isPremiumUser
        }
    }
    
    /// Checks if the user can generate a story based on their subscription and usage
    /// - Returns: True if user can generate a story, false if limit reached
    func canGenerateStory() async -> Bool {
        // Premium users have unlimited access
        if isPremiumUser {
            return true
        }
        
        // Free users are subject to monthly limits
        return await usageTracker?.canGenerateStory() ?? false
    }
    
    /// Gets the number of remaining stories for free users
    /// - Returns: Number of stories remaining this month
    func getRemainingStories() async -> Int {
        if isPremiumUser {
            return Int.max // Unlimited for premium users
        }
        
        return await usageTracker?.getRemainingStories() ?? 0
    }
    
    /// Increments the usage count for free users
    func incrementUsageCount() async {
        // Only track usage for free users
        if !isPremiumUser {
            await usageTracker?.incrementStoryGeneration()
        }
    }
    
    /// Computed property to check if user has premium access
    var isPremiumUser: Bool {
        return subscriptionStatus.isPremium || hasLifetimeAccess
    }
    
    /// Gets user-friendly subscription status text
    var subscriptionStatusText: String {
        if hasLifetimeAccess {
            return "Lifetime Premium"
        }
        return subscriptionStatus.displayText
    }
    
    /// Gets renewal information if applicable
    var renewalInformation: String? {
        return subscriptionStatus.renewalText
    }
    
    // MARK: - Transaction Processing
    
    /// Updates entitlements based on a verified transaction
    /// - Parameter transaction: The verified transaction to process
    func updateEntitlement(for transaction: Transaction) async {
        logger.info("Processing transaction: \(transaction.id) for product: \(transaction.productID)")
        
        // Check if this is a subscription product we recognize
        guard let subscriptionProduct = SubscriptionProduct(rawValue: transaction.productID) else {
            logger.warning("Unknown product ID in transaction: \(transaction.productID)")
            return
        }
        
        // Check if transaction is revoked
        if let revocationDate = transaction.revocationDate {
            logger.info("Transaction \(transaction.id) was revoked on \(revocationDate)")
            await handleRevokedTransaction(transaction)
            return
        }
        
        // Process based on subscription type
        switch subscriptionProduct {
        case .premiumMonthly, .premiumYearly:
            await processSubscriptionTransaction(transaction, product: subscriptionProduct)
        }
        
        // Cache the updated state
        cacheSubscriptionState()
        
        // Reset usage if user became premium
        if isPremiumUser {
            await usageTracker?.resetUsageForPremiumUpgrade()
        }
        
        logger.info("Entitlement update completed for transaction: \(transaction.id)")
    }
    
    /// Refreshes the current entitlement status by checking all current entitlements
    func refreshEntitlementStatus() async {
        isCheckingEntitlements = true
        
        defer {
            Task { @MainActor in
                self.isCheckingEntitlements = false
            }
        }
        
        logger.info("Refreshing entitlement status")
        
        var newSubscriptionStatus: SubscriptionStatus = .free
        var newHasLifetimeAccess = false
        
        // Check current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try await checkVerified(result)
                
                logger.debug("Checking entitlement: \(transaction.productID)")
                
                guard let subscriptionProduct = SubscriptionProduct(rawValue: transaction.productID) else {
                    continue
                }
                
                // Check if transaction is still valid
                if let revocationDate = transaction.revocationDate {
                    logger.info("Entitlement \(transaction.productID) was revoked on \(revocationDate)")
                    continue
                }
                
                // Check subscription expiration
                if let expirationDate = transaction.expirationDate {
                    if expirationDate <= Date() {
                        logger.info("Subscription \(transaction.productID) expired on \(expirationDate)")
                        continue
                    }
                    
                    // Valid subscription
                    switch subscriptionProduct {
                    case .premiumMonthly:
                        newSubscriptionStatus = .premiumMonthly(expiresAt: expirationDate)
                    case .premiumYearly:
                        newSubscriptionStatus = .premiumYearly(expiresAt: expirationDate)
                    }
                } else {
                    // Non-expiring product (lifetime access)
                    newHasLifetimeAccess = true
                }
                
            } catch {
                logger.error("Failed to verify entitlement: \(error.localizedDescription)")
            }
        }
        
        // Update state
        await MainActor.run {
            self.subscriptionStatus = newSubscriptionStatus
            self.hasLifetimeAccess = newHasLifetimeAccess
        }
        
        // Cache the updated state
        cacheSubscriptionState()
        
        logger.info("Entitlement status refreshed: \(self.subscriptionStatusText)")
        
        // Update last check timestamp
        userDefaults.set(Date(), forKey: UserDefaultsKeys.lastEntitlementCheck)
    }
    
    // MARK: - Private Methods
    
    /// Checks entitlements on app launch
    private func checkInitialEntitlements() async {
        logger.info("Checking initial entitlements")
        
        // Check if we should refresh entitlements (once per day)
        let lastCheck = userDefaults.object(forKey: UserDefaultsKeys.lastEntitlementCheck) as? Date
        let shouldRefresh = lastCheck == nil || Date().timeIntervalSince(lastCheck!) > 24 * 60 * 60
        
        if shouldRefresh {
            await refreshEntitlementStatus()
        } else {
            logger.info("Using cached entitlement status")
        }
    }
    
    /// Processes a subscription transaction
    /// - Parameters:
    ///   - transaction: The transaction to process
    ///   - product: The subscription product type
    private func processSubscriptionTransaction(_ transaction: Transaction, product: SubscriptionProduct) async {
        guard let expirationDate = transaction.expirationDate else {
            logger.warning("Subscription transaction missing expiration date: \(transaction.id)")
            return
        }
        
        // Check if subscription is still active
        if expirationDate <= Date() {
            logger.info("Subscription expired: \(product.productID) expired on \(expirationDate)")
            
            await MainActor.run {
                self.subscriptionStatus = .expired(lastActiveDate: expirationDate)
            }
            return
        }
        
        // Update subscription status
        await MainActor.run {
            switch product {
            case .premiumMonthly:
                self.subscriptionStatus = .premiumMonthly(expiresAt: expirationDate)
            case .premiumYearly:
                self.subscriptionStatus = .premiumYearly(expiresAt: expirationDate)
            }
        }
        
        logger.info("Updated subscription: \(product.productID) expires on \(expirationDate)")
    }
    
    /// Handles a revoked transaction
    /// - Parameter transaction: The revoked transaction
    private func handleRevokedTransaction(_ transaction: Transaction) async {
        logger.info("Handling revoked transaction: \(transaction.id)")
        
        // If this was our active subscription, revert to free
        await MainActor.run {
            if case .premiumMonthly = self.subscriptionStatus,
               transaction.productID == SubscriptionProduct.premiumMonthly.productID {
                self.subscriptionStatus = .free
            } else if case .premiumYearly = self.subscriptionStatus,
                      transaction.productID == SubscriptionProduct.premiumYearly.productID {
                self.subscriptionStatus = .free
            }
            
            // Remove lifetime access if applicable
            if transaction.productID.contains("lifetime") {
                self.hasLifetimeAccess = false
            }
        }
        
        // Reset usage tracking for former premium user
        await usageTracker?.resetForDowngrade()
    }
    
    /// Verifies a transaction result
    /// - Parameter result: The verification result to check
    /// - Returns: The verified transaction
    /// - Throws: StoreError if verification fails
    private func checkVerified<T>(_ result: VerificationResult<T>) async throws -> T {
        switch result {
        case .unverified(_, let error):
            logger.error("Transaction verification failed: \(error.localizedDescription)")
            throw StoreError.verificationFailed(error)
        case .verified(let safe):
            return safe
        }
    }
    
    /// Loads cached subscription state from UserDefaults
    private func loadCachedSubscriptionState() {
        // Load subscription status
        if let statusData = userDefaults.data(forKey: UserDefaultsKeys.subscriptionStatus),
           let expiryDate = userDefaults.object(forKey: UserDefaultsKeys.subscriptionExpiryDate) as? Date {
            
            // Check if cached subscription is still valid
            if expiryDate > Date() {
                if let statusString = String(data: statusData, encoding: .utf8) {
                    if statusString.contains("monthly") {
                        subscriptionStatus = .premiumMonthly(expiresAt: expiryDate)
                    } else if statusString.contains("yearly") {
                        subscriptionStatus = .premiumYearly(expiresAt: expiryDate)
                    }
                }
            } else {
                subscriptionStatus = .expired(lastActiveDate: expiryDate)
            }
        }
        
        // Load lifetime access
        hasLifetimeAccess = userDefaults.bool(forKey: UserDefaultsKeys.hasLifetimeAccess)
        
        logger.info("Loaded cached subscription state: \(self.subscriptionStatusText)")
    }
    
    /// Caches current subscription state to UserDefaults
    private func cacheSubscriptionState() {
        switch subscriptionStatus {
        case .premiumMonthly(let expiresAt):
            userDefaults.set("premium_monthly".data(using: .utf8), forKey: UserDefaultsKeys.subscriptionStatus)
            userDefaults.set(expiresAt, forKey: UserDefaultsKeys.subscriptionExpiryDate)
        case .premiumYearly(let expiresAt):
            userDefaults.set("premium_yearly".data(using: .utf8), forKey: UserDefaultsKeys.subscriptionStatus)
            userDefaults.set(expiresAt, forKey: UserDefaultsKeys.subscriptionExpiryDate)
        case .expired(let lastActiveDate):
            userDefaults.set("expired".data(using: .utf8), forKey: UserDefaultsKeys.subscriptionStatus)
            userDefaults.set(lastActiveDate, forKey: UserDefaultsKeys.subscriptionExpiryDate)
        case .free, .pending:
            userDefaults.removeObject(forKey: UserDefaultsKeys.subscriptionStatus)
            userDefaults.removeObject(forKey: UserDefaultsKeys.subscriptionExpiryDate)
        }
        
        userDefaults.set(hasLifetimeAccess, forKey: UserDefaultsKeys.hasLifetimeAccess)
        
        logger.debug("Cached subscription state: \(self.subscriptionStatusText)")
    }
}

// MARK: - Feature Access Helpers

extension EntitlementManager {
    
    /// Checks if a specific feature is restricted for free users
    /// - Parameter feature: The feature to check
    /// - Returns: True if the feature is restricted, false if available
    func isFeatureRestricted(_ feature: PremiumFeature) -> Bool {
        return !hasAccess(to: feature)
    }
    
    /// Gets the appropriate paywall context for a restricted feature
    /// - Parameter feature: The restricted feature
    /// - Returns: The paywall context to use
    func getPaywallContext(for feature: PremiumFeature) -> PaywallContext {
        return .featureRestricted
    }
    
    /// Gets a list of all premium features the user has access to
    var accessiblePremiumFeatures: [PremiumFeature] {
        return PremiumFeature.allCases.filter { hasAccess(to: $0) }
    }
    
    /// Gets a list of all premium features the user doesn't have access to
    var restrictedPremiumFeatures: [PremiumFeature] {
        return PremiumFeature.allCases.filter { !hasAccess(to: $0) }
    }
}

// MARK: - Usage Integration

extension EntitlementManager {
    
    /// Resets monthly usage counters (called by system on month boundary)
    func resetMonthlyUsage() async {
        await usageTracker?.resetMonthlyUsage()
        logger.info("Monthly usage reset completed")
    }
    
    /// Gets usage statistics for the current period
    func getUsageStatistics() async -> (used: Int, limit: Int, isUnlimited: Bool) {
        if isPremiumUser {
            let used = await usageTracker?.getCurrentUsage() ?? 0
            return (used: used, limit: -1, isUnlimited: true)
        } else {
            let used = await usageTracker?.getCurrentUsage() ?? 0
            let remaining = await usageTracker?.getRemainingStories() ?? 0
            let limit = used + remaining
            return (used: used, limit: limit, isUnlimited: false)
        }
    }
}