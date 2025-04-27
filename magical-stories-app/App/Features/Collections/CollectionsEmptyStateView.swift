import SwiftUI

struct CollectionsEmptyStateView: View {
    @EnvironmentObject private var tabSelection: TabSelection

    var body: some View {
        VStack {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .padding(.bottom, 8)

            Text("No Collections Yet")
                .font(.title2)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)

            Text("Create your first Growth Collection from the Home tab!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 16)

            Button {
                // Navigate to Home tab
                tabSelection.selectedTab = .home
            } label: {
                Text("Go to Home")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .accessibilityLabel("Go to Home")
        }
        .accessibilityIdentifier("EmptyStateView")
    }
}

#Preview {
    CollectionsEmptyStateView()
        .environmentObject(TabSelection()) // Provide TabSelection for the preview
}