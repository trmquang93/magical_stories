import SwiftUI
import StoreKit

/// A view that presents subscription options and encourages users to upgrade to premium
struct PaywallView: View {
    let context: PaywallContext
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseService: PurchaseService
    @EnvironmentObject private var entitlementManager: EntitlementManager
    
    @State private var selectedProduct: Product?
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    @State private var isLoading = false
    
    init(context: PaywallContext) {
        self.context = context
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [.magicalPrimary.opacity(0.1), .magicalSecondary.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerSection
                        
                        // Features list
                        featuresSection
                        
                        // Subscription options
                        subscriptionOptionsSection
                        
                        // Trust indicators
                        trustIndicatorsSection
                        
                        // Action buttons
                        actionButtonsSection
                        
                        // Legal links
                        legalLinksSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(context.displayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.magicalTextSecondary)
                }
            }
        }
        .task {
            await loadProducts()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Premium icon
            Image(systemName: "crown.fill")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.magicalPrimary, .magicalSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Title and subtitle
            VStack(spacing: 8) {
                Text(context.displayTitle)
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(.magicalTextPrimary)
                    .multilineTextAlignment(.center)
                
                Text(context.displayMessage)
                    .font(.bodyLarge)
                    .foregroundColor(.magicalTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(spacing: 16) {
            ForEach(SubscriptionProduct.premiumMonthly.features, id: \.self) { feature in
                FeatureRow(text: feature)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Subscription Options Section
    
    private var subscriptionOptionsSection: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .font(.headingLarge.weight(.semibold))
                .foregroundColor(.magicalTextPrimary)
            
            if purchaseService.isLoading {
                ProgressView("Loading subscription options...")
                    .foregroundColor(.magicalTextSecondary)
            } else if purchaseService.products.isEmpty {
                VStack(spacing: 8) {
                    Text("Unable to load subscription options")
                        .foregroundColor(.magicalError)
                    
                    Button("Retry") {
                        Task { await loadProducts() }
                    }
                    .foregroundColor(.magicalPrimary)
                }
            } else {
                ForEach(purchaseService.products, id: \.id) { product in
                    SubscriptionOptionView(
                        product: product,
                        isSelected: selectedProduct?.id == product.id,
                        onSelect: { selectedProduct = product },
                        yearlyProduct: purchaseService.yearlyProduct,
                        monthlyProduct: purchaseService.monthlyProduct
                    )
                }
            }
        }
    }
    
    // MARK: - Trust Indicators Section
    
    private var trustIndicatorsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 24) {
                TrustIndicator(
                    icon: "lock.shield.fill",
                    text: "Secure Payment"
                )
                
                TrustIndicator(
                    icon: "arrow.clockwise",
                    text: "Cancel Anytime"
                )
                
                TrustIndicator(
                    icon: "checkmark.seal.fill",
                    text: "No Hidden Fees"
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Start trial / purchase button
            Button(action: startTrialOrPurchase) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text(primaryButtonText)
                            .font(.bodyLarge.weight(.semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.magicalPrimary, .magicalSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .disabled(selectedProduct == nil || isLoading)
            .opacity(selectedProduct == nil || isLoading ? 0.6 : 1.0)
            
            // Restore purchases button
            Button("Restore Purchases") {
                Task {
                    do {
                        try await purchaseService.restorePurchases()
                    } catch {
                        // Handle error
                    }
                }
            }
            .foregroundColor(.magicalTextSecondary)
            .font(.bodyMedium)
        }
    }
    
    // MARK: - Legal Links Section
    
    private var legalLinksSection: some View {
        HStack(spacing: 16) {
            Button("Terms of Service") {
                showingTerms = true
            }
            
            Text("•")
                .foregroundColor(.magicalTextSecondary)
            
            Button("Privacy Policy") {
                showingPrivacy = true
            }
        }
        .foregroundColor(.magicalTextSecondary)
        .font(.caption)
        .sheet(isPresented: $showingTerms) {
            SafariView(url: URL(string: "https://magicalstories.app/terms")!)
        }
        .sheet(isPresented: $showingPrivacy) {
            SafariView(url: URL(string: "https://magicalstories.app/privacy")!)
        }
    }
    
    // MARK: - Computed Properties
    
    private var primaryButtonText: String {
        guard let product = selectedProduct else {
            return "Select a Plan"
        }
        
        if let trialText = product.introductoryOfferText {
            return "Start \(trialText)"
        } else {
            return "Subscribe for \(product.displayPrice)"
        }
    }
    
    // MARK: - Actions
    
    private func loadProducts() async {
        do {
            try await purchaseService.loadProducts()
            // Auto-select the first product (usually monthly)
            selectedProduct = purchaseService.products.first
        } catch {
            // Handle error - products will remain empty and error state will show
        }
    }
    
    private func startTrialOrPurchase() {
        guard let product = selectedProduct else { return }
        
        isLoading = true
        
        Task {
            do {
                let success = try await purchaseService.purchase(product)
                if success {
                    // Purchase successful, dismiss paywall
                    await MainActor.run {
                        dismiss()
                    }
                }
            } catch {
                // Handle purchase error
                // Could show an alert here
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.magicalSuccess)
                .font(.title3)
            
            Text(text)
                .font(.bodyMedium)
                .foregroundColor(.magicalTextPrimary)
            
            Spacer()
        }
    }
}

struct SubscriptionOptionView: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void
    let yearlyProduct: Product?
    let monthlyProduct: Product?
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(subscriptionProduct?.displayName ?? product.displayName)
                            .font(.headingMedium.weight(.semibold))
                            .foregroundColor(.magicalTextPrimary)
                        
                        if let subscriptionProduct = subscriptionProduct,
                           let savingsMessage = subscriptionProduct.savingsMessage(
                            yearlyProduct: yearlyProduct,
                            monthlyProduct: monthlyProduct
                           ) {
                            Text(savingsMessage)
                                .font(.caption.weight(.medium))
                                .foregroundColor(.magicalSuccess)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(.magicalSuccess.opacity(0.1))
                                )
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(product.displayPrice)
                            .font(.headingMedium.weight(.bold))
                            .foregroundColor(.magicalTextPrimary)
                        
                        if let periodText = product.subscriptionPeriodText {
                            Text(periodText)
                                .font(.caption)
                                .foregroundColor(.magicalTextSecondary)
                        }
                    }
                }
                
                if let trialText = product.introductoryOfferText {
                    HStack {
                        Image(systemName: "gift.fill")
                            .foregroundColor(.magicalSecondary)
                        
                        Text(trialText)
                            .font(.bodyMedium.weight(.medium))
                            .foregroundColor(.magicalSecondary)
                        
                        Spacer()
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? .magicalPrimary.opacity(0.1) : .magicalSurfacePrimary)
                    .stroke(
                        isSelected ? .magicalPrimary : .magicalTextSecondary.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var subscriptionProduct: SubscriptionProduct? {
        return SubscriptionProduct(rawValue: product.id)
    }
}

struct TrustIndicator: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.magicalSuccess)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.magicalTextSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Safari View for Legal Links

import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Preview

#if DEBUG
struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView(context: .usageLimitReached)
            .environmentObject(MockPurchaseService())
            .environmentObject(MockEntitlementManager.freeUser)
    }
}

class MockPurchaseService: PurchaseService {
    override init() {
        super.init()
        // Mock some products for preview
        self.products = [] // Would contain mock Product objects in real implementation
    }
}
#endif