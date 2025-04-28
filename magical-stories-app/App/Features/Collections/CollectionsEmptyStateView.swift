import SwiftUI

struct CollectionsEmptyStateView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 24) {
            // Animated illustration
            ZStack {
                // Background circles
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Color.magicalPrimary.opacity(0.1), lineWidth: 2)
                        .frame(width: 120 + CGFloat(i * 40), height: 120 + CGFloat(i * 40))
                }

                // Floating icons animation
                ZStack {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 24))
                        .foregroundColor(Color.magicalPrimary)
                        .offset(x: isAnimating ? 20 : -20, y: isAnimating ? -30 : -10)
                        .rotationEffect(.degrees(isAnimating ? 10 : -10))

                    Image(systemName: "book.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#FF617B"))
                        .offset(x: isAnimating ? -30 : -10, y: isAnimating ? 20 : -20)
                        .rotationEffect(.degrees(isAnimating ? -5 : 5))

                    Image(systemName: "sparkles")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#F9A826"))
                        .offset(x: isAnimating ? 15 : 30, y: isAnimating ? 15 : 30)
                        .rotationEffect(.degrees(isAnimating ? 15 : -5))
                }
                .animation(
                    Animation.easeInOut(duration: 3)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )

                // Main icon
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(
                                colors: [
                                    Color.magicalPrimary.opacity(0.9),
                                    Color.magicalPrimary.opacity(0.7),
                                ]
                            ),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.magicalPrimary.opacity(0.3), radius: 10, x: 0, y: 5)
                    .overlay(
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                    )
            }
            .frame(height: 200)

            // Text content
            Text("Growth Collections")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)

            Text(
                "Create collections of themed stories designed to support your child's development. Each collection focuses on specific skills like emotional intelligence or problem solving."
            )
            .font(.system(size: 16))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .lineSpacing(4)

            // Create button
            Button {
                // This would be handled by a parent view
            } label: {
                HStack {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))

                    Text("Create First Collection")
                        .font(.system(size: 16, weight: .semibold))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(
                                    colors: [
                                        Color.magicalPrimary, Color.magicalPrimary.opacity(0.8),
                                    ]
                                ),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .foregroundColor(.white)
                .shadow(color: Color.magicalPrimary.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .padding(.top, 8)

            // Benefits
            VStack(spacing: 20) {
                benefitRow(
                    icon: "brain.head.profile",
                    title: "Support Development",
                    description: "Themed stories to build specific skills"
                )

                benefitRow(
                    icon: "person.2.fill",
                    title: "Track Progress",
                    description: "See growth as stories are completed"
                )

                benefitRow(
                    icon: "star.fill",
                    title: "Earn Achievements",
                    description: "Celebrate milestones along the way"
                )
            }
            .padding(.top, 32)
        }
        .padding(24)
        .onAppear {
            isAnimating = true
        }
    }

    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.magicalPrimary.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color.magicalPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

#Preview("Empty State") {
    CollectionsEmptyStateView()
        .background(Color(.systemGroupedBackground))
}
