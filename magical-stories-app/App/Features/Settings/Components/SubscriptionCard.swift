import SwiftUI
import Foundation
import Combine

/// Subscription section card for settings that displays current subscription status
/// and provides access to upgrade options for free users
struct SubscriptionCard: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var showingPaywall = false
    @State private var usageStats: (used: Int, limit: Int, isUnlimited: Bool) = (0, 3, false)
    @State private var refreshTrigger = 0
    
    var body: some View {
        SettingsCard(title: "Subscription", icon: "crown.fill") {
            VStack(spacing: 16) {
                if entitlementManager.isPremiumUser {
                    premiumUserContent
                } else {
                    freeUserContent
                }
            }
            .onAppear {
                // Debug: Track view state
                print("SubscriptionCard: View appeared. isPremiumUser: \(entitlementManager.isPremiumUser)")
            }
            .id(refreshTrigger) // Force view refresh when refreshTrigger changes
        }
        .task {
            await loadUsageStats()
        }
        .onChange(of: entitlementManager.subscriptionStatus) { oldValue, newValue in
            print("SubscriptionCard: subscriptionStatus changed from \(oldValue) to \(newValue)")
            refreshTrigger += 1
            Task {
                await loadUsageStats()
            }
        }
        .onChange(of: entitlementManager.hasLifetimeAccess) { oldValue, newValue in
            print("SubscriptionCard: hasLifetimeAccess changed from \(oldValue) to \(newValue)")
            refreshTrigger += 1
            Task {
                await loadUsageStats()
            }
        }
        .onReceive(entitlementManager.objectWillChange) { _ in
            print("SubscriptionCard: EntitlementManager objectWillChange fired")
            refreshTrigger += 1
            Task {
                await loadUsageStats()
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(context: .settings)
                .onDisappear {
                    // Force refresh when paywall is dismissed
                    print("SubscriptionCard: Paywall dismissed, forcing refresh")
                    refreshTrigger += 1
                    Task {
                        await loadUsageStats()
                    }
                }
        }
    }
    
    // MARK: - Premium User Content
    
    private var premiumUserContent: some View {
        VStack(spacing: 12) {
            // Premium status header
            HStack {
                Image(systemName: "crown.fill")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [UITheme.Colors.primary, UITheme.Colors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(entitlementManager.subscriptionStatusText)
                        .font(UITheme.Typography.headingSmall)
                        .foregroundColor(UITheme.Colors.textPrimary)
                        .onAppear {
                            print("SubscriptionCard: Premium content showing status: \(entitlementManager.subscriptionStatusText)")
                        }
                    
                    if let renewalInfo = entitlementManager.renewalInformation {
                        Text(renewalInfo)
                            .font(UITheme.Typography.bodySmall)
                            .foregroundColor(UITheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
            }
            
            // Premium benefits indicator
            HStack {
                Image(systemName: "infinity")
                    .foregroundColor(UITheme.Colors.success)
                    .font(.caption.weight(.medium))
                
                Text("Unlimited Stories")
                    .font(.caption.weight(.medium))
                    .foregroundColor(UITheme.Colors.success)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(UITheme.Colors.success.opacity(0.1))
            )
        }
    }
    
    // MARK: - Free User Content
    
    private var freeUserContent: some View {
        VStack(spacing: 16) {
            // Free plan header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Free Plan")
                        .font(UITheme.Typography.headingSmall)
                        .foregroundColor(UITheme.Colors.textPrimary)
                        .onAppear {
                            print("SubscriptionCard: Free content showing. isPremiumUser: \(entitlementManager.isPremiumUser), status: \(entitlementManager.subscriptionStatus)")
                        }
                    
                    Text("Limited features")
                        .font(UITheme.Typography.bodySmall)
                        .foregroundColor(UITheme.Colors.textSecondary)
                }
                
                Spacer()
            }
            
            // Usage indicator
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Stories this month: \(usageStats.used)/\(usageStats.limit)")
                        .font(.caption.weight(.medium))
                        .foregroundColor(UITheme.Colors.textSecondary)
                    
                    Spacer()
                }
                
                // Progress bar
                ProgressView(value: progressValue)
                    .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                    .scaleEffect(y: 0.5)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(UITheme.Colors.surfaceSecondary)
            )
            
            // Key benefits preview
            VStack(spacing: 8) {
                premiumBenefitRow(
                    icon: "infinity",
                    title: "Unlimited Stories",
                    subtitle: "Create as many stories as you want"
                )
                
                premiumBenefitRow(
                    icon: "books.vertical.fill",
                    title: "Growth Collections",
                    subtitle: "Developmental story sets"
                )
                
                premiumBenefitRow(
                    icon: "bolt.fill",
                    title: "Priority Generation",
                    subtitle: "Skip the wait"
                )
            }
            .padding(.vertical, 4)
            
            // Upgrade button
            Button(action: { showingPaywall = true }) {
                HStack {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                    
                    Text("Upgrade to Premium")
                        .font(UITheme.Typography.headingSmall)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [UITheme.Colors.primary, UITheme.Colors.secondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func premiumBenefitRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(UITheme.Colors.secondary)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(UITheme.Colors.textPrimary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(UITheme.Colors.textSecondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Computed Properties
    
    private var progressValue: Double {
        guard usageStats.limit > 0 else { return 0 }
        return min(1.0, Double(usageStats.used) / Double(usageStats.limit))
    }
    
    private var progressColor: Color {
        let percentage = progressValue
        if percentage >= 1.0 {
            return UITheme.Colors.error
        } else if percentage >= 0.8 {
            return UITheme.Colors.warning
        } else {
            return UITheme.Colors.success
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadUsageStats() async {
        usageStats = await entitlementManager.getUsageStatistics()
    }
}

// MARK: - Preview

#if DEBUG
struct SubscriptionCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Free user preview
                SubscriptionCard()
                    .environmentObject(MockSubscriptionEntitlementManager.freeUser)
                
                // Premium user preview
                SubscriptionCard()
                    .environmentObject(MockSubscriptionEntitlementManager.premiumUser)
            }
            .padding()
        }
        .background(UITheme.Colors.background)
    }
}

// Mock EntitlementManager for previews
class MockSubscriptionEntitlementManager: EntitlementManager {
    override var isPremiumUser: Bool {
        return mockIsPremium
    }
    
    override var subscriptionStatusText: String {
        return mockIsPremium ? "Premium Monthly (expires 12/31/24)" : "Free Plan"
    }
    
    override var renewalInformation: String? {
        return mockIsPremium ? "Renews on 12/31/24" : nil
    }
    
    private let mockIsPremium: Bool
    
    init(isPremium: Bool) {
        self.mockIsPremium = isPremium
        super.init()
    }
    
    static let freeUser = MockSubscriptionEntitlementManager(isPremium: false)
    static let premiumUser = MockSubscriptionEntitlementManager(isPremium: true)
}
#endif