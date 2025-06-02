import Foundation
import StoreKit
import OSLog

/// Application-level transaction observer that handles all StoreKit transactions
/// This runs at the app level to capture purchases made outside the app (e.g., from App Store)
@MainActor
class TransactionObserver: ObservableObject {
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicalstories", 
                               category: "TransactionObserver")
    private var transactionListener: Task<Void, Error>?
    
    // MARK: - Dependencies
    
    private weak var entitlementManager: EntitlementManager?
    private weak var purchaseService: PurchaseService?
    
    // MARK: - Initialization
    
    init() {
        logger.info("Initializing TransactionObserver")
        startObserving()
    }
    
    deinit {
        // Cancel the transaction listener directly since we can't call @MainActor methods from deinit
        transactionListener?.cancel()
    }
    
    // MARK: - Dependency Injection
    
    /// Sets the entitlement manager dependency
    /// - Parameter entitlementManager: The entitlement manager to notify of transactions
    func setEntitlementManager(_ entitlementManager: EntitlementManager) {
        self.entitlementManager = entitlementManager
    }
    
    /// Sets the purchase service dependency
    /// - Parameter purchaseService: The purchase service for product information
    func setPurchaseService(_ purchaseService: PurchaseService) {
        self.purchaseService = purchaseService
    }
    
    // MARK: - Transaction Observation
    
    /// Starts observing StoreKit transactions
    private func startObserving() {
        logger.info("Starting transaction observation")
        
        transactionListener = Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { break }
                
                do {
                    let transaction = try await self.checkVerified(result)
                    
                    await MainActor.run {
                        self.logger.info("Received transaction: \(transaction.id) for product: \(transaction.productID)")
                        self.logger.info("Purchase date: \(transaction.purchaseDate)")
                        self.logger.info("Transaction source: \(self.getTransactionSource(transaction))")
                    }
                    
                    // Process the transaction with proper expiration calculation
                    await self.processTransaction(transaction)
                    
                    // Finish the transaction
                    await transaction.finish()
                    
                    await MainActor.run {
                        self.logger.info("Finished processing transaction: \(transaction.id)")
                    }
                    
                } catch {
                    await MainActor.run {
                        self.logger.error("Transaction verification failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    /// Stops observing transactions
    private func stopObserving() {
        logger.info("Stopping transaction observation")
        transactionListener?.cancel()
        transactionListener = nil
    }
    
    // MARK: - Transaction Processing
    
    /// Processes a verified transaction with proper expiration date calculation
    /// - Parameter transaction: The verified transaction to process
    private func processTransaction(_ transaction: Transaction) async {
        logger.info("Processing transaction: \(transaction.id)")
        
        // Check if this is a subscription product we recognize
        guard let subscriptionProduct = SubscriptionProduct(rawValue: transaction.productID) else {
            logger.warning("Unknown product ID in transaction: \(transaction.productID)")
            return
        }
        
        // Check if transaction is revoked
        if let revocationDate = transaction.revocationDate {
            logger.info("Transaction \(transaction.id) was revoked on \(revocationDate)")
            await entitlementManager?.handleRevokedTransaction(transaction)
            return
        }
        
        // Calculate proper expiration date using purchase date + subscription period
        let calculatedExpirationDate = await calculateExpirationDate(
            for: transaction,
            subscriptionProduct: subscriptionProduct
        )
        
        guard let expirationDate = calculatedExpirationDate else {
            logger.warning("Could not calculate expiration date for transaction: \(transaction.id)")
            return
        }
        
        logger.info("Calculated expiration date: \(expirationDate) for transaction: \(transaction.id)")
        
        // Update entitlements with calculated expiration
        await entitlementManager?.updateEntitlement(
            for: transaction,
            calculatedExpirationDate: expirationDate
        )
    }
    
    /// Calculates the expiration date for a single transaction period
    /// 
    /// IMPORTANT: Each transaction represents ONE billing period only:
    /// - Intro transaction: Purchase Date + Intro Period = Expiration
    /// - Regular transaction: Purchase Date + Regular Period = Expiration
    /// 
    /// After intro period expires, StoreKit creates a NEW transaction for regular billing.
    /// We should NEVER add intro + regular periods together for one transaction.
    /// 
    /// - Parameters:
    ///   - transaction: The transaction containing purchase date
    ///   - subscriptionProduct: The subscription product type
    /// - Returns: The calculated expiration date for this transaction's billing period
    private func calculateExpirationDate(
        for transaction: Transaction,
        subscriptionProduct: SubscriptionProduct
    ) async -> Date? {
        
        // Try to get the StoreKit product for accurate period information
        let product = await purchaseService?.product(for: subscriptionProduct)
        
        if let product = product,
           let subscription = product.subscription {
            
            let purchaseDate = transaction.purchaseDate
            logger.info("Calculating expiration for transaction purchased on: \(purchaseDate)")
            
            // Determine if this transaction is for an introductory period or regular period
            // We can check the transaction's offer properties to determine the billing period
            
            let isIntroductoryTransaction = isTransactionForIntroductoryPeriod(transaction, subscription: subscription)
            
            if isIntroductoryTransaction, let introOffer = subscription.introductoryOffer {
                // This transaction is for the introductory period
                let introDescription = describeIntroductoryOffer(introOffer)
                logger.info("Transaction is for introductory period: \(introDescription)")
                
                if let introExpirationDate = addSubscriptionPeriod(introOffer.period, to: purchaseDate) {
                    logger.info("Calculated expiration using intro period: \(introExpirationDate)")
                    return introExpirationDate
                }
            }
            
            // This transaction is for the regular subscription period
            let regularPeriodText = formatSubscriptionPeriod(subscription.subscriptionPeriod)
            let regularExpirationDate = addSubscriptionPeriod(subscription.subscriptionPeriod, to: purchaseDate)
            logger.info("Transaction is for regular period (\(regularPeriodText)): \(regularExpirationDate ?? Date())")
            
            return regularExpirationDate
        } else {
            logger.warning("No StoreKit product found, using fallback calculation")
            // Fallback to default periods if StoreKit product not available
            return addDefaultPeriod(for: subscriptionProduct, to: transaction.purchaseDate)
        }
    }
    
    /// Adds a subscription period to a date
    /// - Parameters:
    ///   - period: The subscription period from StoreKit
    ///   - date: The starting date
    /// - Returns: The calculated end date
    private func addSubscriptionPeriod(_ period: Product.SubscriptionPeriod, to date: Date) -> Date? {
        var dateComponents = DateComponents()
        
        switch period.unit {
        case .day:
            dateComponents.day = period.value
        case .week:
            dateComponents.weekOfYear = period.value
        case .month:
            dateComponents.month = period.value
        case .year:
            dateComponents.year = period.value
        @unknown default:
            logger.warning("Unknown subscription period unit")
            return nil
        }
        
        return Calendar.current.date(byAdding: dateComponents, to: date)
    }
    
    /// Adds default subscription period when StoreKit data unavailable
    /// Note: This fallback method cannot account for introductory offers since
    /// StoreKit product data is not available. Expiration may be inaccurate if
    /// the subscription has intro offers.
    /// - Parameters:
    ///   - subscriptionProduct: The subscription product type
    ///   - date: The starting date
    /// - Returns: The calculated end date (without intro period consideration)
    private func addDefaultPeriod(for subscriptionProduct: SubscriptionProduct, to date: Date) -> Date? {
        var dateComponents = DateComponents()
        
        switch subscriptionProduct {
        case .premiumMonthly:
            dateComponents.month = 1
        case .premiumYearly:
            dateComponents.year = 1
        }
        
        return Calendar.current.date(byAdding: dateComponents, to: date)
    }
    
    /// Determines if a transaction is for an introductory period
    /// - Parameters:
    ///   - transaction: The transaction to check
    ///   - subscription: The subscription info from StoreKit
    /// - Returns: True if this transaction is for an introductory period
    private func isTransactionForIntroductoryPeriod(_ transaction: Transaction, subscription: Product.SubscriptionInfo) -> Bool {
        // Method 1: Check if transaction has intro offer identifier
        // Note: StoreKit may provide offer identifiers in the transaction
        if let offer = transaction.offer {
            logger.info("Transaction has offer")
            // If there's an offer, this is likely an intro or promotional transaction
            return true
        }
        
        // Method 2: Check transaction price against regular price
        // If the transaction price is different from regular price, it might be intro pricing
        // Note: This requires access to transaction price, which may not always be available
        
        // Method 3: Without offer information, we cannot reliably determine if this is an intro transaction
        // The presence of an introductory offer on the product doesn't mean this specific transaction used it
        // Users can only use intro offers once, so subsequent transactions would be regular even if intro exists
        logger.info("No offer information available - treating as regular transaction")
        logger.info("Note: Cannot determine if this transaction used intro pricing without offer details")
        return false
    }
    
    /// Gets a human-readable description of the transaction source
    /// - Parameter transaction: The transaction
    /// - Returns: Description of where the purchase was made
    private func getTransactionSource(_ transaction: Transaction) -> String {
        // Note: In a real implementation, you might be able to determine the source
        // based on transaction timing, app state, etc.
        return "Unknown source (could be in-app or App Store)"
    }
    
    /// Gets a human-readable description of an introductory offer
    /// - Parameter introOffer: The introductory offer to describe
    /// - Returns: Formatted description of the intro offer
    private func describeIntroductoryOffer(_ introOffer: Any) -> String {
        // Note: StoreKit 2 introductory offer APIs can vary between iOS versions
        // This is a simplified implementation that works with basic properties
        return "Introductory offer available"
    }
    
    /// Formats a subscription period into human-readable text
    /// - Parameter period: The subscription period to format
    /// - Returns: Formatted period text (e.g., "7 days", "1 month")
    private func formatSubscriptionPeriod(_ period: Product.SubscriptionPeriod) -> String {
        let value = period.value
        
        switch period.unit {
        case .day:
            return value == 1 ? "1 day" : "\(value) days"
        case .week:
            return value == 1 ? "1 week" : "\(value) weeks"
        case .month:
            return value == 1 ? "1 month" : "\(value) months"
        case .year:
            return value == 1 ? "1 year" : "\(value) years"
        @unknown default:
            return "\(value) period(s)"
        }
    }
    
    // MARK: - Transaction Verification
    
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
    
    // MARK: - Public API
    
    /// Processes current entitlements on app launch
    func processCurrentEntitlements() async {
        logger.info("Processing current entitlements on app launch")
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try await checkVerified(result)
                logger.debug("Found current entitlement: \(transaction.productID)")
                
                // Process each current entitlement
                await processTransaction(transaction)
                
            } catch {
                logger.error("Failed to verify current entitlement: \(error.localizedDescription)")
            }
        }
        
        logger.info("Finished processing current entitlements")
    }
}

// MARK: - Extensions

extension TransactionObserver {
    
    /// Manually processes a transaction (for testing or special cases)
    /// - Parameter transaction: The transaction to process
    func manuallyProcessTransaction(_ transaction: Transaction) async {
        await processTransaction(transaction)
    }
}