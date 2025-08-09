import SwiftUI

/// Debug view for testing and monitoring the rating system
struct RatingDebugView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var ratingService: RatingService
    
    @State private var engagementScore: Double = 0.0
    @State private var recentEvents: [RatingEngagementRecord] = []
    @State private var engagementAnalysis: EngagementAnalysis = EngagementAnalysis()
    @State private var currentConfig: RatingConfiguration?
    @State private var isLoading = false
    @State private var lastActionResult: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: UITheme.Spacing.lg) {
                    // Current Status Section
                    VStack(alignment: .leading, spacing: UITheme.Spacing.md) {
                        Text("Current Status")
                            .font(UITheme.Typography.headingMedium)
                            .foregroundColor(UITheme.Colors.textPrimary)
                        
                        VStack(spacing: UITheme.Spacing.sm) {
                            StatusRow(
                                title: "Engagement Score",
                                value: String(format: "%.1f%%", engagementScore * 100)
                            )
                            
                            StatusRow(
                                title: "App Launches",
                                value: "\(engagementAnalysis.appLaunches)"
                            )
                            
                            StatusRow(
                                title: "Stories Created",
                                value: "\(engagementAnalysis.storiesCreated)"
                            )
                            
                            StatusRow(
                                title: "Rating Requests Shown",
                                value: "\(engagementAnalysis.ratingRequestsShown)"
                            )
                        }
                        .padding()
                        .background(UITheme.Colors.surfacePrimary)
                        .cornerRadius(UITheme.Layout.cornerRadiusLarge)
                    }
                    
                    // Configuration Status Section
                    VStack(alignment: .leading, spacing: UITheme.Spacing.md) {
                        Text("Current Configuration")
                            .font(UITheme.Typography.headingMedium)
                            .foregroundColor(UITheme.Colors.textPrimary)
                        
                        VStack(spacing: UITheme.Spacing.xs) {
                            StatusRow(
                                title: "Min App Launches",
                                value: "\(currentConfig?.minimumAppLaunches ?? 0)"
                            )
                            StatusRow(
                                title: "Min Stories Created",
                                value: "\(currentConfig?.minimumStoriesCreated ?? 0)"
                            )
                            StatusRow(
                                title: "Min Days Since First Launch",
                                value: "\(currentConfig?.minimumDaysSinceFirstLaunch ?? 0)"
                            )
                            StatusRow(
                                title: "Min Engagement Score",
                                value: String(format: "%.1f%%", (currentConfig?.minimumEngagementScore ?? 0.0) * 100)
                            )
                            StatusRow(
                                title: "Days Between Requests",
                                value: "\(currentConfig?.minimumDaysBetweenRequests ?? 0)"
                            )
                        }
                        .padding()
                        .background(UITheme.Colors.surfacePrimary)
                        .cornerRadius(UITheme.Layout.cornerRadiusLarge)
                    }
                    
                    // Quick Actions Section
                    VStack(alignment: .leading, spacing: UITheme.Spacing.md) {
                        Text("Quick Actions")
                            .font(UITheme.Typography.headingMedium)
                            .foregroundColor(UITheme.Colors.textPrimary)
                        
                        VStack(spacing: UITheme.Spacing.sm) {
                            ActionButton(
                                title: "Test Rating Request",
                                subtitle: "Show rating dialog (respects conditions)",
                                icon: "star.circle",
                                action: { await testRatingRequest() }
                            )
                            
                            ActionButton(
                                title: "Force Rating Request",
                                subtitle: "Show rating dialog (bypasses conditions)",
                                icon: "star.circle.fill",
                                action: { await forceRatingRequest() }
                            )
                            
                            ActionButton(
                                title: "Simulate Story Creation",
                                subtitle: "Add story creation event",
                                icon: "book.circle",
                                action: { await simulateStoryCreation() }
                            )
                            
                            ActionButton(
                                title: "Simulate App Launch",
                                subtitle: "Add app launch event",
                                icon: "rocket.circle",
                                action: { await simulateAppLaunch() }
                            )
                            
                            ActionButton(
                                title: "Reset Rating Data",
                                subtitle: "Clear all rating tracking data",
                                icon: "trash.circle",
                                color: .red,
                                action: { await resetRatingData() }
                            )
                            
                            ActionButton(
                                title: "Switch to Testing Config",
                                subtitle: "Use minimal requirements for testing",
                                icon: "wrench.and.screwdriver.fill",
                                color: .orange,
                                action: { await switchToTestingConfig() }
                            )
                        }
                    }
                    
                    // Recent Events Section
                    VStack(alignment: .leading, spacing: UITheme.Spacing.md) {
                        Text("Recent Events")
                            .font(UITheme.Typography.headingMedium)
                            .foregroundColor(UITheme.Colors.textPrimary)
                        
                        if recentEvents.isEmpty {
                            Text("No recent events")
                                .font(UITheme.Typography.bodyMedium)
                                .foregroundColor(UITheme.Colors.textSecondary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(UITheme.Colors.surfacePrimary)
                                .cornerRadius(UITheme.Layout.cornerRadiusLarge)
                        } else {
                            LazyVStack(spacing: UITheme.Spacing.xs) {
                                ForEach(recentEvents.indices, id: \.self) { index in
                                    EventRow(event: recentEvents[index])
                                }
                            }
                            .padding()
                            .background(UITheme.Colors.surfacePrimary)
                            .cornerRadius(UITheme.Layout.cornerRadiusLarge)
                        }
                    }
                    
                    // Last Action Result
                    if !lastActionResult.isEmpty {
                        VStack(alignment: .leading, spacing: UITheme.Spacing.sm) {
                            Text("Last Action Result")
                                .font(UITheme.Typography.headingSmall)
                                .foregroundColor(UITheme.Colors.textPrimary)
                            
                            Text(lastActionResult)
                                .font(UITheme.Typography.bodySmall)
                                .foregroundColor(UITheme.Colors.textSecondary)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(UITheme.Layout.cornerRadiusSmall)
                        }
                    }
                }
                .padding(UITheme.Spacing.lg)
            }
            .navigationTitle("Rating Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(UITheme.Colors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        Task { await loadDebugData() }
                    }
                    .foregroundColor(UITheme.Colors.primary)
                    .disabled(isLoading)
                }
            }
        }
        .task {
            await loadDebugData()
        }
    }
    
    // MARK: - Actions
    
    @MainActor
    private func loadDebugData() async {
        isLoading = true
        defer { isLoading = false }
        
        engagementScore = await ratingService.getCurrentEngagementScore()
        recentEvents = await ratingService.getRecentEvents(limit: 10)
        engagementAnalysis = await ratingService.getEngagementAnalysis()
        currentConfig = ratingService.getCurrentConfiguration()
    }
    
    @MainActor
    private func testRatingRequest() async {
        do {
            try await ratingService.requestRating()
            lastActionResult = "✅ Rating request completed successfully"
        } catch {
            lastActionResult = "❌ Rating request failed: \(error.localizedDescription)"
        }
        await loadDebugData()
    }
    
    @MainActor
    private func forceRatingRequest() async {
        do {
            try await ratingService.forceRatingRequest()
            lastActionResult = "✅ Force rating request completed successfully"
        } catch {
            lastActionResult = "❌ Force rating request failed: \(error.localizedDescription)"
        }
        await loadDebugData()
    }
    
    @MainActor
    private func simulateStoryCreation() async {
        await ratingService.handleStoryCreated()
        lastActionResult = "✅ Simulated story creation event"
        await loadDebugData()
    }
    
    @MainActor
    private func simulateAppLaunch() async {
        await ratingService.handleAppLaunch()
        lastActionResult = "✅ Simulated app launch event"
        await loadDebugData()
    }
    
    @MainActor
    private func resetRatingData() async {
        await ratingService.resetRatingData()
        lastActionResult = "✅ Rating data reset successfully"
        await loadDebugData()
    }
    
    @MainActor
    private func switchToTestingConfig() async {
        await ratingService.updateConfiguration(.testing)
        lastActionResult = "✅ Switched to testing configuration (minimal requirements)"
        await loadDebugData()
    }
}

