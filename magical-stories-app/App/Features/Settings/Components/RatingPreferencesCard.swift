import SwiftUI

/// Rating preferences card for settings
struct RatingPreferencesCard: View {
    @EnvironmentObject private var ratingService: RatingService
    @State private var isRatingEnabled: Bool = true
    @State private var showingRatingInfo = false
    @State private var engagementScore: Double = 0.0
    @State private var showingDebugInfo = false
    
    var body: some View {
        SettingsCard(title: "App Rating", icon: "star.fill") {
            VStack(spacing: UITheme.Spacing.lg) {
                // Main rating toggle
                HStack {
                    VStack(alignment: .leading, spacing: UITheme.Spacing.xs) {
                        Text("Enable Rating Requests")
                            .font(UITheme.Typography.bodyMedium)
                            .foregroundColor(UITheme.Colors.textPrimary)
                        
                        Text("Allow the app to occasionally ask for ratings to help improve the experience")
                            .font(UITheme.Typography.caption)
                            .foregroundColor(UITheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isRatingEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: UITheme.Colors.primary))
                        .accessibilityLabel("Enable Rating Requests")
                }
                
                if isRatingEnabled {
                    Divider()
                        .padding(.vertical, UITheme.Spacing.xs)
                    
                    // Rating status information
                    VStack(spacing: UITheme.Spacing.md) {
                        // Engagement score display
                        HStack {
                            Text("Engagement Score")
                                .font(UITheme.Typography.bodyMedium)
                                .foregroundColor(UITheme.Colors.textPrimary)
                            
                            Spacer()
                            
                            HStack(spacing: UITheme.Spacing.xs) {
                                Text(String(format: "%.0f%%", engagementScore * 100))
                                    .font(UITheme.Typography.bodyMedium.weight(.semibold))
                                    .foregroundColor(engagementScoreColor)
                                
                                Button(action: { showingRatingInfo = true }) {
                                    Image(systemName: "info.circle")
                                        .font(.caption)
                                        .foregroundColor(UITheme.Colors.textSecondary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Learn more about rating system")
                            }
                        }
                        
                        // Engagement progress bar
                        ProgressView(value: engagementScore, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: engagementScoreColor))
                            .scaleEffect(x: 1, y: 1.5, anchor: .center)
                        
                        // Test rating button for premium users or debug builds
                        #if DEBUG
                        Button(action: { Task { await testRatingRequest() } }) {
                            HStack {
                                Image(systemName: "star.circle")
                                Text("Test Rating Request")
                            }
                            .font(UITheme.Typography.bodyMedium.weight(.medium))
                            .foregroundColor(UITheme.Colors.primary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Test rating request functionality")
                        #endif
                    }
                }
                
                #if DEBUG
                // Debug controls for testing
                if showingDebugInfo {
                    Divider()
                        .padding(.vertical, UITheme.Spacing.xs)
                    
                    VStack(spacing: UITheme.Spacing.sm) {
                        Text("DEBUG CONTROLS")
                            .font(UITheme.Typography.caption.weight(.semibold))
                            .foregroundColor(UITheme.Colors.textSecondary)
                        
                        HStack(spacing: UITheme.Spacing.md) {
                            Button("Force Rating") {
                                Task { await forceRatingRequest() }
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                            
                            Button("Reset Data") {
                                Task { await resetRatingData() }
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                        }
                    }
                }
                
                // Debug toggle
                Button(action: { showingDebugInfo.toggle() }) {
                    Text(showingDebugInfo ? "Hide Debug" : "Show Debug")
                        .font(.caption)
                        .foregroundColor(UITheme.Colors.textSecondary)
                }
                .buttonStyle(.plain)
                #endif
            }
        }
        .sheet(isPresented: $showingRatingInfo) {
            RatingInfoSheet()
        }
        .onAppear {
            Task {
                await loadRatingPreferences()
            }
        }
        .onChange(of: isRatingEnabled) { _, newValue in
            Task {
                await updateRatingEnabled(newValue)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var engagementScoreColor: Color {
        switch engagementScore {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return UITheme.Colors.primary
        case 0.4..<0.6:
            return .orange
        default:
            return .red
        }
    }
    
    // MARK: - Actions
    
    @MainActor
    private func loadRatingPreferences() async {
        // Load current engagement score
        engagementScore = await ratingService.getCurrentEngagementScore()
        
        // Note: Rating enabled state could be loaded from configuration
        // For now, we assume it's always enabled unless explicitly disabled
        isRatingEnabled = true
    }
    
    @MainActor
    private func updateRatingEnabled(_ enabled: Bool) async {
        // Create a new configuration with the enabled flag
        let newConfig = RatingConfiguration(
            maxRatingRequestsPerYear: 3,
            minimumDaysBetweenRequests: 30,
            minimumEngagementScore: 0.6,
            minimumAppLaunches: 5,
            minimumStoriesCreated: 3,
            minimumDaysSinceFirstLaunch: 3,
            isRatingSystemEnabled: enabled,
            useAppStoreReviewWhenAvailable: true,
            isAnalyticsEnabled: true,
            isDebugLoggingEnabled: false
        )
        
        await ratingService.updateConfiguration(newConfig)
    }
    
    @MainActor
    private func testRatingRequest() async {
        do {
            try await ratingService.requestRating()
        } catch {
            print("[RatingPreferencesCard] Test rating request failed: \(error)")
            // Could show an alert here in a real app
        }
    }
    
    #if DEBUG
    @MainActor
    private func forceRatingRequest() async {
        do {
            try await ratingService.forceRatingRequest()
        } catch {
            print("[RatingPreferencesCard] Force rating request failed: \(error)")
        }
    }
    
    @MainActor
    private func resetRatingData() async {
        await ratingService.resetRatingData()
        await loadRatingPreferences()
    }
    #endif
}

/// Information sheet about the rating system
struct RatingInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: UITheme.Spacing.lg) {
                VStack(alignment: .leading, spacing: UITheme.Spacing.md) {
                    Text("About App Ratings")
                        .font(UITheme.Typography.headingLarge)
                        .foregroundColor(UITheme.Colors.textPrimary)
                    
                    Text("We use an engagement-based system to ask for ratings at appropriate times when you're enjoying the app.")
                        .font(UITheme.Typography.bodyMedium)
                        .foregroundColor(UITheme.Colors.textSecondary)
                }
                
                VStack(alignment: .leading, spacing: UITheme.Spacing.md) {
                    Text("How Engagement is Calculated")
                        .font(UITheme.Typography.headingMedium)
                        .foregroundColor(UITheme.Colors.textPrimary)
                    
                    VStack(alignment: .leading, spacing: UITheme.Spacing.sm) {
                        EngagementFactorRow(
                            icon: "rocket.fill",
                            title: "App Usage",
                            description: "Regular app launches and time spent in the app"
                        )
                        
                        EngagementFactorRow(
                            icon: "book.fill",
                            title: "Story Creation",
                            description: "Creating and reading personalized stories"
                        )
                        
                        EngagementFactorRow(
                            icon: "heart.fill",
                            title: "Positive Actions",
                            description: "Completing stories, sharing content, and other engaged behaviors"
                        )
                    }
                }
                
                Spacer()
            }
            .padding(UITheme.Spacing.lg)
            .navigationTitle("Rating System")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(UITheme.Colors.primary)
                }
            }
        }
    }
}

/// Row displaying an engagement factor
struct EngagementFactorRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: UITheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(UITheme.Colors.primary)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: UITheme.Spacing.xs) {
                Text(title)
                    .font(UITheme.Typography.bodyMedium.weight(.medium))
                    .foregroundColor(UITheme.Colors.textPrimary)
                
