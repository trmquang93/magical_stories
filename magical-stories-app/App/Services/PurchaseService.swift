import Foundation
import StoreKit
import OSLog

/// Service responsible for handling all StoreKit operations including product loading,
/// purchases, transaction verification, and subscription management
@MainActor
class PurchaseService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var products: [Product] = []
    @Published private(set) var isLoading = false
    @Published private(set) var purchaseInProgress = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicalstories", 
                               category: "PurchaseService")
    
    // MARK: - Dependencies
    
    private weak var entitlementManager: EntitlementManager?
    
    // MARK: - Initialization
    
    init() {
        // Transaction listening is now handled at application level by TransactionObserver
        // No need to start transaction listener here
    }
    
    deinit {
        // Transaction listening is now handled at application level
    }
    
    // MARK: - Public API
    
    /// Sets the entitlement manager dependency
    /// - Parameter entitlementManager: The entitlement manager to notify of subscription changes
    func setEntitlementManager(_ entitlementManager: EntitlementManager) {
        self.entitlementManager = entitlementManager
    }
    
    /// Loads products from the App Store
    /// - Throws: StoreError if product loading fails
    func loadProducts() async throws {
        guard !isLoading else {
            logger.info("Product loading already in progress")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        defer {
            Task { @MainActor in
                self.isLoading = false
            }
        }
        
        do {
            logger.info("Loading products for IDs: \(SubscriptionProduct.allProductIDs)")
            
            let loadedProducts = try await Product.products(for: SubscriptionProduct.allProductIDs)
            
            logger.info("Successfully loaded \(loadedProducts.count) products")
            
            await MainActor.run {
                self.products = loadedProducts.sorted { product1, product2 in
                    // Sort monthly first, then yearly
                    if product1.id == SubscriptionProduct.premiumMonthly.productID {
                        return true
                    } else if product2.id == SubscriptionProduct.premiumMonthly.productID {
                        return false
                    }
                    return product1.displayPrice < product2.displayPrice
                }
            }
            
            // Log product details for debugging
            for product in loadedProducts {
                logger.debug("Loaded product: \(product.id) - \(product.displayName) - \(product.displayPrice)")
            }
            
        } catch {
            logger.error("Failed to load products: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Failed to load subscription options. Please check your connection and try again."
            }
            throw StoreError.productNotFound
        }
    }
    
    /// Initiates a purchase for the specified product
    /// - Parameter product: The product to purchase
    /// - Returns: True if purchase was successful, false if cancelled
    /// - Throws: StoreError for various failure scenarios
    func purchase(_ product: Product) async throws -> Bool {
        guard !purchaseInProgress else {
            logger.warning("Purchase already in progress")
            throw StoreError.purchaseFailed("Another purchase is already in progress")
        }
        
        purchaseInProgress = true
        errorMessage = nil
        
        defer {
            Task { @MainActor in
                self.purchaseInProgress = false
            }
        }
        
        logger.info("Starting purchase for product: \(product.id)")
        
        // Track analytics
        trackAnalyticsEvent(.purchaseStarted(SubscriptionProduct(rawValue: product.id) ?? .premiumMonthly))
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                logger.info("Purchase successful for product: \(product.id)")
                
                // Verify the transaction
                let transaction = try await checkVerified(verification)
                
                // Track analytics
                trackAnalyticsEvent(.purchaseCompleted(SubscriptionProduct(rawValue: product.id) ?? .premiumMonthly))
                
                logger.info("Transaction verified successfully: \(transaction.id)")
                
                // Calculate expiration date for the transaction
                let calculatedExpiration = calculateExpirationDate(for: transaction, product: product)
                logger.info("[PURCHASE_SERVICE] Calculated expiration: \(calculatedExpiration?.description ?? "nil")")
                
                // Update entitlements immediately since TransactionObserver might not receive this transaction
                if let expiration = calculatedExpiration {
                    logger.info("[PURCHASE_SERVICE] Updating entitlements directly for transaction: \(transaction.id)")
                    await entitlementManager?.updateEntitlement(for: transaction, calculatedExpirationDate: expiration)
                } else {
                    logger.error("[PURCHASE_SERVICE] Could not calculate expiration date for transaction: \(transaction.id)")
                }
                
                // Finish the transaction so it doesn't appear in updates again
                await transaction.finish()
                logger.info("[PURCHASE_SERVICE] Transaction finished: \(transaction.id)")
                
                return true
                
            case .userCancelled:
                logger.info("Purchase cancelled by user for product: \(product.id)")
                return false
                
            case .pending:
                logger.info("Purchase pending approval for product: \(product.id)")
                await MainActor.run {
                    self.errorMessage = "Your purchase is pending approval. Please wait for confirmation."
                }
                throw StoreError.pending
                
            @unknown default:
                logger.error("Unknown purchase result for product: \(product.id)")
                throw StoreError.unknown
            }
            
        } catch {
            logger.error("Purchase failed for product: \(product.id) - \(error.localizedDescription)")
            
            let storeError: StoreError
            if let skError = error as? StoreKitError {
                storeError = mapStoreKitError(skError)
            } else {
                storeError = StoreError.purchaseFailed(error.localizedDescription)
            }
            
            await MainActor.run {
                self.errorMessage = storeError.errorDescription
            }
            
            // Track analytics
            trackAnalyticsEvent(.purchaseFailed(SubscriptionProduct(rawValue: product.id) ?? .premiumMonthly, error: storeError))
            
            throw storeError
        }
    }
    
    /// Restores previous purchases
    /// - Throws: StoreError if restore fails
    func restorePurchases() async throws {
        logger.info("Restoring purchases")
        
        errorMessage = nil
        
        // Track analytics
        trackAnalyticsEvent(.restorePurchases)
        
        do {
            try await AppStore.sync()
            
            // Refresh entitlements after sync
            await entitlementManager?.refreshEntitlementStatus()
            
            logger.info("Successfully restored purchases")
            
        } catch {
            logger.error("Failed to restore purchases: \(error.localizedDescription)")
            
            await MainActor.run {
                self.errorMessage = "Failed to restore purchases. Please try again."
            }
            
            throw StoreError.purchaseFailed("Restore failed: \(error.localizedDescription)")
        }
    }
    
    /// Opens the system subscription management interface
    func manageSubscriptions() async {
        logger.info("Opening subscription management")
        
        do {
            if let windowScene = UIApplication.shared.connectedUIScenes.first as? UIWindowScene {
                try await AppStore.showManageSubscriptions(in: windowScene)
            }
        } catch {
            logger.error("Failed to open subscription management: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Unable to open subscription management. Please try again."
            }
        }
    }
    
    // MARK: - Product Helpers
    
    /// Gets a product by its subscription type
    /// - Parameter subscription: The subscription product type
    /// - Returns: The matching Product, or nil if not found
    func product(for subscription: SubscriptionProduct) -> Product? {
        return products.first { $0.id == subscription.productID }
    }
    
    /// Checks if products are loaded
    var hasLoadedProducts: Bool {
        return !products.isEmpty
    }
    
    // MARK: - Private Methods
    
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
    
    /// Maps StoreKitError to our custom StoreError
    /// - Parameter error: The StoreKitError to map
    /// - Returns: Corresponding StoreError
    private func mapStoreKitError(_ error: StoreKitError) -> StoreError {
        switch error {
        case .userCancelled:
            return .cancelled
        case .networkError:
            return .purchaseFailed("Network error occurred")
        case .systemError:
            return .purchaseFailed("System error occurred")
        case .notAvailableInStorefront:
            return .productNotFound
        case .notEntitled:
            return .notAllowed
        case .unknown:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
    
    /// Tracks analytics events for subscription actions
    /// - Parameter event: The analytics event to track
    private func trackAnalyticsEvent(_ event: SubscriptionAnalyticsEvent) {
        // TODO: Implement analytics tracking
        logger.debug("Analytics event: \(event.eventName)")
    }
}

// MARK: - Product Access Helper Methods

extension PurchaseService {
    
    /// Gets a product by its product ID
    /// - Parameter productID: The product identifier
    /// - Returns: The StoreKit Product if found
    func product(for productID: String) -> Product? {
        return products.first { $0.id == productID }
    }
    
    /// Gets the monthly subscription product
    var monthlyProduct: Product? {
        return product(for: .premiumMonthly)
    }
    
    /// Gets the yearly subscription product
    var yearlyProduct: Product? {
        return product(for: .premiumYearly)
    }
    
    /// Calculates the savings percentage for yearly vs monthly subscription
    /// - Returns: Savings percentage as an integer, or nil if calculation not possible
    var yearlySavingsPercentage: Int? {
        guard let yearly = yearlyProduct,
              let monthly = monthlyProduct else { return nil }
        
        let yearlyPrice = NSDecimalNumber(decimal: yearly.price)
        let monthlyPrice = NSDecimalNumber(decimal: monthly.price)
        let twelve = NSDecimalNumber(value: 12)
        let annualMonthlyPrice = monthlyPrice.multiplying(by: twelve)
        
        if annualMonthlyPrice.compare(yearlyPrice) == .orderedDescending {
            let savings = annualMonthlyPrice.subtracting(yearlyPrice)
            let hundred = NSDecimalNumber(value: 100)
            let savingsRatio = savings.dividing(by: annualMonthlyPrice)
            let savingsPercentage = savingsRatio.multiplying(by: hundred)
            return Int(savingsPercentage.doubleValue.rounded())
        }
        
        return nil
    }
    
    /// Gets dynamic pricing display for a subscription product
    /// - Parameter subscriptionProduct: The subscription product
    /// - Returns: Display price string from StoreKit or fallback
    func displayPrice(for subscriptionProduct: SubscriptionProduct) -> String {
        return subscriptionProduct.displayPrice(from: product(for: subscriptionProduct))
    }
    
    /// Gets dynamic savings message for yearly subscription
    /// - Returns: Savings message based on real product prices
    func yearlySavingsMessage() -> String? {
        return SubscriptionProduct.premiumYearly.savingsMessage(
            yearlyProduct: yearlyProduct,
            monthlyProduct: monthlyProduct
        )
    }
}

// MARK: - Transaction Processing

extension PurchaseService {
    
    /// Processes current entitlements on app launch
    /// Note: This is now handled by TransactionObserver at the application level
    func processCurrentEntitlements() async {
        logger.info("Current entitlement processing is now handled by TransactionObserver")
        // No-op - TransactionObserver handles this now
    }
    
    /// Calculates expiration date for a transaction
    /// - Parameters:
    ///   - transaction: The verified transaction
    ///   - product: The StoreKit product
    /// - Returns: The calculated expiration date
    private func calculateExpirationDate(for transaction: Transaction, product: Product) -> Date? {
        let purchaseDate = transaction.purchaseDate
        logger.info("[PURCHASE_SERVICE] Calculating expiration for purchase date: \(purchaseDate)")
        
        // If the product has subscription info, use it for accurate calculation
        if let subscription = product.subscription {
            let period = subscription.subscriptionPeriod
            let expirationDate = addSubscriptionPeriod(period, to: purchaseDate)
            
            logger.info("[PURCHASE_SERVICE] Using StoreKit subscription period: \(self.formatSubscriptionPeriod(period))")
            logger.info("[PURCHASE_SERVICE] Calculated expiration: \(expirationDate ?? Date())")
            
            return expirationDate
        } else {
            // Fallback calculation based on product ID
            logger.warning("[PURCHASE_SERVICE] No subscription info available, using fallback calculation")
            return addDefaultPeriod(for: product.id, to: purchaseDate)
        }
    }
    
    /// Adds a subscription period to a date
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
    private func addDefaultPeriod(for productID: String, to date: Date) -> Date? {
        var dateComponents = DateComponents()
        
        if productID.contains("monthly") {
            dateComponents.month = 1
        } else if productID.contains("yearly") {
            dateComponents.year = 1
        } else {
            logger.warning("[PURCHASE_SERVICE] Unknown product ID format: \(productID)")
            return nil
        }
        
        return Calendar.current.date(byAdding: dateComponents, to: date)
    }
    
    /// Formats a subscription period into human-readable text
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
}

// MARK: - Product Extensions

extension Product {
    
    /// Convenience property to get subscription period in readable format
    var subscriptionPeriodText: String? {
        guard let subscription = self.subscription else { return nil }
        
        let period = subscription.subscriptionPeriod
        
        switch period.unit {
        case .day:
            return period.value == 1 ? "Daily" : "\(period.value) days"
        case .week:
            return period.value == 1 ? "Weekly" : "\(period.value) weeks"
        case .month:
            return period.value == 1 ? "Monthly" : "\(period.value) months"
        case .year:
            return period.value == 1 ? "Yearly" : "\(period.value) years"
        @unknown default:
            return nil
        }
    }
    
    /// Convenience property to check if product has an introductory offer
    var hasIntroductoryOffer: Bool {
        return subscription?.introductoryOffer != nil
    }
    
    /// Gets the introductory offer description
    var introductoryOfferText: String? {
        guard let intro = subscription?.introductoryOffer else { return nil }
        
        switch intro.type {
        case .introductory:
            let period = intro.period
            switch period.unit {
            case .day:
                return "\(period.value)-day free trial"
            case .week:
                return "\(period.value)-week free trial"
            case .month:
                return "\(period.value)-month free trial"
            case .year:
                return "\(period.value)-year free trial"
            @unknown default:
                return "Free trial"
            }
        case .introductory:
            return "Introductory offer"
        case .promotional:
            return "Promotional offer"
        default:
            return "Special offer"
        }
    }
}

// MARK: - UIApplication Extension

#if canImport(UIKit)
import UIKit

extension UIApplication {
    var connectedUIScenes: Set<UIScene> {
        return UIApplication.shared.connectedScenes
    }
}
#endif