// MARK: - Supporting Views

struct StatusRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(UITheme.Typography.bodyMedium)
                .foregroundColor(UITheme.Colors.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(UITheme.Typography.bodyMedium.weight(.semibold))
                .foregroundColor(UITheme.Colors.primary)
        }
    }
}

struct ActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () async -> Void
    
    @State private var isExecuting = false
    
    init(
        title: String,
        subtitle: String,
        icon: String,
        color: Color = .blue,
        action: @escaping () async -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            Task {
                isExecuting = true
                await action()
                isExecuting = false
            }
        }) {
            HStack(spacing: UITheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(UITheme.Typography.bodyMedium.weight(.medium))
                        .foregroundColor(UITheme.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(UITheme.Typography.bodySmall)
                        .foregroundColor(UITheme.Colors.textSecondary)
                }
                
                Spacer()
                
                if isExecuting {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(UITheme.Colors.textSecondary)
                }
            }
            .padding()
            .background(UITheme.Colors.surfacePrimary)
            .cornerRadius(UITheme.Layout.cornerRadiusLarge)
        }
        .buttonStyle(.plain)
        .disabled(isExecuting)
    }
}

struct EventRow: View {
    let event: RatingEngagementRecord
    
    var body: some View {
        HStack(spacing: UITheme.Spacing.sm) {
            Image(systemName: eventIcon)
                .font(.caption)
                .foregroundColor(eventColor)
                .frame(width: 16, height: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.event.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(UITheme.Typography.bodySmall.weight(.medium))
                    .foregroundColor(UITheme.Colors.textPrimary)
                
                Text(formatTimestamp(event.timestamp))
                    .font(UITheme.Typography.caption)
                    .foregroundColor(UITheme.Colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(.vertical, UITheme.Spacing.xs)
    }
    
    private var eventIcon: String {
        switch event.event {
        case .appLaunched:
            return "rocket.fill"
        case .storyCreated:
            return "book.fill"
        case .storyCompleted:
            return "checkmark.circle.fill"
        case .storyShared:
            return "square.and.arrow.up.fill"
        case .storyFavorited:
            return "heart.fill"
        case .collectionCreated:
            return "folder.fill"
        case .collectionCompleted:
            return "folder.badge.checkmark"
        case .subscribed:
            return "crown.fill"
        case .subscriptionRenewed:
            return "arrow.clockwise"
        case .sessionCompleted:
            return "clock.fill"
        case .weeklyGoalReached:
            return "target"
        case .achievementUnlocked:
            return "trophy.fill"
        case .longSessionCompleted:
            return "timer.circle.fill"
        case .multipleStoriesInSession:
            return "books.vertical.fill"
        case .returningUserSession:
            return "person.crop.circle.badge.checkmark"
        }
    }
    
    private var eventColor: Color {
        switch event.event {
        case .appLaunched:
            return .blue
        case .storyCreated:
            return .green
        case .storyCompleted:
            return .purple
        case .storyShared:
            return .cyan
        case .storyFavorited:
            return .pink
        case .collectionCreated:
            return .indigo
        case .collectionCompleted:
            return .mint
        case .subscribed:
            return .orange
        case .subscriptionRenewed:
            return .yellow
        case .sessionCompleted:
            return .gray
        case .weeklyGoalReached:
            return .red
        case .achievementUnlocked:
            return .brown
        case .longSessionCompleted:
            return .teal
        case .multipleStoriesInSession:
            return .secondary
        case .returningUserSession:
            return .primary
        }
    }
    
    private func formatTimestamp(_ timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
}

// MARK: - Preview Helpers

//#Preview {
//    RatingDebugView()
//        .environmentObject(MockRatingService())
//}

#if DEBUG
// Create a mock service for debug view specifically
class MockRatingService: RatingServiceProtocol, ObservableObject {
    @Published var isRatingRequestInProgress = false
    @Published var lastRatingRequestResult: RatingRequestResult?
    
    func requestRating() async throws {
        // Mock implementation
    }
    
    func forceRatingRequest() async throws {
        // Mock implementation
    }
    
    func shouldRequestRating() async -> Bool {
        return true
    }
    
    func recordEngagementEvent(_ event: RatingTriggerEvent) async {
        // Mock implementation
    }
    
    func getCurrentEngagementScore() async -> Double {
        return 0.75
    }
    
    func resetRatingData() async {
        // Mock implementation
    }
    
    func updateConfiguration(_ configuration: RatingConfiguration) async {
        // Mock implementation
    }
    
    func handleAppLaunch() async {
        // Mock implementation
    }
    
    func handleStoryCreated() async {
        // Mock implementation
    }
    
    func handleStoryCompleted() async {
        // Mock implementation
    }
    
    func handleSubscriptionPurchased() async {
        // Mock implementation
    }
    
    func getEngagementAnalysis() async -> EngagementAnalysis {
        return EngagementAnalysis()
    }
    
    func getRecentEvents(limit: Int = 20) async -> [RatingEngagementRecord] {
        return [
            RatingEngagementRecord(event: .appLaunched, timestamp: Date(), metadata: [:]),
            RatingEngagementRecord(event: .storyCreated, timestamp: Date().addingTimeInterval(-300), metadata: [:]),
            RatingEngagementRecord(event: .storyCompleted, timestamp: Date().addingTimeInterval(-600), metadata: [:])
        ]
    }
}
#endif
