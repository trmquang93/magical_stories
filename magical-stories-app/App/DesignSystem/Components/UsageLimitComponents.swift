import SwiftUI

// MARK: - Usage Limit Indicator

/// A component that shows the current usage status for free tier users
struct UsageLimitIndicator: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var usageStats: (used: Int, limit: Int, isUnlimited: Bool) = (0, 3, false)
    @State private var showingUpgrade = false
    
    var body: some View {
        Group {
            if usageStats.isUnlimited {
                // Premium user - show unlimited status
                premiumStatusView
            } else {
                // Free user - show usage progress
                freeUserProgressView
            }
        }
        .task {
            await loadUsageStats()
        }
    }
    
    private var premiumStatusView: some View {
        HStack {
            Image(systemName: "infinity")
                .foregroundColor(.magicalSuccess)
                .font(.caption.weight(.medium))
            
            Text("Unlimited Stories")
                .font(.caption.weight(.medium))
                .foregroundColor(.magicalSuccess)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.magicalSuccess.opacity(0.1))
        )
    }
    
    private var freeUserProgressView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Usage text and progress bar
            HStack {
                Text("Stories this month: \(usageStats.used)/\(usageStats.limit)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.magicalTextSecondary)
                
                Spacer()
                
                if usageStats.used >= usageStats.limit {
                    Button("Upgrade") {
                        showingUpgrade = true
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.magicalPrimary)
                }
            }
            
            // Progress bar
            ProgressView(value: progressValue)
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                .scaleEffect(y: 0.5)
        }
        .sheet(isPresented: $showingUpgrade) {
            PaywallView(context: .usageLimitReached)
        }
    }
    
    private var progressValue: Double {
        guard usageStats.limit > 0 else { return 0 }
        return min(1.0, Double(usageStats.used) / Double(usageStats.limit))
    }
    
    private var progressColor: Color {
        let percentage = progressValue
        if percentage >= 1.0 {
            return .magicalError
        } else if percentage >= 0.8 {
            return .magicalWarning
        } else {
            return .magicalSuccess
        }
    }
    
    private func loadUsageStats() async {
        usageStats = await entitlementManager.getUsageStatistics()
    }
}

// MARK: - Compact Usage Indicator

/// A compact version of the usage indicator for toolbars and headers
struct CompactUsageLimitIndicator: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var usageStats: (used: Int, limit: Int, isUnlimited: Bool) = (0, 3, false)
    @State private var showingUpgrade = false
    
    var body: some View {
        Button(action: { showingUpgrade = true }) {
            HStack(spacing: 6) {
                if usageStats.isUnlimited {
                    Image(systemName: "infinity")
                        .foregroundColor(.magicalSuccess)
                } else {
                    Text("\(usageStats.used)/\(usageStats.limit)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(textColor)
                }
                
                Image(systemName: "chart.bar.fill")
                    .font(.caption)
                    .foregroundColor(iconColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(backgroundColor)
            )
        }
        .buttonStyle(.plain)
        .disabled(usageStats.isUnlimited)
        .sheet(isPresented: $showingUpgrade) {
            PaywallView(context: .usageLimitReached)
        }
        .task {
            await loadUsageStats()
        }
    }
    
    private var textColor: Color {
        if usageStats.used >= usageStats.limit {
            return .magicalError
        } else if Double(usageStats.used) / Double(usageStats.limit) >= 0.8 {
            return .magicalWarning
        } else {
            return .magicalTextSecondary
        }
    }
    
    private var iconColor: Color {
        return usageStats.isUnlimited ? .magicalSuccess : .magicalTextSecondary
    }
    
    private var backgroundColor: Color {
        if usageStats.isUnlimited {
            return .magicalSuccess.opacity(0.1)
        } else if usageStats.used >= usageStats.limit {
            return .magicalError.opacity(0.1)
        } else {
            return .magicalSurfaceSecondary
        }
    }
    
    private func loadUsageStats() async {
        usageStats = await entitlementManager.getUsageStatistics()
    }
}

// MARK: - Usage Limit Reached View

/// A full-screen view shown when user reaches their usage limit
struct UsageLimitReachedView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingPaywall = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // Icon and messaging
                VStack(spacing: 24) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.magicalPrimary, .magicalSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    VStack(spacing: 16) {
                        Text("You've used all your free stories this month!")
                            .font(.headingLarge.weight(.bold))
                            .foregroundColor(.magicalTextPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text("Upgrade to Premium for unlimited magical adventures and exclusive features")
                            .font(.bodyLarge)
                            .foregroundColor(.magicalTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Feature highlights
                PremiumFeatureHighlights()
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button("Upgrade to Premium") {
                        showingPaywall = true
                    }
                    .font(.bodyLarge.weight(.semibold))
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
                    
                    Button("Maybe Later") {
                        dismiss()
                    }
                    .font(.bodyMedium)
                    .foregroundColor(.magicalTextSecondary)
                }
            }
            .padding(.horizontal, 24)
            .navigationTitle("Usage Limit Reached")
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
        .sheet(isPresented: $showingPaywall) {
            PaywallView(context: .usageLimitReached)
        }
    }
}

