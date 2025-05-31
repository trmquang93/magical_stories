import Foundation
import StoreKit
import OSLog

/// Service responsible for handling all StoreKit operations including product loading,
/// purchases, transaction verification, and subscription management
@MainActor
final class PurchaseService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false
    @Published private(set) var purchaseInProgress = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicalstories", 
                               category: "PurchaseService")
    private var transactionListener: Task<Void, Error>?
    
    // MARK: - Dependencies
    
    private weak var entitlementManager: EntitlementManager?
    
    // MARK: - Initialization
    
    init() {
        // Start listening for transaction updates
        transactionListener = listenForTransactions()
    }
    
    deinit {
        transactionListener?.cancel()
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
                
                // The transaction listener will handle entitlement updates
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
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
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
    
    /// Starts listening for transaction updates
    /// - Returns: Task that handles transaction updates
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { break }
                
                do {
                    let transaction = try await self.checkVerified(result)
                    
                    await MainActor.run {
                        self.logger.info("Received transaction update: \(transaction.id) - \(transaction.productID)")
                    }
                    
                    // Notify entitlement manager of transaction update
                    await self.entitlementManager?.updateEntitlement(for: transaction)
                    
                    // Finish the transaction
                    await transaction.finish()
                    
                    await MainActor.run {
                        self.logger.info("Finished transaction: \(transaction.id)")
                    }
                    
                } catch {
                    await MainActor.run {
                        self.logger.error("Transaction verification failed: \(error.localizedDescription)")
                    }
                }
            }
        }
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

// MARK: - Transaction Processing

extension PurchaseService {
    
    /// Processes current entitlements on app launch
    func processCurrentEntitlements() async {
        logger.info("Processing current entitlements")
        
        // Check for current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try await checkVerified(result)
                logger.debug("Found current entitlement: \(transaction.productID)")
                
                // Notify entitlement manager
                await entitlementManager?.updateEntitlement(for: transaction)
                
            } catch {
                logger.error("Failed to verify current entitlement: \(error.localizedDescription)")
            }
        }
        
        logger.info("Finished processing current entitlements")
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
    var connectedScenes: Set<UIScene> {
        return UIApplication.shared.connectedScenes
    }
}
#endif