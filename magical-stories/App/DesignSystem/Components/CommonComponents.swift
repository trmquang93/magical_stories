import SwiftUI

// MARK: - MagicalCard
struct MagicalCard<Content: View>: View {
    let content: Content
    var padding: EdgeInsets = EdgeInsets(
        top: Theme.Spacing.md,
        leading: Theme.Spacing.md,
        bottom: Theme.Spacing.md,
        trailing: Theme.Spacing.md
    )
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(Theme.Colors.surfacePrimary)
            .cornerRadius(Theme.Layout.cornerRadiusMedium)
            .shadow(
                color: Color.black.opacity(0.05),
                radius: 8,
                x: 0,
                y: 2
            )
    }
}

// MARK: - MagicalSection
struct MagicalSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(title)
                .font(Theme.Typography.headingMedium)
                .foregroundColor(Theme.Colors.textPrimary)
            
            content
        }
    }
}

// MARK: - MagicalDivider
struct MagicalDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.Colors.surfaceSecondary)
            .frame(height: 1)
    }
}

// MARK: - MagicalLoadingView
struct MagicalLoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(message)
                .font(Theme.Typography.bodyMedium)
                .foregroundColor(Theme.Colors.textSecondary)
                .dynamicTypeSize(...DynamicTypeSize.accessibility5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading")
        .accessibilityHint(message)
    }
}

// MARK: - MagicalErrorView
struct MagicalErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.error)
            
            Text(message)
                .font(Theme.Typography.bodyLarge)
                .foregroundColor(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            PrimaryButton(title: "Try Again") {
                retryAction()
            }
            .frame(maxWidth: 200)
        }
        .padding()
    }
}

// MARK: - MagicalEmptyStateView
struct MagicalEmptyStateView: View {
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.primary)
            
            VStack(spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(Theme.Typography.headingMedium)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                
                Text(message)
                    .font(Theme.Typography.bodyMedium)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility5)
            }
            
            PrimaryButton(title: buttonTitle, action: action)
                .frame(maxWidth: 200)
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(message)
    }
}

// MARK: - Preview
struct CommonComponents_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                MagicalCard {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("Card Title")
                            .font(Theme.Typography.headingMedium)
                        Text("This is a card with some content inside it.")
                            .font(Theme.Typography.bodyMedium)
                    }
                }
                
                MagicalSection("Section Title") {
                    Text("This is a section with content.")
                        .font(Theme.Typography.bodyMedium)
                }
                
                MagicalDivider()
                
                MagicalLoadingView(message: "Generating your story...")
                
                MagicalErrorView(
                    message: "Something went wrong. Please try again."
                ) {
                    print("Retry tapped")
                }
                
                MagicalEmptyStateView(
                    title: "No Stories Yet",
                    message: "Create your first magical story to get started!",
                    buttonTitle: "Create Story"
                ) {
                    print("Create story tapped")
                }
            }
            .padding()
        }
        .background(Theme.Colors.background)
    }
}

/// A magical animated sparkle background for use in HomeView, MainTabView, etc.
/// Sparkles gently float and fade in/out, using ellipses and star shapes.
struct SparkleAnimationView: View {
    // Configurable parameters
    let sparkleCount: Int
    let sparkleColors: [Color]
    let minSize: CGFloat
    let maxSize: CGFloat
    let minDuration: Double
    let maxDuration: Double
    /// Restrict sparkles to a vertical range (0...1 = full height, 0.7...1 = bottom 30%)
    let verticalRange: ClosedRange<CGFloat>?

    @State private var animating = false
    @State private var sparkleStates: [SparkleState] = []

