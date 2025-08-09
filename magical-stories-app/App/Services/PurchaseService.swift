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
    
    // MARK: - Dependencies
    
    private weak var entitlementManager: EntitlementManager?
    private var analyticsService: ClarityAnalyticsService
    private weak var ratingService: RatingService?
    
    // MARK: - Initialization
    
    init() {
        self.analyticsService = ClarityAnalyticsService.shared
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
    
    /// Sets the analytics service dependency
    /// - Parameter analyticsService: The analytics service for tracking events
    func setAnalyticsService(_ analyticsService: ClarityAnalyticsService) {
        self.analyticsService = analyticsService
    }
    
    /// Sets the rating service dependency
    /// - Parameter ratingService: The rating service for tracking user engagement
    func setRatingService(_ ratingService: RatingService) {
        self.ratingService = ratingService
    }
    
    /// Loads products from the App Store
    /// - Throws: StoreError if product loading fails
    func loadProducts() async throws {
        guard !isLoading else {
            print("Product loading already in progress")
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
            print("🛍️ [PURCHASE_SERVICE] Starting product loading...")
            print("🛍️ [PURCHASE_SERVICE] Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
            print("🛍️ [PURCHASE_SERVICE] Product IDs to load: \(SubscriptionProduct.allProductIDs)")
            
            // Check StoreKit availability
            print("🛍️ [PURCHASE_SERVICE] Checking StoreKit availability...")
            
            let loadedProducts = try await Product.products(for: SubscriptionProduct.allProductIDs)
            
            print("🛍️ [PURCHASE_SERVICE] Raw products returned: \(loadedProducts.count)")
            
            if loadedProducts.isEmpty {
                print("🛍️ [PURCHASE_SERVICE] ❌ No products returned from App Store Connect")
                print("🛍️ [PURCHASE_SERVICE] This could indicate:")
                print("🛍️ [PURCHASE_SERVICE] 1. Products not approved in App Store Connect")
                print("🛍️ [PURCHASE_SERVICE] 2. Bundle ID mismatch")
                print("🛍️ [PURCHASE_SERVICE] 3. Network connectivity issues")
                print("🛍️ [PURCHASE_SERVICE] 4. Sandbox account issues (if testing)")
            } else {
                print("🛍️ [PURCHASE_SERVICE] ✅ Successfully loaded \(loadedProducts.count) products")
            }
            
            await MainActor.run {
                self.products = loadedProducts.sorted { product1, product2 in
                    // Sort monthly first, then yearly
                    if product1.id == SubscriptionProduct.premiumMonthly.productID {
                        return true
                    } else if product2.id == SubscriptionProduct.premiumMonthly.productID {
                        return false
                    }
                    return product1.price < product2.price
                }
            }
            
            // Log detailed product information for debugging
            for product in loadedProducts {
                print("🛍️ [PURCHASE_SERVICE] Product details:")
                print("🛍️ [PURCHASE_SERVICE]   ID: \(product.id)")
                print("🛍️ [PURCHASE_SERVICE]   Name: \(product.displayName)")
                print("🛍️ [PURCHASE_SERVICE]   Price: \(product.displayPrice)")
                print("🛍️ [PURCHASE_SERVICE]   Type: \(product.type)")
                if let subscription = product.subscription {
                    print("🛍️ [PURCHASE_SERVICE]   Period: \(subscription.subscriptionPeriod)")
                }
            }
            
        } catch {
            print("🛍️ [PURCHASE_SERVICE] ❌ Failed to load products: \(error)")
            print("🛍️ [PURCHASE_SERVICE] Error type: \(type(of: error))")
            print("🛍️ [PURCHASE_SERVICE] Error description: \(error.localizedDescription)")
            
            if let storeKitError = error as? StoreKitError {
                print("🛍️ [PURCHASE_SERVICE] StoreKit error details: \(storeKitError)")
            }
            
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
            print("Purchase already in progress")
            throw StoreError.purchaseFailed("Another purchase is already in progress")
        }
        
        purchaseInProgress = true
        errorMessage = nil
        
        defer {
            Task { @MainActor in
                self.purchaseInProgress = false
            }
        }
        
        print("Starting purchase for product: \(product.id)")
        
        // Track analytics
        trackAnalyticsEvent(.purchaseStarted(SubscriptionProduct(rawValue: product.id) ?? .premiumMonthly))
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                print("Purchase successful for product: \(product.id)")
                
                // Verify the transaction
                let transaction = try await checkVerified(verification)
                
                // Track analytics
                trackAnalyticsEvent(.purchaseCompleted(SubscriptionProduct(rawValue: product.id) ?? .premiumMonthly))
                
                print("Transaction verified successfully: \(transaction.id)")
                
                // Calculate expiration date for the transaction
                let calculatedExpiration = calculateExpirationDate(for: transaction, product: product)
                print("[PURCHASE_SERVICE] Calculated expiration: \(calculatedExpiration?.description ?? "nil")")
                
                // Update entitlements immediately since TransactionObserver might not receive this transaction
                if let expiration = calculatedExpiration {
                    print("[PURCHASE_SERVICE] Updating entitlements directly for transaction: \(transaction.id)")
                    await entitlementManager?.updateEntitlement(for: transaction, calculatedExpirationDate: expiration)
                } else {
                    print("[PURCHASE_SERVICE] Could not calculate expiration date for transaction: \(transaction.id)")
                }
                
                // Finish the transaction so it doesn't appear in updates again
                await transaction.finish()
                print("[PURCHASE_SERVICE] Transaction finished: \(transaction.id)")
                
                // Record subscription purchase for rating system (non-blocking)
                Task { @MainActor [weak self] in
                    await self?.ratingService?.handleSubscriptionPurchased()
                }
                
                return true
                
            case .userCancelled:
                print("Purchase cancelled by user for product: \(product.id)")
                return false
                
            case .pending:
                print("Purchase pending approval for product: \(product.id)")
                await MainActor.run {
                    self.errorMessage = "Your purchase is pending approval. Please wait for confirmation."
                }
                throw StoreError.pending
                
            @unknown default:
                print("Unknown purchase result for product: \(product.id)")
                throw StoreError.unknown
            }
            
        } catch {
            print("Purchase failed for product: \(product.id) - \(error.localizedDescription)")
            
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
        print("Restoring purchases")
        
        errorMessage = nil
        
        // Track analytics
        trackAnalyticsEvent(.restorePurchases)
        
        do {
            try await AppStore.sync()
            
            // Refresh entitlements after sync
            await entitlementManager?.refreshEntitlementStatus()
            
            // Record successful restore purchases for rating system (non-blocking)
            Task { @MainActor [weak self] in
                await self?.ratingService?.recordEngagementEvent(.subscribed)
            }
            
            print("Successfully restored purchases")
            
        } catch {
            print("Failed to restore purchases: \(error.localizedDescription)")
            
            await MainActor.run {
                self.errorMessage = "Failed to restore purchases. Please try again."
            }
            
            throw StoreError.purchaseFailed("Restore failed: \(error.localizedDescription)")
        }
    }
    
    /// Opens the system subscription management interface
    func manageSubscriptions() async {
        print("Opening subscription management")
        
        do {
            if let windowScene = UIApplication.shared.connectedUIScenes.first as? UIWindowScene {
                try await AppStore.showManageSubscriptions(in: windowScene)
            }
        } catch {
            print("Failed to open subscription management: \(error.localizedDescription)")
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
            print("Transaction verification failed: \(error.localizedDescription)")
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
        print("Analytics event: \(event.eventName)")
        
        switch event {
        case .paywallShown(let context):
            analyticsService.trackPaywallShown(source: context.rawValue)
        case .productViewed(let product):
            analyticsService.trackUserAction("product_viewed", parameters: [
                "product_id": product.productID,
                "timestamp": Date().timeIntervalSince1970
            ])
        case .purchaseStarted(let product):
            analyticsService.trackSubscriptionStarted(productId: product.productID, source: "paywall")
        case .purchaseCompleted(let product):
            analyticsService.trackSubscriptionCompleted(productId: product.productID, source: "paywall")
        case .purchaseFailed(let product, let error):
            analyticsService.trackSubscriptionFailed(productId: product.productID, source: "paywall", error: error.localizedDescription)
        case .trialStarted(let product):
            analyticsService.trackUserAction("trial_started", parameters: [
                "product_id": product.productID,
                "timestamp": Date().timeIntervalSince1970
            ])
        case .subscriptionCancelled:
            analyticsService.trackUserAction("subscription_cancelled", parameters: [
                "timestamp": Date().timeIntervalSince1970
            ])
        case .featureRestricted(let feature):
            analyticsService.trackUserAction("feature_restricted", parameters: [
                "feature": feature.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ])
        case .usageLimitReached:
            analyticsService.trackUserAction("usage_limit_reached", parameters: [
                "timestamp": Date().timeIntervalSince1970
            ])
        case .restorePurchases:
            analyticsService.trackUserAction("restore_purchases", parameters: [
                "timestamp": Date().timeIntervalSince1970
            ])
        }
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
        print("Current entitlement processing is now handled by TransactionObserver")
        // No-op - TransactionObserver handles this now
    }
    
    /// Calculates expiration date for a transaction
    /// - Parameters:
    ///   - transaction: The verified transaction
    ///   - product: The StoreKit product
    /// - Returns: The calculated expiration date
    private func calculateExpirationDate(for transaction: Transaction, product: Product) -> Date? {
        let purchaseDate = transaction.purchaseDate
        print("[PURCHASE_SERVICE] Calculating expiration for purchase date: \(purchaseDate)")
        
        // If the product has subscription info, use it for accurate calculation
        if let subscription = product.subscription {
            let period = subscription.subscriptionPeriod
            let expirationDate = addSubscriptionPeriod(period, to: purchaseDate)
            
            print("[PURCHASE_SERVICE] Using StoreKit subscription period: \(self.formatSubscriptionPeriod(period))")
            print("[PURCHASE_SERVICE] Calculated expiration: \(expirationDate ?? Date())")
            
            return expirationDate
        } else {
            // Fallback calculation based on product ID
            print("[PURCHASE_SERVICE] No subscription info available, using fallback calculation")
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
            print("Unknown subscription period unit")
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
            print("[PURCHASE_SERVICE] Unknown product ID format: \(productID)")
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
