import Foundation
import StoreKit
import OSLog

/// Service responsible for managing user subscription entitlements and feature access control
@MainActor
class EntitlementManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .free
    @Published private(set) var hasLifetimeAccess = false
    @Published private(set) var isCheckingEntitlements = false
    @Published private(set) var hasActiveAccessCode = false
    @Published private(set) var accessCodeFeatures: Set<PremiumFeature> = []
    
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
    private var usageAnalyticsService: UsageAnalyticsServiceProtocol?
    private var accessCodeStorage: AccessCodeStorage?
    private var accessCodeValidator: AccessCodeValidator?
    
    // MARK: - Initialization
    
    init() {
        loadCachedSubscriptionState()
        
        // Check entitlements on initialization
        Task {
            await checkInitialEntitlements()
            await refreshAccessCodeStatus()
        }
    }
    
    // MARK: - Dependency Injection
    
    /// Sets the usage tracker dependency
    /// - Parameter usageTracker: The usage tracker to coordinate with
    func setUsageTracker(_ usageTracker: UsageTracker) {
        self.usageTracker = usageTracker
    }
    
    /// Sets the usage analytics service dependency
    /// - Parameter usageAnalyticsService: The usage analytics service to update user profile
    func setUsageAnalyticsService(_ usageAnalyticsService: UsageAnalyticsServiceProtocol) {
        self.usageAnalyticsService = usageAnalyticsService
    }
    
    /// Sets the access code storage dependency
    /// - Parameter accessCodeStorage: The access code storage service
    func setAccessCodeStorage(_ accessCodeStorage: AccessCodeStorage) {
        self.accessCodeStorage = accessCodeStorage
        
        // Listen for changes in access code storage
        Task {
            await refreshAccessCodeStatus()
        }
    }
    
    /// Sets the access code validator dependency
    /// - Parameter accessCodeValidator: The access code validator service
    func setAccessCodeValidator(_ accessCodeValidator: AccessCodeValidator) {
        self.accessCodeValidator = accessCodeValidator
    }
    
    // MARK: - Public API
    
    /// Checks if the user has access to a specific premium feature
    /// - Parameter feature: The premium feature to check
    /// - Returns: True if user has access, false otherwise
    open func hasAccess(to feature: PremiumFeature) -> Bool {
        // Access codes take precedence over subscription status
        if hasActiveAccessCode && accessCodeFeatures.contains(feature) {
            logger.debug("Access granted via access code for feature: \(feature.rawValue)")
            return true
        }
        
        // Fall back to subscription status
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
    open func canGenerateStory() async -> Bool {
        // Access code users with unlimited story generation have unlimited access
        if hasActiveAccessCode && accessCodeFeatures.contains(.unlimitedStoryGeneration) {
            logger.debug("Story generation allowed via access code")
            return true
        }
        
        // Premium users have unlimited access
        if isPremiumUser {
            return true
        }
        
        // Free users are subject to monthly limits
        return await usageTracker?.canGenerateStory() ?? false
    }
    
    /// Gets the number of remaining stories for free users
    /// - Returns: Number of stories remaining this month
    open func getRemainingStories() async -> Int {
        // Access code users with unlimited story generation get unlimited stories
        if hasActiveAccessCode && accessCodeFeatures.contains(.unlimitedStoryGeneration) {
            return Int.max
        }
        
        if isPremiumUser {
            return Int.max // Unlimited for premium users
        }
        
        return await usageTracker?.getRemainingStories() ?? 0
    }
    
    /// Increments the usage count for free users
    open func incrementUsageCount() async {
        // Don't track usage for access code users with unlimited story generation
        if hasActiveAccessCode && accessCodeFeatures.contains(.unlimitedStoryGeneration) {
            logger.debug("Usage tracking skipped for access code user")
            
            // Still increment access code usage for tracking purposes
            if let storage = accessCodeStorage {
                let activeCodes = storage.getActiveAccessCodes()
                for storedCode in activeCodes {
                    if storedCode.accessCode.grantedFeatures.contains(.unlimitedStoryGeneration) {
                        await storage.incrementUsage(for: storedCode.accessCode.code)
                        break // Only increment the first matching code
                    }
                }
            }
            return
        }
        
        // Only track usage for free users
        if !isPremiumUser {
            await usageTracker?.incrementStoryGeneration()
        }
    }
    
    /// Computed property to check if user has premium access
    var isPremiumUser: Bool {
        return subscriptionStatus.isPremium || hasLifetimeAccess
    }
    
    /// Computed property to check if user has access code premium access
    var hasAccessCodePremiumAccess: Bool {
        return hasActiveAccessCode && !accessCodeFeatures.isEmpty
    }
    
    /// Computed property to check if user has any form of premium access
    var hasAnyPremiumAccess: Bool {
        return isPremiumUser || hasAccessCodePremiumAccess
    }
    
    /// Gets user-friendly subscription status text
    var subscriptionStatusText: String {
        if hasActiveAccessCode && !accessCodeFeatures.isEmpty {
            if accessCodeFeatures.count == PremiumFeature.allCases.count {
                return "Full Access Code Premium"
            } else {
                return "Partial Access Code Premium"
            }
        }
        
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
    
    /// Updates entitlements based on a verified transaction with calculated expiration
    /// - Parameters:
    ///   - transaction: The verified transaction to process
    ///   - calculatedExpirationDate: The expiration date calculated from purchase date + period
    func updateEntitlement(for transaction: Transaction, calculatedExpirationDate: Date) async {
        logger.info("[TRANSACTION_FLOW] Processing transaction: \(transaction.id) for product: \(transaction.productID)")
        logger.info("[TRANSACTION_FLOW] Using calculated expiration date: \(calculatedExpirationDate)")
        logger.info("[TRANSACTION_FLOW] Current time: \(Date())")
        logger.info("[TRANSACTION_FLOW] Current subscription status: \(String(describing: self.subscriptionStatus))")
        
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
        
        // Process based on subscription type using calculated expiration
        switch subscriptionProduct {
        case .premiumMonthly, .premiumYearly:
            await processSubscriptionTransaction(transaction, product: subscriptionProduct, calculatedExpiration: calculatedExpirationDate)
        }
        
        // Cache the updated state
        cacheSubscriptionState()
        
        // Reset usage if user became premium
        if isPremiumUser {
            await usageTracker?.resetUsageForPremiumUpgrade()
        }
        
        logger.info("Entitlement update completed for transaction: \(transaction.id)")
    }
    
    /// Updates entitlements based on a verified transaction (legacy method)
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
    
    /// Processes a subscription transaction with calculated expiration date
    /// - Parameters:
    ///   - transaction: The verified subscription transaction
    ///   - product: The subscription product being purchased
    ///   - calculatedExpiration: The expiration date calculated from purchase date + period
    private func processSubscriptionTransaction(_ transaction: Transaction, product: SubscriptionProduct, calculatedExpiration: Date) async {
        logger.info("[TRANSACTION_FLOW] processSubscriptionTransaction called for product: \(String(describing: product))")
        logger.info("[TRANSACTION_FLOW] Calculated expiration: \(calculatedExpiration)")
        logger.info("[TRANSACTION_FLOW] Current time: \(Date())")
        logger.info("[TRANSACTION_FLOW] Is expiration in future? \(calculatedExpiration > Date())")
        
        // Check if subscription is still valid
        if calculatedExpiration <= Date() {
            logger.error("[TRANSACTION_FLOW] CRITICAL: Calculated subscription \(transaction.productID) is already expired!")
            logger.error("[TRANSACTION_FLOW] Expiration: \(calculatedExpiration), Current: \(Date())")
            logger.error("[TRANSACTION_FLOW] Time difference: \(calculatedExpiration.timeIntervalSince(Date())) seconds")
            return
        }
        
        logger.info("[TRANSACTION_FLOW] Expiration is valid, proceeding with subscription update")
        
        // Update subscription status based on product type using calculated expiration
        let newStatus: SubscriptionStatus
        switch product {
        case .premiumMonthly:
            newStatus = .premiumMonthly(expiresAt: calculatedExpiration)
        case .premiumYearly:
            newStatus = .premiumYearly(expiresAt: calculatedExpiration)
        }
        
        logger.info("[TRANSACTION_FLOW] About to update subscription status to: \(String(describing: newStatus))")
        
        // Update the subscription status
        await MainActor.run {
            self.subscriptionStatus = newStatus
        }
        
        logger.info("[TRANSACTION_FLOW] Successfully updated subscription status to: \(self.subscriptionStatusText)")
        logger.info("[TRANSACTION_FLOW] isPremiumUser is now: \(self.isPremiumUser)")
        
        // Update UserProfile in database via UsageAnalyticsService
        logger.info("[TRANSACTION_FLOW] About to update UserProfile with active=true, productId=\(transaction.productID)")
        await updateUserProfileSubscription(
            isActive: true,
            productId: transaction.productID,
            expiryDate: calculatedExpiration
        )
        logger.info("[TRANSACTION_FLOW] Finished updating UserProfile")
    }
    
    /// Processes a subscription transaction and updates the subscription status (legacy method)
    /// - Parameters:
    ///   - transaction: The verified subscription transaction
    ///   - product: The subscription product being purchased
    private func processSubscriptionTransaction(_ transaction: Transaction, product: SubscriptionProduct) async {
        guard let expirationDate = transaction.expirationDate else {
            logger.warning("Subscription transaction \(transaction.id) has no expiration date")
            return
        }
        
        // Check if subscription is still valid
        if expirationDate <= Date() {
            logger.info("Subscription \(transaction.productID) is already expired")
            return
        }
        
        // Update subscription status based on product type
        let newStatus: SubscriptionStatus
        switch product {
        case .premiumMonthly:
            newStatus = .premiumMonthly(expiresAt: expirationDate)
        case .premiumYearly:
            newStatus = .premiumYearly(expiresAt: expirationDate)
        }
        
        // Update the subscription status
        await MainActor.run {
            self.subscriptionStatus = newStatus
        }
        
        logger.info("Updated subscription status to: \(self.subscriptionStatusText)")
        
        // Update UserProfile in database via UsageAnalyticsService
        await updateUserProfileSubscription(
            isActive: true,
            productId: transaction.productID,
            expiryDate: expirationDate
        )
    }
    
    /// Updates the UserProfile subscription status in the database
    /// - Parameters:
    ///   - isActive: Whether the subscription is currently active
    ///   - productId: The product ID of the subscription
    ///   - expiryDate: When the subscription expires
    private func updateUserProfileSubscription(isActive: Bool, productId: String?, expiryDate: Date?) async {
        guard let usageAnalyticsService = usageAnalyticsService else {
            logger.warning("UsageAnalyticsService not available - UserProfile will not be updated")
            return
        }
        
        await usageAnalyticsService.updateSubscriptionStatus(
            isActive: isActive,
            productId: productId,
            expiryDate: expiryDate
        )
        
        logger.info("Updated UserProfile subscription status: active=\(isActive), productId=\(productId ?? "nil")")
    }
    
    /// Updates the UserProfile based on the current subscription status
    private func updateUserProfileFromCurrentStatus() async {
        logger.info("[USER_PROFILE_UPDATE] updateUserProfileFromCurrentStatus called")
        logger.info("[USER_PROFILE_UPDATE] Current subscription status: \(String(describing: self.subscriptionStatus))")
        
        let isActive = subscriptionStatus.isActive
        let productId: String?
        let expiryDate: Date?
        
        switch subscriptionStatus {
        case .premiumMonthly(let expiry):
            productId = SubscriptionProduct.premiumMonthly.productID
            expiryDate = expiry
        case .premiumYearly(let expiry):
            productId = SubscriptionProduct.premiumYearly.productID
            expiryDate = expiry
        case .expired(let lastActive):
            productId = nil
            expiryDate = lastActive
        case .free, .pending:
            productId = nil
            expiryDate = nil
        }
        
        logger.info("[USER_PROFILE_UPDATE] About to call updateUserProfileSubscription with active=\(isActive), productId=\(productId ?? "nil")")
        
        await updateUserProfileSubscription(
            isActive: isActive,
            productId: productId,
            expiryDate: expiryDate
        )
        
        logger.info("[USER_PROFILE_UPDATE] Finished updateUserProfileFromCurrentStatus")
    }
    
    /// Refreshes the current entitlement status by checking all current entitlements
    func refreshEntitlementStatus() async {
        logger.info("[REFRESH_ENTITLEMENTS] refreshEntitlementStatus called")
        logger.info("[REFRESH_ENTITLEMENTS] Current subscription status before refresh: \(String(describing: self.subscriptionStatus))")
        
        isCheckingEntitlements = true
        
        defer {
            Task { @MainActor in
                self.isCheckingEntitlements = false
            }
        }
        
        logger.info("[REFRESH_ENTITLEMENTS] Starting entitlement refresh process")
        
        // Preserve current status instead of defaulting to .free
        // This prevents overwriting valid subscription status when StoreKit entitlements are unavailable
        var newSubscriptionStatus: SubscriptionStatus = subscriptionStatus
        var newHasLifetimeAccess = hasLifetimeAccess
        var foundAnyEntitlements = false
        
        // Check current entitlements
        for await result in Transaction.currentEntitlements {
            foundAnyEntitlements = true
            do {
                let transaction = try await checkVerified(result)
                
                logger.debug("Checking entitlement: \(transaction.productID)")
                
                guard let subscriptionProduct = SubscriptionProduct(rawValue: transaction.productID) else {
                    continue
                }
                
                // Check if transaction is still valid
                if let revocationDate = transaction.revocationDate {
                    logger.info("Entitlement \(transaction.productID) was revoked on \(revocationDate)")
                    // Reset to free if subscription was revoked
                    newSubscriptionStatus = .free
                    newHasLifetimeAccess = false
                    continue
                }
                
                // Check subscription expiration
                if let expirationDate = transaction.expirationDate {
                    if expirationDate <= Date() {
                        logger.info("Subscription \(transaction.productID) expired on \(expirationDate)")
                        // Reset to free if subscription is expired
                        newSubscriptionStatus = .free
                        continue
                    }
                    
                    // Valid subscription found - update to premium
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
        
        // Only reset to free if we found entitlements but they were all invalid
        // If no entitlements found (e.g., test environment), preserve current status
        if foundAnyEntitlements {
            logger.info("Found StoreKit entitlements - using StoreKit data")
        } else {
            logger.info("No StoreKit entitlements found - preserving current subscription status")
        }
        
        // Update state
        logger.info("[REFRESH_ENTITLEMENTS] Updating subscription status to: \(String(describing: newSubscriptionStatus))")
        await MainActor.run {
            self.subscriptionStatus = newSubscriptionStatus
            self.hasLifetimeAccess = newHasLifetimeAccess
        }
        
        // Cache the updated state
        cacheSubscriptionState()
        
        // Update UserProfile in database
        logger.info("[REFRESH_ENTITLEMENTS] About to call updateUserProfileFromCurrentStatus")
        await updateUserProfileFromCurrentStatus()
        
        logger.info("[REFRESH_ENTITLEMENTS] Entitlement status refreshed: \(self.subscriptionStatusText)")
        logger.info("[REFRESH_ENTITLEMENTS] Final isPremiumUser: \(self.isPremiumUser)")
        
        // Refresh access code status
        await refreshAccessCodeStatus()
        
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
    
    
    /// Handles a revoked transaction
    /// - Parameter transaction: The revoked transaction
    func handleRevokedTransaction(_ transaction: Transaction) async {
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
        
        // Update UserProfile in database
        await updateUserProfileSubscription(
            isActive: false,
            productId: nil,
            expiryDate: nil
        )
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
    
    // MARK: - Access Code Management
    
    /// Refreshes the access code status and updates published properties
    @MainActor
    private func refreshAccessCodeStatus() async {
        guard let storage = accessCodeStorage else {
            logger.debug("No access code storage available")
            hasActiveAccessCode = false
            accessCodeFeatures = []
            return
        }
        
        let activeFeatures = storage.getAccessibleFeatures()
        let hasActiveCodes = !storage.getActiveAccessCodes().isEmpty
        
        logger.debug("Access code status: \(hasActiveCodes) active codes, \(activeFeatures.count) features")
        
        hasActiveAccessCode = hasActiveCodes
        accessCodeFeatures = activeFeatures
    }
    
    /// Validates and stores a new access code
    /// - Parameter codeString: The access code string to validate and store
    /// - Returns: True if successfully validated and stored, false otherwise
    /// - Throws: AccessCodeValidationError if validation fails
    @MainActor
    func validateAndStoreAccessCode(_ codeString: String) async throws -> Bool {
        logger.info("🚀 ENTITLEMENT MANAGER: Starting promo code validation...")
        logger.info("   User entered: '\(codeString)'")
        
        guard let validator = accessCodeValidator,
              let storage = accessCodeStorage else {
            logger.error("❌ Access code services not available")
            throw AccessCodeValidationError.unknown("Access code services not available")
        }
        
        logger.info("✅ Services available, starting validation...")
        
        let validationResult = await validator.validateAccessCode(codeString)
        
        switch validationResult {
        case .valid(let accessCode):
            logger.info("🎯 VALIDATION SUCCESSFUL! Proceeding to store...")
            try await storage.storeAccessCode(accessCode)
            
            logger.info("📱 Refreshing entitlement status...")
            await refreshAccessCodeStatus()
            
            logger.info("🎉 SUCCESS! Access code validated and stored")
            logger.info("   Features unlocked: \(accessCode.grantedFeatures.map { $0.rawValue }.joined(separator: ", "))")
            logger.info("   Type: \(accessCode.type.displayName)")
            logger.info("   Expires: \(accessCode.expiresAt?.description ?? "Never")")
            
            return true
            
        case .invalid(let error):
            logger.error("❌ VALIDATION FAILED: \(error.localizedDescription)")
            logger.error("   Code: '\(codeString)'")
            logger.error("   Error type: \(error)")
            throw error
        }
    }
    
    /// Removes an access code from storage
    /// - Parameter codeString: The access code string to remove
    @MainActor
    func removeAccessCode(_ codeString: String) async {
        guard let storage = accessCodeStorage else {
            logger.warning("Access code storage not available")
            return
        }
        
        await storage.removeAccessCode(codeString)
        await refreshAccessCodeStatus()
        
        logger.info("Access code removed: \(codeString.prefix(4))...")
    }
    
    /// Gets all active access codes
    /// - Returns: Array of active stored access codes
    func getActiveAccessCodes() -> [StoredAccessCode] {
        return accessCodeStorage?.getActiveAccessCodes() ?? []
    }
    
    /// Clears all stored access codes
    @MainActor
    func clearAllAccessCodes() async {
        guard let storage = accessCodeStorage else {
            logger.warning("Access code storage not available")
            return
        }
        
        await storage.clearAllAccessCodes()
        await refreshAccessCodeStatus()
        
        logger.info("All access codes cleared")
    }
    
    /// Gets access code status summary
    var accessCodeStatusSummary: AccessCodeStatusSummary? {
        return accessCodeStorage?.statusSummary
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
        // Access code users with unlimited generation get unlimited status
        if hasActiveAccessCode && accessCodeFeatures.contains(.unlimitedStoryGeneration) {
            let used = await usageTracker?.getCurrentUsage() ?? 0
            return (used: used, limit: -1, isUnlimited: true)
        }
        
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