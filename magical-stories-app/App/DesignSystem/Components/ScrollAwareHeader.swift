import SwiftUI

struct ScrollAwareHeader<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content
    @Binding var isVisible: Bool
    @State private var titleOpacity: Double = 0

    init(
        title: String, subtitle: String? = nil, isVisible: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self._isVisible = isVisible
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Fixed header that appears on scroll
            if isVisible {
                VStack(spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headingMedium)
                            .foregroundColor(UITheme.Colors.textPrimary)
                            .opacity(titleOpacity)

                        Spacer()

                        content
                    }

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.bodyMedium)
                            .foregroundColor(UITheme.Colors.textSecondary)
                            .opacity(titleOpacity)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, UITheme.Spacing.lg)
                .padding(.bottom, UITheme.Spacing.sm)
                .background(
                    UITheme.Colors.background
                        .opacity(0.95)
                )
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.3)),
                    alignment: .bottom
                )
                .transition(.opacity)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        titleOpacity = 1.0
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isVisible)
    }
}

// ScrollViewOffsetPredictor helps detect scroll position without affecting it
struct ScrollViewOffsetPredictor: View {
    let coordinateSpace: String
    @Binding var scrollOffset: CGPoint
    @Binding var scrollDirection: ScrollDirection
    @State private var previousOffset: CGFloat = 0

    // Enum to track scroll direction
    enum ScrollDirection {
        case up, down, none
    }

    var body: some View {
        GeometryReader { geometry in
            Color.clear.preference(
                key: ScrollOffsetPreferenceKey.self,
                value: CGPoint(
                    x: geometry.frame(in: .named(coordinateSpace)).origin.x,
                    y: geometry.frame(in: .named(coordinateSpace)).origin.y
                )
            )
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                Task { @MainActor in
                // Only update if the change is significant to avoid micro-oscillations
                if abs(value.y - scrollOffset.y) > 1 {
                    // Determine scroll direction
                    if value.y > previousOffset {
                        scrollDirection = .down
                    } else if value.y < previousOffset {
                        scrollDirection = .up
                    }

                    previousOffset = value.y
                    scrollOffset = value
                }
                }
            }
        }
    }
}

// Preference key to track scroll offset
struct ScrollOffsetPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGPoint = .zero

    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}

#Preview("ScrollAwareHeader") {
    VStack {
        ScrollAwareHeader(
            title: "Library", subtitle: "Your magical story collection", isVisible: .constant(true)
        ) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 24))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.calmBlue, .magicPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        Spacer()
    }
}
