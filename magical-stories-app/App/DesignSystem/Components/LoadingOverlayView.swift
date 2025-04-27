import SwiftUI

struct LoadingOverlayView: View {
    @Environment(\.colorScheme) private var colorScheme
    let isLoading: Bool
    let title: String
    let subtitle: String

    private var primaryGradient: LinearGradient {
        Theme.Colors.primaryGradient
    }

    var body: some View {
        ZStack {
            // Overlay background with blur
            Rectangle()
                .fill(
                    colorScheme == .light
                        ? Color.white.opacity(0.8) : Color.black.opacity(0.8)
                )
                .background(.ultraThinMaterial)
                .ignoresSafeArea(.container)

            VStack(spacing: Theme.Spacing.xl) {
                // Animated magic wand
                loadingWandAnimation

                // Loading text
                loadingText

                // Animated dots
                loadingDots
            }
            .padding(Theme.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        colorScheme == .light
                            ? Color.white.opacity(0.8)
                            : Color(hex: "#1F2937").opacity(0.8)
                    )
                    .background(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 8)
        }
        .transition(.opacity)
        .zIndex(100)
    }

    private var loadingWandAnimation: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(primaryGradient)
                .frame(width: 100, height: 100)
                .blur(radius: 20)
                .opacity(0.7)

            // Spinner
            Circle()
                .trim(from: 0, to: 0.8)
                .stroke(
                    AngularGradient(
                        colors: [Color(hex: "#7B61FF"), Color(hex: "#FF617B")],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 80, height: 80)
                .rotationEffect(Angle(degrees: isLoading ? 360 : 0))
                .animation(
                    Animation.linear(duration: 2).repeatForever(
                        autoreverses: false), value: isLoading)

            // Inner circle
            Circle()
                .fill(colorScheme == .light ? .white : Color(hex: "#1F2937"))
                .frame(width: 60, height: 60)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

            // Magic wand icon
            Image(systemName: "wand.and.stars")
                .font(.system(size: 24))
                .foregroundStyle(primaryGradient)
        }
    }

    private var loadingText: some View {
        VStack(spacing: Theme.Spacing.md) {
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(
                    colorScheme == .light
                        ? Color(hex: "#4A5568") : Color(hex: "#E2E8F0")
                )
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.system(size: 16))
                .foregroundColor(
                    colorScheme == .light
                        ? Color(hex: "#6B7280") : Color(hex: "#9CA3AF")
                )
                .multilineTextAlignment(.center)
                .opacity(0.8)
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    private var loadingDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(primaryGradient)
                    .frame(width: 10, height: 10)
                    .opacity(0.7)
                    .scaleEffect(isLoading ? 1 : 0.5)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: isLoading
                    )
            }
        }
    }
}
