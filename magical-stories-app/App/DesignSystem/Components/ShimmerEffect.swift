import SwiftUI

/// A reusable shimmer effect component that can be applied to any view
/// to indicate loading state.
struct ShimmerEffect: ViewModifier {
    // The gradient used for the shimmer effect
    let gradient: LinearGradient
    // Whether the shimmer should be static (non-animated)
    let isStatic: Bool

    // Properties for the animation
    private let duration: Double = 1.5
    @State private var phase: CGFloat = 0

    /// Initialize with default color values
    init(
        isStatic: Bool = false,
        startColor: Color = Color(.systemGray6).opacity(0.0),
        centerColor: Color = Color(.systemGray5).opacity(0.5),
        endColor: Color = Color(.systemGray6).opacity(0.0)
    ) {
        self.isStatic = isStatic
        self.gradient = LinearGradient(
            stops: [
                .init(color: startColor, location: 0.0),
                .init(color: centerColor, location: 0.5),
                .init(color: endColor, location: 1.0),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Determine if animation should be active based on accessibility settings and isStatic flag
    func isAnimating(
        isReduceMotion: Bool = UIAccessibility.isReduceMotionEnabled, isStatic: Bool? = nil
    ) -> Bool {
        let staticValue = isStatic ?? self.isStatic
        return !isReduceMotion && !staticValue
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    gradient
                        .rotationEffect(.degrees(45))
                        .offset(x: -geo.size.width + phase * (geo.size.width * 3))
                        .frame(width: geo.size.width * 3)
                }
            )
            .mask(content)
            .onAppear {
                if isAnimating() {
                    withAnimation(
                        Animation.linear(duration: duration)
                            .repeatForever(autoreverses: false)
                    ) {
                        phase = 1.0
                    }
                }
            }
    }
}

// Extension to make usage cleaner
extension View {
    func shimmer(isStatic: Bool = false) -> some View {
        modifier(ShimmerEffect(isStatic: isStatic))
    }

    func shimmer(
        isStatic: Bool = false,
        startColor: Color,
        centerColor: Color,
        endColor: Color
    ) -> some View {
        modifier(
            ShimmerEffect(
                isStatic: isStatic,
                startColor: startColor,
                centerColor: centerColor,
                endColor: endColor
            )
        )
    }
}

#Preview {
    VStack(spacing: 30) {
        Text("Loading...")
            .font(.title)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .shimmer()

        RoundedRectangle(cornerRadius: 10)
            .fill(Color(.systemGray6))
            .frame(height: 100)
            .shimmer()

        RoundedRectangle(cornerRadius: 10)
            .fill(Color(.systemGray6))
            .frame(height: 100)
            .shimmer(
                startColor: Color.pink.opacity(0.0),
                centerColor: Color.pink.opacity(0.5),
                endColor: Color.pink.opacity(0.0)
            )

        RoundedRectangle(cornerRadius: 10)
            .fill(Color(.systemGray6))
            .frame(height: 100)
            .shimmer(isStatic: true)
            .overlay(Text("Static Shimmer (for Reduced Motion)"))
    }
    .padding()
    .preferredColorScheme(.light)
}
