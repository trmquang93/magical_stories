import SwiftUI

/// A reusable placeholder view for illustrations in different loading states.
/// This view adapts its appearance based on the illustration status.
struct IllustrationPlaceholderView: View {
    /// The current status of the illustration
    let status: IllustrationStatus

    /// The height of the placeholder
    let height: CGFloat

    /// The action to perform when retry button is tapped
    let onRetry: (() -> Void)?

    /// Accessibility label for the placeholder based on status
    var accessibilityLabel: String {
        switch status {
        case .pending:
            return "Illustration will be created soon"
        case .generating:
            return "Generating illustration"
        case .failed:
            return "Illustration failed to load"
        case .ready:
            return "Illustration is ready"
        }
    }

    /// Whether to show the shimmer effect (for pending state)
    var shouldShowShimmer: Bool {
        status == .pending
    }

    /// Whether to show the spinner (for generating state)
    var shouldShowSpinner: Bool {
        status == .generating
    }

    /// Whether to show the retry button (for failed state)
    var shouldShowRetryButton: Bool {
        status == .failed && onRetry != nil
    }

    var body: some View {
        ZStack {
            // Base placeholder
            RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusMedium)
                .fill(UITheme.Colors.surfaceSecondary)
                .frame(height: height)
                .frame(maxWidth: .infinity)
                .if(shouldShowShimmer) { view in
                    view.shimmer()
                }

            // Content based on status
            Group {
                if shouldShowSpinner {
                    ProgressView()
                        .scaleEffect(1.5)
                        .accessibilityHidden(true)
                } else if status == .failed {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(UITheme.Colors.warning)
                            .accessibilityHidden(true)

                        Text("Failed to load illustration")
                            .font(UITheme.Typography.bodySmall)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .accessibilityHidden(true)

                        if shouldShowRetryButton {
                            Button("Try Again") {
                                onRetry?()
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 4)
                            .accessibilityHint("Attempts to regenerate the illustration")
                        }
                    }
                } else if status == .pending {
                    VStack {
                        Image(systemName: "wand.and.stars")
                            .font(.title)
                            .foregroundColor(UITheme.Colors.textSecondary)
                            .padding(.bottom, 8)
                            .accessibilityHidden(true)

                        Text("Magical art is on its way!")
                            .font(UITheme.Typography.bodySmall)
                            .foregroundColor(UITheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
        .accessibilityElement(
            children: status == .failed && shouldShowRetryButton ? .contain : .ignore
        )
        .accessibilityLabel(accessibilityLabel)
        // Only add the trait if we're in a loading state
        .if(status == .pending || status == .generating) { view in
            view.accessibilityAddTraits(.updatesFrequently)
        }
    }
}

// Convenient extension to use if conditionally
extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview("All States") {
    VStack(spacing: 20) {
        IllustrationPlaceholderView(
            status: .pending,
            height: 150,
            onRetry: nil
        )

        IllustrationPlaceholderView(
            status: .generating,
            height: 150,
            onRetry: nil
        )

        IllustrationPlaceholderView(
            status: .failed,
            height: 150,
            onRetry: {}
        )

        IllustrationPlaceholderView(
            status: .ready,
            height: 150,
            onRetry: nil
        )
    }
    .padding()
}

#Preview("Dark Mode") {
    VStack(spacing: 20) {
        IllustrationPlaceholderView(
            status: .pending,
            height: 150,
            onRetry: nil
        )

        IllustrationPlaceholderView(
            status: .failed,
            height: 150,
            onRetry: {}
        )
    }
    .padding()
    .preferredColorScheme(.dark)
}

#Preview("Accessibility") {
    IllustrationPlaceholderView(
        status: .pending,
        height: 150,
        onRetry: nil
    )
    .environment(\.dynamicTypeSize, .accessibility3)
    .padding()
}
