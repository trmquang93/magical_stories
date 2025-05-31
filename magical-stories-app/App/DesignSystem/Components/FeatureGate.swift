import SwiftUI

/// A view wrapper that controls access to premium features
/// Shows the wrapped content for premium users, or a locked state for free users
struct FeatureGate<Content: View>: View {
    let feature: PremiumFeature
    let fallbackAction: (() -> Void)?
    let content: Content
    
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var showingUpgrade = false
    
    /// Creates a feature gate for a premium feature
    /// - Parameters:
    ///   - feature: The premium feature to gate
    ///   - fallback: Optional action to perform when feature is restricted
    ///   - content: The content to show when user has access
    init(
        _ feature: PremiumFeature,
        fallback: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.feature = feature
        self.fallbackAction = fallback
        self.content = content()
    }
    
    var body: some View {
        if entitlementManager.hasAccess(to: feature) {
            content
        } else {
            PremiumFeatureLockedView(feature: feature) {
                if let fallback = fallbackAction {
                    fallback()
                } else {
                    showingUpgrade = true
                }
            }
            .sheet(isPresented: $showingUpgrade) {
                PaywallView(context: .featureRestricted)
            }
        }
    }
}

/// A view that displays when a premium feature is locked
struct PremiumFeatureLockedView: View {
    let feature: PremiumFeature
    let onUpgrade: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Feature icon
            Image(systemName: feature.iconName)
                .font(.system(size: 48))
                .foregroundColor(.magicalSecondary)
            
            // Feature information
            VStack(spacing: 8) {
                Text(feature.displayName)
                    .font(.headingMedium)
                    .foregroundColor(.magicalTextPrimary)
                
                Text(feature.unlockMessage)
                    .font(.bodyMedium)
                    .foregroundColor(.magicalTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Upgrade button
            Button(action: onUpgrade) {
                HStack {
                    Image(systemName: "crown.fill")
                    Text("Upgrade to Premium")
                }
                .font(.bodyMedium.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.magicalPrimary, .magicalSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.magicalSurfaceSecondary)
                .stroke(.magicalSecondary.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

/// A compact feature gate that shows an inline upgrade prompt
struct CompactFeatureGate<Content: View>: View {
    let feature: PremiumFeature
    let content: Content
    
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var showingUpgrade = false
    
    init(
        _ feature: PremiumFeature,
        @ViewBuilder content: () -> Content
    ) {
        self.feature = feature
        self.content = content()
    }
    
    var body: some View {
        if entitlementManager.hasAccess(to: feature) {
            content
        } else {
            Button(action: { showingUpgrade = true }) {
                HStack {
                    Image(systemName: feature.iconName)
                        .foregroundColor(.magicalSecondary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.displayName)
                            .font(.bodyMedium.weight(.medium))
                            .foregroundColor(.magicalTextPrimary)
                        
                        Text("Premium Feature")
                            .font(.caption)
                            .foregroundColor(.magicalSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.magicalSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.magicalSurfaceSecondary)
                        .stroke(.magicalSecondary.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingUpgrade) {
                PaywallView(context: .featureRestricted)
            }
        }
    }
}

/// A feature gate specifically for buttons that should be disabled for free users
struct ButtonFeatureGate: View {
    let feature: PremiumFeature
    let title: String
    let systemImage: String?
    let action: () -> Void
    
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var showingUpgrade = false
    
    init(
        _ feature: PremiumFeature,
        title: String,
        systemImage: String? = nil,
        action: @escaping () -> Void
    ) {
        self.feature = feature
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }
    
    var body: some View {
        Button(action: buttonAction) {
            HStack {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                
                if !entitlementManager.hasAccess(to: feature) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                }
            }
        }
        .disabled(!entitlementManager.hasAccess(to: feature))
        .sheet(isPresented: $showingUpgrade) {
            PaywallView(context: .featureRestricted)
        }
    }
    
    private func buttonAction() {
        if entitlementManager.hasAccess(to: feature) {
            action()
        } else {
            showingUpgrade = true
        }
    }
}

/// A view modifier that applies feature gating to any view
struct FeatureGated: ViewModifier {
    let feature: PremiumFeature
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var showingUpgrade = false
    
    func body(content: Content) -> some View {
        if entitlementManager.hasAccess(to: feature) {
            content
        } else {
            content
                .disabled(true)
                .opacity(0.6)
                .overlay(
                    Button(action: { showingUpgrade = true }) {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.magicalSecondary)
                            .padding(4)
                            .background(Circle().fill(.magicalSurfacePrimary))
                    }
                    .buttonStyle(.plain),
                    alignment: .topTrailing
                )
                .sheet(isPresented: $showingUpgrade) {
                    PaywallView(context: .featureRestricted)
                }
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Applies feature gating to this view
    /// - Parameter feature: The premium feature required to access this view
    /// - Returns: A view that shows a locked state for free users
    func featureGated(_ feature: PremiumFeature) -> some View {
        modifier(FeatureGated(feature: feature))
    }
}

// MARK: - Preview Helpers

#if DEBUG
struct FeatureGate_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            // Full feature gate
            FeatureGate(.growthPathCollections) {
                VStack {
                    Text("Growth Path Collections")
                        .font(.headingMedium)
                    Text("Create developmental story collections")
                        .font(.bodyMedium)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(.magicalSurfacePrimary))
            }
            
            // Compact feature gate
            CompactFeatureGate(.unlimitedStoryGeneration) {
                Text("This content is for premium users")
                    .padding()
            }
            
            // Button feature gate
            ButtonFeatureGate(
                .multipleChildProfiles,
                title: "Add Child Profile",
                systemImage: "person.badge.plus"
            ) {
                // Action
            }
            
            // Feature gated modifier
            Button("Premium Feature") {
                // Action
            }
            .featureGated(.customThemes)
        }
        .padding()
        .environmentObject(MockEntitlementManager.freeUser)
    }
}

class MockEntitlementManager: EntitlementManager {
    static let freeUser = MockEntitlementManager(isPremium: false)
    static let premiumUser = MockEntitlementManager(isPremium: true)
    
    private let isPremium: Bool
    
    init(isPremium: Bool) {
        self.isPremium = isPremium
        super.init()
    }
    
    override func hasAccess(to feature: PremiumFeature) -> Bool {
        return isPremium
    }
}
#endif