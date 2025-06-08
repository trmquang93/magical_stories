import SwiftUI

/// Promo Code section card for settings that allows users to redeem access codes
struct PromoCodeCard: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var showingAccessCodeEntry = false
    @State private var activeAccessCodes: [StoredAccessCode] = []
    
    var body: some View {
        // Hide promo code card if user is subscribed
        if entitlementManager.isPremiumUser {
            return AnyView(EmptyView())
        }
        
        return AnyView(SettingsCard(title: R.string.localizable.promoCodeTitle(), icon: "gift.fill") {
            VStack(spacing: UITheme.Spacing.md) {
                if activeAccessCodes.isEmpty {
                    // No active codes - show redeem option
                    VStack(spacing: UITheme.Spacing.sm) {
                        Text(R.string.localizable.promoCodeHaveCode())
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Text(R.string.localizable.promoCodeDescription())
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: {
                        showingAccessCodeEntry = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text(R.string.localizable.promoCodeButtonRedeem())
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                } else {
                    // Show active codes
                    VStack(alignment: .leading, spacing: UITheme.Spacing.sm) {
                        Text("Active Promo Codes")
                            .font(.headline)
                        
                        ForEach(activeAccessCodes, id: \.accessCode.id) { storedCode in
                            PromoCodeRow(storedCode: storedCode)
                        }
                        
                        // Add another code button
                        Button(action: {
                            showingAccessCodeEntry = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Add Another Code")
                            }
                            .font(.body)
                            .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAccessCodeEntry) {
            AccessCodeEntryView()
        }
        .onAppear {
            loadActiveAccessCodes()
        }
        .onChange(of: entitlementManager.hasActiveAccessCode) { _, _ in
            loadActiveAccessCodes()
        }
        .onChange(of: entitlementManager.subscriptionStatus) { _, _ in
            // React to subscription status changes
        }
        .onChange(of: entitlementManager.hasLifetimeAccess) { _, _ in
            // React to lifetime access changes
        }
        .onReceive(entitlementManager.objectWillChange) { _ in
            // React to any entitlement manager changes
        })
    }
    
    private func loadActiveAccessCodes() {
        activeAccessCodes = entitlementManager.getActiveAccessCodes()
    }
}

/// Individual row for displaying an active promo code
struct PromoCodeRow: View {
    let storedCode: StoredAccessCode
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var showingRemoveAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: UITheme.Spacing.xs) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(storedCode.accessCode.type.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text(storedCode.accessCode.formattedCode)
                        .font(.monospaced(.caption)())
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    if let daysRemaining = storedCode.accessCode.daysRemaining {
                        Text("\(daysRemaining) days left")
                            .font(.caption)
                            .foregroundColor(AccessCodeExpirationUtilities.expirationColor(for: storedCode.accessCode))
                    } else {
                        Text("Never expires")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Button("Remove") {
                        showingRemoveAlert = true
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
            
            // Features summary
            Text(storedCode.accessCode.permissionsSummary)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Usage information
            if let usageLimit = storedCode.accessCode.usageLimit {
                let remaining = usageLimit - storedCode.accessCode.usageCount
                Text("Uses remaining: \(remaining)/\(usageLimit)")
                    .font(.caption)
                    .foregroundColor(remaining > 0 ? .secondary : .red)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
        .alert("Remove Promo Code", isPresented: $showingRemoveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                Task {
                    await entitlementManager.removeAccessCode(storedCode.accessCode.code)
                }
            }
        } message: {
            Text("Are you sure you want to remove this promo code? You will lose access to the features it provides.")
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        PromoCodeCard()
            .environmentObject({
                let manager = EntitlementManager()
                return manager
            }())
        
        Spacer()
    }
    .padding()
}