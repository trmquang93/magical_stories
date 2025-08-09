import SwiftUI

/// Settings card for analytics and privacy preferences
struct AnalyticsPrivacyCard: View {
    @EnvironmentObject private var analyticsService: ClarityAnalyticsService
    @AppStorage("user_has_opted_out_of_analytics") private var hasOptedOut: Bool = false
    
    var body: some View {
        SettingsCard(
            title: "Analytics & Privacy",
            icon: "chart.bar.xaxis"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                // Analytics description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Usage Analytics")
                        .font(.bodyLarge.weight(.medium))
                        .foregroundColor(.magicalTextPrimary)
                    
                    Text("Help us improve the app by sharing anonymous usage data. No personal information is collected.")
                        .font(.bodyMedium)
                        .foregroundColor(.magicalTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Analytics toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Share Usage Data")
                            .font(.bodyMedium.weight(.medium))
                            .foregroundColor(.magicalTextPrimary)
                        
                        Text("Anonymous app usage statistics")
                            .font(.bodySmall)
                            .foregroundColor(.magicalTextSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: .init(
                        get: { !hasOptedOut },
                        set: { enabled in
                            hasOptedOut = !enabled
                            Task { @MainActor in
                                ClarityConfiguration.setAnalyticsOptOut(!enabled)
                                
                                // Track the privacy preference change
                                if enabled {
                                    analyticsService.trackUserAction("analytics_enabled", parameters: [
                                        "source": "settings",
                                        "timestamp": Date().timeIntervalSince1970
                                    ])
                                }
                            }
                        }
                    ))
                    .labelsHidden()
                    .accessibilityLabel("Share usage data")
                    .accessibilityHint(hasOptedOut ? "Currently disabled" : "Currently enabled")
                }
                
                // Privacy information
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "shield.checkered")
                            .foregroundColor(.magicalSuccess)
                            .font(.system(size: 16))
                        
                        Text("Your Privacy is Protected")
                            .font(.bodyMedium.weight(.medium))
                            .foregroundColor(.magicalTextPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        privacyPoint("No personal information collected")
                        privacyPoint("Data is anonymized and encrypted")
                        privacyPoint("GDPR and CCPA compliant")
                        privacyPoint("You can opt out anytime")
                    }
                }
                
                // Learn more button
                Button(action: {
                    analyticsService.trackUserAction("privacy_policy_viewed", parameters: [
                        "source": "settings_analytics_card",
                        "timestamp": Date().timeIntervalSince1970
                    ])
                    
                    // Open privacy policy (implement as needed)
                    if let url = URL(string: "https://clarity.microsoft.com/privacy") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                        
                        Text("Learn More About Privacy")
                            .font(.bodySmall)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.magicalSecondary)
                    .padding(.vertical, 8)
                }
                .accessibilityLabel("Learn more about privacy policy")
                .accessibilityHint("Opens external privacy policy")
            }
        }
    }
    
    private func privacyPoint(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.magicalSuccess)
                .font(.system(size: 12))
            
            Text(text)
                .font(.bodySmall)
                .foregroundColor(.magicalTextSecondary)
        }
    }
}

#Preview {
    AnalyticsPrivacyCard()
        .environmentObject(ClarityAnalyticsService.shared)
        .padding()
}