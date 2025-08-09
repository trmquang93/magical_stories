import SwiftUI

/// A custom progress indicator for collection completion
struct CollectionProgressIndicator: View {
    let progress: Double

    // Computed properties for styling
    private var progressColor: Color {
        switch progress {
        case 0..<0.25:
            return Color(hex: "#FF617B")  // Red-ish for low progress
        case 0.25..<0.75:
            return Color(hex: "#F9A826")  // Orange-yellow for medium progress
        case 0.75...1.0:
            return Color(hex: "#7ED957")  // Green for high progress
        default:
            return Color.magicalPrimary
        }
    }

    private var isComplete: Bool {
        return progress >= 1.0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Progress bar
            ProgressView(value: progress)
                .progressViewStyle(
                    LinearProgressViewStyle(tint: progressColor)
                )
                .scaleEffect(x: 1, y: 1.5, anchor: .center)  // Make the bar slightly thicker
                .animation(.easeInOut, value: progress)

            // Percentage text
            HStack {
                Text("\(Int(progress * 100))% Complete")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                // Completion badge
                if isComplete {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 13))

                        Text("Completed")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.green)
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
        }
        .padding(.horizontal, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Progress: \(Int(progress * 100)) percent")
        .accessibilityAddTraits(isComplete ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview("Progress Indicators", traits: .sizeThatFitsLayout) {
    VStack(spacing: 30) {
        Group {
            Text("10% Progress").font(.caption).foregroundColor(.secondary)
            CollectionProgressIndicator(progress: 0.1)
                .padding()
        }

        Group {
            Text("50% Progress").font(.caption).foregroundColor(.secondary)
            CollectionProgressIndicator(progress: 0.5)
                .padding()
        }

        Group {
            Text("80% Progress").font(.caption).foregroundColor(.secondary)
            CollectionProgressIndicator(progress: 0.8)
                .padding()
        }

        Group {
            Text("100% Progress").font(.caption).foregroundColor(.secondary)
            CollectionProgressIndicator(progress: 1.0)
                .padding()
        }
    }
    .padding()
    .background(Color(.systemBackground))
}
