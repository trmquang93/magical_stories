import SwiftUI

/// A card view for adding new collections
struct AddCollectionCardView: View {
    let action: () -> Void

    // Animation states
    @State private var isHovering = false
    @State private var isPressing = false

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            ZStack {
                // Background card with gradient
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(
                                colors: [
                                    Color(.systemBackground),
                                    Color(.systemBackground).opacity(0.95),
                                ]
                            ),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        // Top decorative accent
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(
                                        colors: [
                                            Color.magicalPrimary.opacity(0.5),
                                            Color.magicalPrimary.opacity(0.3),
                                            Color.magicalPrimary.opacity(0.1),
                                            Color.clear,
                                        ]
                                    ),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 80)
                            .clipped()
                            .mask(
                                RoundedRectangle(cornerRadius: 20)
                                    .frame(height: 80)
                            ),
                        alignment: .top
                    )
                    .overlay(
                        // Border with subtle gradient
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(
                                        colors: [
                                            Color.magicalPrimary.opacity(0.5),
                                            Color(.separator).opacity(0.2),
                                        ]
                                    ),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isDashed ? 2 : 1.5
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(0.08),
                        radius: isHovering ? 12 : 6,
                        x: 0,
                        y: isHovering ? 8 : 4
                    )

                // Content
                VStack(spacing: 16) {
                    // Add icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(
                                        colors: [
                                            Color.magicalPrimary,
                                            Color.magicalPrimary.opacity(0.8),
                                        ]
                                    ),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(color: Color.magicalPrimary.opacity(0.3), radius: 5, x: 0, y: 3)

                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(isPressing ? 0.9 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressing)

                    // Text
                    Text("Create New Collection")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.magicalPrimary)
                        .multilineTextAlignment(.center)

                    Text("Design a themed set of stories")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(16)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .aspectRatio(0.75, contentMode: .fit)
        .frame(minWidth: 160, maxWidth: 220)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .pressAction {
            isPressing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isPressing = false
            }
        }
        .scaleEffect(isHovering ? 1.03 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Create new collection")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("AddCollectionCardView")
    }

    // Use dashed border for empty state
    private var isDashed: Bool {
        true
    }
}

// View modifier for handling press states
struct PressActionModifier: ViewModifier {
    var onPress: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        onPress()
                    }
            )
    }
}

extension View {
    func pressAction(onPress: @escaping () -> Void) -> some View {
        modifier(PressActionModifier(onPress: onPress))
    }
}

#Preview("Light Mode") {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        AddCollectionCardView {
            print("Add collection tapped")
        }
        .frame(width: 200)
        .padding()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        AddCollectionCardView {
            print("Add collection tapped")
        }
        .frame(width: 200)
        .padding()
    }
    .preferredColorScheme(.dark)
}