// MARK: - Premium Feature Highlights

/// A component that shows key premium features in a compact format
struct PremiumFeatureHighlights: View {
    private let highlights: [(icon: String, title: String, subtitle: String)] = [
        ("infinity", "Unlimited Stories", "Create as many stories as you want"),
        ("books.vertical.fill", "Growth Collections", "Developmental story sets"),
        ("person.2.fill", "Multiple Profiles", "Perfect for families"),
        ("bolt.fill", "Priority Generation", "Skip the wait")
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(Array(highlights.enumerated()), id: \.offset) { index, highlight in
                HStack(spacing: 16) {
                    Image(systemName: highlight.icon)
                        .font(.title2)
                        .foregroundColor(.magicalSecondary)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(highlight.title)
                            .font(.bodyMedium.weight(.semibold))
                            .foregroundColor(.magicalTextPrimary)
                        
                        Text(highlight.subtitle)
                            .font(.caption)
                            .foregroundColor(.magicalTextSecondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.magicalSurfaceSecondary)
                )
            }
        }
    }
}

// MARK: - Usage Reset Notification

/// A banner that shows when usage limits reset
struct UsageResetNotification: View {
    let daysUntilReset: Int
    @State private var isVisible = true
    
    var body: some View {
        if isVisible {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.magicalSecondary)
                
                Text(resetMessage)
                    .font(.caption)
                    .foregroundColor(.magicalTextSecondary)
                
                Spacer()
                
                Button(action: { isVisible = false }) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.magicalTextSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.magicalSecondary.opacity(0.1))
            )
            .transition(.slide)
        }
    }
    
    private var resetMessage: String {
        if daysUntilReset == 0 {
            return "Your story limit resets tomorrow"
        } else if daysUntilReset == 1 {
            return "Your story limit resets in 1 day"
        } else {
            return "Your story limit resets in \(daysUntilReset) days"
        }
    }
}

// MARK: - Story Generation Button with Usage Check

/// A specialized button for story generation that handles usage limits
struct StoryGenerationButton: View {
    let title: String
    let action: () -> Void
    
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var canGenerate = true
    @State private var showingLimitReached = false
    
    var body: some View {
        Button(action: handleAction) {
            HStack {
                Text(title)
                    .font(.bodyLarge.weight(.semibold))
                
                if !canGenerate {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: canGenerate ? 
                        [.magicalPrimary, .magicalSecondary] : 
                        [.gray, .gray.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
        .disabled(!canGenerate)
        .sheet(isPresented: $showingLimitReached) {
            UsageLimitReachedView()
        }
        .task {
            await checkUsageLimit()
        }
    }
    
    private func handleAction() {
        if canGenerate {
            action()
        } else {
            showingLimitReached = true
        }
    }
    
    private func checkUsageLimit() async {
        canGenerate = await entitlementManager.canGenerateStory()
    }
}

// MARK: - Preview

#if DEBUG
struct UsageLimitComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            // Usage limit indicator
            UsageLimitIndicator()
            
            // Compact indicator
            CompactUsageLimitIndicator()
            
            // Premium feature highlights
            PremiumFeatureHighlights()
            
            // Story generation button
            StoryGenerationButton(title: "Generate Story") {
                // Action
            }
            
            // Usage reset notification
            UsageResetNotification(daysUntilReset: 3)
        }
        .padding()
        .environmentObject(MockEntitlementManager.freeUser)
    }
}
#endif