    init(
        sparkleCount: Int = 12,
        sparkleColors: [Color] = [
            .magicPurple.opacity(0.18),
            .skyBlue.opacity(0.14),
            .fairyPink.opacity(0.12),
            .magicalPrimary.opacity(0.10)
        ],
        minSize: CGFloat = 12,
        maxSize: CGFloat = 32,
        minDuration: Double = 2.5,
        maxDuration: Double = 5.0,
        verticalRange: ClosedRange<CGFloat>? = nil
    ) {
        self.sparkleCount = sparkleCount
        self.sparkleColors = sparkleColors
        self.minSize = minSize
        self.maxSize = maxSize
        self.minDuration = minDuration
        self.maxDuration = maxDuration
        self.verticalRange = verticalRange
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<sparkleCount, id: \ .self) { i in
                    let state = sparkleStates.indices.contains(i) ? sparkleStates[i] : SparkleState.random(
                        in: geo.size,
                        minSize: minSize,
                        maxSize: maxSize,
                        colors: sparkleColors,
                        verticalRange: verticalRange
                    )
                    SparkleShape(type: state.type)
                        .fill(state.color)
                        .frame(width: state.size, height: state.size)
                        .position(x: state.x, y: state.y)
                        .opacity(state.opacity)
                        .animation(
                            Animation.easeInOut(duration: state.duration)
                                .repeatForever(autoreverses: true)
                                .delay(state.delay),
                            value: animating
                        )
                        .onAppear {
                            withAnimation {
                                sparkleStates[i] = SparkleState.random(
                                    in: geo.size,
                                    minSize: minSize,
                                    maxSize: maxSize,
                                    colors: sparkleColors,
                                    verticalRange: verticalRange
                                )
                            }
                        }
                }
            }
            .onAppear {
                if sparkleStates.count != sparkleCount {
                    sparkleStates = (0..<sparkleCount).map { _ in
                        SparkleState.random(
                            in: geo.size,
                            minSize: minSize,
                            maxSize: maxSize,
                            colors: sparkleColors,
                            verticalRange: verticalRange
                        )
                    }
                }
                animating = true
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct SparkleState {
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var opacity: Double
    var duration: Double
    var delay: Double
    var type: SparkleType

    static func random(
        in size: CGSize,
        minSize: CGFloat,
        maxSize: CGFloat,
        colors: [Color],
        verticalRange: ClosedRange<CGFloat>? = nil
    ) -> SparkleState {
        let yRange = verticalRange ?? 0...1
        let y = CGFloat.random(in: yRange) * size.height
        return SparkleState(
            x: CGFloat.random(in: 0...size.width),
            y: y,
            size: CGFloat.random(in: minSize...maxSize),
            color: colors.randomElement() ?? .white.opacity(0.12),
            opacity: Double.random(in: 0.10...0.28),
            duration: Double.random(in: 2.5...5.0),
            delay: Double.random(in: 0...2.0),
            type: SparkleType.allCases.randomElement() ?? .ellipse
        )
    }
}

private enum SparkleType: CaseIterable {
    case ellipse, star
}

private struct SparkleShape: Shape {
    let type: SparkleType
    func path(in rect: CGRect) -> Path {
        switch type {
        case .ellipse:
            return Path(ellipseIn: rect)
        case .star:
            return Path { path in
                let center = CGPoint(x: rect.midX, y: rect.midY)
                let points = 5
                let radius = min(rect.width, rect.height) / 2
                let angle = 2 * .pi / Double(points)
                for i in 0..<points {
                    let theta = Double(i) * angle - .pi/2
                    let x = center.x + CGFloat(cos(theta)) * radius
                    let y = center.y + CGFloat(sin(theta)) * radius
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                path.closeSubpath()
            }
        }
    }
}

// TODO: Consider extracting sparkle animation logic for reuse if needed elsewhere.
// TODO: Add more sparkle types/shapes for variety if desired.
// TODO: Tune animation parameters for best visual effect in context.
// TODO: Add preview provider for SparkleAnimationView.

// Documented: verticalRange restricts sparkles to a vertical slice of the view (e.g., 0.7...1 for bottom 30%). 