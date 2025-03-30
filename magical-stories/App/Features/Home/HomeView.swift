import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                Text("Create a Magical Story")
                    .font(Theme.Typography.displayLarge)
                    .padding(.top, Theme.Spacing.xl)
                
                Text("Let's create a unique bedtime story for your child")
                    .font(Theme.Typography.bodyLarge)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)
                
                // Placeholder for story creation button
                PrimaryButton(title: "Start Creating") {
                    // Will implement navigation later
                }
                .padding(.horizontal, Theme.Spacing.lg)
                
                Spacer()
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeView()
}