                Text(description)
                    .font(UITheme.Typography.bodySmall)
                    .foregroundColor(UITheme.Colors.textSecondary)
            }
        }
    }
}

// MARK: - Preview Helpers

//#Preview {
//    VStack {
//        RatingPreferencesCard()
//        Spacer()
//    }
//    .padding()
//    .background(UITheme.Colors.background)
//    .environmentObject(MockRatingServiceForPreferences())
//}

#if DEBUG
class MockRatingServiceForPreferences: RatingServiceProtocol, ObservableObject {
    @Published var isRatingRequestInProgress = false
    @Published var lastRatingRequestResult: RatingRequestResult?
    
    func getCurrentEngagementScore() async -> Double {
        return 0.75
    }
    
    func updateConfiguration(_ configuration: RatingConfiguration) async {
        print("Mock: Updated configuration")
    }
    
    func requestRating() async throws {
        print("Mock: Rating requested")
    }
    
    func forceRatingRequest() async throws {
        print("Mock: Force rating requested")
    }
    
    func resetRatingData() async {
        print("Mock: Rating data reset")
    }
    
    func shouldRequestRating() async -> Bool {
        return true
    }
    
    func recordEngagementEvent(_ event: RatingTriggerEvent) async {
        print("Mock: Recorded engagement event: \(event.rawValue)")
    }
    
    func handleAppLaunch() async {
        print("Mock: App launch recorded")
    }
    
    func handleStoryCreated() async {
        print("Mock: Story created recorded")
    }
    
    func handleStoryCompleted() async {
        print("Mock: Story completed recorded")
    }
    
    func handleSubscriptionPurchased() async {
        print("Mock: Subscription purchased recorded")
    }
    
    func getEngagementAnalysis() async -> EngagementAnalysis {
        return EngagementAnalysis()
    }
    
    func getRecentEvents(limit: Int = 20) async -> [RatingEngagementRecord] {
        return []
    }
}
#endif
