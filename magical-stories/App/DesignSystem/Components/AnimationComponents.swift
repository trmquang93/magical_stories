import SwiftUI

// MARK: - Animation Components

// Enhanced Shine Effect with better animation
struct EnhancedShineEffect: View {
    @State private var shineOffset: CGFloat = -200

    var body: some View {
        GeometryReader { geometry in
            Color.white.opacity(0.3)
                .mask(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .white, location: 0.45),
                                    .init(color: .white, location: 0.55),
                                    .init(color: .clear, location: 1),
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .rotationEffect(.degrees(-30))
                        .offset(x: shineOffset)
                        .frame(width: geometry.size.width * 2)
                )
        }
        .onAppear {
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                shineOffset = 400
            }
        }
    }
}

// Stars Background Animation
struct StarsBackground: View {
    let starCount = 20

    var body: some View {
        ZStack {
            ForEach(0..<starCount, id: \.self) { index in
                AnimatedStar(index: index, starCount: starCount)
            }
        }
    }
}

// Individual animated star
struct AnimatedStar: View {
    let index: Int
    let starCount: Int

    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.5
    @State private var position: CGPoint
    @State private var rotation: Double

    init(index: Int, starCount: Int) {
        self.index = index
        self.starCount = starCount

        // Random initial positions
        let x = CGFloat.random(
            in: UIScreen.main.bounds.width * 0.1...UIScreen.main.bounds.width * 0.9)
        let y = CGFloat.random(
            in: UIScreen.main.bounds.height * 0.1...UIScreen.main.bounds.height * 0.9)
        self._position = State(initialValue: CGPoint(x: x, y: y))
        self._rotation = State(initialValue: Double.random(in: 0...360))
    }

    var body: some View {
        Image(systemName: ["star.fill", "sparkle", "star"].randomElement()!)
            .font(.system(size: CGFloat.random(in: 8...16)))
            .foregroundColor(
                [Color(hex: "#7B61FF"), Color(hex: "#FF617B"), Color(hex: "#FFD700")]
                    .randomElement()!
            )
            .position(position)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                // Random delays for more natural look
                let delay = Double.random(in: 0...3)
                let duration = Double.random(in: 2...4)

                withAnimation(Animation.easeInOut(duration: duration).repeatForever().delay(delay))
                {
                    opacity = Double.random(in: 0.2...0.7)
                    scale = CGFloat.random(in: 0.8...1.2)
                    rotation = Double.random(in: -20...20)
                }
            }
    }
}

// MARK: - Preview
struct AnimationComponents_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea(.container)

            VStack(spacing: 30) {
                // Preview shine effect
                Rectangle()
                    .fill(Color.blue)
                    .frame(height: 60)
                    .overlay(EnhancedShineEffect())
                    .cornerRadius(10)

                // Preview stars animation with container to visualize
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.05))
                        .frame(height: 200)

                    StarsBackground()
                        .frame(height: 200)
                }
            }
            .padding()
        }
    }
}
